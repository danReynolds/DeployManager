FROM ruby:2.4

# Add Ruby dependencies necessary for deployment
RUN gem install sshkit rake openssl

# Install Docker
RUN apt-get update
RUN apt-get install -y \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     software-properties-common \
     openssl
RUN curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -

RUN add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
   $(lsb_release -cs) \
   stable"

RUN apt-get update
RUN apt-get install -y docker-ce

RUN mkdir /deploy
WORKDIR /deploy
ADD . /deploy
RUN chmod +x deploy.sh

CMD eval $DEPLOY_COMMAND
