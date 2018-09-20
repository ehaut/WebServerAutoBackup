#!/bin/bash
#Read the environment configuration

#-----------------------------			  
# WebServerAutoBackup Script		  
# Author:CHN-STUDENT <chn-student@outlook.com> && Noisky <i@ffis.me> && sunriseydy <i@mail.sunriseydy.top>
# Project home page: https://github.com/CHN-STUDENT/WebServerAutoBackup
# Test by CentOS6&7 X64
# Do not edit this script.
#-----------------------------

#Print welcome info
clear
printf "
######################################################
#            WebServerAutoBackup Script              #
#                2018.9  V0.1.0 Beta                 #
#                                                    #
# Please add your server information in this script  #
#           configuration and run as root            #
#                                                    #
#                    Designed by                     #
#        CHN-STUDENT && Noisky && sunriseydy         #
###################################################### 
It may take some time,please wait...
"
# Check if user is root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must run this script as root.${CEND}"; exit 1; }
# Get base path
basepath=$(cd `dirname $0`; pwd)
# Set ini file
INI_FILE="${1:-config.ini}"
##############################################################
# Set bash ini parser
# The bash ini parser by bash-ini-parser <https://github.com/albfan/bash-ini-parser/>
# This project use GPL V3 LICENSE,so we need to follow it.
# I integrated it in this shell to parse the user config file.
# Latest update:2018.5.26
# We have to show what us change by commits.
##############################################################
PREFIX="cfg_section_"

function debug {
# We do not need debug and it not work on our script,so i committed it.
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

# we do not need the cfg_writer function, so i delete it.

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
         echo "section $SECTION not found" 1>&2
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
         echo "section $SECTION not found" 1>&2
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

# We do not need the cfg_update function,so i delete it.

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
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] The log file does not exist,create it." | tee -a "${SAVE_LOG_DIR}/${log_name}"
fi
# Check if tar command exists
if ! [ -x "$(command -v zip)" ]; then
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${CFAILURE}Error: You may not install the zip.Exit.${CEND}" | tee -a "${SAVE_LOG_DIR}/${log_name}"
	exit 1
fi
# Check if wwwroot folder exists
cfg_section_WWWROOT_CONFIG
if [[ "${WWWROOT_DIR}" = "" ]]; then 
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${CFAILURE}Error: You must set the wwwroot directory.Exit.${CEND}" | tee -a "${SAVE_LOG_DIR}/${log_name}"
	exit 1
fi
# Check if temp folder exists
cfg_section_TEMP_CONFIG
if [[ "${TEMP_DIR}" = "" ]]; then 
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${CFAILURE}Error: You must set the temp directory.Exit.${CEND}" | tee -a "${SAVE_LOG_DIR}/${log_name}"
	exit 1
fi
if ! [ -d "${TEMP_DIR}"  ]; then 
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] The temp folder does not exist,create it." | tee -a "${SAVE_LOG_DIR}/${log_name}"
	mkdir -p "${TEMP_DIR}" 
fi 
# Add the check backup space function <https://github.com/CHN-STUDENT/WebServerAutoBackup/issues/10>
# Start to check wwwroot size
# Base on <https://stackoverflow.com/questions/5920333/how-to-check-size-of-a-file>
wwwroot_size=0
for www_dir in ${WWWROOT_DIR[@]}
do
	wwwroot_size=`expr $(du -sb ${www_dir} | awk '{ print $1 }') + ${wwwroot_size}`
done
# Start to check temp folder and backup folder free space size
# Base on <https://unix.stackexchange.com/questions/6008/get-the-free-space-available-in-current-directory-in-bash>
cfg_section_TEMP_CONFIG
temp_folder_space=`df -P ${TEMP_DIR} | tail -1 | awk '{print $4}'`
if [ ${temp_folder_space} -lt ${wwwroot_size} ];then
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] The temp folder is too small.Can not to start backup." | tee -a "${SAVE_LOG_DIR}/${log_name}"
	exit 1
fi
cfg_section_SAVE_CONFIG
backup_folder_space=`df -P ${SAVE_DIR} | tail -1 | awk '{print $4}'`
if [ ${backup_folder_space} -lt ${wwwroot_size} ];then
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] The backup folder is too small.Can not to start backup." | tee -a "${SAVE_LOG_DIR}/${log_name}"
	exit 1
fi
# Clean the temp dir
cd ${TEMP_DIR}
rm -rf ${TEMP_DIR}/*
# Get server time
NOW=$(date +"%Y%m%d%H%M%S")
# Start backup mysql
cfg_section_MYSQL_CONFIG
# Check if mysqldump command exists
if ! [ -x "$(command -v mysqldump)" ]; then
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${CFAILURE}Error: You may not install the mysql server.Skip to backup mysql.${CEND}" | tee -a "${SAVE_LOG_DIR}/${log_name}"
else
	if  [[ "${MYSQL_DBS}" = "" || "${MYSQL_USER}" = "" || "${MYSQL_PASSWD}" = "" || "${MYSQL_SERVER}" = "" || "${MYSQL_SERVER_PORT}" = "" ]];then
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: You must set your mysql config to backup mysql.Skip mysql backup." | tee -a "${SAVE_LOG_DIR}/${log_name}"
	else
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start backup mysql." | tee -a "${SAVE_LOG_DIR}/${log_name}"
		for db_name in ${MYSQL_DBS[@]}
		do
			mysqldump -u${MYSQL_USER} -h${MYSQL_SERVER} -P${MYSQL_SERVER_PORT} -p${MYSQL_PASSWD} ${db_name} > "${TEMP_DIR}/$db_name.sql" 
		done
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Mysql backup completed." | tee -a "${SAVE_LOG_DIR}/${log_name}"
	fi
fi
# Start backup wwwroot
for www_dir in ${WWWROOT_DIR[@]}
do
	cp -r ${www_dir} .
done
# set backup path and log path
backup_path="${SAVE_DIR}/backup.$NOW.zip"
log_path="${SAVE_LOG_DIR}/${log_name}"
# get the compress password
cfg_section_COMPRESS_CONFIG
ZIP_COMPRESS_PASSWD=${COMPRESS_PASSWD}
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start packing backup." | tee -a "${SAVE_LOG_DIR}/${log_name}"
if [ "${ZIP_COMPRESS_PASSWD}" = "" ];then
    zip -q -r ${SAVE_DIR}/backup.$NOW.zip * 
else
    zip -q -r -P ${ZIP_COMPRESS_PASSWD} ${SAVE_DIR}/backup.$NOW.zip * 
fi
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Backup package completed." | tee -a "${SAVE_LOG_DIR}/${log_name}"
# Start clean backup and logs files based your set
cfg_section_QSHELL_CONFIG
qiniu_delete_prefix="${key_prefix}"
cfg_section_FTP_CONFIG
ftp_delete_prefix="${FTP_DIR}"
cfg_section_UPX_CONFIG
upx_delete_prefix="${UPX_DIR}"
cfg_section_SFTP_CONFIG
sftp_delete_prefix=${REMOTE_DIR}
cfg_section_DAY_CONFIG
if [ "${DAY}" = "" ];then
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error:You must set the delete day.Exit." | tee -a "${SAVE_LOG_DIR}/${log_name}"
	rm -rf ${TEMP_DIR}/*
	exit 1
fi
if [ "${DAY}" != "0" ];then
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start cleaning up backup files and logs based on the date you set." | tee -a "${SAVE_LOG_DIR}/${log_name}"
		files_list=`find ${SAVE_DIR} -mtime +${DAY} -name "*.zip"`
		logs_list=`find ${SAVE_LOG_DIR} -mtime +${DAY} -name "*.log"`
		for files_name in ${files_list}
		do
			# Create delete list 
			if ! [[ "${ftp_delete_prefix}" = "" ]];then 
				echo "/${ftp_delete_prefix}/$(basename ${files_name})" >> ${TEMP_DIR}/ftp_delete_bak.txt
			fi
			if ! [[ "${qiniu_delete_prefix}" = "" ]];then 																	 
				echo "${qiniu_delete_prefix}/$(basename ${files_name})" >> ${TEMP_DIR}/qiniu_delete_bak.txt
			fi
			if ! [[ "${upx_delete_prefix}" = "" ]];then 	
				echo "/${upx_delete_prefix}/$(basename ${files_name})" >> ${TEMP_DIR}/upai_delete_bak.txt
			fi
			if ! [[ "${sftp_delete_prefix}" = "" ]];then 	
				echo "${sftp_delete_prefix}/$(basename ${files_name})" >> ${TEMP_DIR}/sftp_delete_bak.txt
			fi
		done
	# Start clean
	find ${SAVE_DIR} -mtime +${DAY} -name "*.zip" -exec rm -Rf {} \;
	find ${SAVE_LOG_DIR} -mtime +${DAY} -name "*.log" -exec rm -Rf {} \;
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] Clean up completed." | tee -a "${SAVE_LOG_DIR}/${log_name}"
fi
# Check OS type
if [ $(getconf WORD_BIT) = '32' ] && [ $(getconf LONG_BIT) = '64' ] ; then
    OS_TYPE="X64"
else
    OS_TYPE="X86"
fi
# If you set auto upload to your qiniu bucket,then do. 
cfg_section_QSHELL_CONFIG
if  [[ "${AUTO_UPLOAD}" = "yes" || "${AUTO_UPLOAD}" = "YES" ]];then
	# Check if qiniu config exists
	if  [[ "${ACCESS_Key}" = "" || "${SECRET_Key}" = "" || "${BUCKET}" = "" || "${key_prefix}" = "" ]];then
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: You must set up qiniu config to upload to qiniu.Skip to upload to qiniu." | tee -a "${SAVE_LOG_DIR}/${log_name}"
	else
		if [ ${OS_TYPE}="X64" ];then
			qshell_path="${basepath}/qshell64"
		else
			qshell_path="${basepath}/qshell86"
		fi
		if [[ ( ! -x "$(command -v wget)" ) && ( ! -f "${qshell_path}" ) ]];then
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${CFAILURE}Error: You may not install the wget.Can not download qshell to upload qiniu.${CEND}" | tee -a "${SAVE_LOG_DIR}/${log_name}"
		fi
		# Check if qshell exists
		if [ ! -f "${qshell_path}"  ];then 
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] Can not find qshell.Now start to download." | tee -a "${SAVE_LOG_DIR}/${log_name}"
			if [ ${OS_TYPE}="X64" ];then
				wget -t 3 -T 30 --no-check-certificate -O "${basepath}/qshell64" https://dn-devtools.qbox.me/2.1.7/qshell-linux-x64
			else
				wget -t 3 -T 30 --no-check-certificate -O "${basepath}/qshell86" https://dn-devtools.qbox.me/2.1.7/qshell-linux-x86
			fi
		fi
		if [ -f "${qshell_path}"  ];then 
			# Give its permission
			if ! [ -x ${qshell_path} ];then
				chmod a+x ${qshell_path}
			fi
			# Set qshell account
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] Set your qiniu account." | tee -a "${SAVE_LOG_DIR}/${log_name}"
			${qshell_path} account ${ACCESS_Key} ${SECRET_Key}  
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start qshell upload." | tee -a "${SAVE_LOG_DIR}/${log_name}"
			echo "---------------------------------------------------------------------------"
			echo "--------------------------This is qshell out put:--------------------------"
			# Start upload to qiniu bucket by qshell
			${qshell_path} rput ${BUCKET} "${key_prefix}/backup.$NOW.zip" ${backup_path}
			echo "---------------------------------------------------------------------------"
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] qshell upload completed." | tee -a "${SAVE_LOG_DIR}/${log_name}"
			# If you set auto delete from your qiniu bucket,then do. 
			if [ -f "${TEMP_DIR}/qiniu_delete_bak.txt" ];then    
				if  [[ "${AUTO_DELETE}" = "yes" || "${AUTO_DELETE}" = "YES" ]];then
					echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start cleaning up qiniu files based on the date you set." | tee -a "${SAVE_LOG_DIR}/${log_name}"
					echo "---------------------------------------------------------------------------"
					${qshell_path} batchdelete -force ${BUCKET} ${TEMP_DIR}/qiniu_delete_bak.txt
					echo "---------------------------------------------------------------------------"
					echo "[$(date +"%Y-%m-%d %H:%M:%S")] Qiniu file cleanup completed." | tee -a "${SAVE_LOG_DIR}/${log_name}"
				fi
			fi
		else
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: Can not find qshell.Skip to upload to qiniu." | tee -a "${SAVE_LOG_DIR}/${log_name}"
		fi
	fi
fi
# If you set auto upload to your upx bucket,then do. 
cfg_section_UPX_CONFIG
if  [[ "${AUTO_UPLOAD}" = "yes" || "${AUTO_UPLOAD}" = "YES" ]];then
	# Check if upx config exists
	if  [[ "${UPX_UESR}" = "" || "${UPX_PASSWD}" = "" || "${BUCKET}" = "" || "${UPX_DIR}" = "" ]];then
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: To upload to upaiyun,You must set your upaiyun config.Skip to upload to upaiyun." | tee -a "${SAVE_LOG_DIR}/${log_name}"
	else
		if [ ${OS_TYPE}="X64" ];then
			upx_path="${basepath}/upx64"
		else
			upx_path="${basepath}/upx86"
		fi
		if  [[ ( ! -x "$(command -v wget)" ) && ( ! -f "${upx_path}" ) ]];then
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${CFAILURE}Error: You may not install the wget.Can not download upx to upload upaiyun.${CEND}" | tee -a "${SAVE_LOG_DIR}/${log_name}"
		fi
		# Check if qshell exists
		if [ ! -f "${upx_path}" ];then 
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] Can not find upx.Now start to download." | tee -a "${SAVE_LOG_DIR}/${log_name}"
			if [ ${OS_TYPE}="X64" ];then
				wget -t 3 -T 30 --no-check-certificate -O "${basepath}/upx64" http://collection.b0.upaiyun.com/softwares/upx/upx-linux-amd64-v0.2.3
			else
				wget -t 3 -T 30 --no-check-certificate -O "${basepath}/upx86" http://collection.b0.upaiyun.com/softwares/upx/upx-linux-386-v0.2.3
			fi
		fi
		# Check if upx exists
		if [ -f "${upx_path}" ];then 
			# Give its permission
			if ! [ -x ${upx_path} ];then
				chmod a+x ${upx_path}
			fi
			# Login your upaiyun
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] Login your upaiyun." | tee -a "${SAVE_LOG_DIR}/${log_name}"
			echo "---------------------------------------------------------------------------"
			echo "----------------------------This is upx out put:---------------------------"
			${upx_path} login ${BUCKET} ${UPX_UESR} ${UPX_PASSWD}
			# Create the folder
			${upx_path} mkdir /${UPX_DIR}
			echo "---------------------------------------------------------------------------"
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start upx upload." | tee -a "${SAVE_LOG_DIR}/${log_name}"
			echo "---------------------------------------------------------------------------"
			${upx_path} cd /${UPX_DIR}
			${upx_path} put ${backup_path} "/${UPX_DIR}/backup.$NOW.zip" 
			echo "---------------------------------------------------------------------------"
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] upaiyun upload completed." | tee -a "${SAVE_LOG_DIR}/${log_name}"
			# If you set auto delete from your upaiyun bucket,then do. 
			if [ -f "${TEMP_DIR}/ftp_delete_bak.txt" ];then  
				if  [[ "${AUTO_DELETE}" = "yes" || "${AUTO_DELETE}" = "YES" ]];then
					upx_delete_bak_list="$(cat ${TEMP_DIR}/upai_delete_bak.txt | sed ':label;N;s/\n/ /;b label')"
					echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start cleaning up upaiyun files based on the date you set." | tee -a "${SAVE_LOG_DIR}/${log_name}"
					echo "---------------------------------------------------------------------------"
					${upx_path} rm ${upx_delete_bak_list}
					echo "---------------------------------------------------------------------------"
					echo "[$(date +"%Y-%m-%d %H:%M:%S")] Upaiyun file cleanup completed." | tee -a "${SAVE_LOG_DIR}/${log_name}"
				fi
			fi
			# Logout your upaiyun
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] Logout your upaiyun." | tee -a "${SAVE_LOG_DIR}/${log_name}"
			echo "---------------------------------------------------------------------------"
			${upx_path} logout
			echo "---------------------------------------------------------------------------"
		else
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: Can not find upaiyun.Skip to upload to upaiyun." | tee -a "${SAVE_LOG_DIR}/${log_name}"
		fi
	fi
fi
# If you set auto upload to your COS,then do that below.
cfg_section_COS_CONFIG
if  [[ "${AUTO_UPLOAD}" = "yes" || "${AUTO_UPLOAD}" = "YES" ]];then
	# Check out whether coscmd exists
	coscmd_path=`command -v coscmd`
	while ! [ -x "${coscmd_path}" ]; do
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: To upload to COS,you must install coscmd." | tee -a "${SAVE_LOG_DIR}/${log_name}"
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Begin to install coscmd." | tee -a "${SAVE_LOG_DIR}/${log_name}"
		# Check out whether python exists
		python_path=`command -v python`
		if ! [ -x "${python_path}" ]; then
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: To install coscmd,you must install python 2.7" | tee -a "${SAVE_LOG_DIR}/${log_name}"
			break
		else
			# Check out whether python version equals 2.7.
			V1=2
			V2=7
			U_V1=`${python_path} -V 2>&1|awk '{print $2}'|awk -F '.' '{print $1}'`
			U_V2=`${python_path} -V 2>&1|awk '{print $2}'|awk -F '.' '{print $2}'`
			if  ! [[ "${U_V1}" = "2" && "${U_V2}" = "7" ]];then
				echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: You must install python 2.7,but your python version is ${U_V1}.${U_V2}." | tee -a "${SAVE_LOG_DIR}/${log_name}"
				break
			else
				# Check out whether pip installed
				pip_path=`command -v pip`
				if ! [ -x "${pip_path}" ]; then
					echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: To install coscmd,you must install pip" | tee -a "${SAVE_LOG_DIR}/${log_name}"
					break
				else
					echo "[$(date +"%Y-%m-%d %H:%M:%S")] Begin to install coscmd by pip" | tee -a "${SAVE_LOG_DIR}/${log_name}"
					${pip_path} install coscmd | tee -a "${SAVE_LOG_DIR}/${log_name}"
					echo "[$(date +"%Y-%m-%d %H:%M:%S")] Install coscmd by pip finished" | tee -a "${SAVE_LOG_DIR}/${log_name}"
					coscmd_path=`command -v coscmd`
				fi
			fi
		fi
	done
	#coscmd_path=`command -v coscmd`
	# Check out whether coscmd has been configed.
	coscmd_config_file="/root/.cos.conf"
	while ! [ -f "${coscmd_config_file}"  ]
	do
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: To upload your backup file to COS, you must config the coscmd.Next to config it." | tee -a "${SAVE_LOG_DIR}/${log_name}"
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start config coscmd." | tee -a "${SAVE_LOG_DIR}/${log_name}"
		${coscmd_path} config -a ${SECRET_ID} -s ${SECRET_KEY} -b ${BUCKET} -r ${REGION}
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Config coscmd successful." | tee -a "${SAVE_LOG_DIR}/${log_name}"
	done
	# Start upload
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start upload to COS." | tee -a "${SAVE_LOG_DIR}/${log_name}"
	${coscmd_path} upload ${SAVE_DIR}/backup.$NOW.zip ${COS_UPLOAD_DIR}/backup.$NOW.zip | tee -a "${SAVE_LOG_DIR}/${log_name}"
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] Upload to COS finished." | tee -a "${SAVE_LOG_DIR}/${log_name}"

	# If you set auto delete,then do that below
	if [[ "${files_list}" != "" && "${AUTO_DELETE}" = "yes" ]];then
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start delete backup files from COS." | tee -a "${SAVE_LOG_DIR}/${log_name}"
		for files_name in ${files_list}
		do
			${coscmd_path} delete -f ${COS_UPLOAD_DIR}/$(basename ${files_name}) | tee -a "${SAVE_LOG_DIR}/${log_name}"
		done
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Delete backup files from COS finished." | tee -a "${SAVE_LOG_DIR}/${log_name}"
	fi
fi
# If you set auto upload to your BaiDuYun,then do that below.
cfg_section_BPCS_UPLOADER_CONFIG
if  [[ "${AUTO_UPLOAD}" = "yes" || "${AUTO_UPLOAD}" = "YES" ]];then
	# Check out whether bpcs_uploader directory exists
	bpcs_uploader_dir="${basepath}/bpcs_uploader"
	if  ! [ -d "${bpcs_uploader_dir}"  ];then
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: To upload your backup file to BaiDuYun,you must hava the bpcs_uploader files.Skip upload to BaiDuYun." | tee -a "${SAVE_LOG_DIR}/${log_name}"
	else
		#Check out whether the bpcs_uploader.php exists
		bpcs_uploader_path="${bpcs_uploader_dir}/bpcs_uploader.php"
		if ! [ -f "${bpcs_uploader_path}"  ]; then 
			echo  "[$(date +"%Y-%m-%d %H:%M:%S")] Error: To upload your backup file to BaiDuYun, you must hava the bpcs_uploader.php .Skip upload to BaiDuYun." | tee -a "${SAVE_LOG_DIR}/${log_name}"
		else
			# Check if php command exists
			php_path=`command -v php`
			if ! [ -x "${php_path}" ]; then
				echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: You may not install the php.Skip upload to BaiDuYun." | tee -a "${SAVE_LOG_DIR}/${log_name}"
			else
				if ! [ -x "$(command -v curl)" ];then
					echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: You may not install the curl.Skip upload to BaiDuYun." | tee -a "${SAVE_LOG_DIR}/${log_name}"
				else
					# Give the bpcs_uploader.php executed permission
					if ! [ -x ${bpcs_uploader_path} ];then
						chmod a+x ${bpcs_uploader_path}
					fi
					# Check out whether the bpcs_uploader has been initialized，if not，always do that.
					bpcs_uploader_config_dir="${bpcs_uploader_dir}/_bpcs_files_/config"
					while ! [ -f "${bpcs_uploader_config_dir}/config.lock"  ]
					do
						echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: To upload your backup file to BaiDuYun, you must initialize the bpcs_uploader.Next to quick inti it." | tee -a "${SAVE_LOG_DIR}/${log_name}"
						echo "[$(date +"%Y-%m-%d %H:%M:%S")] Quick initialize the bpcs_uploader." | tee -a "${SAVE_LOG_DIR}/${log_name}"
						${php_path} -d disable_functions -d safe_mode=Off -f ${bpcs_uploader_path} quickinit
					done
					# Start upload to BaiDuYun 
					echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start upload to BaiDuYun." | tee -a "${SAVE_LOG_DIR}/${log_name}"
					${php_path} -d disable_functions -d safe_mode=Off -f ${bpcs_uploader_path} upload ${SAVE_DIR}/backup.$NOW.zip ${BDY_DIR}/backup.$NOW.zip
					echo "[$(date +"%Y-%m-%d %H:%M:%S")] upload to BaiDuYun finished." | tee -a "${SAVE_LOG_DIR}/${log_name}"
					# If you set auto delete from BaiDuYun,then do. 
					if [[ "${files_list}" != "" && "${AUTO_DELETE}" = "yes" ]];then
						echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start delete backup files based on your set." | tee -a "${SAVE_LOG_DIR}/${log_name}"
						for files_name in ${files_list}
						do
							${php_path} -d disable_functions -d safe_mode=Off -f ${bpcs_uploader_path} delete ${BDY_DIR}/$(basename ${files_name})
						done
						echo "[$(date +"%Y-%m-%d %H:%M:%S")] Delete backup files based on your set finished." | tee -a "${SAVE_LOG_DIR}/${log_name}"
					fi
				fi
			fi
		fi
	fi
fi
# If you set auto upload to your ftp server,then do.
cfg_section_FTP_CONFIG
if  [[ "${AUTO_UPLOAD}" = "yes" || "${AUTO_UPLOAD}" = "YES" ]];then
	# Check if ftp command exists
	if ! [ -x "$(command -v ftp)" ];then
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${CFAILURE}Error: You may not install the ftp.Skip to upload to your ftp server.${CEND}" | tee -a "${SAVE_LOG_DIR}/${log_name}"
	else
		# Check if ftp config exists
		if  [[ "${FTP_DIR}" = "" || "${FTP_UESR}" = "" || "${FTP_PASSWD}" = "" || "${FTP_ADDR}" = "" || "${FTP_PORT}" = "" ]];then
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: You must set ftp config to upload to ftp.Skip to upload to ftp." | tee -a "${SAVE_LOG_DIR}/${log_name}"
		else
			ftp_delete_bak_list=""
			# Make delete list for ftp
			if [ -f "${TEMP_DIR}/ftp_delete_bak.txt" ];then  
				if  [[ "${AUTO_DELETE}" = "yes" || "${AUTO_DELETE}" = "YES" ]];then
					ftp_delete_bak_list="$(cat ${TEMP_DIR}/ftp_delete_bak.txt | sed ':label;N;s/\n/ /;b label')"
				fi
			fi
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start to upload to ftp." | tee -a "${SAVE_LOG_DIR}/${log_name}"
			echo "---------------------------------------------------------------------------"
			echo "----------------------------This is ftp out put:---------------------------"
			# Connect to ftp server
			ftp -n << EOF
			open ${FTP_ADDR} ${FTP_PORT}
			user ${FTP_UESR} ${FTP_PASSWD}
			binary  
			mkdir "${FTP_DIR}" 
			prompt  
			put ${backup_path} "/${FTP_DIR}/backup.$NOW.zip"
			mdelete ${ftp_delete_bak_list}		 
			close  
			bye  
EOF
			echo -e "\n---------------------------------------------------------------------------"
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] Ftp upload completed." | tee -a "${SAVE_LOG_DIR}/${log_name}"
		fi
	fi
fi
# If you set auto upload to your remote server,then do.
cfg_section_SFTP_CONFIG
if  [[ "${AUTO_UPLOAD}" = "yes" || "${AUTO_UPLOAD}" = "YES" ]];then
	# check if ssh command exists
	if ! [ -x "$(command -v ssh)" ]; then
		echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${CFAILURE}Error: You may not install the ssh.Skip to upload backup to remote server.${CEND}" | tee -a "${SAVE_LOG_DIR}/${log_name}"
	else
		# check if set auth method exists
		if ! [[ "${AUTH_METHOD}" = "password" || "${AUTH_METHOD}" = "certificate" ]];then
			echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${CFAILURE}Error: You have to set the correct auth method.Skip to upload backup to remote server.${CEND}" | tee -a "${SAVE_LOG_DIR}/${log_name}"
		else
			# if the auth_method is password,then do.
			if [ "${AUTH_METHOD}" = "password" ];then
				# Check if sftp config exists
				if  [[ "${REMOTE_IP}" = "" || "${REMOTE_PORT}" = "" || "${REMOTE_USER}" = "" || "${REMOTE_PASSWD}" = "" || "${REMOTE_DIR}" = "" ]];then
					echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: You must set sftp config to upload to remote server.Skip to upload backup to remote server." | tee -a "${SAVE_LOG_DIR}/${log_name}"
				else
					# check if sshpass command exists
					if ! [ -x "$(command -v sshpass)" ]; then
						echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${CFAILURE}Error: You may not install the sshpass.Skip to upload backup to remote server.${CEND}" | tee -a "${SAVE_LOG_DIR}/${log_name}"
					else
						sftp_delete_bak_list=""
							# Make delete list for sftp
							if [ -f "${TEMP_DIR}/sftp_delete_bak.txt" ];then  # using the ftp delete list 
								if  [[ "${AUTO_DELETE}" = "yes" || "${AUTO_DELETE}" = "YES" ]];then
									sftp_delete_bak_list="$(cat ${TEMP_DIR}/sftp_delete_bak.txt | sed ':label;N;s/\n/ /;b label')"
								fi
							fi
						echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start to upload to sftp." | tee -a "${SAVE_LOG_DIR}/${log_name}"
						echo "---------------------------------------------------------------------------"
						echo "----------------------------This is sftp out put:--------------------------"
						# connect to the remote server by ssh with password
						# check if remote directory exists by ssh with password
						if ! sshpass -p ${REMOTE_PASSWD} ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_IP} -p ${REMOTE_PORT} -q [[ -d ${REMOTE_DIR} ]] ;then
						# if remote directory dose not exist,so create it,then upload backup file and delete old file
							echo "The remote directory exists,Create it." | tee -a "${SAVE_LOG_DIR}/${log_name}"
							sshpass -p ${REMOTE_PASSWD} ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_IP} -p ${REMOTE_PORT} "mkdir -p ${REMOTE_DIR}"
							sshpass -p ${REMOTE_PASSWD} sftp -o StrictHostKeyChecking=no -P ${REMOTE_PORT}  -b - ${REMOTE_USER}@${REMOTE_IP} <<SFTPPASSWORD0
								cd ${REMOTE_DIR}
								put ${backup_path}
								exit
SFTPPASSWORD0
						else	
						# if remote directory exists,we do not need to create it,then upload backup file and delete old file
						sshpass -p ${REMOTE_PASSWD} sftp -o StrictHostKeyChecking=no -P ${REMOTE_PORT} -b - ${REMOTE_USER}@${REMOTE_IP} <<SFTPPASSWORD1
							cd ${REMOTE_DIR}
							put ${backup_path}
							exit
SFTPPASSWORD1
						fi
						echo -e "\n---------------------------------------------------------------------------"
						echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start delete backup files based on your set." | tee -a "${SAVE_LOG_DIR}/${log_name}"
						if ! [[ "${sftp_delete_bak_list}" = ""  ]]; then
						# Delete the remote old files if the list is not null
							sshpass -p ${REMOTE_PASSWD} ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_IP} -p ${REMOTE_PORT} "rm -rf ${sftp_delete_bak_list}"
						fi
			            echo "[$(date +"%Y-%m-%d %H:%M:%S")] Sftp upload completed." | tee -a "${SAVE_LOG_DIR}/${log_name}"
					fi
				fi
			# if the auth_method is certificate,then do.
			elif [ "${AUTH_METHOD}" = "certificate" ];then
				# Check if sftp config exists
				if  [[ "${REMOTE_IP}" = "" || "${REMOTE_PORT}" = "" || "${REMOTE_USER}" = "" || "${REMOTE_CERT}" = "" || "${REMOTE_DIR}" = "" ]];then
					echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: You must set sftp config to upload to remote server.Skip to upload backup to remote server." | tee -a "${SAVE_LOG_DIR}/${log_name}"
				else
					cert_path=${REMOTE_CERT}
					# Check if auth_certitficate exists
					if [ -f "${cert_path}" ];then 
						# set its permission
						chmod 600 ${cert_path}
						sftp_delete_bak_list=""
							# Make delete list for sftp
							if [ -f "${TEMP_DIR}/sftp_delete_bak.txt" ];then  # using the ftp delete list 
								if  [[ "${AUTO_DELETE}" = "yes" || "${AUTO_DELETE}" = "YES" ]];then
									sftp_delete_bak_list="$(cat ${TEMP_DIR}/sftp_delete_bak.txt | sed ':label;N;s/\n/ /;b label')"
								fi
							fi
						echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start to upload to sftp." | tee -a "${SAVE_LOG_DIR}/${log_name}"
						echo "---------------------------------------------------------------------------"
						echo "----------------------------This is sftp out put:--------------------------"
						# connect to the remote server by ssh with certitficate
						# check if remote directory exists by ssh with certitficate
						if ! ssh -o StrictHostKeyChecking=no -i ${cert_path} ${REMOTE_USER}@${REMOTE_IP} -p ${REMOTE_PORT} -q [[ -d ${REMOTE_DIR} ]] ;then
						# if remote directory dose not exist,so create it,then upload backup file and delete old file
							echo "The remote directory exists,Create it." | tee -a "${SAVE_LOG_DIR}/${log_name}"
							ssh -o StrictHostKeyChecking=no -i ${cert_path} ${REMOTE_USER}@${REMOTE_IP} -p ${REMOTE_PORT} "mkdir -p ${REMOTE_DIR}"
							sftp -o StrictHostKeyChecking=no -i ${cert_path}  -P ${REMOTE_PORT} -b - ${REMOTE_USER}@${REMOTE_IP} <<SFTPCERT0
								cd ${REMOTE_DIR}
								put ${backup_path}
								exit
SFTPCERT0
						else
						# if remote directory exists,we do not need to create it,then upload backup file and delete old file
						sftp -o StrictHostKeyChecking=no -i ${cert_path}  -P ${REMOTE_PORT} -b - ${REMOTE_USER}@${REMOTE_IP} <<SFTPCERT1
							cd ${REMOTE_DIR}
							put ${backup_path}
							exit
SFTPCERT1
						fi
						echo -e "\n---------------------------------------------------------------------------"
						echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start delete backup files based on your set." | tee -a "${SAVE_LOG_DIR}/${log_name}"
						if ! [[ "${sftp_delete_bak_list}" = "" ]]; then
						# Delete the remote old files if the list is not null
							ssh -o StrictHostKeyChecking=no -i ${cert_path} ${REMOTE_USER}@${REMOTE_IP} -p ${REMOTE_PORT} "rm -rf ${sftp_delete_bak_list}"
						fi
			            echo "[$(date +"%Y-%m-%d %H:%M:%S")] Sftp upload completed." | tee -a "${SAVE_LOG_DIR}/${log_name}"
					else
						echo "[$(date +"%Y-%m-%d %H:%M:%S")] Error: You must set correct auth certitificate config to upload to remote server.Skip to upload backup to remote server." | tee -a "${SAVE_LOG_DIR}/${log_name}"
					fi
				fi
			fi
		fi
	fi
fi

# All clear
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Start clear temp files." | tee -a "${SAVE_LOG_DIR}/${log_name}"
rm -rf ${TEMP_DIR}/*
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Clean temp files completed." | tee -a "${SAVE_LOG_DIR}/${log_name}"
# Finished
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Backup completed. Thank you for your use." | tee -a "${SAVE_LOG_DIR}/${log_name}"
printf "Backup successful.
"
