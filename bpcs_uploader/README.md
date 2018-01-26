###  百度云上传工具 bpcs_uploader 使用说明
1. 初始化工具
第一次运行备份脚本并选择上传百度云的时候，如果工具没有初始化则会进行初始化：
```shell
[2018-01-26 14:47:44] Error: To upload your backup file to BaiDuYun, you must initialize the bpcs_uploader.Next to quick inti it.
[2018-01-26 14:47:45] Quick initialize the bpcs_uploader.
Uploader initialization will be begin. If you have already configured the uploader before, your old settings will be overwritten.
Continue? [y/N]
```
输入`y`进行初始化，如果不进行初始化则会一直提示
```shell
Launch your favorite web browser and visit https://openapi.baidu.com/device 用浏览器打开这个网址，登陆百度云账号
Input x26276nb as the user code if asked.在文本框中输入input后面的一串字符
After granting access to the application, come back here and press Enter to continue. 在获得权限之后再返回这里，按回车继续
```
用浏览器打开 [https://openapi.baidu.com/device](https://openapi.baidu.com/device "https://openapi.baidu.com/device")，登陆百度云账号后是这样的：
![](https://cdn.sunriseydy.top/wp-content/uploads/2018/01/2-1.png)
输入上面的字符串
![](https://cdn.sunriseydy.top/wp-content/uploads/2018/01/3-1.png)
完成授权后回到命令行，按回车继续
```shell
Access Granted. Your Storage Status: 675.05G/2057.00G (32.82%)
Enjoy!
```
脚本提示已经授权成功，开始上传备份文件
```shell
File /apps/bpcs_uploader/backup/backup.20180126144743.tar.gz uploaded.
Size:1.051K MD5 Sum:390d60291afd9a74a2b613a92e073286
```
上传备份文件成功，请到你的百度云根目录/我的应用数据（apps）/bpcs_uploader/你设置的百度云保存文件夹/ 下查看是否上传成功
![](https://cdn.sunriseydy.top/wp-content/uploads/2018/01/4-1.png)
