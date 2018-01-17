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
#e.g: BACKUP_DIR="/home/wwwroot/"
#------------------------------------------------------------------

#------------------------------------------------------------------
#BACKUP_DIR="/home/wwwroot/"
#------------------------------------------------------------------
BACKUP_DIR=""

#------------------------------------------------------------------
#MYSQL_DBS="dbname"
#------------------------------------------------------------------
MYSQL_DBS=""

#------------------------------------------------
#MYSQL_USER="root"
#------------------------------------------------
MYSQL_USER="root"

#------------------------------------------------
#MYSQL_PASS="123456"
#------------------------------------------------
MYSQL_PASS=""

#------------------------------------------------
#MYSQL_SERVER="127.0.0.1"
#------------------------------------------------
MYSQL_SERVER="127.0.0.1"

#------------------------------------------------
#MYSQL_SERVER_PORT="3306"
#------------------------------------------------
MYSQL_SERVER_PORT="3306"

#------------------------------------------------
#SAVE_DIR="/home/backup/save/"
#------------------------------------------------
SAVE_DIR="/home/backup/save/"

#------------------------------------------------
#SAVE_LOG_DIR="/home/backup/save/"
#------------------------------------------------
SAVE_LOG_DIR="/home/backup/save/"

##############  Don't edit the following section!!!  ##############
###################################################################

#Set path and print welcome info
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
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
