# WebServerAutoBackup

This is a script that automatically backs up your site and database to local or to Qiniu (which will be implemented in the future)

WEB 服务器自动备份脚本 （Shell）  
仅在CentOS 6 x64 && CentOS 7 x64 Ubuntu 16.04 x64 上测试通过

已实现功能：
 - 自动备份网站和数据库到本地
 - 自动记录日志到文件
 - 自动删除三天前的备份文件和日志
 - 备份脚本和配置文件分离（通过ini解析引擎解析外置config.ini）
 - 自动将备份文件上传到七牛云并和本地同步删除
 - 自动将备份文件上传到百度云并和本地同步删除

将来会实现的功能：
 - 自动判断机器类型，下载相应的云上传工具
 - 兼容更多的linux发行版
 
原理：通过mysqldump导出数据库，tar压缩备份，调用七牛官方qshell上传，调用 bpcs_uploader 上传百度云。

不足：
 - 由于tar绝对路径压缩可能存在问题，故将所有备份文件放在一个临时文件夹中，操作完自动清除。
 - 无法忽略mysql-5.6及以上密码传递造成安全警告
 - qshell是x64版本的，本脚本仅在64位系统测试通过
 - 更多的容错处理



打包下载：https://github.com/CHN-STUDENT/WebServerAutoBackup/archive/master.zip

使用方法：

	//请保证机器安装tar、mysql和php，以及配置文件设置正确
	git clone https://github.com/CHN-STUDENT/WebServerAutoBackup.git 
	//如果国内clone速度慢可打包下载后上传到服务器
    cd WebServerAutoBackup
    vi config.ini //修改配置文件内的网站、数据库等参数
    chmod a+x backup.sh
    ./backup.sh
	
	注意在第一次使用bpcs_uploader工具时需要进行工具的快速初始化，请根据脚本里的提示进行操作

添加计划任务，每天凌晨两点自动备份
    
    crontab -e
    0 2 * * * cd /root/WebServerAutoBackup && ./backup.sh > /data/backup/log/backup-cron.log  2>&1 & 
    //请自行修改脚本文件目录和输出日志文件目录

### Thanks：
ini解析引擎-bash-ini-parser  
Github：https://github.com/albfan/bash-ini-parser
bpcs_uploader 百度云上传工具
Github：https://github.com/oott123/bpcs_uploader


