#!/bin/bash
#-----------------------------
source /etc/profile
export TERM=${TERM:-dumb}
#-----------------------------			  
# WebServerAutoBackup Script		  
# Author:CHN-STUDENT <chn-student@outlook.com> && Noisky <i@ffis.me>
# Project home page: https://github.com/CHN-STUDENT/WebServerAutoBackup
# Test by CentOS6&7
# Do not edit this script.
#-----------------------------

#Print welcome info
clear
printf "
######################################################
#            WebServerAutoBackup Script              #
#                2018.1  V0.0.2 Beta                 #
#                                                    #
# Please add your server information in this script  #
#           configuration and run as root            #
#                                                    #
#         Designed by CHN-STUDENT && Noisky          #
###################################################### 
It may take some time,please wait...
"
# Check if user is root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must run this script as root.${CEND}"; exit 1; }
# Set test file
INI_FILE="${1:-config.ini}"
# Set bash ini parser
source ./bash-ini-parser
cfg_parser "${INI_FILE}"
# Check if the save folder exists
cfg_section_SAVE_CONFIG
if  [[ "${SAVE_LOG_DIR}" != "" && "${SAVE_DIR}" != "" ]];then
	if ! [ -d "${SAVE_DIR}"  ]; then 
		mkdir -p "${SAVE_DIR}" 
	fi 
	if ! [ -d "${SAVE_LOG_DIR}" ]; then 
		mkdir -p "${SAVE_LOG_DIR}" 
	fi 
else
	echo "${CFAILURE}Error: You must set the save directory.${CEND}" 
	exit 1
fi
# Check if the log file exists
log_name="$(date +"%Y%m%d").backup.log"
if ! [ -e "${SAVE_LOG_DIR}/${log_name}" ]; then
	touch "${SAVE_LOG_DIR}/${log_name}"
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] The log file does not exist,create it." >> "${SAVE_LOG_DIR}/${log_name}"
fi
# Check if mysqldump command exists
if ! [ -x "$(command -v mysqldump)" ]; then
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${CFAILURE}Error: You may not install the mysql server.Exit.${CEND}" >> "${SAVE_LOG_DIR}/${log_name}"
	exit 1
fi
# Check if wwwroot folder exists
cfg_section_WWWROOT_CONFIG
if [[ "${WWWROOT_DIR}" = "" ]]; then 
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${CFAILURE}Error: You must set the wwwroot directory.Exit.${CEND}" >> "${SAVE_LOG_DIR}/${log_name}"
	exit 1
fi
# Check if temp folder exists
cfg_section_TEMP_CONFIG
if [[ "${TEMP_DIR}" = "" ]]; then 
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${CFAILURE}Error: You must set the temp directory.Exit.${CEND}" >> "${SAVE_LOG_DIR}/${log_name}"
	exit 1
fi
if ! [ -d "${TEMP_DIR}"  ]; then 
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] The temp folder does not exist,create it." >> "${SAVE_LOG_DIR}/${log_name}"
	mkdir -p "${TEMP_DIR}" 
fi 
# Get server time
NOW=$(date +"%Y%m%d%H%M%S")
# Start backup mysql
cfg_section_MYSQL_CONFIG
cd ${TEMP_DIR}
rm -rf ${TEMP_DIR}/*
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start backup mysql." >> "${SAVE_LOG_DIR}/${log_name}"
for db_name in ${MYSQL_DBS}
do
	mysqldump -u${MYSQL_USER} -h${MYSQL_SERVER} -P${MYSQL_SERVER_PORT} -p${MYSQL_PASSWD} ${db_name} > "${TEMP_DIR}/$db_name.sql" 
done
# Start backup wwwroot
cp -r ${WWWROOT_DIR} .
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start pack up backup." >> "${SAVE_LOG_DIR}/${log_name}"
tar -czf${SAVE_DIR}/backup.$NOW.tar.gz * 
# All clear
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start clear temp files." >> "${SAVE_LOG_DIR}/${log_name}"
rm -rf ${TEMP_DIR}/*
# Start clean backup and logs files more than three days
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start clearing up more than three days of backup and log files." >> "${SAVE_LOG_DIR}/${log_name}"
find ${SAVE_DIR} -mtime +3 -name "*.tar.gz" -exec rm -Rf {} \;
find ${SAVE_LOG_DIR} -mtime +3 -name "*.log" -exec rm -Rf {} \;
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Backup completed. Thank you for your use." >> "${SAVE_LOG_DIR}/${log_name}"
printf "Backup successful.
"
