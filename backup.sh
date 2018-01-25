#!/bin/bash
#Read the environment configuration
source /etc/profile
export TERM=${TERM:-dumb}
#-----------------------------			  
# WebServerAutoBackup Script		  
# Author:CHN-STUDENT <chn-student@outlook.com> && Noisky <i@ffis.me>
# Project home page: https://github.com/CHN-STUDENT/WebServerAutoBackup
# Test by CentOS6&7 X64
# Do not edit this script.
#-----------------------------

#Print welcome info
clear
printf "
######################################################
#            WebServerAutoBackup Script              #
#                2018.1  V0.0.4 Beta                 #
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
# Get base path
basepath=$(cd `dirname $0`; pwd)
# Set ini file
INI_FILE="${1:-config.ini}"
# Set bash ini parser
# The bash ini parser by bash-ini-parser <https://github.com/albfan/bash-ini-parser/>
# Latest update:2018.1.24
PREFIX="cfg_section_"

function debug {
#   if  ! [ -v "BASH_INI_PARSER_DEBUG" ]
#   then 
      #abort debug
      return
#   fi
   echo $*
   echo --start--
   echo "${ini[*]}"
   echo --end--
   echo
}

function cfg_parser {
   shopt -p extglob &> /dev/null
   CHANGE_EXTGLOB=$?
   if [ $CHANGE_EXTGLOB = 1 ]
   then
      shopt -s extglob
   fi
   ini="$(<$1)"                 # read the file
   ini=${ini//$'\r'/}           # remove linefeed i.e dos2unix

   ini="${ini//[/\\[}"
   debug "escaped ["
   ini="${ini//]/\\]}"
   debug "escaped ]"
   IFS=$'\n' && ini=( ${ini} )  # convert to line-array
   debug
   ini=( ${ini[*]/#*([[:space:]]);*/} )
   debug "remove ; comments"
   ini=( ${ini[*]/#*([[:space:]])\#*/} )
   debug "remove # comments"
   ini=( ${ini[*]/#+([[:space:]])/} ) # remove init whitespace
   debug
   ini=( ${ini[*]/%+([[:space:]])/} ) # remove ending whitespace
   debug "whitespace around ="
   ini=( ${ini[*]/*([[:space:]])=*([[:space:]])/=} ) # remove whitespace around =
   debug
   ini=( ${ini[*]/#\\[/\}$'\n'"$PREFIX"} ) # set section prefix
   debug
   ini=( ${ini[*]/%\\]/ \(} )   # convert text2function (1)
   debug
   ini=( ${ini[*]/=/=\( } )     # convert item to array
   debug
   ini=( ${ini[*]/%/ \)} )      # close array parenthesis
   debug
   ini=( ${ini[*]/%\\ \)/ \\} ) # the multiline trick
   debug
   ini=( ${ini[*]/%\( \)/\(\) \{} ) # convert text2function (2)
   debug
   ini=( ${ini[*]/%\} \)/\}} )  # remove extra parenthesis
   ini=( ${ini[*]/%\{/\{$'\n''cfg_unset ${FUNCNAME/#'$PREFIX'}'$'\n'} )  # clean previous definition of section 
   debug
   ini[0]=""                    # remove first element
   debug
   ini[${#ini[*]} + 1]='}'      # add the last brace
   debug
   eval "$(echo "${ini[*]}")"   # eval the result
   EVAL_STATUS=$?
   if [ $CHANGE_EXTGLOB = 1 ]
   then
      shopt -u extglob
   fi
   return $EVAL_STATUS
}

function cfg_unset {
   SECTION=$1
   OLDIFS="$IFS"
   IFS=' '$'\n'
   if [ -z "$SECTION" ] 
   then
      fun="$(declare -F)"
   else
      fun="$(declare -F $PREFIX$SECTION)"
      if [ -z "$fun" ]
      then
         echo "section $SECTION not found" >2
         return
      fi
   fi
   fun="${fun//declare -f/}"
   for f in $fun; do
      [ "${f#$PREFIX}" == "${f}" ] && continue
      item="$(declare -f ${f})"
      item="${item##*\{}" # remove function definition
      item="${item##*FUNCNAME*$PREFIX\};}" # remove clear section
      item="${item/\}}"  # remove function close
      item="${item%)*}" # remove everything after parenthesis
      item="${item});" # add close parenthesis
      vars=""
      while [ "$item" != "" ]
      do
         newvar="${item%%=*}" # get item name
         vars="$vars $newvar" # add name to collection
         item="${item#*;}" # remove readed line
      done
      for var in $vars; do
         unset $var
      done
   done
   IFS="$OLDIFS"
}

function cfg_clear {
   SECTION=$1
   OLDIFS="$IFS"
   IFS=' '$'\n'
   if [ -z "$SECTION" ] 
   then
      fun="$(declare -F)"
   else
      fun="$(declare -F $PREFIX$SECTION)"
      if [ -z "$fun" ]
      then
         echo "section $SECTION not found" >2
         exit 1
      fi
   fi
   fun="${fun//declare -f/}"
   for f in $fun; do
      [ "${f#$PREFIX}" == "${f}" ] && continue
      unset -f ${f}
   done
   IFS="$OLDIFS"
}

#Test harness
if [ $# != 0 ]
then
   $@
fi

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
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] The log file does not exist,create it." | tee "${SAVE_LOG_DIR}/${log_name}"
fi
# Check if tar command exists
if ! [ -x "$(command -v tar)" ]; then
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${CFAILURE}Error: You may not install the tar.Exit.${CEND}" | tee "${SAVE_LOG_DIR}/${log_name}"
	exit 1
fi
# Check if wwwroot folder exists
cfg_section_WWWROOT_CONFIG
if [[ "${WWWROOT_DIR}" = "" ]]; then 
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${CFAILURE}Error: You must set the wwwroot directory.Exit.${CEND}" | tee "${SAVE_LOG_DIR}/${log_name}"
	exit 1
fi
# Check if temp folder exists
cfg_section_TEMP_CONFIG
if [[ "${TEMP_DIR}" = "" ]]; then 
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${CFAILURE}Error: You must set the temp directory.Exit.${CEND}" | tee "${SAVE_LOG_DIR}/${log_name}"
	exit 1
fi
if ! [ -d "${TEMP_DIR}"  ]; then 
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] The temp folder does not exist,create it." | tee "${SAVE_LOG_DIR}/${log_name}"
	mkdir -p "${TEMP_DIR}" 
fi 
# Get server time
NOW=$(date +"%Y%m%d%H%M%S")
# Start backup mysql
cfg_section_MYSQL_CONFIG
cd ${TEMP_DIR}
rm -rf ${TEMP_DIR}/*
# Check if mysqldump command exists
if ! [ -x "$(command -v mysqldump)" ]; then
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${CFAILURE}Error: You may not install the mysql server.Skip to backup mysql.${CEND}" | tee "${SAVE_LOG_DIR}/${log_name}"
else
	if  [[ "${MYSQL_DBS}" = "" || "${MYSQL_USER}" = "" || "${MYSQL_PASSWD}" = "" || "${MYSQL_SERVER}" = "" || "${MYSQL_SERVER_PORT}" = "" ]];then
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: To backup mysql,You must set your mysql config.Skip to backup mysql." | tee "${SAVE_LOG_DIR}/${log_name}"
	else
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start backup mysql." | tee "${SAVE_LOG_DIR}/${log_name}"
		for db_name in ${MYSQL_DBS[@]}
		do
			mysqldump -u${MYSQL_USER} -h${MYSQL_SERVER} -P${MYSQL_SERVER_PORT} -p${MYSQL_PASSWD} ${db_name} > "${TEMP_DIR}/$db_name.sql" 
		done
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Mysql backup completed." | tee "${SAVE_LOG_DIR}/${log_name}"
	fi
fi
# Start backup wwwroot
for www_dir in ${WWWROOT_DIR[@]}
do
	cp -r ${www_dir} .
done
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start packing backup." | tee "${SAVE_LOG_DIR}/${log_name}"
tar -czf${SAVE_DIR}/backup.$NOW.tar.gz * 
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Backup package completed." | tee "${SAVE_LOG_DIR}/${log_name}"
# Start clean backup and logs files based your set
cfg_section_DAY_CONFIG
if [ "${DAY}" = "" ];then
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error:You must set the delete day.Exit." | tee "${SAVE_LOG_DIR}/${log_name}"
	rm -rf ${TEMP_DIR}/*
	exit 1
fi
if [ "${DAY}" != "0" ];then
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start cleaning up backup files and logs based on the date you set." | tee "${SAVE_LOG_DIR}/${log_name}"
	# Create delete list for qshell
		files_list=`find ${SAVE_DIR} -mtime +${DAY} -name "*.tar.gz"`
		logs_list=`find ${SAVE_LOG_DIR} -mtime +${DAY} -name "*.log"`
		for files_name in ${files_list}
		do
			echo "${key_prefix}/save/$(basename ${files_name})" >> ${TEMP_DIR}/qiniu_delete_bak.txt
		done
		for logs_name in ${logs_list}
		do
			echo "${key_prefix}/log/$(basename ${logs_name})" >> ${TEMP_DIR}/qiniu_delete_log.txt
		done
	# Start clean
	find ${SAVE_DIR} -mtime +${DAY} -name "*.tar.gz" -exec rm -Rf {} \;
	find ${SAVE_LOG_DIR} -mtime +${DAY} -name "*.log" -exec rm -Rf {} \;
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] Clean up completed." | tee "${SAVE_LOG_DIR}/${log_name}"
fi
# If you set auto upload to your qiniu bucket,then do. 
cfg_section_QSHELL_CONFIG
if  [[ "${AUTO_UPLOAD}" = "yes" || "${AUTO_UPLOAD}" = "YES" ]];then
	# Check if qiniu config exists
	if  [[ "${ACCESS_Key}" = "" || "${SECRET_Key}" = "" || "${BUCKET}" = "" || "${key_prefix}" = "" ]];then
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: You must set up qiniu config to upload to qiniu.Skip to upload to qiniu." | tee "${SAVE_LOG_DIR}/${log_name}"
	else
		# Check if qshell exists
		qshell_path="${basepath}/qshell"
		if [ "${qshell_path}" = "" ];then 
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: Can not find qshell.Skip to upload to qiniu." | tee "${SAVE_LOG_DIR}/${log_name}"
			exit 1
		fi
		# Give its permission
		if ! [ -x ${qshell_path} ];then
			chmod a+x ${qshell_path}
		fi
		# Set qshell account
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Set your qiniu account." | tee "${SAVE_LOG_DIR}/${log_name}"
		${qshell_path} account ${ACCESS_Key} ${SECRET_Key}  
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start make upload list." | tee "${SAVE_LOG_DIR}/${log_name}"
		echo "---------------------------------------------------------------------------"
		echo "--------------------------This is qshell out put:--------------------------"
		# Update the files list cache 
		${qshell_path} dircache ${SAVE_DIR} "${TEMP_DIR}/file_cache.txt"
		${qshell_path} dircache ${SAVE_LOG_DIR} "${TEMP_DIR}/log_cache.txt"
		echo "---------------------------------------------------------------------------"
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start qshell upload." | tee "${SAVE_LOG_DIR}/${log_name}"
		echo "---------------------------------------------------------------------------"
		# Start upload to qiniu bucket by qshell
		${qshell_path} qupload2 -src-dir=${SAVE_DIR} -bucket=${BUCKET} -key-prefix="${key_prefix}/save/" -file-list="${TEMP_DIR}/file_cache.txt"
		${qshell_path} qupload2 -src-dir=${SAVE_LOG_DIR} -bucket=${BUCKET} -key-prefix="${key_prefix}/log/" -file-list="${TEMP_DIR}/log_cache.txt"
		echo "---------------------------------------------------------------------------"
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] qshell upload completed." | tee "${SAVE_LOG_DIR}/${log_name}"
		# If you set auto delete from your qiniu bucket,then do. 
		if [ -f "${TEMP_DIR}/qiniu_delete_bak.txt" -a -f "${TEMP_DIR}/qiniu_delete_log.txt" ];then    
			if  [[ "${AUTO_DELETE}" = "yes" || "${AUTO_DELETE}" = "YES" ]];then
				echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start cleaning up qiniu files based on the date you set." | tee "${SAVE_LOG_DIR}/${log_name}"
				echo "---------------------------------------------------------------------------"
				${qshell_path} batchdelete -force ${BUCKET} ${TEMP_DIR}/qiniu_delete_bak.txt
				${qshell_path} batchdelete -force ${BUCKET} ${TEMP_DIR}/qiniu_delete_log.txt
				echo "---------------------------------------------------------------------------"
				echo "[$(date +"%Y-%m-%d %H:%M:%S")] Qiniu file cleanup completed." | tee "${SAVE_LOG_DIR}/${log_name}"
			fi
		fi
	fi
fi
# If you set auto upload to your ftp server,then do.
cfg_section_FTP_CONFIG
if  [[ "${AUTO_UPLOAD}" = "yes" || "${AUTO_UPLOAD}" = "YES" ]];then
	# Check if ftp command exists
	if ! [ -x "$(command -v ftp)" ];then
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${CFAILURE}Error: You may not install the ftp.Skip to upload to your ftp server.${CEND}" | tee "${SAVE_LOG_DIR}/${log_name}"
	else
		# Check if ftp config exists
		if  [[ "${FTP_DIR}" = "" || "${FTP_UESR}" = "" || "${FTP_PASSWD}" = "" || "${FTP_ADDR}" = "" || "${FTP_PORT}" = "" ]];then
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: You must set ftp config to upload to ftp.Skip to upload to ftp." | tee "${SAVE_LOG_DIR}/${log_name}"
		else
			echo "---------------------------------------------------------------------------"
			echo "----------------------------This is ftp out put:---------------------------"
			# Connect to ftp server
			ftp -n << EOF
			open ${FTP_ADDR} ${FTP_PORT}
			user ${FTP_UESR} ${FTP_PASSWD}
			binary  
			mkdir "${FTP_DIR}" 
			mkdir "./${FTP_DIR}/save" 
			mkdir "./${FTP_DIR}/log" 
			prompt  
			cd "./${FTP_DIR}/save"
			lcd ${SAVE_DIR} 
			mput *.* 
			cd ~
			cd "./${FTP_DIR}/log"
			lcd ${SAVE_LOG_DIR} 
			mput *.* 
			close  
			bye  
EOF
			echo "---------------------------------------------------------------------------"
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] Upload completed." | tee "${SAVE_LOG_DIR}/${log_name}"
		fi
	fi
fi
# All clear
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start clear temp files." | tee "${SAVE_LOG_DIR}/${log_name}"
rm -rf ${TEMP_DIR}/*
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Clean temp files completed." | tee "${SAVE_LOG_DIR}/${log_name}"
# Finished
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Backup completed. Thank you for your use." | tee "${SAVE_LOG_DIR}/${log_name}"
printf "Backup successful.
"