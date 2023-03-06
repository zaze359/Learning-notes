# 	Android系统启动流程

## 流程概览

![img](./Android%E7%B3%BB%E7%BB%9F%E5%90%AF%E5%8A%A8%E6%B5%81%E7%A8%8B.assets/image_1cegf6i1jmjmtdbqisgik1mu89.png)


1. **设备供电，执行bootloader**：主要负责初始化软件运行的最小硬件环境
2. **加载内核(Linux kernel)到内存中**：bootloader 最后会将Linux kernel加载到内存中。
3. **启动用户空间的init进程**：内核加载进内存后，首先进入内核引导界面(主要是汇编)，在引导阶段最后，调用`start_kernel`进入内核启动阶段，最终会启动第一个用户空间进程-`init进程`。
4. **启动zygote和ServiceManager等进程**： `init`程序负责解析`init.rc`配置文件执行Action和Service,开启系统守护进程。其中最重要的是`zygote`和`ServiceManager`。
   * **zygote**：是Android启动的第一个Dalvik虚拟机(4.4以上应该是ART吧)，它**负责启动java世界的进程**。
   * **ServiceManager**：是Binder通信的基础，负责管理所有的Binder服务，提供了**Service注册**和**Service检索**功能。
5. **启动system_server**：的zygote fork了 `system_server`进程，同时**定义了一个Socket用于接收AMS启动应用的请求**。
6. **启动系统进程**：在system_server进程的`init1 ` 和 `init2`启动了系统进程。
   * **init1启动 Native System Service**。
   * **init2启动 Java System Service**
7. 系统服务启动后会自身注册到ServiceManager中，用于Binder通信。
8. ActivityManagerService进入systemReady状态。
9. 在systemReady状态下，ActivityManagerService与zygote中的Socket通信，请求启动Home。
10. zygote收到请求，执行runSelectLoopMode处理请求。
11. zygote处理请求会通过forkAndSpecialize启动新的应用进程，最终启动了Home。

 

## bootloader

> 主要负责初始化软件运行的最小硬件环境，加载内核到内存中。



## init进程

内核启动完成后会启动 init进程，它是**第一个用户空间进程**(`pid = 1`)。

主要职责包括: 创建系统中的几个关键进程（zygote等）。提供属性服务(property service) 来管理Android系统的属性。

* **main**：init程序的执行入口
* **FirstStageMain**：首先被调用的函数，主要负责创建一些目录 以及 挂载一些必要的设备，并触发
* **SetupSelinux**：负责安装 selinux安全策略，并触发SecondStageMain。
* **SecondStageMain**：主要负责初始化属性服务并启动、解析 init.rc文件并启动相关的进程。其中包括了**启动zygote进程**。

![image-20230306164147139](./Android%E7%B3%BB%E7%BB%9F%E5%90%AF%E5%8A%A8%E6%B5%81%E7%A8%8B.assets/image-20230306164147139.png)

### main()

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

主要负责创建一些目录 以及 挂载一些必要的设备。最终会调用 `execv(path, const_cast<char**>(args));` ，此处重新调用了init程序, 并传入参数`selinux_setup`。从而触发 `SetupSelinux()`

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
- **按照一定的顺序执行Action**：包括创建zygote。
- **init进入一个无限循环**： 默认休眠直到一些事情的发生。

```cpp
int SecondStageMain(int argc, char** argv) {
    ...
	// 当设备解锁且允许debug时开启 adb root
    // See if need to load debug props to allow adb root, when the device is unlocked.
    const char* force_debuggable_env = getenv("INIT_FORCE_DEBUGGABLE");
    bool load_debug_prop = false;
    if (force_debuggable_env && AvbHandle::IsDeviceUnlocked()) {
        load_debug_prop = "true"s == force_debuggable_env;
    }
    unsetenv("INIT_FORCE_DEBUGGABLE");
    // Umount the debug ramdisk so property service doesn't read .prop files from there, when it
    // is not meant to.
    if (!load_debug_prop) {
        UmountDebugRamdisk();
    }
    
    // 从指定文件中读取属性并初始化，可以通过 getprop 查看。例如 ro.boot.platform 等。
    PropertyInit();
	
    // Umount second stage resources after property service has read the .prop files.
    // 读取完后卸载
    UmountSecondStageRes();
	
    // 挂载 第二阶段使用的文件系统
    // Mount extra filesystems required during second stage init
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
    // Make the time that init stages started available for bootstat to log.
    RecordStageBoottimes(start_time);
	....
	// 获取 command和fuction的映射表，后续ExecuteOneCommand时会使用。
    const BuiltinFunctionMap& function_map = GetBuiltinFunctionMap();
    Action::set_function_map(&function_map);
        
    ...
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

    // Queue an action that waits for coldboot done so we know ueventd has set up all of /dev...
    am.QueueBuiltinAction(wait_for_coldboot_done_action, "wait_for_coldboot_done");
    // ... so that we can start queuing up actions that require stuff from /dev.
    am.QueueBuiltinAction(SetMmapRndBitsAction, "SetMmapRndBits");
    
    // 初始化/dev/keychord设备, 这与调试有关
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
    am.QueueBuiltinAction(queue_property_triggers_action, "queue_property_triggers");

    // Restore prio before main loop
    setpriority(PRIO_PROCESS, 0, 0);
    // 开启无限循环
    while (true) {
        // By default, sleep until something happens.
        std::optional<std::chrono::milliseconds> epoll_timeout;

        auto shutdown_command = shutdown_state.CheckShutdown();
        if (shutdown_command) {
            LOG(INFO) << "Got shutdown_command '" << *shutdown_command
                      << "' Calling HandlePowerctlMessage()";
            HandlePowerctlMessage(*shutdown_command);
            shutdown_state.set_do_shutdown(false);
        }

        if (!(prop_waiter_state.MightBeWaiting() || Service::is_exec_service_running())) {
            // 一条一条执行action
            am.ExecuteOneCommand();
        }
        if (!IsShuttingDown()) {
            auto next_process_action_time = HandleProcessActions();

            // If there's a process that needs restarting, wake up in time for that.
            // 重启一些需要重启的进程
            if (next_process_action_time) {
                epoll_timeout = std::chrono::ceil<std::chrono::milliseconds>(
                        *next_process_action_time - boot_clock::now());
                if (epoll_timeout < 0ms) epoll_timeout = 0ms;
            }
        }

        if (!(prop_waiter_state.MightBeWaiting() || Service::is_exec_service_running())) {
            // If there's more work to do, wake up again immediately.
            if (am.HasMoreCommands()) epoll_timeout = 0ms;
        }
		// 等待
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

> Note：关于init.rc文件的语法和具体解析流程可以参考 [Android之init.rc配置文件](./Android之init_rc配置文件.md)一文。

* 加载init.rc，解析内部的Action和Service。
* 首先会尝试通过``GetProperty("ro.boot.init_rc", "")``获取配置
* 若不存在则使用默认的几个配置文件。
* 最终都是调用``parser.ParseConfig()``函数进行解析。

> [init.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:system/core/init/init.cpp;drc=5ca657189aac546af0aafaba11bbc9c5d889eab3;l=364)

```cpp
static void LoadBootScripts(ActionManager& action_manager, ServiceList& service_list) {
    // 解析Service
    Parser parser = CreateParser(action_manager, service_list);
	// 优先从 ro.boot.init_rc 中获取init.rc的路径
    std::string bootscript = GetProperty("ro.boot.init_rc", "");
    if (bootscript.empty()) {
        // 没有则使用默认的init.rc文件
        parser.ParseConfig("/system/etc/init/hw/init.rc");
        if (!parser.ParseConfig("/system/etc/init")) {
            late_import_paths.emplace_back("/system/etc/init");
        }
        // late_import is available only in Q and earlier release. As we don't
        // have system_ext in those versions, skip late_import for system_ext.
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

Parser CreateParser(ActionManager& action_manager, ServiceList& service_list) {
    Parser parser;
    // 解析service
    parser.AddSectionParser("service", std::make_unique<ServiceParser>(
                                               &service_list, GetSubcontext(), std::nullopt));
    // 解析action
    parser.AddSectionParser("on", std::make_unique<ActionParser>(&action_manager, GetSubcontext()));
    // 解析 improt
    parser.AddSectionParser("import", std::make_unique<ImportParser>(&parser));
    return parser;
}
```

我们来简单的看一下 init.rc文件：

* 导入了 zygote相关的rc配置文件。
* 在 init 阶段 启动了一些重要的服务。例如 `servicemanager`。
* 在 late-init 阶段中 触发了zygote-start, 这个Action内部启动了 `zygote` 。

```shell
import /init.environ.rc
import /system/etc/init/hw/init.usb.rc
import /init.${ro.hardware}.rc
import /vendor/etc/init/hw/init.${ro.hardware}.rc
import /system/etc/init/hw/init.usb.configfs.rc
# 导入Zygote相关的配置
import /system/etc/init/hw/init.${ro.zygote}.rc

on init
    # Mount binderfs
    mkdir /dev/binderfs
    mount binder binder /dev/binderfs stats=global
    chmod 0755 /dev/binderfs
	....
	
    # Start essential services.
    # 这里启动了 servicemanager
    start servicemanager
    start hwservicemanager
    start vndservicemanager

.....
on late-init
    trigger early-fs
    ....
    # Now we can start zygote for devices with file based encryption
    # 触发 zygote-start,内部启动了zygote
    trigger zygote-start
	...
	
    trigger early-boot
    trigger boot

on zygote-start && property:ro.crypto.state=unencrypted
    wait_for_prop odsign.verification.done 1
    # A/B update verifier that marks a successful boot.
    exec_start update_verifier_nonencrypted
    start statsd
    start netd
    # 启动 zygote进程
    start zygote
    # 启动 zygote_secondary
    start zygote_secondary
.....
```



### 启动service

[builtins.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:system/core/init/builtins.cpp;l=171;drc=61ca3f250160739af64126139661392dd4cb4af9;bpv=1;bpt=1)

```C++
static Result<void> do_class_start(const BuiltinArguments& args) {
    // Do not start a class if it has a property persist.dont_start_class.CLASS set to 1.
    if (android::base::GetBoolProperty("persist.init.dont_start_class." + args[1], false))
        return {};
    // Starting a class does not start services which are explicitly disabled.
    // They must  be started individually.
    for (const auto& service : ServiceList::GetInstance()) {
      	// 找到对应的service
        if (service->classnames().count(args[1])) {
            // 启动服务
            if (auto result = service->StartIfNotDisabled(); !result.ok()) {
                LOG(ERROR) << "Could not start service '" << service->name()
                           << "' as part of class '" << args[1] << "': " << result.error();
            }
        }
    }
    return {};
}
```

[service.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:system/core/init/service.cpp;bpv=0;bpt=1)

```C++
Result<void> Service::StartIfNotDisabled() {
    if (!(flags_ & SVC_DISABLED)) {
      	// 当前服务不可用则启动
        return Start();
    } else {
        flags_ |= SVC_DISABLED_START;
    }
    return {};
}
```

```c++
Result<void> Service::Start() {
    auto reboot_on_failure = make_scope_guard([this] {
        if (on_failure_reboot_target_) {
            trigger_shutdown(*on_failure_reboot_target_);
        }
    });

    if (is_updatable() && !ServiceList::GetInstance().IsServicesUpdated()) {
        ServiceList::GetInstance().DelayService(*this);
        return Error() << "Cannot start an updatable service '" << name_
                       << "' before configs from APEXes are all loaded. "
                       << "Queued for execution.";
    }

    bool disabled = (flags_ & (SVC_DISABLED | SVC_RESET));
    ResetFlagsForStart();

    // Running processes require no additional work --- if they're in the
    // process of exiting, we've ensured that they will immediately restart
    // on exit, unless they are ONESHOT. For ONESHOT service, if it's in
    // stopping status, we just set SVC_RESTART flag so it will get restarted
    // in Reap().
    if (flags_ & SVC_RUNNING) {
        if ((flags_ & SVC_ONESHOT) && disabled) {
            flags_ |= SVC_RESTART;
        }

        LOG(INFO) << "service '" << name_
                  << "' requested start, but it is already running (flags: " << flags_ << ")";

        // It is not an error to try to start a service that is already running.
        reboot_on_failure.Disable();
        return {};
    }

    std::unique_ptr<std::array<int, 2>, decltype(&ClosePipe)> pipefd(new std::array<int, 2>{-1, -1},
                                                                     ClosePipe);
    if (pipe(pipefd->data()) < 0) {
        return ErrnoError() << "pipe()";
    }

    if (Result<void> result = CheckConsole(); !result.ok()) {
        return result;
    }

    struct stat sb;
    if (stat(args_[0].c_str(), &sb) == -1) {
        flags_ |= SVC_DISABLED;
        return ErrnoError() << "Cannot find '" << args_[0] << "'";
    }

    std::string scon;
    if (!seclabel_.empty()) {
        scon = seclabel_;
    } else {
        auto result = ComputeContextFromExecutable(args_[0]);
        if (!result.ok()) {
            return result.error();
        }
        scon = *result;
    }

    // APEXd is always started in the "current" namespace because it is the process to set up
    // the current namespace.
    const bool is_apexd = args_[0] == "/system/bin/apexd";

    if (!IsDefaultMountNamespaceReady() && !is_apexd) {
        // If this service is started before APEXes and corresponding linker configuration
        // get available, mark it as pre-apexd one. Note that this marking is
        // permanent. So for example, if the service is re-launched (e.g., due
        // to crash), it is still recognized as pre-apexd... for consistency.
        use_bootstrap_ns_ = true;
    }

    // For pre-apexd services, override mount namespace as "bootstrap" one before starting.
    // Note: "ueventd" is supposed to be run in "default" mount namespace even if it's pre-apexd
    // to support loading firmwares from APEXes.
    std::optional<MountNamespace> override_mount_namespace;
    if (name_ == "ueventd") {
        override_mount_namespace = NS_DEFAULT;
    } else if (use_bootstrap_ns_) {
        override_mount_namespace = NS_BOOTSTRAP;
    }

    post_data_ = ServiceList::GetInstance().IsPostData();

    LOG(INFO) << "starting service '" << name_ << "'...";

    std::vector<Descriptor> descriptors;
    for (const auto& socket : sockets_) {
        if (auto result = socket.Create(scon); result.ok()) {
            descriptors.emplace_back(std::move(*result));
        } else {
            LOG(INFO) << "Could not create socket '" << socket.name << "': " << result.error();
        }
    }

    for (const auto& file : files_) {
        if (auto result = file.Create(); result.ok()) {
            descriptors.emplace_back(std::move(*result));
        } else {
            LOG(INFO) << "Could not open file '" << file.name << "': " << result.error();
        }
    }

    pid_t pid = -1;
    if (namespaces_.flags) {
        pid = clone(nullptr, nullptr, namespaces_.flags | SIGCHLD, nullptr);
    } else {
      	// 调用fork创建子进程。
        pid = fork();
    }
    // pid = 0表示运行在子进程中。
    if (pid == 0) {
        umask(077);
        // 
        RunService(override_mount_namespace, descriptors, std::move(pipefd));
        _exit(127);
    }

    if (pid < 0) {
        pid_ = 0;
        return ErrnoError() << "Failed to fork";
    }

    if (oom_score_adjust_ != DEFAULT_OOM_SCORE_ADJUST) {
        std::string oom_str = std::to_string(oom_score_adjust_);
        std::string oom_file = StringPrintf("/proc/%d/oom_score_adj", pid);
        if (!WriteStringToFile(oom_str, oom_file)) {
            PLOG(ERROR) << "couldn't write oom_score_adj";
        }
    }

    time_started_ = boot_clock::now();
    pid_ = pid;
    flags_ |= SVC_RUNNING;
    start_order_ = next_start_order_++;
    process_cgroup_empty_ = false;

    bool use_memcg = swappiness_ != -1 || soft_limit_in_bytes_ != -1 || limit_in_bytes_ != -1 ||
                      limit_percent_ != -1 || !limit_property_.empty();
    errno = -createProcessGroup(proc_attr_.uid, pid_, use_memcg);
    if (errno != 0) {
        if (char byte = 0; write((*pipefd)[1], &byte, 1) < 0) {
            return ErrnoError() << "sending notification failed";
        }
        return Error() << "createProcessGroup(" << proc_attr_.uid << ", " << pid_
                       << ") failed for service '" << name_ << "'";
    }

    if (use_memcg) {
        ConfigureMemcg();
    }

    if (oom_score_adjust_ != DEFAULT_OOM_SCORE_ADJUST) {
        LmkdRegister(name_, proc_attr_.uid, pid_, oom_score_adjust_);
    }

    if (char byte = 1; write((*pipefd)[1], &byte, 1) < 0) {
        return ErrnoError() << "sending notification failed";
    }

    NotifyStateChange("running");
    reboot_on_failure.Disable();
    return {};
}

```



## zygote进程

在 `init.rc` 文件中，我看到zygote相关配置是通过 `import /system/etc/init/hw/init.${ro.zygote}.rc `导入的。这里面包含了很多zygote的配置文件，分别对应 32位、64位，不过里面的内容都大同小异。

> Notes：若是查看源码则是在 `/system/core/rootdir/` 目录下可用找到这些配置文件。

![image-20230306144359250](./Android%E7%B3%BB%E7%BB%9F%E5%90%AF%E5%8A%A8%E6%B5%81%E7%A8%8B.assets/image-20230306144359250.png)

目前最新设备一般都使用`init.zygote64_32.rc`，表示内部同时运行了64位和32位两个zygote进程，以64为主，主要是为了同时支持64位和32位（Android5.0才开始支持64位）。

> [init.zygote64_32.rc - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:system/core/rootdir/init.zygote64_32.rc)

```shell
# 导入了64位的配置
import /system/etc/init/hw/init.zygote64.rc

service zygote_secondary /system/bin/app_process32 -Xzygote /system/bin --zygote --socket-name=zygote_secondary --enable-lazy-preload
    class main
    priority -20
    user root
    group root readproc reserved_disk
    socket zygote_secondary stream 660 root system
    socket usap_pool_secondary stream 660 root system
    onrestart restart zygote
    task_profiles ProcessCapacityHigh MaxPerformance
```

> [init.zygote64.rc - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:system/core/rootdir/init.zygote64.rc)

* 服务名： zygote。	
* 程序二进程文件位于：`/system/bin/app_process64`
* 启动参数：`-Xzygote /system/bin --zygote --start-system-server --socket-name=zygote`
  * 

```shell
# 定义一个 zygote 服务。
# 执行
service zygote /system/bin/app_process64 -Xzygote /system/bin --zygote --start-system-server --socket-name=zygote
    class main
    priority -20
    user root
    group root readproc reserved_disk
    socket zygote stream 660 root system
    socket usap_pool_primary stream 660 root system
    onrestart exec_background - system system -- /system/bin/vdc volume abort_fuse
    onrestart write /sys/power/state on
    # NOTE: If the wakelock name here is changed, then also
    # update it in SystemSuspend.cpp
    onrestart write /sys/power/wake_lock zygote_kwl
    onrestart restart audioserver
    onrestart restart cameraserver
    onrestart restart media
    onrestart restart media.tuner
    onrestart restart netd
    onrestart restart wificond
    task_profiles ProcessCapacityHigh MaxPerformance
    critical window=${zygote.critical_window.minute:-off} target=zygote-fatal
```

