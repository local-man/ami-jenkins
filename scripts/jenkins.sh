#!/bin/bash

echo "Installing Jenkins"
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list >/dev/null
sudo apt-get update
sudo apt-get install jenkins -y

sudo apt update
sudo apt install fontconfig openjdk-17-jre -y

java -version

echo "Starting Jenkins"
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

echo "Setup Jenkins CLI"
wget http://localhost:8080/jnlpJars/jenkins-cli.jar -O jenkins-cli.jar

# Wait for Jenkins to start (replace localhost with your Jenkins hostname if necessary)
echo "Waiting for Jenkins to start"
while ! nc -z localhost 8080; do
  sleep 1
done

export JENKINS_URL=http://localhost:8080
export JENKINS_USER=admin
export JENKINS_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# Install recommended plugins
plugins=(
  cloudbees-folder
  antisamy-markup-formatter
  build-timeout
  credentials-binding
  timestamper
  ws-cleanup
  ant
  gradle
  workflow-aggregator
  github-branch-source
  pipeline-github-lib
  pipeline-stage-view
  git
  github
  github-api
  ssh-slaves
  matrix-auth
  pam-auth
  ldap
  email-ext
  mailer
  metrics
  pipeline-graph-view
  docker-commons
  docker-pipeline
  docker
)

# Install the recommended plugins
echo "Installing recommended plugins"
for plugin in "${plugins[@]}"; do
  echo "Installing plugin: $plugin"
  java -jar jenkins-cli.jar -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASSWORD" install-plugin "$plugin"
done

echo "Setup Github credentials"
java -jar jenkins-cli.jar -s "$JENKINS_URL" -auth $JENKINS_USER:$JENKINS_PASSWORD groovy = < ./jenkins_scripts/gh-creds.groovy $GH_ACCESS_TOKEN

echo "Setup Docker credentials"
java -jar jenkins-cli.jar -s "$JENKINS_URL" -auth $JENKINS_USER:$JENKINS_PASSWORD groovy = < ./jenkins_scripts/docker-creds.groovy $DOCKER_ACCESS_TOKEN

echo "Setup Docker image builder job"
java -jar jenkins-cli.jar -s "$JENKINS_URL" -auth $JENKINS_USER:$JENKINS_PASSWORD groovy = < ./jenkins_scripts/docker-image-job.groovy

echo "Restarting Jenkins to apply plugin changes"
java -jar jenkins-cli.jar -s "$JENKINS_URL" -auth $JENKINS_USER:$JENKINS_PASSWORD safe-restart
