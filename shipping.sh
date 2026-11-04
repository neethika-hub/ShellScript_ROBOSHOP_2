#!/bin/bash

source ./common.sh
APP_NAME=shipping
PID_VALIDATION="/app/shipping-1.0.jar"
echo "Enter password for MySQL"
read -s MYSQL_PASSWORD
ROOT_VALIDATION
APP_CONFIGURATION
MAVEN_INSTALLATION
SYSTEMD_SETUP_START

dnf install mysql -y &>>$OUTPUT_LOG
OUTPUT_VALIDATION $? "Installing MySQL"

mysql -h mysql.shynudevops.shop -uroot -p$MYSQL_PASSWORD -e 'use cities'
if [ $? -ne 0 ]
then
    mysql -h mysql.shynudevops.shop -uroot -p$MYSQL_PASSWORD < /app/db/schema.sql
    mysql -h mysql.shynudevops.shop -uroot -p$MYSQL_PASSWORD < /app/db/app-user.sql 
    mysql -h mysql.shynudevops.shop -uroot -p$MYSQL_PASSWORD < /app/db/master-data.sql
    OUTPUT_VALIDATION $? "Loading Data"
else
    echo "Data is already Present" | tee -a $OUTPUT_LOG
fi

systemctl restart shipping 
OUTPUT_VALIDATION $? "Restarting $APP_NAME"

PIDCHECK
ERRORLOG_CHECK
TIME_TAKEN