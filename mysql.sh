#!/bin/bash

source ./common.sh
APP_NAME=mysql
PID_VALIDATION="/usr/sbin/mysqld"
MYSQL_INSTALLATION
PIDCHECK
ERRORLOG_CHECK
TIME_TAKEN