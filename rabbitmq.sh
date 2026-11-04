#!/bin/bash

source ./common.sh
APP_NAME=rabbitmq
PID_VALIDATION="/usr/sbin/rabbitmq"
echo "Enter password"
read -s RABBITMQ_PASSWORD
ROOT_VALIDATION
RABBITMQ
PID
ERRORLOG_CHECK
TIME_TAKEN
