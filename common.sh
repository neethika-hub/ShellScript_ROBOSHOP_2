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

    dnf install mongodb-org -y &>>$OUTPUT_LOG
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
        echo "Roboshop System user is already Present" | tee -a $OUTPUT_LOG
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

REDIS_INSTALLATION(){
    dnf module disable redis -y &>>$OUTPUT_LOG
    OUTPUT_VALIDATION $? "Diabling default REDIS"

    dnf module enable redis:7 -y &>>$OUTPUT_LOG
    OUTPUT_VALIDATION $? "Enabling REDIS 7"

    dnf install redis -y &>>$OUTPUT_LOG
    OUTPUT_VALIDATION $? "Installing REDIS"

    sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
    OUTPUT_VALIDATION $? "Updating redis configuration"

    systemctl enable redis 
    systemctl start redis 
    OUTPUT_VALIDATION $? "Starting REDIS"

}

SYSTEMD_SETUP_START(){
    cp $SCRIPT_PATH/$APP_NAME.service /etc/systemd/system/$APP_NAME.service
    OUTPUT_VALIDATION $? "Copying Service Configuration File"

    systemctl daemon-reload
    systemctl enable $APP_NAME
    systemctl start $APP_NAME
    OUTPUT_VALIDATION $? "Enabling and Restarting $APP_NAME.service"
}

NGINX_INSTALLATION(){
    dnf module disable nginx -y &>>$OUTPUT_LOG
    OUTPUT_VALIDATION $? "Disabling default nginx"

    dnf module enable nginx:1.24 -y &>>$OUTPUT_LOG
    OUTPUT_VALIDATION $? "Enabling 1.24 nginx"

    dnf install nginx -y &>>$OUTPUT_LOG
    OUTPUT_VALIDATION $? "Installing nginx"

    systemctl enable nginx
    systemctl start nginx
    OUTPUT_VALIDATION $? "Starting nginx"
}

MYSQL_INSTALLATION(){

    echo "Enter the password"
    read -s MySQL_PASSWORD
    dnf install mysql-server -y &>>$OUTPUT_LOG
    OUTPUT_VALIDATION $? "Installing MySQL"

    systemctl enable mysqld
    systemctl start mysqld
    OUTPUT_VALIDATION $? "Starting MySQL"

    mysql_secure_installation --set-root-pass $MySQL_PASSWORD
    OUTPUT_VALIDATION $? "Updating ROOT password for MySQL"

}

MAVEN_INSTALLATION(){
    dnf install maven -y &>>$OUTPUT_LOG
    OUTPUT_VALIDATION $? "Installing Maven"

    cd /app
    mvn clean package &>>$OUTPUT_LOG
    OUTPUT_VALIDATION $? "Installing Dependencies"

    mv target/shipping-1.0.jar shipping.jar
    OUTPUT_VALIDATION $? "Updating jar name"
}

RABBITMQ_INSTALLATION(){
    cp $SCRIPT_PATH/$APP_NAME.repo /etc/yum.repos.d/$APP_NAME.repo
    OUTPUT_VALIDATION $? "Copying rabbit mq repo"
    
    dnf install rabbitmq-server -y &>>$OUTPUT_LOG
    OUTPUT_VALIDATION $? "Installing RABBITMQ"

    systemctl enable rabbitmq-server
    systemctl start rabbitmq-server
    OUTPUT_VALIDATION $? "Starting RABBITMQ"

    rabbitmqctl add_user roboshop $RABBITMQ_PASSWORD
    rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
    OUTPUT_VALIDATION $? "Adding user and permissions"
}

PYTHON_INSTALLATION(){
    dnf install python3 gcc python3-devel -y &>>$OUTPUT_LOG
    OUTPUT_VALIDATION $? "Installing Python3"

    cd /app
    pip3 install -r requirements.txt &>>$OUTPUT_LOG
    OUTPUT_VALIDATION $? "Installing dependencies"
}

PIDCHECK(){
    PID=$(ps -ef | grep $PID_VALIDATION | grep -v grep | head -1 | awk '{print $2}')
    echo "The PID is $PID"
    PID_COUNT=$(ps -ef | grep $PID_VALIDATION | grep -v grep | head -1 | awk '{print $2}' | wc -l)
    echo $PID
    if [ $PID_COUNT -eq 1 ]
    then
        echo "$APP_NAME is Started with PID:$PID" | tee -a $OUTPUT_LOG
    else
        echo "$APP_NAME is not started" | tee -a $OUTPUT_LOG
    fi
    
}

ERRORLOG_CHECK(){
    ERROR_COUNT=$(grep -i "ERROR" /var/log/messages | wc -l)
    if [ $ERROR_COUNT -eq 0 ]
    then   
        echo "No ERRORS in $APP_NAME logs" | tee -a $OUTPUT_LOG
    else
        echo "There are errors in $APP_NAME logs. PLEASE CHECK" | tee -a $OUTPUT_LOG
        echo "Restarted the applciation:$APP_NAME if required" | tee -a $OUTPUT_LOG
    fi
}

TIME_TAKEN()
{
    END_TIME=$(date +%s)
    TOTAL_TIME=$(($END_TIME - $START_TIME))
    echo "Script completed in: $TOTAL_TIME ms" | tee -a $OUTPUT_LOG
}










