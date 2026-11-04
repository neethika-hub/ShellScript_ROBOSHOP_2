#!/bin/bash

source ./common.sh
APP_NAME=rabbitmq
PID_VALIDATION="/bin/beam.smp"
echo "Enter password"
read -s RABBITMQ_PASSWORD
ROOT_VALIDATION
RABBITMQ_INSTALLATION
PID
ERRORLOG_CHECK
TIME_TAKEN
