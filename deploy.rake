# use SSHKit directly instead of Capistrano
require 'sshkit'
require 'yaml'
require 'sshkit/dsl'
include SSHKit::DSL

deploy_config = YAML.load_file('/app/deploy.yml')

# set the identifier used to tag Docker images
deploy_tag = ENV['DEPLOY_TAG']

# set the key used to decrypt the environment variables secret file into .env
env_key = ENV['ENV_KEY']

# set the location on the server of where we want files copied to and commands executed from
deploy_path = deploy_config['remote_path']

app_name = deploy_config['app_name']

hub_account = deploy_config['hub_account']

# Commands to run in the image before it is started
pre_commands = deploy_config['pre'] || []

# Commands to run in the image after it is started
post_commands = deploy_config['post'] || []

# Files to copy to the production environment
remote_files = deploy_config['remote_files'] || []

# connect to server
server = SSHKit::Host.new hostname: ENV['SERVER_HOST'], user: ENV['SERVER_USER'], password: ENV['SERVER_PASS']

namespace :deploy do
  desc 'Copy to server files needed to run and manage Docker containers'
  task configs: 'docker:decrypt' do
    on server do
      upload! '/app/.env', deploy_path
      remote_files.each do |file|
        upload! "/app/#{file}", deploy_path
      end
    end
  end
end

namespace :docker do
  desc 'Build the docker container'
  task build: :decrypt do
    run_locally do
      within '/app' do
        execute "cd /app; docker build -f #{deploy_config['dockerfile']} -t #{hub_account}/#{app_name}:#{deploy_tag} ."
      end
    end
  end

  desc 'Upload the docker to docker hub'
  task push: :login_local do
    run_locally do
      within '/app' do
        execute "docker push #{hub_account}/#{app_name}:#{deploy_tag}"
      end
    end
  end

  desc 'Logs into Docker Hub locally for pushing and pulling'
  task :login_local do
    run_locally do
      execute 'docker', 'login', '-u', ENV['DOCKER_USER'], '-p', "'#{ENV['DOCKER_PASS']}'"
    end
  end

  desc 'Logs into Docker Hub on remote server for pushing and pulling'
  task :login_remote do
    on server do
      within deploy_path do
        execute 'docker', 'login', '-u', ENV['DOCKER_USER'], '-p', "'#{ENV['DOCKER_PASS']}'"
      end
    end
  end

  desc 'Pulls images from Docker Hub'
  task pull: 'docker:login_remote' do
    on server do
      within deploy_path do
        with deploy_tag: deploy_tag do
          execute 'docker', 'pull', "#{ENV['DOCKER_USER']}/#{app_name}:#{deploy_tag}"
        end
      end
    end
  end

  desc 'Decrypt the latest environment variables to .env'
  task :decrypt do
    run_locally do
      execute 'rake secrets:decrypt'
    end
  end

  desc 'Stops all Docker containers via Docker Compose'
  task stop: 'deploy:configs' do
    on server do
      within deploy_path do
        with deploy_tag: deploy_tag do
          execute 'docker-compose', '-f', 'docker-compose.yml', '-f', 'docker-compose.production.yml', 'down', '--remove-orphans'
        end
      end
    end
  end

  desc 'Runs all commands specified in the pre'
  task :pre do
    on server do
      within deploy_path do
        with deploy_tag: deploy_tag do
          pre_commands.each do |command|
            execute 'docker-compose', '-f', 'docker-compose.yml', '-f', 'docker-compose.production.yml', 'run', 'app', "#{command}"
          end
        end
      end
    end
  end

  desc 'Runs all commands specified in the post'
  task :post do
    on server do
      within deploy_path do
        with deploy_tag: deploy_tag do
          post_commands.each do |command|
            execute 'docker-compose', '-f', 'docker-compose.yml', '-f', 'docker-compose.production.yml', 'run', 'app', "#{command}"
          end
        end
      end
    end
  end

  desc 'Starts all Docker containers via Docker Compose'
  task start: 'deploy:configs' do
    on server do
      within deploy_path do
        with deploy_tag: deploy_tag do
          execute 'docker-compose', '-f', 'docker-compose.yml', '-f', 'docker-compose.production.yml', 'up', '-d'

          # Remove the old image and write the new deploy tag to a log file
          execute 'docker', 'rmi', "#{hub_account}/#{app_name}:$(cat deploy.tag)"
          execute 'echo', deploy_tag , '>', 'deploy.tag'
        end
      end
    end
  end

  desc 'pulls images, stops old containers and starts new containers'
  task deploy: %w{docker:pull docker:stop docker:pre docker:start docker:post}

  desc 'builds from local, pushes to hub, pulls images, stops old containers and starts new containers'
  task build_deploy: %w{docker:build docker:push docker:pull docker:stop docker:pre docker:start docker:post}
end
