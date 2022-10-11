# Android数据采集

## CPU 使用率和调度信息

```shell
# 获取 CPU 核心数
cat /sys/devices/system/cpu/possible  
# 获取某个 CPU 的频率
cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq
# 进程CPU使用情况
/proc/[pid]/stat
# 进程下面各个线程的CPU使用情况
/proc/[pid]/task/[tid]/stat
# 进程CPU调度相关
/proc/[pid]/sched    
# 系统平均负载，uptime命令对应文件
/proc/loadavg              
```

