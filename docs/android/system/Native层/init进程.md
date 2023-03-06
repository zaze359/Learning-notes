# init进程

> init进程是Linux系统中的第一个进程。
>
> Android基于Linux内核，所以init是android系统中用户空间的第一个进程````。

主要职责：负责创建系统中的几个关键进程（zygote等）。提供property service(属性服务)管理Android系统的属性。

- 解析配置文件(init.rc等)
- 执行各个阶段的动作， 例如创建zygote。
- 调用``property_init()`初始化属性相关的资源,并且通过``StartPropertyService(&epoll)``启动属性服务。
- init进入一个无限循环, 默认休眠直到一些事情的发生。

## init启动流程	

> 参考代码分支: android-12.0.0_r32
>
> main.cpp为init进程的启动入口

[main.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/android-10.0.0_r47:system/core/init/main.cpp)

```c++
int main(int argc, char** argv) {
#if __has_feature(address_sanitizer)
    __asan_set_error_report_callback(AsanReportCallback);
#endif

    if (!strcmp(basename(argv[0]), "ueventd")) {
        return ueventd_main(argc, argv);
    }

    if (argc > 1) {
        if (!strcmp(argv[1], "subcontext")) {
            android::base::InitLogging(argv, &android::base::KernelLogger);
            const BuiltinFunctionMap function_map;

            return SubcontextMain(argc, argv, &function_map);
        }

        if (!strcmp(argv[1], "selinux_setup")) {
            return SetupSelinux(argv);
        }

        if (!strcmp(argv[1], "second_stage")) {
       			// 调用init.cpp的SecondStageMain
            return SecondStageMain(argc, argv);
        }
    }

    return FirstStageMain(argc, argv);
}
```

[init.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/android-12.0.0_r32:system/core/init/init.cpp)

```c++
int SecondStageMain(int argc, char** argv) {
    if (REBOOT_BOOTLOADER_ON_PANIC) {
        InstallRebootSignalHandlers();
    }

    SetStdioToDevNull(argv);
    InitKernelLogging(argv);
    LOG(INFO) << "init second stage started!";
  
		// Set init and its forked children's oom_adj.
    if (auto result = WriteFile("/proc/1/oom_score_adj", "-1000"); !result) {
        LOG(ERROR) << "Unable to write -1000 to /proc/1/oom_score_adj: " << result.error();
    }

    // Enable seccomp if global boot option was passed (otherwise it is enabled in zygote).
    GlobalSeccomp();

    // Set up a session keyring that all processes will have access to. It
    // will hold things like FBE encryption keys. No process should override
    // its session keyring.
    keyctl_get_keyring_ID(KEY_SPEC_SESSION_KEYRING, 1);

    // Indicate that booting is in progress to background fw loaders, etc.
    close(open("/dev/.booting", O_WRONLY | O_CREAT | O_CLOEXEC, 0000));
  	// 初始化和属性相关的资源
    property_init();
  
    // If arguments are passed both on the command line and in DT,
    // properties set in DT always have priority over the command-line ones.
    process_kernel_dt();
    process_kernel_cmdline();

    // Propagate the kernel variables to internal variables
    // used by init as well as the current required properties.
    export_kernel_boot_props();

    // Make the time that init started available for bootstat to log.
    property_set("ro.boottime.init", getenv("INIT_STARTED_AT"));
    property_set("ro.boottime.init.selinux", getenv("INIT_SELINUX_TOOK"));

    // Set libavb version for Framework-only OTA match in Treble build.
    const char* avb_version = getenv("INIT_AVB_VERSION");
    if (avb_version) property_set("ro.boot.avb_version", avb_version);

    // See if need to load debug props to allow adb root, when the device is unlocked.
    const char* force_debuggable_env = getenv("INIT_FORCE_DEBUGGABLE");
    if (force_debuggable_env && AvbHandle::IsDeviceUnlocked()) {
        load_debug_prop = "true"s == force_debuggable_env;
    }

    // Clean up our environment.
    unsetenv("INIT_STARTED_AT");
    unsetenv("INIT_SELINUX_TOOK");
    unsetenv("INIT_AVB_VERSION");
    unsetenv("INIT_FORCE_DEBUGGABLE");

    // Now set up SELinux for second stage.
    SelinuxSetupKernelLogging();
    SelabelInitialize();
    SelinuxRestoreContext();

    Epoll epoll;
    if (auto result = epoll.Open(); !result) {
        PLOG(FATAL) << result.error();
    }

    InstallSignalFdHandler(&epoll);

    property_load_boot_defaults(load_debug_prop);
    UmountDebugRamdisk();
    fs_mgr_vendor_overlay_mount_all();
    export_oem_lock_status();
  	// 启动属性服务
    StartPropertyService(&epoll);
    MountHandler mount_handler(&epoll);
    set_usb_controller();

    const BuiltinFunctionMap function_map;
    Action::set_function_map(&function_map);

    if (!SetupMountNamespaces()) {
        PLOG(FATAL) << "SetupMountNamespaces failed";
    }

    subcontexts = InitializeSubcontexts();

    ActionManager& am = ActionManager::GetInstance();
    ServiceList& sm = ServiceList::GetInstance();

  	// 加载init.rc
    LoadBootScripts(am, sm);

    // Turning this on and letting the INFO logging be discarded adds 0.2s to
    // Nexus 9 boot time, so it's disabled by default.
    if (false) DumpState();

    // Make the GSI status available before scripts start running.
  	// 调用property_set函数设置属性项,一个属性项包括属性名和属性值。
    if (android::gsi::IsGsiRunning()) {
        property_set("ro.gsid.image_running", "1");
    } else {
        property_set("ro.gsid.image_running", "0");
    }

  	// 将解析得到的action 按照一定的顺序执行(有些动作必须在其他动作完成后才能执行)
  	// "early-init"、"init"、
    am.QueueBuiltinAction(SetupCgroupsAction, "SetupCgroups");

    am.QueueEventTrigger("early-init");

    // Queue an action that waits for coldboot done so we know ueventd has set up all of /dev...
    am.QueueBuiltinAction(wait_for_coldboot_done_action, "wait_for_coldboot_done");
    // ... so that we can start queuing up actions that require stuff from /dev.
    am.QueueBuiltinAction(MixHwrngIntoLinuxRngAction, "MixHwrngIntoLinuxRng");
    am.QueueBuiltinAction(SetMmapRndBitsAction, "SetMmapRndBits");
    am.QueueBuiltinAction(SetKptrRestrictAction, "SetKptrRestrict");
  	// 初始化/dev/keychord设备, 这与调试有关
    Keychords keychords;
    am.QueueBuiltinAction(
        [&epoll, &keychords](const BuiltinArguments& args) -> Result<Success> {
            for (const auto& svc : ServiceList::GetInstance()) {
                keychords.Register(svc->keycodes());
            }
            keychords.Start(&epoll, HandleKeychord);
            return Success();
        },
        "KeychordInit");
    am.QueueBuiltinAction(console_init_action, "console_init");

    // Trigger all the boot actions to get us started.
    am.QueueEventTrigger("init");

    // Starting the BoringSSL self test, for NIAP certification compliance.
    am.QueueBuiltinAction(StartBoringSslSelfTest, "StartBoringSslSelfTest");

    // Repeat mix_hwrng_into_linux_rng in case /dev/hw_random or /dev/random
    // wasn't ready immediately after wait_for_coldboot_done
    am.QueueBuiltinAction(MixHwrngIntoLinuxRngAction, "MixHwrngIntoLinuxRng");

    // Initialize binder before bringing up other system services
    // 初始化Binder
    am.QueueBuiltinAction(InitBinder, "InitBinder");

    // Don't mount filesystems or start core system services in charger mode.
    std::string bootmode = GetProperty("ro.bootmode", "");
    if (bootmode == "charger") {
        am.QueueEventTrigger("charger");
    } else {
        am.QueueEventTrigger("late-init");
    }

    // Run all property triggers based on current state of the properties.
    am.QueueBuiltinAction(queue_property_triggers_action, "queue_property_triggers");
  
		// 进入循环
    while (true) {
        // By default, sleep until something happens.
        auto epoll_timeout = std::optional<std::chrono::milliseconds>{};

        if (do_shutdown && !shutting_down) {
            do_shutdown = false;
            if (HandlePowerctlMessage(shutdown_command)) {
                shutting_down = true;
            }
        }

        if (!(waiting_for_prop || Service::is_exec_service_running())) {
          	// 执行action
            am.ExecuteOneCommand();
        }
        if (!(waiting_for_prop || Service::is_exec_service_running())) {
            if (!shutting_down) {
                auto next_process_action_time = HandleProcessActions();

                // If there's a process that needs restarting, wake up in time for that.
              	// 重启一些已经死去的进程
                if (next_process_action_time) {
                    epoll_timeout = std::chrono::ceil<std::chrono::milliseconds>(
                            *next_process_action_time - boot_clock::now());
                    if (*epoll_timeout < 0ms) epoll_timeout = 0ms;
                }
            }

            // If there's more work to do, wake up again immediately.
            if (am.HasMoreCommands()) epoll_timeout = 0ms;
        }
				// 等待
        if (auto result = epoll.Wait(epoll_timeout); !result) {
            LOG(ERROR) << result.error();
        }
    }

    return 0;
}
```

## 配置文件解析流程

首先会尝试通过``GetProperty("ro.boot.init_rc", "")``获取配置，若不存在则使用默认配置,最终都是调用``parser.ParseConfig()``函数进行解析。

``init.cpp``

```C++
static void LoadBootScripts(ActionManager& action_manager, ServiceList& service_list) {
    Parser parser = CreateParser(action_manager, service_list);

    std::string bootscript = GetProperty("ro.boot.init_rc", "");
    if (bootscript.empty()) {
     		// 执行默认
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
```

[parser.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/android-12.0.0_r32:system/core/init/parser.cpp)

```C++
bool Parser::ParseConfig(const std::string& path) {
    if (is_dir(path.c_str())) {
      	// 
        return ParseConfigDir(path);
    }
    return ParseConfigFile(path);
}
```

若``path``是一个文件，将先读取文件内容，若读取成功将调用``ParseData()``函数处理数据并返回``true``，否则将返回``false``。

```C++
bool Parser::ParseConfigFile(const std::string& path) {
    LOG(INFO) << "Parsing file " << path << "...";
    android::base::Timer t;
    auto config_contents = ReadFile(path);
    if (!config_contents) {
        LOG(INFO) << "Unable to read config file '" << path << "': " << config_contents.error();
        return false;
    }
		// 执行解析数据操作
    ParseData(path, &config_contents.value());

    LOG(VERBOSE) << "(Parsing " << path << " took " << t << ".)";
    return true;
}
```

若``path``是一个文件夹，将会筛选出该文件夹下的配置文件, 最终便利文件列表依次调用``ParseConfigFile()函数``。

```C++
bool Parser::ParseConfigDir(const std::string& path) {
    LOG(INFO) << "Parsing directory " << path << "...";
    std::unique_ptr<DIR, decltype(&closedir)> config_dir(opendir(path.c_str()), closedir);
    if (!config_dir) {
        PLOG(INFO) << "Could not import directory '" << path << "'";
        return false;
    }
    dirent* current_file;
    std::vector<std::string> files;
    while ((current_file = readdir(config_dir.get()))) {
        // Ignore directories and only process regular files.
        if (current_file->d_type == DT_REG) {
            std::string current_path =
                android::base::StringPrintf("%s/%s", path.c_str(), current_file->d_name);
            files.emplace_back(current_path);
        }
    }
    // Sort first so we load files in a consistent order (bug 31996208)
    std::sort(files.begin(), files.end());
    for (const auto& file : files) {
      	// 最终还是调用的单文件解析配置
        if (!ParseConfigFile(file)) {
            LOG(ERROR) << "could not import file '" << file << "'";
        }
    }
    return true;
}
```

``ParseData()``主要的作用就是找到配置文件中的``Section``

```C++
void Parser::ParseData(const std::string& filename, std::string* data) {
    data->push_back('\n');
    data->push_back('\0');

    parse_state state;
    state.line = 0;
    state.ptr = data->data();
    state.nexttoken = 0;

    SectionParser* section_parser = nullptr;
    int section_start_line = -1;
    std::vector<std::string> args;

    // If we encounter a bad section start, there is no valid parser object to parse the subsequent
    // sections, so we must suppress errors until the next valid section is found.
    bool bad_section_found = false;

    auto end_section = [&] {
        bad_section_found = false;
        if (section_parser == nullptr) return;

        if (auto result = section_parser->EndSection(); !result.ok()) {
            parse_error_count_++;
            LOG(ERROR) << filename << ": " << section_start_line << ": " << result.error();
        }

        section_parser = nullptr;
        section_start_line = -1;
    };

    for (;;) {
        switch (next_token(&state)) {
            case T_EOF:
                end_section();

                for (const auto& [section_name, section_parser] : section_parsers_) {
                    section_parser->EndFile();
                }

                return;
            case T_NEWLINE: {
                state.line++;
                if (args.empty()) break;
                // If we have a line matching a prefix we recognize, call its callback and unset any
                // current section parsers.  This is meant for /sys/ and /dev/ line entries for
                // uevent.
                auto line_callback = std::find_if(
                    line_callbacks_.begin(), line_callbacks_.end(),
                    [&args](const auto& c) { return android::base::StartsWith(args[0], c.first); });
                if (line_callback != line_callbacks_.end()) {
                    end_section();

                    if (auto result = line_callback->second(std::move(args)); !result.ok()) {
                        parse_error_count_++;
                        LOG(ERROR) << filename << ": " << state.line << ": " << result.error();
                    }
                } else if (section_parsers_.count(args[0])) {
                    end_section();
                    section_parser = section_parsers_[args[0]].get();
                    section_start_line = state.line;
                    if (auto result =
                                section_parser->ParseSection(std::move(args), filename, state.line);
                        !result.ok()) {
                        parse_error_count_++;
                        LOG(ERROR) << filename << ": " << state.line << ": " << result.error();
                        section_parser = nullptr;
                        bad_section_found = true;
                    }
                } else if (section_parser) {
                    if (auto result = section_parser->ParseLineSection(std::move(args), state.line);
                        !result.ok()) {
                        parse_error_count_++;
                        LOG(ERROR) << filename << ": " << state.line << ": " << result.error();
                    }
                } else if (!bad_section_found) {
                    parse_error_count_++;
                    LOG(ERROR) << filename << ": " << state.line
                               << ": Invalid section keyword found";
                }
                args.clear();
                break;
            }
            case T_TEXT:
                args.emplace_back(state.text);
                break;
        }
    }
}
```



## init.rc文件

[init.rc - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:system/core/rootdir/init.rc?q=init.rc&ss=android%2Fplatform%2Fsuperproject)

### 1. 关键字表

| 关键字      | 对应类型 | 范例                                                         |
| ----------- | -------- | ------------------------------------------------------------ |
| import      | SECTION  | 说明                                                         |
| on          | SECTION  | 一个section的内容从这个标识section的关键字开始,到下一个标识section的地方结束。 |
| service     | SECTION  |                                                              |
| class_start | COMMAND  | 对应函数为do_class_start                                     |
|             |          |                                                              |

```shell
on early-init
	# Disable sysrq from keyboard
    write /proc/sys/kernel/sysrq 0
	# ... 省略
# Run boringssl self test for each ABI so that later processes can skip it. http://b/139348610
# 条件： early-init && property:ro.product.cpu.abilist32=* 

# 满足添加执行COMMAND：exec_start boringssl_self_test32
on early-init && property:ro.product.cpu.abilist32=*
    exec_start boringssl_self_test32
on early-init && property:ro.product.cpu.abilist64=*
    exec_start boringssl_self_test64
on property:apexd.status=ready && property:ro.product.cpu.abilist32=*
    exec_start boringssl_self_test_apex32
on property:apexd.status=ready && property:ro.product.cpu.abilist64=*
    exec_start boringssl_self_test_apex64

service boringssl_self_test32 /system/bin/boringssl_self_test32
    reboot_on_failure reboot,boringssl-self-check-failed
    stdio_to_kmsg

service boringssl_self_test64 /system/bin/boringssl_self_test64
    reboot_on_failure reboot,boringssl-self-check-failed
    stdio_to_kmsg

service boringssl_self_test_apex32 /apex/com.android.conscrypt/bin/boringssl_self_test32
    reboot_on_failure reboot,boringssl-self-check-failed
    stdio_to_kmsg

service boringssl_self_test_apex64 /apex/com.android.conscrypt/bin/boringssl_self_test64
    reboot_on_failure reboot,boringssl-self-check-failed
    stdio_to_kmsg

on init
    sysclktz 0
		# ... 省略
```

Builtin-function-map:

```c++
// Builtin-function-map start
const BuiltinFunctionMap& GetBuiltinFunctionMap() {
    constexpr std::size_t kMax = std::numeric_limits<std::size_t>::max();
    // clang-format off
    static const BuiltinFunctionMap builtin_functions = {
        {"bootchart",               {1,     1,    {false,  do_bootchart}}},
        {"chmod",                   {2,     2,    {true,   do_chmod}}},
        {"chown",                   {2,     3,    {true,   do_chown}}},
        {"class_reset",             {1,     1,    {false,  do_class_reset}}},
        {"class_restart",           {1,     2,    {false,  do_class_restart}}},
        {"class_start",             {1,     1,    {false,  do_class_start}}},
        {"class_stop",              {1,     1,    {false,  do_class_stop}}},
        {"copy",                    {2,     2,    {true,   do_copy}}},
        {"copy_per_line",           {2,     2,    {true,   do_copy_per_line}}},
        {"domainname",              {1,     1,    {true,   do_domainname}}},
        {"enable",                  {1,     1,    {false,  do_enable}}},
        {"exec",                    {1,     kMax, {false,  do_exec}}},
        {"exec_background",         {1,     kMax, {false,  do_exec_background}}},
        {"exec_start",              {1,     1,    {false,  do_exec_start}}},
        {"export",                  {2,     2,    {false,  do_export}}},
        {"hostname",                {1,     1,    {true,   do_hostname}}},
        {"ifup",                    {1,     1,    {true,   do_ifup}}},
        {"init_user0",              {0,     0,    {false,  do_init_user0}}},
        {"insmod",                  {1,     kMax, {true,   do_insmod}}},
        {"installkey",              {1,     1,    {false,  do_installkey}}},
        {"interface_restart",       {1,     1,    {false,  do_interface_restart}}},
        {"interface_start",         {1,     1,    {false,  do_interface_start}}},
        {"interface_stop",          {1,     1,    {false,  do_interface_stop}}},
        {"load_exports",            {1,     1,    {false,  do_load_exports}}},
        {"load_persist_props",      {0,     0,    {false,  do_load_persist_props}}},
        {"load_system_props",       {0,     0,    {false,  do_load_system_props}}},
        {"loglevel",                {1,     1,    {false,  do_loglevel}}},
        {"mark_post_data",          {0,     0,    {false,  do_mark_post_data}}},
        {"mkdir",                   {1,     6,    {true,   do_mkdir}}},
        // TODO: Do mount operations in vendor_init.
        // mount_all is currently too complex to run in vendor_init as it queues action triggers,
        // imports rc scripts, etc.  It should be simplified and run in vendor_init context.
        // mount and umount are run in the same context as mount_all for symmetry.
        {"mount_all",               {0,     kMax, {false,  do_mount_all}}},
        {"mount",                   {3,     kMax, {false,  do_mount}}},
        {"perform_apex_config",     {0,     0,    {false,  do_perform_apex_config}}},
        {"umount",                  {1,     1,    {false,  do_umount}}},
        {"umount_all",              {0,     1,    {false,  do_umount_all}}},
        {"update_linker_config",    {0,     0,    {false,  do_update_linker_config}}},
        {"readahead",               {1,     2,    {true,   do_readahead}}},
        {"remount_userdata",        {0,     0,    {false,  do_remount_userdata}}},
        {"restart",                 {1,     2,    {false,  do_restart}}},
        {"restorecon",              {1,     kMax, {true,   do_restorecon}}},
        {"restorecon_recursive",    {1,     kMax, {true,   do_restorecon_recursive}}},
        {"rm",                      {1,     1,    {true,   do_rm}}},
        {"rmdir",                   {1,     1,    {true,   do_rmdir}}},
        {"setprop",                 {2,     2,    {true,   do_setprop}}},
        {"setrlimit",               {3,     3,    {false,  do_setrlimit}}},
        {"start",                   {1,     1,    {false,  do_start}}},
        {"stop",                    {1,     1,    {false,  do_stop}}},
        {"swapon_all",              {0,     1,    {false,  do_swapon_all}}},
        {"enter_default_mount_ns",  {0,     0,    {false,  do_enter_default_mount_ns}}},
        {"symlink",                 {2,     2,    {true,   do_symlink}}},
        {"sysclktz",                {1,     1,    {false,  do_sysclktz}}},
        {"trigger",                 {1,     1,    {false,  do_trigger}}},
        {"verity_update_state",     {0,     0,    {false,  do_verity_update_state}}},
        {"wait",                    {1,     2,    {true,   do_wait}}},
        {"wait_for_prop",           {2,     2,    {false,  do_wait_for_prop}}},
        {"write",                   {2,     2,    {true,   do_write}}},
    };
    // clang-format on
    return builtin_functions;
}
// Builtin-function-map end
```

### 2. 解析service

```shell
# 名字：boringssl_self_test32
# 执行路径：/system/bin/boringssl_self_test32
# 执行的指令：reboot_on_failure reboot,boringssl-self-check-failed
service boringssl_self_test32 /system/bin/boringssl_self_test32
    reboot_on_failure reboot,boringssl-self-check-failed
    stdio_to_kmsg
```

在``init.cpp``中构建解析器：

```C++
Parser CreateParser(ActionManager& action_manager, ServiceList& service_list) {
    Parser parser;
		// 这里注册了service的解析器ServiceParser，解析后的内容存放在ServiceList中。
    parser.AddSectionParser("service", std::make_unique<ServiceParser>(&service_list, subcontexts));
    parser.AddSectionParser("on", std::make_unique<ActionParser>(&action_manager, subcontexts));
    parser.AddSectionParser("import", std::make_unique<ImportParser>(&parser));

    return parser;
}
```

``ActionParser``：[action_parser.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:system/core/init/action_parser.cpp;bpv=0;bpt=1)

``ServiceParser``解析：[service_parser.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/android-12.0.0service_list：_r32:system/core/init/service_parser.cpp)

``ServiceList``：[service_list.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/android-12.0.0_r32:system/core/init/service_list.cpp)

``Service结构体``：[service.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/android-12.0.0_r32:system/core/init/service.h)

```c++
class Service {
  // ...省略
  private:
      void NotifyStateChange(const std::string& new_state) const;
      void StopOrReset(int how);
      void KillProcessGroup(int signal, bool report_oneshot = false);
      void SetProcessAttributesAndCaps();

      static unsigned long next_start_order_;
      static bool is_exec_service_running_;

      std::string name_;	//service的名字
      std::set<std::string> classnames_;	// service所属class的名字

      unsigned flags_;	// service的属性
      pid_t pid_;	//进程号
      android::base::boot_clock::time_point time_started_;  // time of last start 最近启动时间
      android::base::boot_clock::time_point time_crashed_;  // first crash within inspection window 最近崩溃时间
      int crash_count_;                     // number of times crashed within window	// 崩溃次数
      std::chrono::minutes fatal_crash_window_ = 4min;  // fatal() when more than 4 crashes in it
      std::optional<std::string> fatal_reboot_target_;  // reboot target of fatal handler

      std::optional<CapSet> capabilities_;
      ProcessAttributes proc_attr_;
      NamespaceInfo namespaces_;

      std::string seclabel_;

      std::vector<SocketDescriptor> sockets_;	// 部分service使用了socket，用来描述sockets相关信息
      std::vector<FileDescriptor> files_;
  		// service一般运行在一个单独的进程中,environment_vars_用来描述创建这个进程时所需的环境变量信息
      std::vector<std::pair<std::string, std::string>> environment_vars_;

      Subcontext* subcontext_;
      Action onrestart_;  // Commands to execute on restart.

      std::vector<std::string> writepid_files_;

      std::vector<std::string> task_profiles_;

      std::set<std::string> interfaces_;  // e.g. some.package.foo@1.0::IBaz/instance-name

      // keycodes for triggering this service via /dev/input/input*
      std::vector<int> keycodes_;

      int oom_score_adjust_;

      int swappiness_ = -1;
      int soft_limit_in_bytes_ = -1;

      int limit_in_bytes_ = -1;
      int limit_percent_ = -1;
      std::string limit_property_;

      bool process_cgroup_empty_ = false;

      bool override_ = false;

      unsigned long start_order_;

      bool sigstop_ = false;

      std::chrono::seconds restart_period_ = 5s;
      std::optional<std::chrono::seconds> timeout_period_;

      bool updatable_ = false;

      std::vector<std::string> args_;

      std::vector<std::function<void(const siginfo_t& siginfo)>> reap_callbacks_;

      bool use_bootstrap_ns_ = false;

      bool post_data_ = false;

      bool running_at_post_data_reset_ = false;

      std::optional<std::string> on_failure_reboot_target_;

      bool from_apex_ = false;
}
```

### 3. 启动service

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
      	// 服务不可用则启动
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

111
