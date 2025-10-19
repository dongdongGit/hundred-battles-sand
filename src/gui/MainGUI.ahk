/**
 * 主图形界面
 * 提供程序控制、状态监控、配置管理的图形界面
 */

#Requires AutoHotkey v2.0

class MainGUI {
    __New(loggerInstance := "", configInstance := "", windowManagerInstance := "", imageRecognitionInstance := "", taskManagerInstance := "") {
        ; 如果没有传入实例，使用全局实例（向后兼容）
        if (loggerInstance = "") {
            loggerInstance := LoggerInstance
        }
        if (configInstance = "") {
            configInstance := ConfigInstance
        }
        if (windowManagerInstance = "") {
            global App
            windowManagerInstance := App.WindowManager
        }
        if (imageRecognitionInstance = "") {
            global App
            imageRecognitionInstance := App.ImageRecognition
        }
        if (taskManagerInstance = "") {
            global App
            taskManagerInstance := App.TaskManager
        }

        this.logger := loggerInstance
        this.config := configInstance
        this.windowManager := windowManagerInstance
        this.imageRecognition := imageRecognitionInstance
        this.taskManager := taskManagerInstance

        this.guiHwnd := 0
        this.isVisible := false
        this.statusText := ""
        this.logText := ""

        this.controlButtons := Map()
        this.statusLabels := Map()
        this.configControls := Map()
    }

    Show() {
        this.logger.Info("显示主界面")

        try {
            ; 创建主窗口
            this.guiHwnd := Gui("+Resize +MinSize400x300", "百战沙城自动化 v1.0.0")

            ; 设置字体
            this.guiHwnd.SetFont("s10", "Microsoft YaHei UI")

            ; 跳过工具栏，按钮已在主控制标签页中

            ; 创建主内容区域
            this.CreateMainContent()

            ; 创建状态栏
            this.CreateStatusBar()

            ; 设置窗口事件处理
            this.SetupEventHandlers()

            ; 显示窗口（调整大小以适应更多控件）
            this.guiHwnd.Show("w900 h700")
            this.isVisible := true

            ; 初始化状态
            this.UpdateStatus("就绪")

            this.logger.Info("主界面显示完成")
        }
        catch as e {
            this.logger.Error(Format("显示主界面失败: {}", e.Message))
            throw e
        }
    }

    CreateMenuBar() {
        ; 文件菜单
        fileMenu := Menu()
        fileMenu.Add("&启动程序", (*) => this.OnStartMenu())
        fileMenu.Add("&停止程序", (*) => this.OnStopMenu())
        fileMenu.Add("&重启程序", (*) => this.RestartApp())
        fileMenu.Add()
        fileMenu.Add("&设置", (*) => this.ShowSettings())
        fileMenu.Add()
        fileMenu.Add("退出(&X)", (*) => this.OnExitMenu())

        ; 工具菜单
        toolsMenu := Menu()
        toolsMenu.Add("任务管理器", (*) => this.ShowTaskManager())
        toolsMenu.Add("日志查看器", (*) => this.ShowLogViewer())
        toolsMenu.Add("图像识别测试", (*) => this.ShowImageRecognitionTest())

        ; 帮助菜单
        helpMenu := Menu()
        helpMenu.Add("使用说明(&H)", (*) => this.ShowHelp())
        helpMenu.Add("关于(&A)", (*) => this.ShowAbout())

        ; 主菜单
        mainMenu := Menu()
        mainMenu.Add("&文件(&F)", fileMenu)
        mainMenu.Add("&工具(&T)", toolsMenu)
        mainMenu.Add("&帮助(&H)", helpMenu)

        ; 在AutoHotkey v2.0中，菜单栏通过构造函数参数设置
        ; 这里暂时禁用菜单栏，或者使用其他方式实现菜单功能
        ; this.guiHwnd.MenuBar := mainMenu  ; 传统方式在新版本中不可用
    }

    CreateToolBar() {
        ; 在AutoHotkey v2.0中，ToolBar不可用，使用按钮组替代
        this.startBtn := this.guiHwnd.Add("Button", "x10 y10 w80 h30", "启动")
        this.stopBtn := this.guiHwnd.Add("Button", "x100 y10 w80 h30", "停止")
        this.settingsBtn := this.guiHwnd.Add("Button", "x190 y10 w80 h30", "设置")

        this.controlButtons["start"] := "OnStart"
        this.controlButtons["stop"] := "OnStop"
        this.controlButtons["settings"] := "OnSettings"
    }

    CreateMainContent() {
        ; 创建标签页控件（调整大小）
        tabControl := this.guiHwnd.Add("Tab3", "xm ym w880 h600", ["主控制", "任务状态", "日志输出", "调试信息"])

        ; 主控制标签页
        tabControl.UseTab(1)
        this.CreateMainControlTab()

        ; 任务状态标签页
        tabControl.UseTab(2)
        this.CreateTaskStatusTab()

        ; 日志输出标签页
        tabControl.UseTab(3)
        this.CreateLogOutputTab()

        ; 调试信息标签页
        tabControl.UseTab(4)
        this.CreateDebugInfoTab()

        tabControl.UseTab(1)  ; 默认显示主控制页
    }

    CreateMainControlTab() {
        ; 游戏状态组
        gameGroup := this.guiHwnd.Add("GroupBox", "xm+10 ym+40 w360 h100", "游戏状态")

        this.guiHwnd.Add("Text", "xp+10 yp+20 w80 h20", "游戏窗口:")
        this.statusLabels["game_window"] := this.guiHwnd.Add("Text", "xp+90 yp w250 h20", "未检测")

        this.guiHwnd.Add("Text", "xp-90 yp+25 w80 h20", "游戏进程:")
        this.statusLabels["game_process"] := this.guiHwnd.Add("Text", "xp+90 yp w250 h20", "未运行")

        this.guiHwnd.Add("Text", "xp-90 yp+25 w80 h20", "连接状态:")
        this.statusLabels["connection"] := this.guiHwnd.Add("Text", "xp+90 yp w250 h20", "未连接")

        ; 任务控制组
        taskGroup := this.guiHwnd.Add("GroupBox", "xm+380 ym+40 w500 h140", "任务控制")

        this.guiHwnd.Add("CheckBox", "xp+10 yp+25 w100 h20 vEnableDailySignin", "每日签到")
        this.guiHwnd.Add("CheckBox", "xp+120 yp w100 h20 vEnableDailyTasks", "日常任务")

        ; 野外BOSS挂机（与每日签到左对齐）
        this.guiHwnd.Add("CheckBox", "xp-120 yp+30 w120 h20 vEnableWildBoss", "野外BOSS挂机")

        ; BOSS等级和挑战地点（与野外BOSS挂机垂直对齐）
        this.guiHwnd.Add("Text", "xp yp+30 w60 h20", "BOSS等级:")
        this.wildBossLevelCombo := this.guiHwnd.Add("ComboBox", "xp+60 yp w100 vWildBossLevel", ["妖级", "魔级", "王级", "帝级", "仙级", "神级", "绝世级", "神圣级", "圣尊级", "主宰级", "鸿蒙级", "远古级", "创世级", "洪荒级", "混沌级", "轮回级", "渡厄级", "寂灭级", "时光级", "暗黑级", "禁忌级", "星辰级", "曜日级", "传世级", "永恒级", "荣耀级", "万劫级", "诛仙级", "杀神级", "斗佛级", "炼魔级", "灭日级", "焚天级", "灭魔级", "斩魔级", "天人级"])

        this.guiHwnd.Add("Text", "xp+120 yp w60 h20", "挑战地点:")
        this.wildBossLocationCombo := this.guiHwnd.Add("ComboBox", "xp+60 yp w100 vWildBossLocation", ["请选择等级"])

        ; 下拉菜单选项已在创建时设置完成

        ; 设置默认值（从配置读取）
        defaultLevel := this.config.GetString("tasks", "wild_boss_level", "妖级")
        defaultLocation := this.config.GetString("tasks", "wild_boss_location", "鬼翼神殿一层")

        this.guiHwnd["WildBossLevel"].Text := defaultLevel
        this.guiHwnd["WildBossLocation"].Text := defaultLocation

        ; 根据默认等级更新地点选项
        this.UpdateWildBossLocationsByLevel(defaultLevel)

        this.guiHwnd.Add("CheckBox", "xp-250 yp+30 w100 h20 vEnableEquipment", "装备强化")

        ; 控制按钮（移到底部）
        this.startBtn := this.guiHwnd.Add("Button", "xm+10 yp+200 w80 h30", "启动")
        this.stopBtn := this.guiHwnd.Add("Button", "xp+90 yp w80 h30", "停止")
        this.settingsBtn := this.guiHwnd.Add("Button", "xp+90 yp w80 h30", "设置")
        this.exitBtn := this.guiHwnd.Add("Button", "xp+90 yp w80 h30", "退出")

        ; 进度条（调整位置，避免与底部按钮重叠）
        this.guiHwnd.Add("Text", "xm+10 yp+100 w80 h20", "执行进度:")
        this.guiHwnd.Add("Progress", "xp+90 yp w300 h20 vTaskProgress", 0)
        this.statusLabels["progress"] := "TaskProgress"
    }

    CreateTaskStatusTab() {
        this.guiHwnd.Add("ListView", "xm+10 ym+40 w740 h400 vTaskListView", ["任务名称", "状态", "进度", "开始时间", "耗时"])
        this.refreshTasksBtn := this.guiHwnd.Add("Button", "xm+10 yp+410 w80 h30", "刷新")
        this.clearTasksBtn := this.guiHwnd.Add("Button", "xp+90 yp w80 h30", "清空")
    }

    CreateLogOutputTab() {
        this.guiHwnd.Add("Edit", "xm+10 ym+40 w740 h400 vLogEdit ReadOnly")
        this.clearLogBtn := this.guiHwnd.Add("Button", "xm+10 yp+410 w80 h30", "清空")
        this.saveLogBtn := this.guiHwnd.Add("Button", "xp+90 yp w80 h30", "保存")
        this.refreshLogBtn := this.guiHwnd.Add("Button", "xp+90 yp w80 h30", "刷新")
    }

    CreateDebugInfoTab() {
        this.guiHwnd.Add("Edit", "xm+10 ym+40 w740 h400 vDebugEdit ReadOnly")
        this.refreshDebugBtn := this.guiHwnd.Add("Button", "xm+10 yp+410 w80 h30", "刷新")
        this.testImageRecogBtn := this.guiHwnd.Add("Button", "xp+90 yp w80 h30", "图像识别测试")
        this.testWindowDetectBtn := this.guiHwnd.Add("Button", "xp+90 yp w80 h30", "窗口检测测试")
    }

    CreateStatusBar() {
        ; 创建状态栏（在v2.0中语法有所不同）
        ; 暂时禁用状态栏功能，避免语法错误
        this.statusText := "就绪"
    }

    SetupEventHandlers() {
        ; 窗口大小改变事件
        this.guiHwnd.OnEvent("Size", (*) => this.OnResize())

        ; 关闭事件
        this.guiHwnd.OnEvent("Close", (*) => this.OnClose())

        ; 按钮事件处理（使用正确的v2.0语法）
        ; 注意：App是全局变量，在GUI内部无法直接访问
        ; 需要通过其他方式处理，或者让GUI直接调用方法
        this.startBtn.OnEvent("Click", (*) => this.OnStartButton())
        this.stopBtn.OnEvent("Click", (*) => this.OnStopButton())
        this.settingsBtn.OnEvent("Click", (*) => this.ShowSettings())
        this.exitBtn.OnEvent("Click", (*) => this.OnExitButton())

        ; 野外BOSS等级选择事件
        try {
            if (this.guiHwnd.HasProp("WildBossLevel") && this.guiHwnd["WildBossLevel"]) {
                this.guiHwnd["WildBossLevel"].OnEvent("Change", (*) => this.OnWildBossLevelChange())
            }
        }
        catch as e {
            this.logger.Error(Format("绑定BOSS等级选择事件失败: {}", e.Message))
        }

        ; 其他标签页按钮事件
        this.refreshTasksBtn.OnEvent("Click", (*) => this.OnRefreshTasks())
        this.clearTasksBtn.OnEvent("Click", (*) => this.OnClearTasks())
        this.clearLogBtn.OnEvent("Click", (*) => this.OnClearLog())
        this.saveLogBtn.OnEvent("Click", (*) => this.OnSaveLog())
        this.refreshLogBtn.OnEvent("Click", (*) => this.OnRefreshLog())
        this.refreshDebugBtn.OnEvent("Click", (*) => this.OnRefreshDebug())
        this.testImageRecogBtn.OnEvent("Click", (*) => this.OnTestImageRecog())
        this.testWindowDetectBtn.OnEvent("Click", (*) => this.OnTestWindowDetection())
    }

    OnResize() {
        ; 处理窗口大小改变
        if (this.guiHwnd.Hwnd) {
            ; 重新调整控件大小
            this.RefreshLayout()
        }
    }

    OnClose() {
        ; 点击右上角x按钮时最小化窗口而不是退出程序
        this.logger.Info("用户点击关闭按钮，最小化窗口到托盘")
        this.Hide()

        ; 显示托盘提示
        TrayTip("程序已最小化到托盘", "百战沙城自动化", 0x1)

        ; 如果需要完全退出，可以右键托盘图标选择退出
        ; 或者使用快捷键 Ctrl+Shift+Q 退出程序
    }

    RefreshLayout() {
        ; 刷新布局（根据窗口大小调整控件）
        this.logger.Debug("刷新界面布局")
    }

    UpdateStatus(status) {
        this.statusText := status
        ; 在v2.0中，状态栏功能暂时禁用
        ; if (this.guiHwnd.Hwnd) {
        ;     SB_SetText(status)
        ; }
    }

    UpdateGameStatus() {
        if (!this.isVisible) {
            return
        }

        try {
            ; 检查组件实例是否存在
            if (!this.windowManager) {
                this.logger.Error("WindowManager实例不存在")
                return
            }

            ; 更新游戏窗口状态
            if (this.windowManager.IsGameRunning()) {
                this.guiHwnd["game_window"].Value := "已检测"
                this.guiHwnd["game_process"].Value := "运行中"
                this.guiHwnd["connection"].Value := "已连接"
            }
            else {
                ; 尝试更宽松的检测条件
                if (this.TryLooseGameDetection()) {
                    this.guiHwnd["game_window"].Value := "宽松检测"
                    this.guiHwnd["game_process"].Value := "可能运行"
                    this.guiHwnd["connection"].Value := "待确认"
                }
                else {
                    this.guiHwnd["game_window"].Value := "未检测"
                    this.guiHwnd["game_process"].Value := "未运行"
                    this.guiHwnd["connection"].Value := "未连接"
                }
            }

            ; 更新任务状态
            this.UpdateTaskStatus()

        }
        catch as e {
            this.logger.Error(Format("更新游戏状态失败: {}", e.Message))
        }
    }

    UpdateTaskStatus() {
        if (!this.isVisible) {
            return
        }

        try {
            ; 更新进度条
            progress := 0  ; 这里应该从任务管理器获取实际进度
            this.guiHwnd["TaskProgress"].Value := progress

            ; 更新任务列表
            this.RefreshTaskList()

        }
        catch as e {
            this.logger.Error(Format("更新任务状态失败: {}", e.Message))
        }
    }

    RefreshTaskList() {
        ; 刷新任务列表（应该从任务管理器获取数据）
        this.logger.Debug("刷新任务列表")
    }

    RefreshLogOutput() {
        if (!this.isVisible) {
            return
        }

        try {
            ; 从日志文件读取最新内容
            logFilePath := A_ScriptDir "\logs\app.log"
            if (FileExist(logFilePath)) {
                logContent := FileRead(logFilePath, "UTF-8")
                this.guiHwnd["LogEdit"].Value := logContent
                ; 滚动到底部（在v2.0中需要使用不同的方式）
                ; 暂时注释掉滚动功能，避免语法错误
                ; SendMessage(0x115, 7, 0, this.guiHwnd["LogEdit"].Hwnd)
            }
        }
        catch as e {
            this.logger.Error(Format("刷新日志输出失败: {}", e.Message))
        }
    }

    RefreshDebugInfo() {
        if (!this.isVisible) {
            return
        }

        try {
            debugInfo := ""

            ; 窗口管理器信息
            debugInfo .= "=== 窗口管理器 ===`n"
            if (this.windowManager && this.windowManager.HasMethod("GetDebugInfo")) {
                windowInfo := this.windowManager.GetDebugInfo()
                for key, value in windowInfo {
                    debugInfo .= Format("{}: {}`n", key, value)
                }
            }
            else {
                debugInfo .= "WindowManager: 不可用`n"
            }

            ; 图像识别信息
            debugInfo .= "`n=== 图像识别 ===`n"
            if (this.imageRecognition && this.imageRecognition.HasMethod("GetDebugInfo")) {
                imageInfo := this.imageRecognition.GetDebugInfo()
                for key, value in imageInfo {
                    debugInfo .= Format("{}: {}`n", key, value)
                }
            }
            else {
                debugInfo .= "ImageRecognition: 不可用`n"
            }

            this.guiHwnd["DebugEdit"].Value := debugInfo

        }
        catch as e {
            this.logger.Error(Format("刷新调试信息失败: {}", e.Message))
        }
    }

    ShowError(title, message) {
        if (this.isVisible) {
            MsgBox(message, title, "IconX")
        }
        this.logger.Error(Format("{}: {}", title, message))
    }

    ShowInfo(title, message) {
        if (this.isVisible) {
            MsgBox(message, title, "IconI")
        }
        this.logger.Info(Format("{}: {}", title, message))
    }

    ShowWarning(title, message) {
        if (this.isVisible) {
            MsgBox(message, title, "Icon!")
        }
        this.logger.Warn(Format("{}: {}", title, message))
    }

    ShowSettings() {
        ; 显示设置窗口
        this.logger.Info("显示设置窗口")
        this.ShowInfo("设置", "设置功能开发中...")
    }

    ShowTaskManager() {
        ; 显示任务管理器
        this.logger.Info("显示任务管理器")
        this.ShowInfo("任务管理器", "任务管理器功能开发中...")
    }

    ShowLogViewer() {
        ; 显示日志查看器
        this.logger.Info("显示日志查看器")
        this.ShowInfo("日志查看器", "日志查看器功能开发中...")
    }

    ShowImageRecognitionTest() {
        ; 显示图像识别测试工具
        this.logger.Info("显示图像识别测试")
        this.ShowInfo("图像识别测试", "图像识别测试功能开发中...")
    }


    ShowHelp() {
        helpText :=
            (
                "《百战沙城自动化脚本》使用说明`n`n"
                "快捷键：`n"
                "F9  - 显示主界面`n"
                "F10 - 启动自动化`n"
                "F11 - 停止自动化`n"
                "F12 - 退出程序`n`n"
                "调试工具：`n"
                "在调试信息页面可以使用窗口检测测试功能`n"
                "帮助诊断游戏窗口识别问题`n`n"
                "窗口操作：`n"
                "点击右上角X按钮可最小化到托盘`n"
                "程序会自动更新游戏状态显示`n`n"
                "注意事项：`n"
                "1. 请确保 QQ 游戏盒子和《百战沙城》已正常运行`n"
                "2. 首次使用请先进行图像识别测试和校准`n"
                "3. 建议在测试环境中先试运行一段时间`n"
                "4. 如遇到问题请查看日志文件`n`n"
                "支持：`n"
                "如有问题请联系开发者或查看项目文档。"
            )
        MsgBox(helpText, "帮助", "0x40")
    }

    ShowAbout() {
        AppName := "百战沙城助手"
        AppVersion := "1.0.0"

        aboutText := Format("{} v{}`n"
            . "一个专为《百战沙城》游戏设计的自动化脚本工具。`n`n"
            . "技术栈：`n"
            . "    - AutoHotkey v2.0`n"
            . "    - GDI+ 图像处理`n"
            . "    - Interception 驱动支持`n`n"
            . "开发者：代码生成助手`n"
            . "项目主页：https://github.com/your-repo/bzzc-automation`n"
            . "© 2025 版权所有"
            , AppName, AppVersion)

        MsgBox(aboutText, "关于", "0x40")
    }

    RestartApp() {
        this.logger.Info("重启应用程序")
        global App
        App.Stop()
        Sleep(1000)
        Reload()  ; 在AutoHotkey v2.0中需要括号
    }

    Hide() {
        if (this.guiHwnd.Hwnd) {
            this.guiHwnd.Hide()
            this.isVisible := false
        }
    }

    ShowWindow() {
        if (this.guiHwnd.Hwnd) {
            this.guiHwnd.Show()
            this.isVisible := true
            ; 立即刷新所有状态
            this.RefreshAll()
            ; 立即更新一次游戏状态
            this.UpdateGameStatus()
        }
    }

    RefreshAll() {
        this.UpdateGameStatus()
        this.RefreshLogOutput()
        this.RefreshDebugInfo()
    }

    ; 事件处理方法
    OnRefreshTasks(*) {
        this.RefreshTaskList()
    }

    OnClearTasks(*) {
        ; 清空任务列表
        this.logger.Info("清空任务列表")
    }

    OnClearLog(*) {
        ; 清空日志显示
        this.guiHwnd["LogEdit"].Value := ""
    }

    OnSaveLog(*) {
        ; 保存日志到文件
        this.logger.Info("保存日志文件")
    }

    OnRefreshLog(*) {
        this.RefreshLogOutput()
    }

    OnRefreshDebug(*) {
        this.RefreshDebugInfo()
    }

    OnTestImageRecog(*) {
        this.ShowImageRecognitionTest()
    }

    OnTestWindowDetection(*) {
        ; 显示窗口检测对话框
        this.logger.Info("显示窗口检测对话框")

        try {
            ; 创建窗口检测对话框
            this.ShowWindowDetectionDialog()
        }
        catch as e {
            this.ShowError("窗口检测失败", e.Message)
        }
    }

    OnWildBossLevelChange(*) {
        ; 处理野外BOSS等级选择变化
        try {
            selectedLevel := this.guiHwnd["WildBossLevel"].Text
            this.logger.Info(Format("野外BOSS等级选择变化: {}", selectedLevel))

            ; 根据选择的等级更新地点选项
            this.UpdateWildBossLocationsByLevel(selectedLevel)

            ; 清空当前地点选择
            this.guiHwnd["WildBossLocation"].Text := ""
        }
        catch as e {
            this.logger.Error(Format("处理BOSS等级选择变化失败: {}", e.Message))
        }
    }

    UpdateWildBossLocationsByLevel(level) {
        ; 根据等级更新地点选项
        try {
            ; 尝试从全局配置获取地点数据
            locations := []

            ; 检查全局WildBossLocations是否存在
            if (IsSet(WildBossLocations) && WildBossLocations.Has(level)) {
                locations := WildBossLocations[level]
            }
            else {
                ; 从配置文件中获取地点数据
                locations := this.GetLocationsForLevel(level)
            }

            ; 清空现有选项并重新添加提示选项
            this.guiHwnd["WildBossLocation"].Delete()
            this.guiHwnd["WildBossLocation"].Add(["--请选择地点--"])

            ; 添加新选项
            if (locations.Length > 0) {
                for location in locations {
                    this.guiHwnd["WildBossLocation"].Add([location])
                }
                this.logger.Debug(Format("为等级 {} 更新了 {} 个地点选项", level, locations.Length))
            }
            else {
                this.guiHwnd["WildBossLocation"].Add(["无可选地点"])
                this.logger.Warn(Format("等级 {} 没有可用地点", level))
            }

            ; 设置第一个选项为默认选中（提示选项）
            this.guiHwnd["WildBossLocation"].Choose(1)
        }
        catch as e {
            this.logger.Error(Format("更新BOSS地点选项失败: {}", e.Message))
            this.ShowError("地点更新失败", "无法获取该等级的地点信息，请检查配置。")
        }
    }

    GetLocationsForLevel(level) {
        ; 获取指定等级的地点列表（模拟数据）
        ; 这个方法应该从配置文件中读取实际数据
        static locationMap := Map(
            "妖级", ["鬼翼神殿一层", "鬼翼神殿二层", "鬼翼神殿三层", "鬼翼神殿四层"],
            "魔级", ["鬼翼神殿一层", "鬼翼神殿二层", "鬼翼神殿三层", "鬼翼神殿四层"],
            "王级", ["鬼翼神殿一层", "鬼翼神殿二层", "鬼翼神殿三层", "鬼翼神殿四层"],
            "帝级", ["元组神殿一层", "元组神殿二层", "元组神殿三层", "诸神之家一层"],
            "仙级", ["元组神殿一层", "元组神殿二层", "元组神殿三层", "诸神之家一层"],
            "神级", ["元组神殿一层", "元组神殿二层", "元组神殿三层", "诸神之家一层"],
            "绝世级", ["血月峡谷一层", "血月峡谷二层", "血月峡谷三层", "封魔大殿一层"],
            "神圣级", ["血月峡谷一层", "血月峡谷二层", "血月峡谷三层", "封魔大殿一层"],
            "圣尊级", ["血月峡谷一层", "血月峡谷二层", "血月峡谷三层", "封魔大殿一层"],
            "主宰级", ["牛魔洞一层", "牛魔洞二层", "牛魔洞三层", "诸神之家二层"],
            "鸿蒙级", ["牛魔洞一层", "牛魔洞二层", "牛魔洞三层", "诸神之家二层"],
            "远古级", ["牛魔洞一层", "牛魔洞二层", "牛魔洞三层", "诸神之家二层"],
            "创世级", ["海底世界一层", "海底世界二层", "封魔大殿二层"],
            "洪荒级", ["海底世界一层", "海底世界二层", "封魔大殿二层"],
            "混沌级", ["海底世界一层", "海底世界二层", "封魔大殿二层"],
            "轮回级", ["魔龙城一层", "魔龙城二层", "诸神之家三层"],
            "渡厄级", ["魔龙城一层", "魔龙城二层", "诸神之家三层"],
            "寂灭级", ["魔龙城一层", "魔龙城二层", "诸神之家三层"],
            "时光级", ["冰封山脉一层", "冰封山脉二层", "封魔大殿三层"],
            "暗黑级", ["冰封山脉一层", "冰封山脉二层", "封魔大殿三层"],
            "禁忌级", ["冰封山脉一层", "冰封山脉二层", "封魔大殿三层"],
            "星辰级", ["烈焰谷一层", "烈焰谷二层", "诸神之家四层"],
            "曜日级", ["烈焰谷一层", "烈焰谷二层", "诸神之家四层"],
            "传世级", ["烈焰谷一层", "烈焰谷二层", "诸神之家四层"],
            "永恒级", ["火龙神殿一层", "火龙神殿二层", "封魔大殿四层"],
            "荣耀级", ["火龙神殿一层", "火龙神殿二层", "封魔大殿四层"],
            "万劫级", ["火龙神殿一层", "火龙神殿二层", "封魔大殿四层"],
            "诛仙级", ["绝龙岭一层", "绝龙岭二层"],
            "杀神级", ["绝龙岭一层", "绝龙岭二层"],
            "斗佛级", ["绝龙岭一层", "绝龙岭二层"],
            "炼魔级", ["死亡牢狱一层", "死亡牢狱二层"],
            "灭日级", ["死亡牢狱一层", "死亡牢狱二层"],
            "焚天级", ["死亡牢狱一层", "死亡牢狱二层"],
            "灭魔级", ["星空大陆一层", "星空大陆二层", "星空腹地"],
            "斩魔级", ["星空大陆一层", "星空大陆二层", "星空腹地"],
            "天人级", ["星空腹地"]
        )

        return locationMap.Has(level) ? locationMap[level] : []
    }

    ShowWindowDetectionDialog(*) {
        ; 创建窗口检测对话框
        dialogGui := Gui("+Resize +MinSize400x300", "游戏窗口检测")

        ; 添加说明文本
        dialogGui.Add("Text", "x10 y10 w380",
            "请选择您的游戏窗口。程序将列出所有检测到的候选窗口：")

        ; 创建ListView显示候选窗口
        LV := dialogGui.Add("ListView", "x10 y40 w380 h200",
            ["编号", "窗口标题", "类名", "进程名"])

        ; 获取候选窗口
        windows := WinGetList()
        candidateWindows := []
        rowNum := 0

        for hwnd in windows {
            try {
                title := WinGetTitle(hwnd)
                className := WinGetClass(hwnd)
                processName := WinGetProcessName(hwnd)

                ; 跳过自身窗口，收集游戏相关窗口
                if (!InStr(title, "百战沙城自动化") && !InStr(className, "AutoHotkeyGUI") &&
                    (InStr(title, "QQ游戏") || InStr(title, "百战沙城") || InStr(title, "百战沙场") ||
                        InStr(processName, "QQGame") || className = "GRootViewClass")) {

                    rowNum++
                    candidateWindows.Push(Map(
                        "hwnd", hwnd,
                        "title", title,
                        "class", className,
                        "process", processName
                    ))

                    ; 添加到ListView
                    LV.Add("", rowNum, title, className, processName)
                }
            }
            catch {
                continue
            }
        }

        if (candidateWindows.Length = 0) {
            dialogGui.Add("Text", "x10 y260 w380 cRed",
                "❌ 未找到游戏窗口！`n请确保QQ游戏盒子和《百战沙城》已正常运行。")
        }
        else {
            ; 添加操作按钮
            selectBtn := dialogGui.Add("Button", "x10 y260 w80", "选择")
            cancelBtn := dialogGui.Add("Button", "x100 y260 w80", "取消")
            refreshBtn := dialogGui.Add("Button", "x190 y260 w80", "刷新")

            ; 设置按钮事件
            selectBtn.OnEvent("Click", (*) => this.OnDialogSelect(LV, candidateWindows, dialogGui))
            cancelBtn.OnEvent("Click", (*) => dialogGui.Destroy())
            refreshBtn.OnEvent("Click", (*) => this.RefreshWindowList(dialogGui, LV, candidateWindows))
        }

        ; 显示对话框
        dialogGui.Show("w400 h300")
    }

    OnDialogSelect(LV, candidateWindows, dialogGui) {
        ; 处理用户选择的窗口
        selectedRow := LV.GetNext()
        if (selectedRow = 0) {
            MsgBox("请选择一个窗口！", "提示", "0x30")
            return
        }

        selectedWindow := candidateWindows[selectedRow]

        ; 确认选择
        infoText := Format("🎯 您选择了以下窗口：`n`n📋 窗口信息：`n窗口标题：{}`n窗口类名：{}`n进程名：{}`n窗口句柄：{}`n`n❓ 确认保存此配置？",
            selectedWindow["title"], selectedWindow["class"], selectedWindow["process"], selectedWindow["hwnd"])

        result := MsgBox(infoText, "确认游戏窗口", "YesNo")
        if (result = "Yes") {
            this.SaveGameWindowConfig(selectedWindow)
            this.ShowInfo("✅ 配置已保存", "游戏窗口配置已更新！`n`n请重新启动程序以应用新配置。")
            dialogGui.Destroy()
        }
    }

    RefreshWindowList(dialogGui, LV, candidateWindows) {
        ; 刷新窗口列表
        LV.Delete()
        candidateWindows := []

        windows := WinGetList()
        rowNum := 0

        for hwnd in windows {
            try {
                title := WinGetTitle(hwnd)
                className := WinGetClass(hwnd)
                processName := WinGetProcessName(hwnd)

                if (!InStr(title, "百战沙城自动化") && !InStr(className, "AutoHotkeyGUI") &&
                    (InStr(title, "QQ游戏") || InStr(title, "百战沙城") || InStr(title, "百战沙场") ||
                        InStr(processName, "QQGame") || className = "GRootViewClass")) {

                    rowNum++
                    candidateWindows.Push(Map(
                        "hwnd", hwnd,
                        "title", title,
                        "class", className,
                        "process", processName
                    ))

                    LV.Add("", rowNum, title, className, processName)
                }
            }
            catch {
                continue
            }
        }
    }

    TryAutoDetectGameWindow(*) {
        ; 尝试自动检测游戏窗口
        this.logger.Debug("尝试自动检测游戏窗口")

        try {
            ; 查找最可能的游戏窗口
            gameWindow := this.FindMostLikelyGameWindow()
            if (gameWindow) {
                infoText := Format("🎯 自动检测到游戏窗口！`n`n📋 窗口信息：`n窗口标题：{}`n窗口类名：{}`n进程名：{}`n窗口句柄：{}`n`n❓ 是否确认这是您的游戏窗口？",
                    gameWindow["title"], gameWindow["class"], gameWindow["process"], gameWindow["hwnd"])

                result := MsgBox(infoText, "确认游戏窗口", "YesNo")
                if (result = "Yes") {
                    this.SaveGameWindowConfig(gameWindow)
                    this.ShowInfo("✅ 配置已保存", "游戏窗口配置已更新！`n`n请重新启动程序以应用新配置。")
                    return true
                }
                else {
                    ; 用户否认，进入手动选择
                    return false
                }
            }
        }
        catch {
            ; 自动检测失败，继续手动选择
        }

        return false
    }

    FindMostLikelyGameWindow(*) {
        ; 查找最可能的游戏窗口
        windows := WinGetList()
        bestCandidate := ""
        bestScore := 0

        for hwnd in windows {
            try {
                title := WinGetTitle(hwnd)
                class := WinGetClass(hwnd)
                processName := WinGetProcessName(hwnd)

                ; 跳过自身窗口
                if (InStr(title, "百战沙城自动化") || InStr(class, "AutoHotkeyGUI")) {
                    continue
                }

                ; 计算匹配得分
                score := 0
                if (InStr(title, "QQ游戏")) score += 10
                    if (InStr(title, "百战沙城") || InStr(title, "百战沙场")) score += 20
                        if (InStr(processName, "QQGame")) score += 15
                            if (class = "GRootViewClass") score += 5
                                ; 如果是最高分，返回这个窗口
                                if (score > bestScore && score >= 5) {
                                    bestScore := score
                                    bestCandidate := Map(
                                        "hwnd", hwnd,
                                        "title", title,
                                        "class", class,
                                        "process", processName
                                    )
                                }
            }
            catch {
                continue
            }
        }

        return bestCandidate
    }

    ShowManualWindowSelection(*) {
        ; 显示手动选择界面
        this.logger.Info("显示手动窗口选择界面")

        ; 查找所有候选窗口
        windows := WinGetList()
        candidateWindows := []

        for hwnd in windows {
            try {
                title := WinGetTitle(hwnd)
                class := WinGetClass(hwnd)
                processName := WinGetProcessName(hwnd)

                ; 收集候选窗口（排除自身窗口）
                if (!InStr(title, "百战沙城自动化") && !InStr(class, "AutoHotkeyGUI") &&
                    (InStr(title, "QQ游戏") || InStr(title, "百战沙城") || InStr(title, "百战沙场") ||
                        InStr(processName, "QQGame") || class = "GRootViewClass")) {
                    candidateWindows.Push(Map(
                        "hwnd", hwnd,
                        "title", title,
                        "class", class,
                        "process", processName
                    ))
                }
            }
            catch {
                continue
            }
        }

        if (candidateWindows.Length = 0) {
            this.ShowWarning("❌ 未找到游戏窗口",
                "请确保：`n" .
                "✅ QQ游戏盒子已启动`n" .
                "✅ 《百战沙城》游戏已进入`n" .
                "✅ 游戏窗口未最小化`n`n" .
                "然后重新点击『窗口检测测试』按钮。")
            return
        }

        ; 创建选择菜单
        windowMenu := Menu()
        windowList := []

        for i, window in candidateWindows {
            windowList.Push(window)
            menuText := Format("&{}: {} ({})", i, window["title"], window["process"])

            ; 捕获当前索引值，避免闭包问题
            currentIndex := i
            windowMenu.Add(menuText, (*) => this.OnWindowSelected(windowList[currentIndex]))
        }

        windowMenu.Add()
        windowMenu.Add("&取消", (*) => "")

        ; 显示菜单
        windowMenu.Show()
    }

    OnWindowSelected(selectedWindow) {
        ; 处理用户选择的窗口
        try {
            infoText := Format("🎯 您选择了以下窗口：`n`n📋 窗口信息：`n窗口标题：{}`n窗口类名：{}`n进程名：{}`n窗口句柄：{}`n`n❓ 确认保存此配置？",
                selectedWindow["title"], selectedWindow["class"], selectedWindow["process"], selectedWindow["hwnd"])

            result := MsgBox(infoText, "确认游戏窗口", "YesNo")
            if (result = "Yes") {
                this.SaveGameWindowConfig(selectedWindow)
                this.ShowInfo("✅ 配置已保存", "游戏窗口配置已更新！`n`n请重新启动程序以应用新配置。")
            }
        }
        catch as e {
            this.ShowError("保存配置失败", e.Message)
        }
    }

    SaveGameWindowConfig(windowInfo) {
        try {
            ; 更新配置文件
            configPath := A_ScriptDir "\..\resources\config\config.ini"

            IniWrite(windowInfo["class"], configPath, "game", "window_class")
            IniWrite(windowInfo["title"], configPath, "game", "window_title")
            IniWrite(windowInfo["process"], configPath, "game", "process_name")

            this.logger.Info(Format("游戏窗口配置已保存: class={}, title={}, process={}",
                windowInfo["class"], windowInfo["title"], windowInfo["process"]))
        }
        catch as e {
            this.logger.Error(Format("保存游戏窗口配置失败: {}", e.Message))
            throw e
        }
    }

    TryLooseGameDetection(*) {
        ; 尝试更宽松的游戏检测条件
        try {
            windows := WinGetList()

            for hwnd in windows {
                try {
                    title := WinGetTitle(hwnd)
                    class := WinGetClass(hwnd)
                    processName := WinGetProcessName(hwnd)

                    ; 跳过自身窗口
                    if (InStr(title, "百战沙城自动化") || InStr(class, "AutoHotkeyGUI")) {
                        continue
                    }

                    ; 宽松条件：任何包含游戏相关关键词的窗口
                    if (InStr(title, "游戏") || InStr(title, "Game") ||
                        InStr(processName, "Game") || InStr(processName, "QQ") ||
                        InStr(class, "Game")) {
                        this.logger.Info(Format("宽松检测找到窗口: {} ({})", title, processName))
                        return true
                    }
                }
                catch {
                    continue
                }
            }
        }
        catch as e {
            this.logger.Error(Format("宽松检测失败: {}", e.Message))
        }

        return false
    }

    ; 按钮事件处理方法
    OnStartButton(*) {
        this.logger.Info("用户点击启动按钮")
        ToolTip("正在启动自动化...")
        ; 通过全局App变量调用Start方法
        global App
        App.Start()
        ToolTip("")
    }

    OnStopButton(*) {
        this.logger.Info("用户点击停止按钮")
        ToolTip("正在停止自动化...")
        global App
        App.Stop()
        ToolTip("")
    }

    OnExitButton(*) {
        this.logger.Info("用户点击退出按钮")
        ToolTip("正在退出程序...")
        global App
        App.Exit()
        ToolTip("")
    }

    ; 菜单事件处理方法
    OnStartMenu(*) {
        this.logger.Info("用户点击启动菜单")
        global App
        App.Start()
    }

    OnStopMenu(*) {
        this.logger.Info("用户点击停止菜单")
        global App
        App.Stop()
    }

    OnExitMenu(*) {
        this.logger.Info("用户点击退出菜单")
        global App
        App.Exit()
    }

    ; 托盘图标相关方法
    ShowTrayMenu() {
        ; 在AutoHotkey v2.0中，托盘菜单语法有所不同
        ; 暂时简化托盘功能，使用默认菜单
        A_IconTip := AppName
    }

    ; 清理资源
    Cleanup() {
        if (this.guiHwnd.Hwnd) {
            this.guiHwnd.Destroy()
        }
        this.isVisible := false
    }
}

; 注意：不再创建全局实例，由主程序统一管理
