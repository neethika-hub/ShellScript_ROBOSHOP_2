#!/bin/bash

source ./common.sh

ROOT_VALIDATION
NGINX_INSTALLATION

cd /usr/share/nginx/html
rm -rf *
OUTPUT_VALIDATION $? "Removing default html configurations"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$OUTPUT_LOG
cp /tmp/frontend.zip /usr/share/nginx/html
unzip frontend.zip &>>$OUTPUT_LOG
OUTPUT_VALIDATION $? "Downloading and Unzipping"
rm -rf frontend.zip

cp $SCRIPT_PATH/nginx.conf /etc/nginx/nginx.conf
OUTPUT_VALIDATION $? "Copying nginx configuration"

systemctl restart nginx
OUTPUT_VALIDATION $? "Restarting nginx"