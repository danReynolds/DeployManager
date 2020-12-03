Deploys applications to a server.

## Setup

Create a `deploy.yml` file such as the following:

```yaml
hub_account: danreynolds
app_name: summonerexpert_client
remote_path: /home/deploy/docker/SummonerExpert-Client
dockerfile: Dockerfile.prod
remote_files:
  - docker-compose.yml
  - docker-compose.production.yml
  - nginx.conf
  - nginx.upstream.conf
```

* hub_account: Account to use to upload to docker hub
* app_name: App name to use to deploy to docker hub
* remote_path: Path on server to deploy application to
* dockerfile: Dockerfile to use as base for the image created
* remote files: Files to copy to the remote server in the application directory

## Deployment Usage

To run the deploymanager, create a script such as:

```sh
#!/bin/sh

DEPLOY_COMMAND=${1:-"rake docker:build"}

if [ -z "${ENV_KEY}" ]; then
  echo "Missing ENV_KEY environment variable."
  return
fi

if [ -z "${DEPLOY_TAG}" ]; then
  echo "Missing DEPLOY_TAG environment variable."
  return
fi

docker run -e DEPLOY_COMMAND="$DEPLOY_COMMAND" -e DEPLOY_TAG=$DEPLOY_TAG -e ENV_KEY=$ENV_KEY -v $PWD:/app:rw -v /var/run/docker.sock:/var/run/docker.sock --env-file .env danreynolds/deploymanager:version
```

Where `ENV_KEY` is a required environment variable used in the application and `DEPLOY_TAG` is the tag to be used for the docker image being built and or deployed.

Takes one argument `DEPLOY_COMMAND` which will be executed in the deploy container environment.

## Decryption Usage

```
sudo docker run -e DEPLOY_COMMAND="rake secrets:decrypt" -e ENV_KEY="YOUR_KEY" -v $PWD:/app:rw -v /var/run/docker.sock:/var/run/docker.sock danreynolds/deploymanager:version
```
