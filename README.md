# WebServerAutoBackup

This is a script that automatically backs up your site and database to local or to Qiniu (which will be implemented in the future)

WEB 服务器自动备份脚本 （Shell）

已实现功能：
 - 自动备份网站和数据库到本地
 - 自动删除三天前的备份文件和日志
 - 备份脚本和配置文件分离
 - 自动将备份文件上传到七牛云并和本地同步删除

将来会实现的功能：
 - 自动将备份文件上传到百度云、七牛云等

程序使用方法：

    git clone https://github.com/CHN-STUDENT/WebServerAutoBackup.git 
	//如果国内clone速度慢可打包下载后上传到服务器
    cd WebServerAutoBackup
    vi config.ini //修改配置文件内的网站、数据库等参数
    chmod a+x backup.sh
    ./backup.sh

添加计划任务，每天凌晨两点自动备份
    
    crontab -e
    0 2 * * * cd /root/WebServerAutoBackup && ./backup.sh > /data/backup/log/backup-cron.log  2>&1 & 
    //请自行修改脚本文件目录和输出日志文件目录



