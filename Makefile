#/bin/sh

# Build a Docker image

docker build -t rhombus/website .

#https://github.com/dgofman/static-website-example/settings/secrets/dependabot
docker login -u dgofman

docker tag rhombus/website dgofman/rhombus

docker push dgofman/rhombus

docker run -p 80:80 --name rhombus dgofman/rhombus:master

# Deploy all

cd static-website-example/terraform

terraform init

terraform apply -auto-approve