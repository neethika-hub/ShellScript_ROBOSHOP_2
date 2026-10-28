#!/bin/bash

source ./common.sh
APP_NAME=catalogue

ROOT_VALIDATION
APP_CONFIGURATION
NODEJS_INSTALLATION

cp $SCRIPT_PATH/mongo.conf /etc/yum.repos.d.mongod.repo
OUTPUT_VALIDATION $? "Copying MONGO Repo"

dnf install mongodb-mongosh -y &>>$OUTPUT_LOG
OUTPUT_VALIDATION $? "Installing MONGODB Client"


STATUS=$(mongosh --host mongodb.shynudevops.shop --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.shynudevops.shop < /app/db/master-data.js &>>$OUTPUT_LOG
    OUTPUT_VALIDATION $? "Loaded data into MONGODB"
else
    echo "Data is Already Present"
fi

TIME_TAKEN