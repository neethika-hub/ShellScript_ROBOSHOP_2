#!/bin/bash

USER_ID=$(id -u)
LOG_FOLDER=/var/log/roboshop_logs
SCRIPT_NAME=$( echo $0 | cut -d "." -f1)
OUTPUT_LOG=$LOG_FOLDER/$SCRIPT_NAME.log
SCRIPT_PATH=$PWD
START_TIME=$(date +%s)


#Validates if the commands executed are success or failed
OUTPUT_VALIDATION(){
    if [ $1 -eq 0 ]
    then
        echo "$2 is SUCCESS"
    else
        echo "$2 is FAILED"
        exit 1
    fi
}

mkdir -p $LOG_FOLDER
OUTPUT_VALIDATION $? "Creating log folder '$LOG_FOLDER'"

#CHECK IF IN ROOT OR NOT
ROOT_VALIDATION(){
    if [ $USER_ID -ne 0 ]
    then
        echo "Please run the script with root..ERROR"
        exit 1
    else
        echo "You are in ROOT!! Continue with next steps.."
        OUTPUT_VALIDATION $? "The Script is executing with ROOT"
    fi
}

MONGODB_INSTALLATION(){
    cp $SCRIPT_PATH/mongo.conf /etc/yum.repos.d/mongo.conf
    OUTPUT_VALIDATION $? "Copying MONGODB repo"

    dnf install mongodb-org -y
    OUTPUT_VALIDATION $? "Installing MONGODB"

    systemctl enable mongodb
    systemctl start mongodb
    OUTPUT_VALIDATION $? "Starting MONGODB"

    sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
    systemctl restart mongodb
}








