#!/bin/bash
# Author:Noisky <i@ffis.me> && CHN-STUDENT <chn-student@outlook.com>
# Project home page: https://github.com/CHN-STUDENT/WebServerAutoBackup
# Test by CentOS7
# Do not edit the other parts of the configuration file.

###################################################################
####################  Your Server Info Config  ####################

#------------------------------------------------------------------
#Tip:You can edit like this:
#------------------------------------------------------------------
#Attribute:"value"
#------------------------------------------------------------------
#e.g: WWWROOT_DIR="/home/wwwroot"
#------------------------------------------------------------------

#------------------------------------------------------------------
#WWWROOT="/home/wwwroot"
#------------------------------------------------------------------
WWWROOT_DIR="/home/wwwroot"

#------------------------------------------------------------------
#MYSQL_DBS="dbname"
#------------------------------------------------------------------
MYSQL_DBS="TEST"

#------------------------------------------------------------------
#MYSQL_USER="root"
#------------------------------------------------------------------
MYSQL_USER="root"

#------------------------------------------------------------------
#MYSQL_PASSWD="123456"
#------------------------------------------------------------------
MYSQL_PASSWD="123456"

#------------------------------------------------------------------
#MYSQL_SERVER="127.0.0.1"
#------------------------------------------------------------------
MYSQL_SERVER="127.0.0.1"

#------------------------------------------------------------------
#MYSQL_SERVER_PORT="3306"
#------------------------------------------------------------------
MYSQL_SERVER_PORT="3306"

#------------------------------------------------------------------
#SAVE_DIR="/home/backup/save"
#------------------------------------------------------------------
SAVE_DIR="/home/backup/save"

#------------------------------------------------------------------
#SAVE_LOG_DIR="/home/backup/log"
#------------------------------------------------------------------
SAVE_LOG_DIR="/home/backup/log"

##############  Don't edit the following section!!!  ##############
###################################################################

#Print welcome info
clear
printf "
######################################################
# WebServerAutoBackup Script                         #          
# Author:Noisky && CHN-STUDENT                       #                 
# Date:2018.1                                        #       
# Version:V0.0.1 Beta                                #              
# Please add your server info in this script config  #
# and run as root.                                   #
######################################################
"
# Check if user is root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }
# Check if the save folder exists
if  [[ "${SAVE_LOG_DIR}" != "" && "${SAVE_DIR}" != "" ]];then
	if ! [ -d "${SAVE_DIR}"  ]; then 
		mkdir -p "${SAVE_DIR}" 
	fi 
	if ! [ -d "${SAVE_LOG_DIR}" ]; then 
		mkdir -p "${SAVE_LOG_DIR}" 
	fi 
else
	echo "${CFAILURE}Error: You must set the save directory${CEND}" 
	exit 1
fi
# Check if mysqldump command exists
if ! [ -x "$(command -v mysqldump)" ]; then
	echo "${CFAILURE}Error: You may not install mysql server${CEND}"
	exit 1
fi
# Check if wwwroot folder exists
if [[ "${WWWROOT_DIR}" = "" ]]; then 
	echo "${CFAILURE}Error: You must set the wwwroot directory${CEND}" 
	exit 1
fi
# Get server time
NOW=$(date +"%Y%m%d%H%M%S")
# Start backup mysql
for db_name in ${MYSQL_DBS}
do
	mysqldump -u${MYSQL_USER} -h${MYSQL_SERVER} -P${MYSQL_SERVER_PORT} -p${MYSQL_PASSWD} ${db_name} > "${SAVE_DIR}/$db_name.sql"
done
# Start backup wwwroot
	tar -czPf"${SAVE_DIR}/backup.$NOW.tar.gz" "${SAVE_DIR}/*.sql" ${WWWROOT_DIR}
# All clear
	rm -rf "${SAVE_DIR}/*.sql"
# Start clean backup files more than three days
	find ${SAVE_DIR} -mtime +3 -name "*.tar.gz" -exec rm -Rf {} \;
