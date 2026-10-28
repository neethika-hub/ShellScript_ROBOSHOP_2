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
        echo "$2 is SUCCESS" | tee -a $OUTPUT_LOG
    else 
        echo "$2 is FAILED" | tee -a $OUTPUT_LOG
        exit 1
    fi
}

mkdir -p $LOG_FOLDER
OUTPUT_VALIDATION $? "Creating log folder '$LOG_FOLDER'"

#CHECK IF IN ROOT OR NOT
ROOT_VALIDATION(){
    if [ $USER_ID -ne 0 ]
    then
        echo "Please run the script with root..ERROR" | tee -a $OUTPUT_LOG
        exit 1
    else
        echo "You are in ROOT!! Continue with next steps.."
        OUTPUT_VALIDATION $? "The Script is executing with ROOT"
    fi
}

MONGODB_INSTALLATION(){
    cp $SCRIPT_PATH/mongo.conf /etc/yum.repos.d/mongo.repo
    OUTPUT_VALIDATION $? "Copying MONGODB repo"

    dnf install mongodb-org -y &>>OUTPUT_LOG
    OUTPUT_VALIDATION $? "Installing MONGODB"

    systemctl enable mongod
    systemctl start mongod
    OUTPUT_VALIDATION $? "Starting MONGODB"

    sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
    OUTPUT_VALIDATION $? "Updating the Address in mongod.conf file"
    systemctl restart mongod
    OUTPUT_VALIDATION $? "Restarting MONGODB"
}

APP_CONFIGURATION(){
    mkdir -p /app
    id roboshop &>>$OUTPUT_LOG
    if [ $? -ne 0 ]
    then
        useradd --system --home /app --shell /sbin/nologin --comment "Roboshop System User" roboshop
        OUTPUT_VALIDATION $? "Roboshop System User Creation"
    else
        echo "Roboshop System user is already Present"
    fi
    cd /app
    rm -rf *
    curl -o /tmp/$APP_NAME.zip https://roboshop-artifacts.s3.amazonaws.com/$APP_NAME-v3.zip
    cp /tmp/$APP_NAME.zip /app
    unzip $APP_NAME.zip &>>$OUTPUT_LOG
    OUTPUT_VALIDATION $? "Downloading and Unzipping Application Binaries"
    rm -rf $APP_NAME.zip
}

NODEJS_INSTALLATION(){
    dnf module disable nodejs -y &>>$OUTPUT_LOG
    OUTPUT_VALIDATION $? "Diabling default nodejs"

    dnf module enable nodejs:20 -y &>>$OUTPUT_LOG
    OUTPUT_VALIDATION $? "Enabling nodejs 20"

    dnf install nodejs -y &>>$OUTPUT_LOG
    OUTPUT_VALIDATION $? "Installing nodejs 20"
    npm install &>>$OUTPUT_LOG
    OUTPUT_VALIDATION $? "Installing nodejs dependencies"
    
}

SYSTEMD_SETUP_START(){
    cp $SCRIPT_PATH/$APP_NAME.service /etc/systemd/system/$APP_NAME.service
    OUTPUT_VALIDATION $? "Copying Service Configuration File"

    systemctl daemon-reload
    systemctl enable $APP_NAME
    systemctl start $APP_NAME
    OUTPUT_VALIDATION $? "Enabling and Restarting $APP_NAME.service"
}

TIME_TAKEN()
{
    END_TIME=$(date +%s)
    TOTAL_TIME=$(($END_TIME - $START_TIME))
    echo "Script completed in: $TOTAL_TIME ms"
}










