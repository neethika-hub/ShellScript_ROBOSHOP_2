#!/bin/bash

source ./common.sh

ROOT_VALIDATION

cp $SCRIPT_PATH/mongo.conf /etc/yum.repos.d/mongo.conf

dnf install mongodb-org -y
OUTPUT_VALIDATION $? "Installing MONGODB"

systemctl enable mongodb
systemctl start mongodb

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
systemctl restart mongodb
