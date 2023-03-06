# Android之init.rc文件

init.rc是一个配置文件，它是在 init进程启动后执行的，记录着 init进程 需要执行哪些操作。

## Android Init Language

init.rc文件内部是由 Android Init Language编写的脚本，我们需要简单了解一下语法以便后续阅读rc文件。

[具体的语法可以在这里查看](https://cs.android.com/android/platform/superproject/+/master:system/core/init/README.md)。

包括五大类语句：Actions, Commands, Services, Options, and Imports。

| 语句     |                                                              |      |
| -------- | ------------------------------------------------------------ | ---- |
| Imports  | 解析指定的配置，作为当前的配置的扩展。                       |      |
| Actions  | 表示一组被命名的命令集合。它**包含一个触发器**，可以被 `trigger`命令触发。当一个事件的发生与Action的触发器相匹配时，该Action就被添加到待执行队列的尾部。 |      |
| Services | 它是init启动的程序，并且服务会在退出后重新启动。即服务进程是守护进程。 |      |
| -        |                                                              |      |
| Commands | 它就是Action中包含的一条条命令。                             |      |
| Options  | 用于指定在什么时间怎么样来启动服务。                         |      |

### Section

init.rc 文件在解析中是以**Section为基本单位**，包括Actions，Services, Imports。

#### Action

```shell
on <trigger> [&& <trigger>]*
   <command>
   <command>
   <command>

# 定义 late-init 事件触发器
# 当 late-init 被触发时执行下方的Commands
on late-init
    trigger early-fs
    # 触发 zygote-start
    trigger zygote-start
    
on zygote-start
	...
```

#### Service

```shell
service <name> <pathname> [ <argument> ]*
   <option>
   <option>
   ...
#
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

#### Import

```shell
import <path>
#
import /system/etc/init/hw/init.${ro.zygote}.rc
```

### Trigger

和Action相关的还有一个触发器Trigger的概念，包括`event triggers` 和 `property triggers`两大类，本质是一个字符串。只要满足条件就会触发Action。

* event triggers：事件触发器由 `trigger`命令 或者 `QueueEventTrigger()`函数触发。

  ```shell
  on boot && property:a=b
  # 定义 boot 事件触发器， property:a=b 属性触发器
  # 当 boot事件发生 并且 属性 a=b 才会真的执行Action
  ```

* property triggers：属性触发器是指当一个指定的属性的值变为给定的新值时，或者当一个指定的属性的值变为任何新值时，触发的字符串。

  ```shell
  on property:a=b && property:c=d 
  # 此处定义了两个属性触发器。
  # a=b && c=d 时就触发Action
  ```


### Commod

命令有很多，这里摘录一些常见的：

| COMMAND                        |                                                              |
| ------------------------------ | ------------------------------------------------------------ |
| start                          | 启动指定的服务                                               |
| stop                           | 关闭指定的服务                                               |
| `class_start <serviceclass>`   | 启动指定类中的所有服务。对应函数为do_class_start.            |
| `class_stop <serviceclass>`    | 关闭指定类中的所有服务                                       |
| exec                           | 根据指定的文件或文件夹找到可执行程序，并在当前进程执行它。进程的用户空间代码和数据完全被新程序替换。**调用成功时无返回，失败返回-1** |
| exec_start                     |                                                              |
| trigger                        | 触发指定Action，会将指定的Action放到队尾。这样外部的循环就能够执行它。 |
| export                         | 设置全局环境变量，对所有进程都生效。                         |
| -                              |                                                              |
| mount                          | 挂载                                                         |
| `chmod <octal-mode> <path>`    | 修改文件的访问权限                                           |
| `chown <owner> <group> <path>` | 修改文件的owner 和 group                                     |
| hostname                       | 设置主机名                                                   |
| ifup                           | 使指定网络接口可用。                                         |
| chroot                         | 改变根目录                                                   |
| chdir                          | 改变工作目录                                                 |
| insmod                         | 安装模块到指定路径                                           |
| sysclktz                       | 设置系统的时区                                               |
| ....                           |                                                              |

## init.rc 文件简析

* on early-init：初始化早期阶段。位于触发序列的第一位，在cgroups被配置后但在ueventd的冷启动完成前被触发。
* on init：初始化阶段，冷启动完成后触发。负责启动一些重要的服务。**servicemanager在此时启动**。
* on late-init：初始化后期阶段，挂载文件系统并启动核心系统服务。触发了 zygote-start、boot等。
* on zygote-start：**启动zygote进程**。
* on boot：启动阶段
* on property:ro.debuggable=1：类型此结构都是表示，当对应属性等于指定值时触发。

> 完整文件可以查看 [init.rc - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:system/core/rootdir/init.rc?q=init.rc&ss=android%2Fplatform%2Fsuperproject)

```shell
import /init.environ.rc
import /system/etc/init/hw/init.usb.rc
import /init.${ro.hardware}.rc
import /vendor/etc/init/hw/init.${ro.hardware}.rc
import /system/etc/init/hw/init.usb.configfs.rc
# 导入Zygote相关的配置
import /system/etc/init/hw/init.${ro.zygote}.rc

# Cgroups are mounted right before early-init using list from /etc/cgroups.json
on early-init
	......
    start ueventd
    # create sys dirctory
    mkdir /dev/sys 0755 system system
	...
    
on init
    sysclktz 0

	...
    # cpuctl hierarchy for devices using utilclamp
    mkdir /dev/cpuctl/foreground
  	....
	
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

# Mount filesystems and start core system services.
on late-init
    trigger early-fs
    ....
    # Now we can start zygote for devices with file based encryption
    # 触发 zygote-start,内部启动了zygote
    trigger zygote-start
	...
	
    trigger early-boot
    trigger boot

on early-fs
    # Once metadata has been mounted, we'll need vold to deal with userdata checkpointing
    start vold

on post-fs
    exec - system system -- /system/bin/vdc checkpoint markBootAttempt
	....
	
on late-fs
    # Ensure that tracefs has the correct permissions.
    # This does not work correctly if it is called in post-fs.
    .....
    
# It is recommended to put unnecessary data/ initialization from post-fs-data
# to start-zygote in device's init.rc to unblock zygote start.
# Section满足条件则会执行指定的COMMAND
# 条件：zygote-start被触发 并且 property:ro.crypto.state=unencrypted
# COMMAND：wait_for_prop.... 
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

on boot
    # basic network init
    ifup lo
    hostname localhost
    domainname localdomain
    ....
    # Start standard binderized HAL daemons
    class_start hal
    class_start core

....
on property:ro.debuggable=1
    # Give writes to the same group for the trace folder on debug builds,
    # it's further protected by selinux policy.
    # The folder is used to store method traces.
    chmod 0773 /data/misc/trace
    # Give writes and reads to anyone for the window trace folder on debug builds,
    # it's further protected by selinux policy.
    chmod 0777 /data/misc/wmtrace
    # Give reads to anyone for the accessibility trace folder on debug builds.
    chmod 0775 /data/misc/a11ytrace

on init && property:ro.debuggable=1
    start console
.....
```

## init.rc 解析流程

* 在 init进程的 `SecondStageMain()` 流程中的 `LoadBootScripts()` 函数中被init.rc 文件会被解析。
* 首先会尝试通过``GetProperty("ro.boot.init_rc", "")``获取配置
* 若不存在则使用默认的几个配置文件。
* 最终都是调用``parser.ParseConfig()``函数进行解析。

### LoadBootScripts

选定需要解析的 init.rc 文件，并使用对应的解析器解析文件。

* ServiceParser：
* ActionParser： [action_parser.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:system/core/init/action_parser.cpp)
* ImportParser：

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

### ParseConfig

最终是在 [parser.cpp](https://cs.android.com/android/platform/superproject/+/master:system/core/init/parser.cpp;drc=5ca657189aac546af0aafaba11bbc9c5d889eab3;l=186) 中处理的解析：

```cpp
bool Parser::ParseConfig(const std::string& path) {
    if (is_dir(path.c_str())) {
        // 文件夹流程，内部最终调用的还是 ParseConfigFile
        return ParseConfigDir(path);
    }
    // 文件流程
    auto result = ParseConfigFile(path);
    if (!result.ok()) {
        LOG(INFO) << result.error();
    }
    return result.ok();
}
```

若``path``是一个文件夹，将会筛选出该文件夹下的配置文件, 最终便利文件列表依次调用``ParseConfigFile()函数``。

```cpp
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
        // 仅处理 规则文件
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
        if (auto result = ParseConfigFile(file); !result.ok()) {
            LOG(ERROR) << "could not import file '" << file << "': " << result.error();
        }
    }
    return true;
}
```

若``path``是一个文件，将先读取文件内容，若读取成功将调用``ParseData()``函数处理数据并返回``true``，否则将返回``false``。

```cpp
Result<void> Parser::ParseConfigFile(const std::string& path) {
    LOG(INFO) << "Parsing file " << path << "...";
    android::base::Timer t;
    auto config_contents = ReadFile(path);
    if (!config_contents.ok()) {
        return Error() << "Unable to read config file '" << path
                       << "': " << config_contents.error();
    }

    ParseData(path, &config_contents.value());

    LOG(VERBOSE) << "(Parsing " << path << " took " << t << ".)";
    return {};
}
```

### ParseData

主要的作用就是解析处配置文件中的`Section`。

```cpp
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
	
    // 这个函数 表示一个section解析完成，此时将会把解析结果直接移动拷贝到对应的地方
    // 例如action 则将被移动拷贝到 actionmanager 中。
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
                    // ParseSection
                    if (auto result =
                                section_parser->ParseSection(std::move(args), filename, state.line);
                        !result.ok()) {
                        parse_error_count_++;
                        LOG(ERROR) << filename << ": " << state.line << ": " << result.error();
                        section_parser = nullptr;
                        bad_section_found = true;
                    }
                } else if (section_parser) {
                    // ParseLineSection
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



## Action执行流程

* 在`builtins.cpp`中定义了 一个 BuiltinFunctionMap，其中记录了Command和函数的对应关系。
* 在 init的 `SecondStageMain()` 阶段的 loop循环中会调用 `am.ExecuteOneCommand()`。

```cpp
int SecondStageMain(int argc, char** argv) {
    ...
	// 获取 command和fuction的映射表
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
    // 开启无限循环
    while (true) {
       	...
        if (!(prop_waiter_state.MightBeWaiting() || Service::is_exec_service_running())) {
            // 一条一条执行action
            am.ExecuteOneCommand();
        }
 		...
    }
    return 0;
}
```

### GetBuiltinFunctionMap

[builtins.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:system/core/init/builtins.cpp;drc=5ca657189aac546af0aafaba11bbc9c5d889eab3;bpv=1;bpt=1;l=1341)

```cpp
// Builtin-function-map start
const BuiltinFunctionMap& GetBuiltinFunctionMap() {
    constexpr std::size_t kMax = std::numeric_limits<std::size_t>::max();
    // clang-format off
    // 这个Map对应的结构体在后面
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

// 定义
using BuiltinFunction = std::function<Result<void>(const BuiltinArguments&)>;
struct BuiltinFunctionMapValue {
    bool run_in_subcontext;
    BuiltinFunction function;
};
using BuiltinFunctionMap = KeywordMap<BuiltinFunctionMapValue>;

// 相应的结构体
struct BuiltinArguments {
    const std::string& operator[](std::size_t i) const { return args[i]; }
    auto begin() const { return args.begin(); }
    auto end() const { return args.end(); }
    auto size() const { return args.size(); }

    std::vector<std::string> args;
    const std::string& context;
};


struct BuiltinFunctionMapValue {
    bool run_in_subcontext;
    BuiltinFunction function;
};

class KeywordMap {
  public:
    struct MapValue {
        size_t min_args;
        size_t max_args;
        Value value;
    };
}
// 
```



### ExecuteOneCommand

在 init的 `SecondStageMain()` 阶段的 loop循环中会调用 `am.ExecuteOneCommand()`。

[action_manager.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:system/core/init/action_manager.cpp;drc=5ca657189aac546af0aafaba11bbc9c5d889eab3;bpv=1;bpt=1;l=43)

```cpp
void ActionManager::ExecuteOneCommand() {
    {
        auto lock = std::lock_guard{event_queue_lock_};
        // Loop through the event queue until we have an action to execute
        // 当没有可执行的Action时，将循环检查是否存在event trigger
        // 存在event trigger 则将筛选出符合条件的Action，放入执行列表中。
        while (current_executing_actions_.empty() && !event_queue_.empty()) {
            for (const auto& action : actions_) {
                if (std::visit([&action](const auto& event) { return action->CheckEvent(event); },
                               event_queue_.front())) {
                    current_executing_actions_.emplace(action.get());
                }
            }
            event_queue_.pop();
        }
    }

    if (current_executing_actions_.empty()) {
        return;
    }

    auto action = current_executing_actions_.front();

    if (current_command_ == 0) {
        std::string trigger_name = action->BuildTriggersString();
        LOG(INFO) << "processing action (" << trigger_name << ") from (" << action->filename()
                  << ":" << action->line() << ")";
    }

    action->ExecuteOneCommand(current_command_);

    // If this was the last command in the current action, then remove
    // the action from the executing list.
    // If this action was oneshot, then also remove it from actions_.
    ++current_command_;
    if (current_command_ == action->NumCommands()) {
        current_executing_actions_.pop();
        current_command_ = 0;
        if (action->oneshot()) {
            auto eraser = [&action](std::unique_ptr<Action>& a) { return a.get() == action; };
            actions_.erase(std::remove_if(actions_.begin(), actions_.end(), eraser),
                           actions_.end());
        }
    }
}
```

```cpp
ExecuteOneCommandvoid Action::ExecuteOneCommand(std::size_t command) const {
    // We need a copy here since some Command execution may result in
    // changing commands_ vector by importing .rc files through parser
    Command cmd = commands_[command];
    ExecuteCommand(cmd);
}

void Action::ExecuteCommand(const Command& command) const {
    android::base::Timer t;
    // 调用 InvokeFunc()ExecuteOneCommand cmd_str << "' action=" << trigger_name << " (" << filename_
                  << ":" << command.line() << ") took " << duration.count() << "ms and "
                  << (result.ok() ? "succeeded" : "failed: " + result.error().message());
    }
}

Result<void> Command::InvokeFunc(Subcontext* subcontext) const {
    if (subcontext) {
        if (execute_in_subcontext_) {
            return subcontext->Execute(args_);
        }

        auto expanded_args = subcontext->ExpandArgs(args_);
        if (!expanded_args.ok()) {
            return expanded_args.error();
        }
        return RunBuiltinFunction(func_, *expanded_args, subcontext->context());
    }

    return RunBuiltinFunction(func_, args_, kInitContext);
}

Result<void> RunBuiltinFunction(const BuiltinFunction& function,
                                const std::vector<std::string>& args, const std::string& context) {
    BuiltinArguments builtin_arguments{.context = context};

    builtin_arguments.args.resize(args.size());
    builtin_arguments.args[0] = args[0];
    for (std::size_t i = 1; i < args.size(); ++i) {
        auto expanded_arg = ExpandProps(args[i]);
        if (!expanded_arg.ok()) {
            return expanded_arg.error();
        }
        builtin_arguments.args[i] = std::move(*expanded_arg);
    }
	// 执行对应的function，并将参数传入。
    return function(builtin_arguments);
}

```

## 启动service

在inti.rc文件中 启动服务 一般都是通过 `start` 命令执行，所以对应 `do_start()`函数。

[builtins.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:system/core/init/builtins.cpp;l=765;drc=5ca657189aac546af0aafaba11bbc9c5d889eab3)

```C++
static Result<void> do_start(const BuiltinArguments& args) {
    // 查询服务
    Service* svc = ServiceList::GetInstance().FindService(args[1]);
    if (!svc) return Error() << "service " << args[1] << " not found";
    // 启动服务
    if (auto result = svc->Start(); !result.ok()) {
        return ErrorIgnoreEnoent() << "Could not start service: " << result.error();
    }
    return {};
}
```

[service.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:system/core/init/service.cpp;drc=5ca657189aac546af0aafaba11bbc9c5d889eab3;l=565)

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

## 加餐

###  解析service

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

``Service``结构体：[service.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/android-12.0.0_r32:system/core/init/service.h)

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

### 