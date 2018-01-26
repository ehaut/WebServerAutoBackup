# WebServerAutoBackup

This is a script that automatically backs up your site and database to local or to Qiniu,UpaiYun,BaiDuCloud,ftp

### WEB 服务器自动备份脚本 （Shell）  
仅在CentOS 6 x64 && CentOS 7 x64 && Ubuntu 16.04 x64 测试通过

***

已实现功能：
 - 自动备份网站和数据库到本地
 - 自动记录日志到文件
 - 自动删除三天前的备份文件和日志
 - 备份脚本和配置文件分离（通过ini解析引擎解析外置config.ini）
 - 自动判断机器类型，下载相应的云上传工具
 - 自动将备份文件上传到七牛云并和本地同步删除
 - 自动将备份文件上传到又拍云并和本地同步删除
 - 自动将备份文件上传到百度云并和本地同步删除
 - 自动将备份文件上传到ftp服务器并和本地同步删除

将来会实现的功能：
 - 兼容更多的linux发行版
 
原理：
- 通过ini解析引擎`bash-ini-parser`解析用户配置文件`config.ini`
- 通过`mysqldump`导出数据库
- `tar`压缩备份
- 判断是否存在七牛官方`qshell`,又拍官方`upx`,如果没有使用`wget`下载，
- 下载好调用`qshell`上传七牛云或者`upx`又拍云
- 调用`bpcs_uploader` 上传百度云(请保证安装`php`和`curl`)
- 调用`ftp`上传ftp
- 备份日志通过`echo`和`tee`同时显示屏幕和输出到文件

不足：
 - 由于能力原因可能存在很多bug,欢迎提交issue指出
 - 由于tar绝对路径压缩可能存在问题，故将所有备份文件放在一个临时文件夹中，操作完自动清除
 - 无法忽略mysql-5.6及以上密码传递造成安全警告
 - 由于无法在ftp里写判断语句，所以使用ftp每次强制创建备份文件夹，因此会有警告
 - 同样由于ftp命令支持语句较少，因此没有上传进度条，且ftp上传极易受网络影响
 - 更多的容错处理

打包下载：https://github.com/CHN-STUDENT/WebServerAutoBackup/archive/master.zip

***

### 使用方法：
	
	yum -y install wget tar ftp curl #for CentOS/Redhat
	# apt-get -y install wget tar ftp curl #for Debian/Ubuntu
	git clone https://github.com/CHN-STUDENT/WebServerAutoBackup.git 
	cd WebServerAutoBackup
	vi config.ini //修改配置文件内的网站、数据库等参数
	chmod a+x backup.sh
	./backup.sh

添加计划任务，每天凌晨两点自动备份
    
    crontab -e
    0 2 * * * cd /root/WebServerAutoBackup && ./backup.sh > /data/backup/log/backup-cron.log  2>&1 & 
    #请自行修改脚本文件目录和输出日志文件目录

### 注意事项：
- 如果国内clone速度慢，可以只下载 config.ini 和 backup.sh 上传即可，机器安装好wget命令且网络通畅下程序会自动下载相应的上传工具
- 使用前请保证机器安装tar、mysql，以及配置文件设置正确
- 如果要使用ftp上传请确保ftp服务器防火墙设置放行，权限正确，本机安装ftp命令
- 使用百度云上传需要安装php和curl
- 注意在第一次使用bpcs_uploader工具上传到百度云时需要进行工具的快速初始化，请根据脚本里的提示进行操作

bpcs_uploader工具使用说明：[bpcs_uploader/README.md](https://github.com/CHN-STUDENT/WebServerAutoBackup/blob/master/bpcs_uploader/README.md "bpcs_uploader/README.md")

***

### Thanks：
- ini 解析引擎 `bash-ini-parser`

	Github：https://github.com/albfan/bash-ini-parser

- bpcs_uploader 百度云上传工具

	Github：https://github.com/oott123/bpcs_uploader

- 七牛官方Shell工具 `qshell`

	Github：https://github.com/qiniu/qshell/
	
- 又拍官方Shell工具 `upx`

	Github：https://github.com/polym/upx
