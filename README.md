# WebServerAutoBackup

This is a script that automatically backs up your site and database to local or to Qiniu (which will be implemented in the future)

WEB 服务器自动备份脚本 （Shell）

已实现功能：
- 自动备份网站和数据库到本地
- 自动删除三天前的备份文件和日志

将来会实现的功能：
- 自动将备份文件上传到七牛云


程序使用方法：

    git clone https://github.com/CHN-STUDENT/WebServerAutoBackup.git
    cd WebServerAutoBackup
    vi backup.sh //修改文件内的网站、数据库等
    chmod 777 backup.sh
    ./backup.sh





