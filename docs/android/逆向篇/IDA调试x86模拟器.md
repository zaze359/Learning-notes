# IDA调试x86模拟器

* 打开IDA安装目录下的`dbgsrv`文件夹，找到`android_x86_server`文件。

* 上传到手机的中。

  ```shell
  adb push D:\IDA_Pro_v7.5_Portable\dbgsrv\android_x86_server /data/local/tmp/.
  ```

* 修改文件权限

  ```shell
  adb shell chmod 777 /data/local/tmp/android_x86_server
  ```

* 启动android_x86_server

  ```shell
  adb shell /data/local/tmp/android_x86_server
  ```

  

![image-20221011000420371](./IDA%E8%B0%83%E8%AF%95x86%E6%A8%A1%E6%8B%9F%E5%99%A8.assets/image-20221011000420371.png)

* 设置端口转发

  ```shell
  adb forward tcp:23946 tcp:23946
  ```

* 打开 IDA32位，attach设备

  ![image-20221011000717828](./IDA%E8%B0%83%E8%AF%95x86%E6%A8%A1%E6%8B%9F%E5%99%A8.assets/image-20221011000717828.png)