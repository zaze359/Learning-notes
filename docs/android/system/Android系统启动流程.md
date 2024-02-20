# 	Android系统启动流程

## 流程概览

> 这张图摘录自《深入理解Android》

![img](./Android%E7%B3%BB%E7%BB%9F%E5%90%AF%E5%8A%A8%E6%B5%81%E7%A8%8B.assets/image_1cegf6i1jmjmtdbqisgik1mu89.png)

* **设备供电，执行bootloader**：负责初始化软件运行的最小硬件环境，加载内核到内存中。


* **启动用户空间的init进程**：内核加载进内存后，首先进入内核引导界面(主要是汇编)，在引导阶段最后，调用`start_kernel`进入内核启动阶段，最终会启动第一个用户空间进程（`init`）。
* **启动zygote和ServiceManager等系统守护进程**： `init`程序负责解析`init.rc`配置文件并执行Action和Service。其中最重要的是启动了`zygote`和`ServiceManager`。
   * **zygote**：内部启动了 Android的ART 虚拟机(5.0以前是Dalvik)。它**负责启动java世界的进程**（`ZygoteInit.main()`）。
   * **ServiceManager**：是Binder通信的基础，负责管理所有的Binder服务，提供了**Service注册**和**Service检索**功能。
* **zygote进程 启动后 会fork system_server 进程。同时注册 zygote socket**。最后进入 loop 循环等待socket消息。

   * **system_server进程**：启动后会自身注册到ServiceManager中，用于Binder通信。同时也管理了 AMS、PMS等各种服务。
   * **zygote socket**： 用于接收AMS启动应用的请求。

* system_server进程启动后 会使 AMS 进入systemReady 状态。
* ActivityManagerService 与 zygote 通过 Socket 进行通信，请求启动Home。
* zygote收到 socket 请求，通过forkAndSpecialize启动新的应用进程，最终启动了Home。

后续阅读源码过程中会涉及SystemServer、SystemService、ServiceManager、LocalService、SystemServiceManager这几个名字相似的类，简单介绍下它们的职责：

* **SystemServer**：是zygote 孵化的第一个进程，是zygote的得力干将，它内部启动很多重要的系统服务。

* **ServiceManager**：主要负责服务的访问，提供了服务注册和服务检索的功能。**需要Binder通信的服务会被注册到ServiceManager中**。
* **LocalService**：和ServiceManager相对应，**进程内部通信的服务会注册到LocalService中**。
* **SystemServiceManager**：管理 系统服务 的生命周期，包括创建、启动等。

> 我画了张从 `init启动 -> zygote孵化子进程` 这一流程的时序图。不同颜色表示不同的进程。

![系统启动流程](./Android%E7%B3%BB%E7%BB%9F%E5%90%AF%E5%8A%A8%E6%B5%81%E7%A8%8B.assets/%E7%B3%BB%E7%BB%9F%E5%90%AF%E5%8A%A8%E6%B5%81%E7%A8%8B.jpg)



---

## 分析工具和命令

* 源码查看可以使用Google提供的[Android Code Search](https://cs.android.com/)。

* 查看环境变量，源码中的很多环境变量可以通过这个方式来查看具体的值

  ```shell
  adb shell
  # 输出所有所有环境变量
  export
  # 输出对应环境变量的值
  echo $SYSTEMSERVERCLASSPATH
  ```

---

## init

内核启动完成后会启动 init进程，它是**第一个用户空间进程**(`pid = 1`)。

包括创建系统中的几个关键进程（zygote、servicmanager等）、提供属性服务(property service) 来管理Android系统的属性等功能。

主要涉及以下几个函数：

* **main()**：init程序的执行入口
* **FirstStageMain()**：首先被调用的函数，主要负责创建一些目录 以及 挂载一些必要的设备，并触发
* **SetupSelinux()**：负责安装 selinux安全策略，并触发SecondStageMain。
* **SecondStageMain()**：主要负责**初始化属性服务并启动、解析 init.rc文件 并 启动相关的进程**。其中包括了`zygote` 和`servicemanager` 。

> 这几个函数间的调用流程如下

![init](./Android%E7%B3%BB%E7%BB%9F%E5%90%AF%E5%8A%A8%E6%B5%81%E7%A8%8B.assets/init.jpg)

### init.main()

init 程序的入口

> [system/core/init/main.cpp](https://cs.android.com/android/platform/superproject/+/master:system/core/init/main.cpp)

```cpp
using namespace android::init;

int main(int argc, char** argv) {
#if __has_feature(address_sanitizer)
    __asan_set_error_report_callback(AsanReportCallback);
#elif __has_feature(hwaddress_sanitizer)
    __hwasan_set_error_report_callback(AsanReportCallback);
#endif
    // Boost prio which will be restored later
    setpriority(PRIO_PROCESS, 0, -20);
    if (!strcmp(basename(argv[0]), "ueventd")) {
        // 启动 ueventd，负责设备节点的创建
        return ueventd_main(argc, argv);
    }

    if (argc > 1) {
        if (!strcmp(argv[1], "subcontext")) {
            android::base::InitLogging(argv, &android::base::KernelLogger);
            const BuiltinFunctionMap& function_map = GetBuiltinFunctionMap();
			// 
            return SubcontextMain(argc, argv, &function_map);
        }

        if (!strcmp(argv[1], "selinux_setup")) {
            // 安装selinux安全策略, 内部重新执行init传入参数 "second_stage"
            return SetupSelinux(argv);
        }

        if (!strcmp(argv[1], "second_stage")) {
            // 执行第二阶段主流程
            return SecondStageMain(argc, argv);
        }
    }
	// 执行第一阶段主流程
    // 内部重新执行init传入参数 "selinux_setup"
    return FirstStageMain(argc, argv);
}
```

### FirstStageMain()

主要负责创建一些目录 以及 挂载一些必要的设备。最终会调用 `execv(path, const_cast<char**>(args));` 。

此处重新调用了init程序, 并传入参数`selinux_setup`。从而触发 `SetupSelinux()`

> [system/core/init/first_stage_init.cpp](https://cs.android.com/android/platform/superproject/+/master:system/core/init/first_stage_init.cpp;drc=5ca657189aac546af0aafaba11bbc9c5d889eab3;l=224)

```cpp
int FirstStageMain(int argc, char** argv) {
    if (REBOOT_BOOTLOADER_ON_PANIC) {
        InstallRebootSignalHandlers();
    }

    boot_clock::time_point start_time = boot_clock::now();
	// 保存错误信息
    std::vector<std::pair<std::string, int>> errors;
    // 定义了带参数的宏 CHECKCALL(x)，负责将执行失败的信息存入 errors中。
#define CHECKCALL(x) \
    if ((x) != 0) errors.emplace_back(#x " failed", errno);

    // Clear the umask.
    umask(0);
	// 清除环境变量
    CHECKCALL(clearenv());
    // 添加环境变量 PATH
    CHECKCALL(setenv("PATH", _PATH_DEFPATH, 1));
    //
    // Get the basic filesystem setup we need put together in the initramdisk
    // on / and then we'll let the rc file figure out the rest.
    // 此处将我们需要的文件系统挂载到 根目录/的 初始化内存盘中，然后创建了一些目录，并设置了相应的权限。
    // 将tmpfs虚拟内存文件系统 挂载到/dev目录上。
    CHECKCALL(mount("tmpfs", "/dev", "tmpfs", MS_NOSUID, "mode=0755"));
    CHECKCALL(mkdir("/dev/pts", 0755));
    // 创建socket设备节点
    CHECKCALL(mkdir("/dev/socket", 0755));
    CHECKCALL(mkdir("/dev/dm-user", 0755));
    // 将devpts文件系统 挂载到/dev/pts目录上
    CHECKCALL(mount("devpts", "/dev/pts", "devpts", 0, NULL));
#define MAKE_STR(x) __STRING(x)
    // 挂载proc虚拟文件系统 到 /proc上。
    CHECKCALL(mount("proc", "/proc", "proc", 0, "hidepid=2,gid=" MAKE_STR(AID_READPROC)));
#undef MAKE_STR
	....
     // 挂载 sysfs 虚拟内存文件系统，负责向user namespace提供直观的设备和驱动信息
    CHECKCALL(mount("sysfs", "/sys", "sysfs", 0, NULL));
    CHECKCALL(mount("selinuxfs", "/sys/fs/selinux", "selinuxfs", 0, NULL));
    
    // 创建 /dev/kmsg 设备节点，用于输出日志
    CHECKCALL(mknod("/dev/kmsg", S_IFCHR | 0600, makedev(1, 11)));
	...
        
    // `/second_stage_resources` is used to preserve files from first to second
    // stage init
    // 挂载tmpfs 到 /second_stage_resources，用于维护第一阶段到第二阶段的文件。
    CHECKCALL(mount("tmpfs", kSecondStageRes, "tmpfs", MS_NOEXEC | MS_NOSUID | MS_NODEV,
                    "mode=0755,uid=0,gid=0"))
#undef CHECKCALL

    // Now that tmpfs is mounted on /dev and we have /dev/kmsg, we can actually
    // talk to the outside world...
    InitKernelLogging(argv);
	...
    
    //  kBootImageRamdiskProp = "/system/etc/ramdisk/build.prop"
 	if (access(kBootImageRamdiskProp, F_OK) == 0) {
        std::string dest = GetRamdiskPropForSecondStage();
        std::string dir = android::base::Dirname(dest);
        std::error_code ec;
        if (!fs::create_directories(dir, ec) && !!ec) {
            LOG(FATAL) << "Can't mkdir " << dir << ": " << ec.message();
        }
        if (!fs::copy_file(kBootImageRamdiskProp, dest, ec)) {
            LOG(FATAL) << "Can't copy " << kBootImageRamdiskProp << " to " << dest << ": "
                       << ec.message();
        }
        LOG(INFO) << "Copied ramdisk prop to " << dest;
    }
        
    ...
    setenv(kEnvFirstStageStartedAt, std::to_string(start_time.time_since_epoch().count()).c_str(),
           1);
    const char* path = "/system/bin/init";
    const char* args[] = {path, "selinux_setup", nullptr};
    // 输出日志
    auto fd = open("/dev/kmsg", O_WRONLY | O_CLOEXEC);
    dup2(fd, STDOUT_FILENO);
    dup2(fd, STDERR_FILENO);
    close(fd);
    // 执行 /system/bin/init ，并传入args参数
    execv(path, const_cast<char**>(args));
	// 仅在错误发送时返回，
    // execv() only returns if an error happened, in which case we
    // panic and never fall through this conditional.
    PLOG(FATAL) << "execv(\"" << path << "\") failed";

    return 1;
}
```



### SetupSelinux()

负责安装selinux安全策略，同时也是触发 SecondStageMain() 的地方。

```cpp
int SetupSelinux(char** argv) {
	...
    LoadSelinuxPolicy(policy);
    ...
    SelinuxSetEnforcement();
 	...
	// 执行 "/system/bin/init"， 传入 "second_stage"。从而启动SecondStageMain().
    const char* path = "/system/bin/init";
    const char* args[] = {path, "second_stage", nullptr};
    execv(path, const_cast<char**>(args));
    // execv() only returns if an error happened, in which case we
    // panic and never return from this function.
    PLOG(FATAL) << "execv(\"" << path << "\") failed";

    return 1;
}
```



### SecondStageMain()

主要负责启动 属性服务 并 解析 init.rc文件然后启动相关的进程，其中包括zygote。

- **初始化属性**：调用`PropertyInit()` 从指定文件中读取属性并初始化属性。
- **启动属性服务**：通过`StartPropertyService(&property_fd)`启动属性服务。
- **解析`.rc`配置文件获取`Action` 和 `Service`**：比如 `init.rc`等
- **init进入一个无限循环**： 内部按照一定的顺序执行Action，包括创建zygote。

![SecondStageMain](./Android%E7%B3%BB%E7%BB%9F%E5%90%AF%E5%8A%A8%E6%B5%81%E7%A8%8B.assets/SecondStageMain.jpg)

> [init.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:system/core/init/init.cpp;drc=5ca657189aac546af0aafaba11bbc9c5d889eab3;l=939)

```cpp
int SecondStageMain(int argc, char** argv) {

    // No threads should be spin up until signalfd
    // is registered. If the threads are indeed required,
    // each of these threads _should_ make sure SIGCHLD signal
    // is blocked. See b/223076262
    boot_clock::time_point start_time = boot_clock::now();
    trigger_shutdown = [](const std::string& command) { shutdown_state.TriggerShutdown(command); };


    // 当设备解锁且允许debug时开启 adb root
    // See if need to load debug props to allow adb root, when the device is unlocked.
    const char* force_debuggable_env = getenv("INIT_FORCE_DEBUGGABLE");
    bool load_debug_prop = false;
    if (force_debuggable_env && AvbHandle::IsDeviceUnlocked()) {
        load_debug_prop = "true"s == force_debuggable_env;
    }
    unsetenv("INIT_FORCE_DEBUGGABLE");
	...

    // 从指定文件中读取属性并初始化，可以通过 getprop 查看。例如 ro.boot.platform 等。
    PropertyInit();
    
    // Umount second stage resources after property service has read the .prop files.
    // 读取完后卸载
    UmountSecondStageRes();
	...
    // Mount extra filesystems required during second stage init
    // 挂载 第二阶段使用的文件系统
    MountExtraFilesystems();
	...

    // 创建一个epoll
    Epoll epoll;
    if (auto result = epoll.Open(); !result.ok()) {
        PLOG(FATAL) << result.error();
    }
    epoll.SetFirstCallback(ReapAnyOutstandingChildren);
    InstallSignalFdHandler(&epoll);
    InstallInitNotifier(&epoll);
    
    // 启动属性服务，同时也设置了一些参数
    StartPropertyService(&property_fd);
	...

    // 获取 command和fuction的映射表，后续ExecuteOneCommand时会使用。
    const BuiltinFunctionMap& function_map = GetBuiltinFunctionMap();
    Action::set_function_map(&function_map);
    
    // 初始化Subcontext
    InitializeSubcontext();

    // 存储并管理解析到的 Action
    ActionManager& am = ActionManager::GetInstance();
    // 存储解析到的 Service
    ServiceList& sm = ServiceList::GetInstance();

    // 加载init.rc，解析内部的Action和Service
    LoadBootScripts(am, sm);
	...
    
	// 将解析得到的action 按照一定的顺序排列(有些动作必须在其他动作完成后才能执行)
  	// 重要的触发时机："early-init"、"init"、`late-init`
    am.QueueBuiltinAction(SetupCgroupsAction, "SetupCgroups");
    am.QueueBuiltinAction(SetKptrRestrictAction, "SetKptrRestrict");
    am.QueueBuiltinAction(TestPerfEventSelinuxAction, "TestPerfEventSelinux");
    am.QueueBuiltinAction(ConnectEarlyStageSnapuserdAction, "ConnectEarlyStageSnapuserd");
    // 添加 early-init 触发事件
    am.QueueEventTrigger("early-init");
	...
    
    // 初始化/dev/keychord设备
    Keychords keychords;
    am.QueueBuiltinAction(
            [&epoll, &keychords](const BuiltinArguments& args) -> Result<void> {
                for (const auto& svc : ServiceList::GetInstance()) {
                    keychords.Register(svc->keycodes());
                }
                keychords.Start(&epoll, HandleKeychord);
                return {};
            },
            "KeychordInit");

    // Trigger all the boot actions to get us started.
    // 添加 init 触发事件
    am.QueueEventTrigger("init");

    // Don't mount filesystems or start core system services in charger mode.
    std::string bootmode = GetProperty("ro.bootmode", "");
    if (bootmode == "charger") {
        am.QueueEventTrigger("charger");
    } else {
        // 添加 late-init 触发事件
        am.QueueEventTrigger("late-init");
    }

    // Run all property triggers based on current state of the properties.
    // 负责根据属性的当前状态，运行所有的属性触发
    am.QueueBuiltinAction(queue_property_triggers_action, "queue_property_triggers");

    // Restore prio before main loop
    setpriority(PRIO_PROCESS, 0, 0);
    // 开启无限循环
    while (true) {
        // By default, sleep until something happens. Do not convert far_future into
        // std::chrono::milliseconds because that would trigger an overflow. The unit of boot_clock
        // is 1ns.
        const boot_clock::time_point far_future = boot_clock::time_point::max();
        boot_clock::time_point next_action_time = far_future;

        auto shutdown_command = shutdown_state.CheckShutdown();
        if (shutdown_command) {
            LOG(INFO) << "Got shutdown_command '" << *shutdown_command
                      << "' Calling HandlePowerctlMessage()";
            HandlePowerctlMessage(*shutdown_command);
        }

        if (!(prop_waiter_state.MightBeWaiting() || Service::is_exec_service_running())) {
            // 执行action中的一个 Command
            am.ExecuteOneCommand();
            // If there's more work to do, wake up again immediately.
            // 还存在Command，则记录当前时间为唤醒时间
            if (am.HasMoreCommands()) {
                next_action_time = boot_clock::now();
            }
        }
        // Since the above code examined pending actions, no new actions must be
        // queued by the code between this line and the Epoll::Wait() call below
        // without calling WakeMainInitThread().
        if (!IsShuttingDown()) {
            auto next_process_action_time = HandleProcessActions();

            // If there's a process that needs restarting, wake up in time for that.
            // 重启一些需要重启的进程
            if (next_process_action_time) {
                next_action_time = std::min(next_action_time, *next_process_action_time);
            }
        }

        std::optional<std::chrono::milliseconds> epoll_timeout;
        if (next_action_time != far_future) {
            // 按秒 向上取整，计算epoll_timeout
            epoll_timeout = std::chrono::ceil<std::chrono::milliseconds>(
                    std::max(next_action_time - boot_clock::now(), 0ns));
        }
        // 调用 epoll.Wait()，指定epoll_timeout后唤醒
        auto epoll_result = epoll.Wait(epoll_timeout);
        if (!epoll_result.ok()) {
            LOG(ERROR) << epoll_result.error();
        }
        if (!IsShuttingDown()) {
            HandleControlMessages();
            SetUsbController();
        }
    }

    return 0;
}
```

### LoadBootScripts

在了解了 SencondStageMain 的大致流程后，我们就可以看看 LoadBootScripts 中加载了哪些配置？是如何加载的？

> Note：更多关于init.rc文件的语法和具体解析流程可以参考 [Android之init.rc配置文件](./Android之init_rc配置文件.md)一文。

从源码中发现主要是加载 `init.rc` 这类配置文件，并解析其中的Action和Service，这里概括一下大致流程：

* 首先选择init.rc文件进行加载，解析内部的Action和Service。
  * 优先通过``GetProperty("ro.boot.init_rc", "")``获取配置
  * 若不存在则使用默认的几个配置文件。

* 最终都是调用``parser.ParseConfig()``函数进行解析。
* 解析结果会保存到 `action_manager`和`service_list`中。

```cpp
static void LoadBootScripts(ActionManager& action_manager, ServiceList& service_list) {
    Parser parser = CreateParser(action_manager, service_list);
	// 优先从 ro.boot.init_rc 中获取init.rc的路径
    std::string bootscript = GetProperty("ro.boot.init_rc", "");
    if (bootscript.empty()) {
        // 没有则使用默认的init.rc文件
        parser.ParseConfig("/system/etc/init/hw/init.rc");
        if (!parser.ParseConfig("/system/etc/init")) {
            late_import_paths.emplace_back("/system/etc/init");
        }
        parser.ParseConfig("/system_ext/etc/init");
        if (!parser.ParseConfig("/vendor/etc/init")) {
            late_import_paths.emplace_back("/vendor/etc/init");
        }
        if (!parser.ParseConfig("/odm/etc/init")) {
            late_import_paths.emplace_back("/odm/etc/init");
        }
        if (!parser.ParseConfig("/product/etc/init")) {
            late_import_paths.emplace_back("/product/etc/init");
        }
    } else {
        parser.ParseConfig(bootscript);
    }
}
```

这里摘录部分 init.rc文件的内容，它内部涉及两个重要的进程 ： servicemanager、zygote。

* 导入了 zygote相关的rc配置文件。
* 定义在 init 阶段 需要启动的一些重要服务。例如 `servicemanager`。
* 会在 late-init 阶段中 触发`zygote-start` 进而启动 `zygote` 。

```shell
# 导入Zygote相关的配置
import /system/etc/init/hw/init.${ro.zygote}.rc

on init
    # 这里启动了 servicemanager
    start servicemanager
    ...

on late-init
    ...
    # 触发 zygote-start,内部启动了zygote
    trigger zygote-start
	...

on zygote-start && property:...
	....
    # 启动 zygote进程
    start zygote
    # 启动 zygote_secondary
    start zygote_secondary
	...
```

---

## zygote 进程

> zygote的启动流程的代码比较多，从native层一路到 java层。

zygote 是由init创建的，它是Android中的第一个ART 虚拟机(4.4以前是Dalvik)进程。主要就是**负责启动Java进程，所有应用进程以及system_server进程都是从zygote 孵化而来**。

* **启动VM并预加载了一些系统资源和类**。提供了一个基础的环境用于快速孵化其他进程。
* **fork SystemServer进程，交由它来启动一些重要的服务**。包括 AMS、PMS等。
* **创建socket进行IPC通信**。会进入 select poll 循环，等待socket请求，例如AMS的应用启动请求。

在[Android Init Language](./Android-Init-Language.md)一文中已经以zygote为例分析了 配置文件中的 service 是如何启动的。这里就简单介绍一下：

* 首先init进程会解析 rc 配置文件。

  * 在 `init.${ro.zygote}.rc` 配置文件中定义了 zygote。

    ```shell
    # 定义一个 zygote 服务。
    # 服务名： zygote。	
    # 程序二进程文件位于：`/system/bin/app_process64`
    # 启动参数：`-Xzygote /system/bin --zygote --start-system-server --socket-name=zygote`
    # --start-system-server：zygote启动后启动 system_server进程。
    # --socket-name=zygote：创建一个名为 zygote的socket，用于后续通信。
    service zygote /system/bin/app_process64 -Xzygote /system/bin --zygote --start-system-server --socket-name=zygote
    ...
    ```

  * 在  `init.rc` 的 `on late-init` 定义了 zygote启动 的 Command。

    ```shell
    # 导入Zygote相关的配置
    import /system/etc/init/hw/init.${ro.zygote}.rc
    on late-init
        ....
        # Now we can start zygote for devices with file based encryption
        # 触发 zygote-start,内部启动了zygote
        trigger zygote-start
    	...
    	
    on zygote-start && ...
        # 启动 zygote进程
        start zygote
        # 启动 zygote_secondary
        start zygote_secondary
    ```

* 接着init进程会开启 loop循环，在内部中通过 `ExecuteOneCommand()` 执行`start zygote`，对应 `do_start()`函数。

* do_start() 内部会 fork 一个子进程，然后在子进程中调用 `execv()` 启动了zygote程序。

  * 包含2个zygote程序：`/system/bin/app_process64`、`/system/bin/app_process32`。一个是64位一个是32位的区别。其中 zygote64是 primay_zygote，它的流程是完整的（比如只有primay_zygote会启动system_server）。我们仅分析 primay_zygote 即可。

* zygote启动后会fork system_server 并 创建一个socket 来接收AMS创建应用的请求。


### app_process.main()

那么我们接着来看看 `app_process ` 做了哪些事情？

* 将运行时参数解析到 args 中：`/system/bin --zygote --start-system-server --socket-name=zygote`。
* 将进程名修改为 zygote。
* 调用 `runtime.start()` 来执行Java类 `com.android.internal.os.ZygoteInit`。传入参数 args。

> [app_main.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/cmds/app_process/app_main.cpp;l=173;)

```cpp
#if defined(__LP64__)
static const char ABI_LIST_PROPERTY[] = "ro.product.cpu.abilist64";
static const char ZYGOTE_NICE_NAME[] = "zygote64";
#else
static const char ABI_LIST_PROPERTY[] = "ro.product.cpu.abilist32";
static const char ZYGOTE_NICE_NAME[] = "zygote";
#endif
// --zygote : Start in zygote mode
// --start-system-server : Start the system server.
// --application : Start in application (stand alone, non zygote) mode.
// --nice-name : The nice name for this process.
int main(int argc, char* const argv[])
{
	// argv: -Xzygote /system/bin --zygote --start-system-server --socket-name=zygote
    AppRuntime runtime(argv[0], computeArgBlockSize(argc, argv));
    // Process command line arguments
    // ignore argv[0]
    // 跳过第一个参数
    argc--;
    argv++;
    // argv: /system/bin --zygote --start-system-server --socket-name=zygote

	...
    // Parse runtime arguments.  Stop at first unrecognized option.
    // 解析运行时参数
    bool zygote = false;
    bool startSystemServer = false;
    bool application = false;
    String8 niceName; // 用于重命名
    String8 className;

    ++i;  // Skip unused "parent dir" argument.
    // 跳过 parent dir
    // argv: --zygote --start-system-server --socket-name=zygote

    while (i < argc) {
        const char* arg = argv[i++];
        if (strcmp(arg, "--zygote") == 0) {
            zygote = true; // 后面判断使用
            niceName = ZYGOTE_NICE_NAME; // nickname 赋值，进程重命名使用
        } else if (strcmp(arg, "--start-system-server") == 0) {
            startSystemServer = true; // 此处 ture， 后续处理 args 会用到
        } else if (strcmp(arg, "--application") == 0) {
            application = true;
        } else if (strncmp(arg, "--nice-name=", 12) == 0) {
            niceName.setTo(arg + 12);
        } else if (strncmp(arg, "--", 2) != 0) {
            className.setTo(arg);
            break;
        } else {
            --i;
            break;
        }
    }

    Vector<String8> args;
    if (!className.isEmpty()) {
        // We're not in zygote mode, the only argument we need to pass
        // to RuntimeInit is the application argument.
        //
        // The Remainder of args get passed to startup class main(). Make
        // copies of them before we overwrite them with the process name.
        args.add(application ? String8("application") : String8("tool"));
        runtime.setClassNameAndArgs(className, argc - i, argv + i);
        if (!LOG_NDEBUG) {
          String8 restOfArgs;
          char* const* argv_new = argv + i;
          int argc_new = argc - i;
          for (int k = 0; k < argc_new; ++k) {
            restOfArgs.append("\"");
            restOfArgs.append(argv_new[k]);
            restOfArgs.append("\" ");
          }
          ALOGV("Class name = %s, args = %s", className.string(), restOfArgs.string());
        }
    } else {
        // We're in zygote mode.
        maybeCreateDalvikCache();

        if (startSystemServer) { 
            // 添加 start-system-server 参数，后续启动 system_server 会用到。
            args.add(String8("start-system-server"));
        }

        char prop[PROP_VALUE_MAX];
        if (property_get(ABI_LIST_PROPERTY, prop, NULL) == 0) {
            LOG_ALWAYS_FATAL("app_process: Unable to determine ABI list from property %s.",
                ABI_LIST_PROPERTY);
            return 11;
        }

        String8 abiFlag("--abi-list=");
        abiFlag.append(prop);
        args.add(abiFlag);

        // In zygote mode, pass all remaining arguments to the zygote
        // main() method.
        for (; i < argc; ++i) {
            args.add(String8(argv[i]));
        }
    }

    if (!niceName.isEmpty()) {
        // 将进程名修改为 ZYGOTE_NICE_NAME: zygote
        runtime.setArgv0(niceName.string(), true /* setProcName */);
    }
    //
    if (zygote) {
        // 根据java类的类名来执行它
        runtime.start("com.android.internal.os.ZygoteInit", args, zygote);
    } else if (!className.isEmpty()) {
        runtime.start("com.android.internal.os.RuntimeInit", args, zygote);
    } else {
        fprintf(stderr, "Error: no class name or --zygote supplied.\n");
        app_usage();
        LOG_ALWAYS_FATAL("app_process: no class name or --zygote supplied.");
    }
}
```

### AndroidRuntime::start()

* 将一些根目录添加到环境变量中。比如`/system`。
* **初始化 Jni 调用的实现**，这里使用了默认库：persist.sys.dalvik.vm.lib
* **启动了vm虚拟机**。
* **在虚拟机上注册JNI函数**。
* 创建一个strArray 保存 className 和 options，后续作为 main()函数的参数。
  *  strArray[0] = classNameStr。
  *  strArray[1 ..] = options[..]
* 通过`JNI.CallStaticVoidMethod`来调用Java方法：`ZygoteInit.main()`，**启动了Zygote程序**。

> [AndroidRuntime.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/jni/AndroidRuntime.cpp;drc=5ca657189aac546af0aafaba11bbc9c5d889eab3;l=1199)

```cpp
// className = com.android.internal.os.ZygoteInit
void AndroidRuntime::start(const char* className, const Vector<String8>& options, bool zygote)
{
    ALOGD(">>>>>> START %s uid %d <<<<<<\n",
            className != NULL ? className : "(unknown)", getuid());
	
    // 如果是primary_zygote 则会 fork system_server 。
    static const String8 startSystemServer("start-system-server");
    // Whether this is the primary zygote, meaning the zygote which will fork system server.
    bool primary_zygote = false;
    for (size_t i = 0; i < options.size(); ++i) {
        // 我们传入的参数是有 start-system-server的
        if (options[i] == startSystemServer) {
            // 是 primary_zygote
            primary_zygote = true;
           /* track our progress through the boot sequence */
           const int LOG_BOOT_PROGRESS_START = 3000;
           LOG_EVENT_LONG(LOG_BOOT_PROGRESS_START,  ns2ms(systemTime(SYSTEM_TIME_MONOTONIC)));
        }
    }

    // 设置一些根目录
    const char* rootDir = getenv("ANDROID_ROOT");
    if (rootDir == NULL) {
        rootDir = "/system";
        if (!hasDir("/system")) {
            LOG_FATAL("No root directory specified, and /system does not exist.");
            return;
        }
        setenv("ANDROID_ROOT", rootDir, 1);
    }
	// ART
    const char* artRootDir = getenv("ANDROID_ART_ROOT");
    if (artRootDir == NULL) {
        LOG_FATAL("No ART directory specified with ANDROID_ART_ROOT environment variable.");
        return;
    }
	// 多国语言
    const char* i18nRootDir = getenv("ANDROID_I18N_ROOT");
    if (i18nRootDir == NULL) {
        LOG_FATAL("No runtime directory specified with ANDROID_I18N_ROOT environment variable.");
        return;
    }
	// 时区
    const char* tzdataRootDir = getenv("ANDROID_TZDATA_ROOT");
    if (tzdataRootDir == NULL) {
        LOG_FATAL("No tz data directory specified with ANDROID_TZDATA_ROOT environment variable.");
        return;
    }

    /* start the virtual machine */
    // 初始化Jni调用的实现库
    JniInvocation jni_invocation;
    // NULL表示使用默认库：persist.sys.dalvik.vm.lib
    jni_invocation.Init(NULL);
    JNIEnv* env;
    // 启动虚拟机
    if (startVm(&mJavaVM, &env, zygote, primary_zygote) != 0) {
        return;
    }
	// 回调
    onVmCreated(env);

    /*
     * Register android functions.
     * 开始 在VM上注册JNI
     */
    if (startReg(env) < 0) { 
        ALOGE("Unable to register all android natives\n");
        return;
    }

    /*
     * We want to call main() with a String array with arguments in it.
     * At present we have two arguments, the class name and an option string.
     * Create an array to hold them.
     */
    // 创建一个数组保存 className 和 options，后续作为 main()方法的参数
    jclass stringClass;
    jobjectArray strArray;
    jstring classNameStr;
    stringClass = env->FindClass("java/lang/String");
    strArray = env->NewObjectArray(options.size() + 1, stringClass, NULL);
    classNameStr = env->NewStringUTF(className);
    // strArray[0] = classNameStr
    env->SetObjectArrayElement(strArray, 0, classNameStr);
    for (size_t i = 0; i < options.size(); ++i) {
        // strArray[1 ..] = options[..]
        jstring optionsStr = env->NewStringUTF(options.itemAt(i).string());
        assert(optionsStr != NULL);
        env->SetObjectArrayElement(strArray, i + 1, optionsStr);
    }

    /*
     * Start VM.  This thread becomes the main thread of the VM, and will
     * not return until the VM exits.
     */
    char* slashClassName = toSlashClassName(className != NULL ? className : "");
    // 找到 com.android.internal.os.ZygoteInit
    jclass startClass = env->FindClass(slashClassName);
    if (startClass == NULL) {
        ALOGE("JavaVM unable to locate class '%s'\n", slashClassName);
        /* keep going */
    } else {
        // 获取到 main()方法
        jmethodID startMeth = env->GetStaticMethodID(startClass, "main",
            "([Ljava/lang/String;)V");
        if (startMeth == NULL) {
            ALOGE("JavaVM unable to find main() in '%s'\n", className);
            /* keep going */
        } else { // 执行 com.android.internal.os.ZygoteInit.main()函数
            env->CallStaticVoidMethod(startClass, startMeth, strArray);

#if 0
            if (env->ExceptionCheck())
                threadExitUncaughtException(env);
#endif
        }
    }
    
    free(slashClassName);
}
```



### ZygoteInit.main()： 终于来到Java层

`ZygoteInit.main()` 函数是 Zygote进程的入口。其中的主要流程包括以下这些：

* 在zygote fork 其他子进程之前做了一些初始化操作：启动ddms，替换libcore的MimeMap。
* 为了避免频繁的加载类和资源，会在 第一次fork子进程之前进行的预加载。包括了通用类、drawable和color、openGL、WebView以及共享库等等。
* 创建 ZygoteServer，它内部创建了zygote socket。
* fork了 `system_server`进程并启动。zygote将孵化外的其他工作基本都交给了system_server来处理。
* 开启 select loop 等待请求，这里会接收socket请求，例如socket连接请求，AMS的应用启动请求等。
* 收到请求后 fork 一个子进程。在父进程中通过socket返回结果，包括子进程的pid。
* 在子进程中在子进程中关闭不要的socket、创建Binder，并查询对应程序的启动入口 `main()`，最终启动程序。

> [ZygoteInit.java - main()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/com/android/internal/os/ZygoteInit.java;l=831;)

```java
public class ZygoteInit {
    
    private static final String SOCKET_NAME_ARG = "--socket-name=";
    private static final String ABI_LIST_ARG = "--abi-list=";
    
    @UnsupportedAppUsage
    public static void main(String[] argv) {
        ZygoteServer zygoteServer = null;
        // Mark zygote start. This ensures that thread creation will throw
        // an error.
        ZygoteHooks.startZygoteNoThreadCreation();

        // Zygote goes into its own process group.
        try {
            // 设置 pid=0; pgid=0。所以Zygote是 Group Leader
            Os.setpgid(0, 0);
        } catch (ErrnoException ex) {
            throw new RuntimeException("Failed to setpgid(0,0)", ex);
        }

        Runnable caller;
        try {
            // Store now for StatsLogging later.
            final long startTime = SystemClock.elapsedRealtime();
            ...
            // 在fork前做一些初始化：启动ddms，替换libcore的MimeMap
            RuntimeInit.preForkInit();

            boolean startSystemServer = false;
            // socket
            String zygoteSocketName = "zygote";
            String abiList = null;
            boolean enableLazyPreload = false;
            for (int i = 1; i < argv.length; i++) {
                if ("start-system-server".equals(argv[i])) {
                    startSystemServer = true; // 此处 ture。后续用于判断是否需要启动SystemServer
                } else if ("--enable-lazy-preload".equals(argv[i])) {
                    enableLazyPreload = true;
                } else if (argv[i].startsWith(ABI_LIST_ARG)) {
                    abiList = argv[i].substring(ABI_LIST_ARG.length());
                } else if (argv[i].startsWith(SOCKET_NAME_ARG)) {
                    // 从 --socket-name=，中取出socketName: zygote。优先用这个。
                    zygoteSocketName = argv[i].substring(SOCKET_NAME_ARG.length());
                } else {
                    throw new RuntimeException("Unknown command line argument: " + argv[i]);
                }
            }
			// Zygote.PRIMARY_SOCKET_NAME = "zygote"
            // isPrimaryZygote = true
            final boolean isPrimaryZygote = zygoteSocketName.equals(Zygote.PRIMARY_SOCKET_NAME);
            ...
            if (!enableLazyPreload) {
                ...
                // 为了避免频繁的加载类和资源，在第一次fork之前进行的预加载。
                preload(bootTimingsTraceLog);
               ... // ZygotePreload
            }
				
            // Do an initial gc to clean up after startup
            gcAndFinalize();
            Zygote.initNativeState(isPrimaryZygote);
            //
            ZygoteHooks.stopZygoteNoThreadCreation();
            
			// 创建一个 ZygoteServer，它内部创建了zygote socket
            zygoteServer = new ZygoteServer(isPrimaryZygote);
            if (startSystemServer) {
                // fork systemserver进程
                Runnable r = forkSystemServer(abiList, zygoteSocketName, zygoteServer);
 				// 仅子进程才有值，zygote 进程是null
                if (r != null) {
                    // 例如 systemserver进程创建成功后，会返回指向main函数的MethodAndArgsCaller，并在此处运行程序。
                    r.run();
                    return;
                }
            }
			...
           	// 开启 select loop 等待请求，这里会接收AMS的应用启动请求。
            // 当fock了一个子进程时才会有返回值
            caller = zygoteServer.runSelectLoop(abiList);
        } catch (Throwable ex) {
            Log.e(TAG, "System zygote died with fatal exception", ex);
            throw ex;
        } finally {
            // 只有两种情况才会执行到这：
            // 1. 发生异常。
            // 2. 是新建子进程，然而子进程并不需要socket。
            if (zygoteServer != null) {
                zygoteServer.closeServerSocket();
            }
        }
        // We're in the child process and have exited the select loop. Proceed to execute the
        // command.
        // 仅子进程才有值，zygote 进程是null
        // 应用进程启动会返回指向main函数的MethodAndArgsCaller，在此处运行应用程序。
        if (caller != null) {
            caller.run();
        }
    }
}

```

---

## system_server 进程

system_server **是zygote 孵化的第一个进程**，内部启动很多重要的系统服务（zygote将除了孵化进程之外的功能基本都交给了 system_server 来处理），包括 ActivityManagerService、WindowManagerService、PackageManagerService、DisplayManager Service等等。

首先来看一下 system_server 是如何被 zygote fork 出来的。

### forkSystemServer()

* 硬编码了system_server启动的参数，比较关键的是定义了启动类名`com.android.server.SystemServer`。
* 在fork 之前停止了所有其他线程，保证变成单线程。
  * **fork机制仅会拷贝当前线程，并不支持多线程**，zygote会将这些线程管理起来，在fork前将所有线程停止，fork完后再重新启动线程。

* 最终会调用 `nativeForkSystemServer()` 这个native函数来创建 system_server 进程。

> [ZygoteInit.java - forkSystemServer()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/com/android/internal/os/ZygoteInit.java;drc=5ca657189aac546af0aafaba11bbc9c5d889eab3;l=693)

```java
private static Runnable forkSystemServer(String abiList, String socketName,
                                         ZygoteServer zygoteServer) {
    ...
    
    /* Hardcoded command line to start the system server */
    // system server的一些硬编码启动参数
    String[] args = {
        "--setuid=1000",
        "--setgid=1000",
        "--setgroups=1001,1002,1003,1004,1005,1006,1007,1008,1009,1010,1018,1021,1023,"
            + "1024,1032,1065,3001,3002,3003,3005,3006,3007,3009,3010,3011,3012",
        "--capabilities=" + capabilities + "," + capabilities,
        "--nice-name=system_server", 
        "--runtime-args", // 表示后面的是运行时参数，应该由RuntimeInit处理
        "--target-sdk-version=" + VMRuntime.SDK_VERSION_CUR_DEVELOPMENT,
        "com.android.server.SystemServer", // start classname
    };
    ZygoteArguments parsedArgs;
    int pid;
    ...
    try {
        // 负责解析args，最终会被解析到 ZygoteArguments 中
 		ZygoteCommandBuffer commandBuffer = new ZygoteCommandBuffer(args);
        try {
            parsedArgs = ZygoteArguments.getInstance(commandBuffer);
        } catch (EOFException e) {
            throw new AssertionError("Unexpected argument error for forking system server", e);
        }
        commandBuffer.close();
        // 内部调用nativeForkSystemServer() 这个native函数fork SystemServer进程。
        pid = Zygote.forkSystemServer(
            parsedArgs.mUid, parsedArgs.mGid,
            parsedArgs.mGids,
            parsedArgs.mRuntimeFlags,
            null,
            parsedArgs.mPermittedCapabilities,
            parsedArgs.mEffectiveCapabilities);
    } catch (IllegalArgumentException ex) {
        throw new RuntimeException(ex);
    }

    /* For child process */
    // 子进程创建成功
    if (pid == 0) { 
        // 等待 SecondaryZygote
        if (hasSecondZygote(abiList)) {
            waitForSecondaryZygote(socketName);
        }
        zygoteServer.closeServerSocket();
        // 处理 进程
        return handleSystemServerProcess(parsedArgs);
    }
    return null;
}

 // 先停止所有线程，fock完后再重新启动线程
 static int forkSystemServer(int uid, int gid, int[] gids, int runtimeFlags,
            int[][] rlimits, long permittedCapabilities, long effectiveCapabilities) {
     	// 内部stop了所有 DAEMONS 线程
        ZygoteHooks.preFork();

        int pid = nativeForkSystemServer(
                uid, gid, gids, runtimeFlags, rlimits,
                permittedCapabilities, effectiveCapabilities);
        // Set the Java Language thread priority to the default value for new apps.
     	// 将线程优先级设置成默认
        Thread.currentThread().setPriority(Thread.NORM_PRIORITY);
		// 内部会重新开启所有DAEMONS线程
        ZygoteHooks.postForkCommon();
        return pid;
 }

```

### handleSystemServerProcess()

子进程创建后执行SystemServer程序

进程创建后通过 handleSystemServerProcess() 处理指令参数。

* 通过环境变量`SYSTEMSERVERCLASSPATH`来获取SystemServer的Class路径，构建ClassLoader。

  ```shell
  /system/framework/com.android.location.provider.jar:/system/framework/services.jar:/apex/com.android.adservices/javalib/service-adservices.jar:/apex/com.android.adservices/javalib/service-sdksandbox.jar:/apex/com.android.appsearch/javalib/service-appsearch.jar:/apex/com.android.art/javalib/service-art.jar:/apex/com.android.media/javalib/service-media-s.jar:/apex/com.android.permission/javalib/service-permission.jar
  ```

* 将参数 传入 ZygoteInit.zygoteInit()  返回执行 main()函数的runnable。

> [ZygoteInit.java - handleSystemServerProcess()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/com/android/internal/os/ZygoteInit.java;drc=cd1df1e4c9737d5e51e1dc5f5d22038eca0aa1e7;l=503)

```java
private static Runnable handleSystemServerProcess(ZygoteArguments parsedArgs) {
    // set umask to 0077 so new files and directories will default to owner-only permissions.
    Os.umask(S_IRWXG | S_IRWXO);
    if (parsedArgs.mNiceName != null) {
        Process.setArgV0(parsedArgs.mNiceName);
    }
   	...
	//
    if (parsedArgs.mInvokeWith != null) {
        // 启动参数中并不存在 --invoke-with
        ...
    } else {
        // 获取 ClassLoader
        ClassLoader cl = getOrCreateSystemServerClassLoader();
        if (cl != null) {
            Thread.currentThread().setContextClassLoader(cl);
        }
        // 将参数传给zygoteInit来处理，会返回执行 main()函数的runnable。
        return ZygoteInit.zygoteInit(parsedArgs.mTargetSdkVersion,
                                     parsedArgs.mDisabledCompatChanges,
                                     parsedArgs.mRemainingArgs, cl);
    }

    /* should never reach here */
}

// 获取systemServer的classpath 构建 classLoader 并缓存。
private static ClassLoader getOrCreateSystemServerClassLoader() {
    if (sCachedSystemServerClassLoader == null) {
        // 通过 Os.getenv("SYSTEMSERVERCLASSPATH") 来获取systemServer相关class的路径
        final String systemServerClasspath = Os.getenv("SYSTEMSERVERCLASSPATH");
        if (systemServerClasspath != null) {
            sCachedSystemServerClassLoader = createPathClassLoader(systemServerClasspath,
                                                                   VMRuntime.SDK_VERSION_CUR_DEVELOPMENT);
        }
    }
    return sCachedSystemServerClassLoader;
}
```

### ZygoteInit.zygoteInit()：子进程初始化过程

**zygote进程 fork的所有子进程在启动后都会调用这个函数**。这里以 启动 SystemServer 来分析，若是启动其他应用的请求仅是参数存在差异而已，这一部分的流程是一样的。

* **设置一些通用的配置**：异常处理、日志输出等。
* 通过`ZygoteInit.nativeZygoteInit()`**打开了Binder并开启了Binder线程池**。
* **初始化应用并返回用于启动的应用程序的 runnable**。在 `ZygoteInit.main()` 中执行这个runnable。

> [ZygoteInit.java - zygoteInit()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/com/android/internal/os/ZygoteInit.java;drc=cd1df1e4c9737d5e51e1dc5f5d22038eca0aa1e7;l=990)

```java
public static Runnable zygoteInit(int targetSdkVersion, long[] disabledCompatChanges,
                                  String[] argv, ClassLoader classLoader) {
    if (RuntimeInit.DEBUG) {
        Slog.d(RuntimeInit.TAG, "RuntimeInit: Starting application from zygote");
    }

    Trace.traceBegin(Trace.TRACE_TAG_ACTIVITY_MANAGER, "ZygoteInit");
    RuntimeInit.redirectLogStreams();
    // 一些通用的配置：异常处理、日志输出等。
    RuntimeInit.commonInit();
    // 调用 nativeZygoteInit() 这个native方法。
    // 启动了Binder线程池
    ZygoteInit.nativeZygoteInit(); 
    // 初始化应用：最终会通过反射的方式调用 main() 函数
    return RuntimeInit.applicationInit(targetSdkVersion, disabledCompatChanges, argv,
                                       classLoader);
}
```

#### nativeZygoteInit()

再zygote中启动的AndroidRuntime其实是 AppRuntime, `onZygoteInit()`的 实现就在AppRuntime中。

> [AndroidRuntime.cpp - com_android_internal_os_ZygoteInit_nativeZygoteInit()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/jni/AndroidRuntime.cpp;drc=3a7ad36d2815b7b3ecc930c6b94b6be0e62fbce7;l=254)

```cpp
static void com_android_internal_os_ZygoteInit_nativeZygoteInit(JNIEnv* env, jobject clazz)
{
    // gCurRuntime 就是 AppRuntime
    gCurRuntime->onZygoteInit();
}
```

#### AppRuntime.onZygoteInit()：Binder相关

这里主要是创建了 ProcessState实例，它是一个单例，在构造函数中打开了Binder设备。之后又启动了Binder线程池。

这一块的具体分析我放到了[Android Binder]() 中。

> [app_main.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/cmds/app_process/app_main.cpp;l=92)

```cpp
virtual void onZygoteInit()
{
    // 这里打开了Binder驱动
    sp<ProcessState> proc = ProcessState::self();
    ALOGV("App process: starting thread pool.\n");
    // 启动了一个线程池，它是Binder线程池
    proc->startThreadPool();
}
```

#### RuntimeInit.commonInit()

* 设置了默认异常处理机制。
* 设置了一个时区。
* 配置了android 的日志输出方式。
* 配置了HttpURLConnection的默认user-agent。
* 将流量统计 和 socket tagger关联。

> [RuntimeInit.java - commonInit()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/com/android/internal/os/RuntimeInit.java;drc=cd1df1e4c9737d5e51e1dc5f5d22038eca0aa1e7;l=226)

```java
protected static final void commonInit() {
    LoggingHandler loggingHandler = new LoggingHandler();
    // 设置默认异常处理机制
    // set pre handler， 应用无法替换 
    RuntimeHooks.setUncaughtExceptionPreHandler(loggingHandler);
    // set default handler，应用中可以替换这个
    Thread.setDefaultUncaughtExceptionHandler(new KillApplicationHandler(loggingHandler));
    /*
     * Install a time zone supplier that uses the Android persistent time zone system property.
     */
    RuntimeHooks.setTimeZoneIdSupplier(() -> SystemProperties.get("persist.sys.timezone"));

    // AndroidConfig的构造函数实现了对应log的配置，添加了一个处理器。
    // java.util.logging.addHandler(new AndroidHandler());
    LogManager.getLogManager().reset();
    new AndroidConfig();

    // 设置HttpURLConnection的默认user-agent：例如 "Dalvik/1.1.0 (Linux; U; Android Eclair Build/MAIN)"
    String userAgent = getDefaultUserAgent();
    System.setProperty("http.agent", userAgent);
    /*
     * Wire socket tagging to traffic stats.
     * 流量统计 和 socket tagger关联
     */
    TrafficStats.attachSocketTagger();
    initialized = true;
}

```

#### RuntimeInit.applicationInit()

* 在app启动之前设置一些VMRuntime的配置。
* 解析参数，并通过 findStaticMain() 找到 需要执行的main()函数。

> [RuntimeInit.java - applicationInit()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/com/android/internal/os/RuntimeInit.java;drc=cd1df1e4c9737d5e51e1dc5f5d22038eca0aa1e7;l=364)

```java
 protected static Runnable applicationInit(int targetSdkVersion, long[] disabledCompatChanges,
            String[] argv, ClassLoader classLoader) {
     ...
     nativeSetExitWithoutCleanup(true);

     // VMRuntime 是 VM-global的访问接口。可以通过它来修改vm的全局配置。
     // app 启动之前修改一些会影响vm行为的配置。
     // 设置targetSdkVersion。
     VMRuntime.getRuntime().setTargetSdkVersion(targetSdkVersion);
     VMRuntime.getRuntime().setDisabledCompatChanges(disabledCompatChanges);
	 // 进一步解析剩余的参数，主要就是运行时参数。
     final Arguments args = new Arguments(argv);
     // startClass：例如 com.android.server.SystemServer
     return findStaticMain(args.startClass, args.startArgs, classLoader);
 }
```

#### RuntimeInit.findStaticMain()

返回 用于启动的应用程序的 runnable。

> [RuntimeInit.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/com/android/internal/os/RuntimeInit.java;drc=cd1df1e4c9737d5e51e1dc5f5d22038eca0aa1e7;l=305)

```java
protected static Runnable findStaticMain(String className, String[] argv,
                                         ClassLoader classLoader) {
    Class<?> cl;
    try {
        // 获取className对应的Class类实例,
        cl = Class.forName(className, true, classLoader);
    } catch (ClassNotFoundException ex) {
        ...
    }
    Method m;
    try {
        // 反射获取 main()函数的Method
        m = cl.getMethod("main", new Class[] { String[].class });
    } catch () {
        ...
    }

    int modifiers = m.getModifiers();
    // 检测是不是 public static
    if (! (Modifier.isStatic(modifiers) && Modifier.isPublic(modifiers))) {
        throw new RuntimeException(
            "Main method is not public and static on " + className);
    }
    // 返回MethodAndArgsCaller,交由ZygoteInit.main()执行。
    // 它是一个Runnable, run()中反射执行了 main()函数。
    return new MethodAndArgsCaller(m, argv);
}
```

### MethodAndArgsCaller.java

在run() 中反射执行了 main() 函数。

```java
static class MethodAndArgsCaller implements Runnable {
    /** method to call */
    private final Method mMethod;
    /** argument array */
    private final String[] mArgs;

    public void run() {
        try {
            // 执行对应函数
            mMethod.invoke(null, new Object[] { mArgs });
        } catch (IllegalAccessException ex) {
            throw new RuntimeException(ex);
        } catch (InvocationTargetException ex) {
            Throwable cause = ex.getCause();
            if (cause instanceof RuntimeException) {
                throw (RuntimeException) cause;
            } else if (cause instanceof Error) {
                throw (Error) cause;
            }
            throw new RuntimeException(ex);
        }
    }
}
```



### SystemServer.main()

在 `ZygoteInit.main()` 中会执行 找到的 对应程序的main() 函数，

这里是调用 `SystemServer.main()`来启动 SystemServer程序。

> [SystemServer.java - main()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/java/com/android/server/SystemServer.java;l=650;)

```java
/**
 * The main entry point from zygote.
 * 从zygote开始的主入口
 */
public static void main(String[] args) {
    new SystemServer().run();
}
```

### SystemServer.run()

和ActivityThread的main()类似，只不过做的事情不一样。

* 在启动服务前执行一些**初始化操作**。
  * 添加一些SystemProperties。
  * Binder的一些配置：最大线程数等。
* **创建system context**。
* **准备好 main looper。**
* **将SystemServer自身注册到 ServiceManager 中**。
* **创建了 SystemServiceManager来管理系统服务的创建、启动等生命周期事件**。
* **启动系统服务**：可分为BootstrapServices、CoreServices、OtherServices、ApexServices 四种类型的服务，内部启动了很多系统服务。
  * 包括WindowManagerService、PackageManagerService、DisplayManager Service、ActivityManagerService等等。
* **启动Loop 循环**，等待消息。

> [SystemServer.java -run()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/java/com/android/server/SystemServer.java;l=763)

```java
 private void run() {
     ...
     try {
         // 启动服务前的一些初始化操作
		 // 在SystemProperties中设置一些信息。如system进程启动信息、默认时区、语言等等
         SystemProperties.set(SYSPROP_START_COUNT, String.valueOf(mStartCount));
		 ...
         //    
         // Here we go! 那就go
         Slog.i(TAG, "Entered the Android system server!");
         final long uptimeMillis = SystemClock.elapsedRealtime();
         // 如果 runtime 在上次启动后发生了切换（例如OTA），重新设置整个属性来保持同步。
         SystemProperties.set("persist.sys.dalvik.vm.lib.2", VMRuntime.getRuntime().vmLibrary());

         // Mmmmmm... more memory! 哈哈哈
         // 移除限制，允许分配到最大的堆大小
         VMRuntime.getRuntime().clearGrowthLimit();

         // Some devices rely on runtime fingerprint generation, so make sure
         // we've defined it before booting further.
         // 确保以定义了指纹识别
         Build.ensureFingerprintProperty();

         // Within the system server, it is an error to access Environment paths without
         // explicitly specifying a user.
         // 明确指定用户，以访问环境变量
         Environment.setUserRequired(true);

         // Within the system server, any incoming Bundles should be defused
         // to avoid throwing BadParcelableException.
         // 所有Bundles数据应该被 Defuse
         BaseBundle.setShouldDefuse(true);
         // Within the system server, when parceling exceptions, include the stack trace
         Parcel.setStackTraceParceling(true);
		
         // Ensure binder calls into the system always run at foreground priority.
         BinderInternal.disableBackgroundScheduling(true);
         // 增加binder的最大线程数
         BinderInternal.setMaxThreads(sMaxBinderThreads);
		
         // 准备 main looper thread
         // Prepare the main looper thread (this thread).
         android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_FOREGROUND);
         android.os.Process.setCanSelfBackground(false);
         // 
         Looper.prepareMainLooper();
         Looper.getMainLooper().setSlowLogThresholdMs(SLOW_DISPATCH_THRESHOLD_MS, SLOW_DELIVERY_THRESHOLD_MS);

         SystemServiceRegistry.sEnableServiceNotFoundWtf = true;

         // Initialize native services.
         // 初始化 native services
         System.loadLibrary("android_servers");
		 ...
			
         // Initialize the system context.
         // 初始化system context，创建了ActivityThread。
         createSystemContext();
		 
         // 
         // Call per-process mainline module initialization.
         ActivityThread.initializeMainlineModules();

         // Sets the dumper service
         // 将SystemServer自身注册到 ServiceManager 中
         ServiceManager.addService("system_server_dumper", mDumper);
         mDumper.addDumpable(this);
		 
         // 创建 SystemServiceManager.
         mSystemServiceManager = new SystemServiceManager(mSystemContext);
         mSystemServiceManager.setStartInfo(mRuntimeRestart,
                                            mRuntimeStartElapsedTime, mRuntimeStartUptime);
         mDumper.addDumpable(mSystemServiceManager);
		 // 将SystemServiceManager添加到本地服务
         LocalServices.addService(SystemServiceManager.class, mSystemServiceManager);
         // Prepare the thread pool for init tasks that can be parallelized
         SystemServerInitThreadPool tp = SystemServerInitThreadPool.start();
         mDumper.addDumpable(tp);

         // 为系统服务加载预装的系统字体
         if (Typeface.ENABLE_LAZY_TYPEFACE_INITIALIZATION) {
             Typeface.loadPreinstalledSystemFontMap();
         }

         // Attach JVMTI agent if this is a debuggable build and the system property is set.
         // 若可调试则关联 JVMTI代理。
         if (Build.IS_DEBUGGABLE) {
             ...
         }
     } finally {
         t.traceEnd();  // InitBeforeStartServices
     }

     // Setup the default WTF handler
     // what the fack??, 好像是为了处理系统早期启动中的错误，
     RuntimeInit.setDefaultApplicationWtfHandler(SystemServer::handleEarlySystemWtf);

     // Start services.
     try {
         t.traceBegin("StartServices");
         // 引导服务
         startBootstrapServices(t);
         // 核心服务
         startCoreServices(t);
         // 其他服务
         startOtherServices(t);
         // 顶级服务
         startApexServices(t);
     } catch (Throwable ex) {
         Slog.e("System", "******************************************");
         Slog.e("System", "************ Failure starting system services", ex);
         throw ex;
     } finally {
         t.traceEnd(); // StartServices
     }
	
     StrictMode.initVmDefaults(null);

     if (!mRuntimeRestart && !isFirstBootOrUpgrade()) {
         final long uptimeMillis = SystemClock.elapsedRealtime();
         FrameworkStatsLog.write(FrameworkStatsLog.BOOT_TIME_EVENT_ELAPSED_TIME_REPORTED,
                                 FrameworkStatsLog.BOOT_TIME_EVENT_ELAPSED_TIME__EVENT__SYSTEM_SERVER_READY,
                                 uptimeMillis);
         final long maxUptimeMillis = 60 * 1000;
         if (uptimeMillis > maxUptimeMillis) {
             Slog.wtf(SYSTEM_SERVER_TIMING_TAG,
                      "SystemServer init took too long. uptimeMillis=" + uptimeMillis);
         }
     }
	
     // 启动Loop 循环
     // Loop forever.
     Looper.loop();
     throw new RuntimeException("Main thread loop unexpectedly exited");
 }
```

#### createSystemContext()

调用了`ActivityThread.systemMain()`， 它是供系统进程执行的main函数。内部创建了ActivityThread并调了 `attach()`。

```java
private void createSystemContext() {
    // 调用了ActivityThread.systemMain()， 它是供系统进程执行的main函数
    // 内部创建了ActivityThread并调了 attach()。
    ActivityThread activityThread = ActivityThread.systemMain();
    mSystemContext = activityThread.getSystemContext();
    mSystemContext.setTheme(DEFAULT_SYSTEM_THEME);
	// getSystemUiContext
    final Context systemUiContext = activityThread.getSystemUiContext();
    systemUiContext.setTheme(DEFAULT_SYSTEM_THEME);
}
```

#### startBootstrapServices()

启动最小规模的关键服务，它们是系统启动必须的，且相互之间存在复杂的相互依赖关系。这些服务都继承自 `SystemServer`类。

使用 SystemServiceManager 来管理这些服务的创建、启动等生命周期事件。

这里面包括了熟悉的 **ActivityManagerService**、**PackageMangerService**等等很多系统服务。

> 并不是所有的服务都是里面启动，有些是先创建服务，然后等其他一些服务先启动，到达一定的启动阶段后才会真正完全启动。例如 AMS是这里创建的，但是在 `startOtherServices()` 里面调用 `systemReady()`启动的。

> [SystemServer.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/java/com/android/server/SystemServer.java;drc=a889f4c71d5105ec590b2ef74b04c0e72d03d258;l=1054)

```java
private void startBootstrapServices(@NonNull TimingsTraceAndSlog t) {
    // 启动watchdog，使死锁的服务崩溃
    final Watchdog watchdog = Watchdog.getInstance();
    watchdog.start();
    
	// 读取 SystemConfig
    Slog.i(TAG, "Reading configuration...");
    final String TAG_SYSTEM_CONFIG = "ReadingSystemConfig";
    SystemServerInitThreadPool.submit(SystemConfig::getInstance, TAG_SYSTEM_CONFIG);

    // Platform compat service is used by ActivityManagerService, PackageManagerService, and
    // possibly others in the future. b/135010838.
    PlatformCompat platformCompat = new PlatformCompat(mSystemContext);
    ServiceManager.addService(Context.PLATFORM_COMPAT_SERVICE, platformCompat);
    ServiceManager.addService(Context.PLATFORM_COMPAT_NATIVE_SERVICE,
                              new PlatformCompatNative(platformCompat));

    // 启动 FileIntegrityService 服务，提供文件完整性相关服务，需要在apps启动之前运行。
    mSystemServiceManager.startService(FileIntegrityService.class);
    
    // 启动 Installer服务，等待installed完成启动后，创建关键目录，如/data/user
    // AMS会使用到它，所有需要在AMS之前启动。
    Installer installer = mSystemServiceManager.startService(Installer.class);
    
    // 启动 DeviceIdentifiersPolicyService，提供访问设备标识符的功能。
    mSystemServiceManager.startService(DeviceIdentifiersPolicyService.class);
    
    // Uri Grants Manager.
    mSystemServiceManager.startService(UriGrantsManagerService.Lifecycle.class);
    // 启动 PowerStatsService，用于跟踪电量
    mSystemServiceManager.startService(PowerStatsService.class);
    //
    startIStatsService();

    // Start MemtrackProxyService before ActivityManager, so that early calls
    // to Memtrack::getMemory() don't fail.
    startMemtrackProxyService();
	
    // Activity manager runs the show.
    // 启动 ATMS，android 10之后由 ATMS来管理Activity
    ActivityTaskManagerService atm = mSystemServiceManager.startService(
        ActivityTaskManagerService.Lifecycle.class).getService();
    // 启动 AMS, 管理四大组件中的其他三个. service broadcast contentprovider
    // AMS 持有了 ATMS
    mActivityManagerService = ActivityManagerService.Lifecycle.startService(
        mSystemServiceManager, atm);
    // setSystemServiceManager
    mActivityManagerService.setSystemServiceManager(mSystemServiceManager);
    // setInstaller
    mActivityManagerService.setInstaller(installer);
    mWindowManagerGlobalLock = atm.getGlobalLock();
    
    // Data loader manager service needs to be started before package manager
    mDataLoaderManagerService = mSystemServiceManager.startService(
        DataLoaderManagerService.class);
    // Incremental service needs to be started before package manager
    mIncrementalServiceHandle = startIncrementalService();

    // 启动 PowerManagerService，负责电源相关管理
    mPowerManagerService = mSystemServiceManager.startService(PowerManagerService.class);

    // 启动 ThermalManagerService, 它会监听硬件的热量事件，然后分发这些事件
    mSystemServiceManager.startService(ThermalManagerService.class);
	// 启动 HintManagerService
    mSystemServiceManager.startService(HintManagerService.class);

    // power manager启动后，由AMS来初始化它的功能
    mActivityManagerService.initPowerManagement();

    // 启动RecoverySystemService，和 Recovery重置相关
    mSystemServiceManager.startService(RecoverySystemService.Lifecycle.class);
	
    // Now that we have the bare essentials of the OS up and running, take
    // note that we just booted, which might send out a rescue party if
    // we're stuck in a runtime restart loop.
    // 监听 packages 健康状态，看看是不是存在 启动循环。
    RescueParty.registerHealthObserver(mSystemContext);
    PackageWatchdog.getInstance(mSystemContext).noteBoot();

    // Manages LEDs and display backlight so we need it to bring up the display.
    // 启动LightsService。灯光相关 
    mSystemServiceManager.startService(LightsService.class);
    // Package manager isn't started yet; need to use SysProp not hardware feature
    if (SystemProperties.getBoolean("config.enable_display_offload", false)) {
        mSystemServiceManager.startService(WEAR_DISPLAYOFFLOAD_SERVICE_CLASS);
    }
    // Package manager isn't started yet; need to use SysProp not hardware feature
    if (SystemProperties.getBoolean("config.enable_sidekick_graphics", false)) {
        mSystemServiceManager.startService(WEAR_SIDEKICK_SERVICE_CLASS);
    }

    // Display manager is needed to provide display metrics before package manager
    // starts up.
    // 启动DisplayManagerService，管理显示器相关
    mDisplayManagerService = mSystemServiceManager.startService(DisplayManagerService.class);
    // WaitForDisplay
    mSystemServiceManager.startBootPhase(t, SystemService.PHASE_WAIT_FOR_DEFAULT_DISPLAY);

    // Only run "core" apps if we're encrypting the device.
    String cryptState = VoldProperties.decrypt().orElse("");
    if (ENCRYPTING_STATE.equals(cryptState)) {
        Slog.w(TAG, "Detected encryption in progress - only parsing core apps");
        mOnlyCore = true;
    } else if (ENCRYPTED_STATE.equals(cryptState)) {
        Slog.w(TAG, "Device encrypted - only parsing core apps");
        mOnlyCore = true;
    }

    // 启动DomainVerificationService，服务域名验证
    DomainVerificationService domainVerificationService = new DomainVerificationService(
        mSystemContext, SystemConfig.getInstance(), platformCompat);
    mSystemServiceManager.startService(domainVerificationService);
	

    IPackageManager iPackageManager;
    try {
        // 通知watchdog暂停监视此线程，
        Watchdog.getInstance().pauseWatchingCurrentThread("packagemanagermain");
        // 内部创建了PackageManagerService，并注册到了 ServiceManager中。
        Pair<PackageManagerService, IPackageManager> pmsPair = PackageManagerService.main(
            mSystemContext, installer, domainVerificationService,
            mFactoryTestMode != FactoryTest.FACTORY_TEST_OFF, mOnlyCore);
        mPackageManagerService = pmsPair.first;
        iPackageManager = pmsPair.second;
    } finally {
        Watchdog.getInstance().resumeWatchingCurrentThread("packagemanagermain");
    }

    // 捕获所有 system server加载的dex文件，由BackgroundDexOptService来优化 dex
    SystemServerDexLoadReporter.configureSystemServerDexReporter(iPackageManager);

    mFirstBoot = mPackageManagerService.isFirstBoot();
    mPackageManager = mSystemContext.getPackageManager();
   
    //启动 UserManagerService，用户管理相关，例如多用户的创建、删除等
    mSystemServiceManager.startService(UserManagerService.LifeCycle.class);

    // Initialize attribute cache used to cache resources from packages.
    t.traceBegin("InitAttributerCache");
    AttributeCache.init(mSystemContext);
    t.traceEnd();

    // 设置应用程序实例，并启动。
    // 这个应用程序就是"android"
    mActivityManagerService.setSystemProcess();

    // The package receiver depends on the activity service in order to get registered.
    platformCompat.registerPackageReceiver(mSystemContext);

    // 通过mActivityManagerService完成watchdog的设置，并监听Intent.ACTION_REBOOT事件
    watchdog.init(mSystemContext, mActivityManagerService);
    // DisplayManagerService needs to setup android.display scheduling related policies
    // since setSystemProcess() would have overridden policies due to setProcessGroup
    mDisplayManagerService.setupSchedulerPolicies();

    // Manages Overlay packages
    mSystemServiceManager.startService(new OverlayManagerService(mSystemContext));
    // Manages Resources packages
    // 启动 ResourcesManagerService，管理package中的资源。
    ResourcesManagerService resourcesService = new ResourcesManagerService(mSystemContext);
    resourcesService.setActivityManagerService(mActivityManagerService);
    mSystemServiceManager.startService(resourcesService);
    // 启动 SensorPrivacyService 传感器隐私服务相关，例如提示什么应用正在使用传感器
    mSystemServiceManager.startService(new SensorPrivacyService(mSystemContext));
    // 启动 SensorService 传感器功能相关
    mSystemServiceManager.startService(SensorService.class);
}

```

#### startCoreServices()

启动核心服务，相比引导服务少了好多。

> [SystemServer.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/java/com/android/server/SystemServer.java;drc=a889f4c71d5105ec590b2ef74b04c0e72d03d258;l=1338)

```java
private void startCoreServices(@NonNull TimingsTraceAndSlog t) {
    // SystemConfigService， 系统配置
    mSystemServiceManager.startService(SystemConfigService.class);
    // BatteryService，电量相关
    mSystemServiceManager.startService(BatteryService.class);

    // UsageStatsService 应用使用情况的统计
    mSystemServiceManager.startService(UsageStatsService.class);
    mActivityManagerService.setUsageStatsManager(
        LocalServices.getService(UsageStatsManagerInternal.class));

    // Tracks whether the updatable WebView is in a ready state and watches for update installs.
    if (mPackageManager.hasSystemFeature(PackageManager.FEATURE_WEBVIEW)) {
        // WebViewUpdateService，webview的更新
        mWebViewUpdateService = mSystemServiceManager.startService(WebViewUpdateService.class);
    }

    // CachedDeviceStateService，跟踪并缓存设备状态
    mSystemServiceManager.startService(CachedDeviceStateService.class);

    // BinderCallsStatsService, 跟踪 binder调用消耗的cpu时间
    mSystemServiceManager.startService(BinderCallsStatsService.LifeCycle.class);

    // LooperStatsService, 跟踪 handlers中处理消息的耗时
    mSystemServiceManager.startService(LooperStatsService.Lifecycle.class);

    // RollbackManagerService，管理应用回滚
    mSystemServiceManager.startService(ROLLBACK_MANAGER_SERVICE_CLASS);

    // Tracks native tombstones.
    // NativeTombstoneManagerService，跟踪并管理native的崩溃
    mSystemServiceManager.startService(NativeTombstoneManagerService.class);

    // Service to capture bugreports.
    mSystemServiceManager.startService(BugreportManagerService.class);

    // Service for GPU and GPU driver.
    mSystemServiceManager.startService(GpuService.class);

    // Handles system process requests for remotely provisioned keys & data.
    mSystemServiceManager.startService(RemoteProvisioningService.class);
}
```

#### startOtherService()

Mmmmmmmm.... 这个函数有1600+行，总之就使启动了一堆，后续一些奇奇怪怪的服务都可以先来这看看。

不过在这里 调用了很多 服务的systemReady()。其中包含了 AMS.systemReady()，表示 AMS准备完毕，后续可以开始启动三方应用。

> [SystemServer.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/java/com/android/server/SystemServer.java;drc=330f520e10293c8bb6e8c198b24be4259b26a822;l=1411)

```java
// 整个函数 line: 1411 ~ 3063
/**
 * Starts a miscellaneous grab bag of stuff that has yet to be refactored and organized.
 */
private void startCoreServices(@NonNull TimingsTraceAndSlog t) {
    ...
    //    
    // StartAlarmManagerService：Alarm相关
    mSystemServiceManager.startService(ALARM_MANAGER_SERVICE_CLASS);

    // StartInputManagerService：输入设备相关
    inputManager = new InputManagerService(context);
    // DeviceStateManagerService 管理用户可配置的设备的状态。例如折叠手机，可以被用户改变成不同的设备状态。
    mSystemServiceManager.startService(DeviceStateManagerService.class);
    // CameraServiceProxy 相机
    mSystemServiceManager.startService(CameraServiceProxy.class);
    // PHASE_WAIT_FOR_SENSOR_SERVICE
    mSystemServiceManager.startBootPhase(t, SystemService.PHASE_WAIT_FOR_SENSOR_SERVICE);
    // WindowManagerService
    wm = WindowManagerService.main(context, inputManager, !mFirstBoot, mOnlyCore,
                                   new PhoneWindowManager(), mActivityManagerService.mActivityTaskManager);
    // 将 WindowManagerService 注册到ServiceManager
    ServiceManager.addService(Context.WINDOW_SERVICE, wm, /* allowIsolated= */ false,
                              DUMP_FLAG_PRIORITY_CRITICAL | DUMP_FLAG_PROTO);
    // 将 InputManagerService 注册到ServiceManager
    ServiceManager.addService(Context.INPUT_SERVICE, inputManager,
                              /* allowIsolated= */ false, DUMP_FLAG_PRIORITY_CRITICAL);
    mActivityManagerService.setWindowManager(wm);
    wm.onInitReady();
	...
    inputManager.setWindowManagerCallbacks(wm.getInputManagerCallback());
    inputManager.start();
	...
    // BluetoothService 蓝牙服务
	mSystemServiceManager.startServiceFromJar(BLUETOOTH_SERVICE_CLASS,BLUETOOTH_APEX_SERVICE_JAR_PATH);
    // LogcatManagerService logcat
    mSystemServiceManager.startService(LogcatManagerService.class);
    // InputMethodManagerService, 输入法
    mSystemServiceManager.startService(InputMethodManagerService.Lifecycle.class);
    // AccessibilityManagerService$Lifecycle, 无障碍 
    mSystemServiceManager.startService(ACCESSIBILITY_MANAGER_SERVICE_CLASS);
	...
    // MakeDisplayReady
    wm.displayReady();
    // StorageManagerService$Lifecycle 存储管理
    mSystemServiceManager.startService(STORAGE_MANAGER_SERVICE_CLASS);

    // 下面的一些配置会根据手表或电视 进行相应的跳转
    ...
    // Always start the Device Policy Manager, so that the API is compatible with
    // API8.
    // DevicePolicyManagerService 设备管理器相关
    dpms = mSystemServiceManager.startService(DevicePolicyManagerService.Lifecycle.class);
    if (!isWatch) {// 非手表
       // StatusBarManagerService 状态栏管理
       statusBar = new StatusBarManagerService(context);
       ServiceManager.addService(Context.STATUS_BAR_SERVICE, statusBar);
    }
	...
	// NetworkManagementService 网络 
    networkManagement = NetworkManagementService.create(context);
    ServiceManager.addService(Context.NETWORKMANAGEMENT_SERVICE, networkManagement);
    // 还有wifi、vpn等
    ...
	// FontManagerService 字体
    mSystemServiceManager.startService(new FontManagerService.Lifecycle(context, safeMode));
	...
	// SystemUpdateManagerService 系统更新
    ServiceManager.addService(Context.SYSTEM_UPDATE_SERVICE, new SystemUpdateManagerService(context));
    // 通知
    mSystemServiceManager.startService(NotificationManagerService.class);
    ...
    // 定位
    mSystemServiceManager.startService(LocationManagerService.Lifecycle.class);
    ...
    // 壁纸
    mSystemServiceManager.startService(WALLPAPER_SERVICE_CLASS);
    // 音频
    mSystemServiceManager.startService(AudioService.Lifecycle.class);
    // adb
    mSystemServiceManager.startService(ADB_SERVICE_CLASS);
    // job scheduler
    mSystemServiceManager.startService(JOB_SCHEDULER_SERVICE_CLASS);
    //appwidget
    mSystemServiceManager.startService(APPWIDGET_SERVICE_CLASS);
    // add runtime
    ServiceManager.addService("runtime", new RuntimeService(context));
    ...
    // 面部识别
    final FaceService faceService =mSystemServiceManager.startService(FaceService.class);
    // 剪贴板
    mSystemServiceManager.startService(ClipboardService.class);
  	// PHASE_LOCK_SETTINGS_READY PHASE_SYSTEM_SERVICES_READY
    mSystemServiceManager.startBootPhase(t, SystemService.PHASE_LOCK_SETTINGS_READY);
    mSystemServiceManager.startBootPhase(t, SystemService.PHASE_SYSTEM_SERVICES_READY);
    // 准备就绪可以启动 windowManager
    wm.systemReady();
    // 权限
    mSystemServiceManager.startService(PermissionPolicyService.class);
    // 准备就绪可以启动 PackageManager、DisplayManager
    mPackageManagerService.systemReady();
    mDisplayManagerService.systemReady(safeMode, mOnlyCore);
    // PHASE_DEVICE_SPECIFIC_SERVICES_READY
    mSystemServiceManager.startBootPhase(t, SystemService.PHASE_DEVICE_SPECIFIC_SERVICES_READY);
    
    //  ams.ready()
    mActivityManagerService.systemReady(() -> {
        // PHASE_ACTIVITY_MANAGER_READY
        mSystemServiceManager.startBootPhase(t, SystemService.PHASE_ACTIVITY_MANAGER_READY);
        // native crash 监控
        mActivityManagerService.startObservingNativeCrashes();
        // 准备webview
        final String WEBVIEW_PREPARATION = "WebViewFactoryPreparation";
        Future<?> webviewPrep = null;
        if (!mOnlyCore && mWebViewUpdateService != null) {
            webviewPrep = SystemServerInitThreadPool.submit(() -> {
				...
                //
                mWebViewUpdateService.prepareWebViewInSystemServer();
            }, WEBVIEW_PREPARATION);
        }
		//
        networkManagementF.systemReady()
        // 
        // Wait for all packages to be prepared
        mPackageManagerService.waitForAppDataPrepared();
		// PHASE_THIRD_PARTY_APPS_CAN_START, 三方应用可以启动
        mSystemServiceManager.startBootPhase(t, SystemService.PHASE_THIRD_PARTY_APPS_CAN_START);
        networkTimeUpdaterF.systemRunning();
        inputManagerF.systemRunning();
        ...
    }, t);

	// 启动 SystemUi
   	startSystemUi(context, windowManagerF);
}

```

#### startApexServices()

从 "android" package 中获取清单列表。来启动对应服务。

> [SystemServer.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/java/com/android/server/SystemServer.java;drc=330f520e10293c8bb6e8c198b24be4259b26a822;l=3072)

```java
private void startApexServices(@NonNull TimingsTraceAndSlog t) {
    t.traceBegin("startApexServices");
    // TODO(b/192880996): get the list from "android" package, once the manifest entries
    // are migrated to system manifest.
    // 从 "android" package 中获取清单列表。
    List<ApexSystemServiceInfo> services = ApexManager.getInstance().getApexSystemServices();
    for (ApexSystemServiceInfo info : services) {
        String name = info.getName();
        String jarPath = info.getJarPath();
        t.traceBegin("starting " + name);
        if (TextUtils.isEmpty(jarPath)) {
            mSystemServiceManager.startService(name);
        } else {
            mSystemServiceManager.startServiceFromJar(name, jarPath);
        }
        t.traceEnd();
    }
    // make sure no other services are started after this point
    mSystemServiceManager.sealStartedServices();
}
```

#### 启动阶段汇总

`startBootPhase()` 函数 就是来标记当前启动阶段的。会前面已启动服务回调 `onBootPhase()` 。我将上面涉及到的各个阶段汇总一下：

> [SystemService.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/SystemService.java;l=77;)

| PHASE                                | value | 说明                                                         | 调用处                   |
| ------------------------------------ | ----- | ------------------------------------------------------------ | ------------------------ |
| PHASE_WAIT_FOR_DEFAULT_DISPLAY       | 100   | 创建了PackageManagerService、UserManagerService、ResourcesManagerService、SensorService、等服务 | startBootstrapServices() |
| PHASE_WAIT_FOR_SENSOR_SERVICE        | 200   | 创建了WindowManagerService、InputManagerService、LogcatManagerService、NetworkManagementService等服务 | startOtherService()      |
| PHASE_LOCK_SETTINGS_READY            | 480   | 调用完后，就之间调用 PHASE_SYSTEM_SERVICES_READY了           | startOtherService()      |
| PHASE_SYSTEM_SERVICES_READY          | 500   | 除了创建服务之外还调用了很多服务的systemReady() 方法。例如WM.systemReady()、PackageManager.Ready()等等。 | startOtherService()      |
| PHASE_DEVICE_SPECIFIC_SERVICES_READY | 520   | 除了创建服务之外还调用了 AMS.systemReady()。                 | startOtherService()      |
| PHASE_ACTIVITY_MANAGER_READY         | 550   | 此时AMS准备完毕。后续监听了native crash，准备了webview等等。 | startOtherService()      |
| PHASE_THIRD_PARTY_APPS_CAN_START     | 600   | 调用了很多 systemRunning()函数。例如inputManagerF.systemRunning() 等。还包括启动systemUI。 |                          |
| PHASE_BOOT_COMPLETED                 | 1000  |                                                              | AMS.finishBooting()      |

---

### ActivityThread

#### systemMain()

> [ActivityThread.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/app/ActivityThread.java;drc=a889f4c71d5105ec590b2ef74b04c0e72d03d258;l=7651)

```java
public static ActivityThread systemMain() {
    ThreadedRenderer.initForSystemProcess();
    ActivityThread thread = new ActivityThread();
    // attach
    thread.attach(true, 0);
    return thread;
}
```

#### attach()

```java
// system = true
private void attach(boolean system, long startSeq) {
    sCurrentActivityThread = this;
    mConfigurationController = new ConfigurationController(this);
    mSystemThread = system;
    if (!system) {
        ...
    } else {
        // Don't set application object here -- if the system crashes,
        // we can't display an alert, we just want to die die die.
        android.ddm.DdmHandleAppName.setAppName("system_process",
                                                UserHandle.myUserId());
        try {
            // 创建 Instrumentation
            mInstrumentation = new Instrumentation();
            mInstrumentation.basicInit(this);
            // 创建 app context
            ContextImpl context = ContextImpl.createAppContext(
                this, getSystemContext().mPackageInfo);
            mInitialApplication = context.mPackageInfo.makeApplicationInner(true, null);
            // 调用 application onCreate()
            mInitialApplication.onCreate();
        } catch (Exception e) {
            throw new RuntimeException(
                "Unable to instantiate Application():" + e.toString(), e);
        }
    }

    ViewRootImpl.ConfigChangedCallback configChangedCallback = (Configuration globalConfig) -> {
        synchronized (mResourcesManager) {
            // We need to apply this change to the resources immediately, because upon returning
            // the view hierarchy will be informed about it.
            if (mResourcesManager.applyConfigurationToResources(globalConfig,
                                                                null /* compat */)) {
                mConfigurationController.updateLocaleListFromAppContext(
                    mInitialApplication.getApplicationContext());

                // This actually changed the resources! Tell everyone about it.
                final Configuration updatedConfig =
                    mConfigurationController.updatePendingConfiguration(globalConfig);
                if (updatedConfig != null) {
                    sendMessage(H.CONFIGURATION_CHANGED, globalConfig);
                    mPendingConfiguration = updatedConfig;
                }
            }
        }
    };
    ViewRootImpl.addConfigCallback(configChangedCallback);
}
```



## App 进程

关于应用进程孵化的详细流程，我会在 [Android 应用启动流程](./Android应用启动流程.md) 一文中来梳理。

* ATMS 向zygote 发起socket连接请求，之后两者建立连接。
* ATMS 向zygote发送应用启动指令，zygote接收并解析指令。SystemServer 是硬编码的指令参数，而应用启动则是从socket中获取指令参数。
* zygote 孵化应用进程。
  * 父进程：将子进程 Pid写入socket，会被ATMS读取。
  * 子进程：将参数传给`ZygoteInit.zygoteInit()` 函数来初始化应用程序、创建Binder线程池，并返回 `ActivityThread.main()`函数。

* 在子进程中启动对应程序。

![zygote孵化应用进程](./Android%E7%B3%BB%E7%BB%9F%E5%90%AF%E5%8A%A8%E6%B5%81%E7%A8%8B.assets/zygote%E5%AD%B5%E5%8C%96%E5%BA%94%E7%94%A8%E8%BF%9B%E7%A8%8B.jpg)

---

## ServiceManager

ServiceManager 提供了**Service注册**和**Service检索**功能。它主要和Binder有关，所以具体的分析放到了 [Android之Binder机制](./Android之Binder机制.md) 这一篇中。简单看一下它的配置。

> [servicemanager.rc - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/native/cmds/servicemanager/servicemanager.rc)

* 服务名：`servicemanager`
* 可执行文件：`/system/bin/servicemanager`

```shell
service servicemanager /system/bin/servicemanager
    class core animation
    user system
    group system readproc
    critical
    file /dev/kmsg w
    onrestart setprop servicemanager.ready false
    onrestart restart --only-if-running apexd
    onrestart restart audioserver
    onrestart restart gatekeeperd
    onrestart class_restart --only-enabled main
    onrestart class_restart --only-enabled hal
    onrestart class_restart --only-enabled early_hal
    task_profiles ServiceCapacityLow
    shutdown critical
```

