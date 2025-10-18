/**
 * 主图形界面
 * 提供程序控制、状态监控、配置管理的图形界面
 */

#Requires AutoHotkey v2.0

class MainGUI {
    __New(loggerInstance := "", configInstance := "") {
        ; 如果没有传入实例，使用全局实例（向后兼容）
        if (loggerInstance = "") {
            loggerInstance := LoggerInstance
        }
        if (configInstance = "") {
            configInstance := ConfigInstance
        }

        this.logger := loggerInstance
        this.config := configInstance

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
            this.guiHwnd := Gui("+Resize +MinSize400x300", AppName " v" AppVersion)

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
        gameGroup := this.guiHwnd.Add("GroupBox", "xm+10 ym+40 w360 h80", "游戏状态")

        this.guiHwnd.Add("Text", "xp+10 yp+20 w80 h20", "游戏窗口:")
        this.statusLabels["game_window"] := this.guiHwnd.Add("Text", "xp+90 yp w250 h20", "未检测")

        this.guiHwnd.Add("Text", "xp-90 yp+25 w80 h20", "游戏进程:")
        this.statusLabels["game_process"] := this.guiHwnd.Add("Text", "xp+90 yp w250 h20", "未运行")

        this.guiHwnd.Add("Text", "xp-90 yp+25 w80 h20", "连接状态:")
        this.statusLabels["connection"] := this.guiHwnd.Add("Text", "xp+90 yp w250 h20", "未连接")

        ; 任务控制组
        taskGroup := this.guiHwnd.Add("GroupBox", "xm+380 ym+40 w360 h80", "任务控制")

        this.guiHwnd.Add("CheckBox", "xp+10 yp+20 w100 h20 vEnableDailySignin", "每日签到")
        this.guiHwnd.Add("CheckBox", "xp+120 yp w100 h20 vEnableDailyTasks", "日常任务")
        this.guiHwnd.Add("CheckBox", "xp+240 yp w100 h20 vEnableHangup", "挂机刷元宝")

        this.guiHwnd.Add("CheckBox", "xp-360 yp+25 w100 h20 vEnableResource", "资源采集")
        this.guiHwnd.Add("CheckBox", "xp+120 yp w100 h20 vEnableEquipment", "装备强化")
        this.guiHwnd.Add("CheckBox", "xp+240 yp w100 h20 vEnableFriend", "好友互动")

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

        ; 其他标签页按钮事件
        this.refreshTasksBtn.OnEvent("Click", (*) => this.OnRefreshTasks())
        this.clearTasksBtn.OnEvent("Click", (*) => this.OnClearTasks())
        this.clearLogBtn.OnEvent("Click", (*) => this.OnClearLog())
        this.saveLogBtn.OnEvent("Click", (*) => this.OnSaveLog())
        this.refreshLogBtn.OnEvent("Click", (*) => this.OnRefreshLog())
        this.refreshDebugBtn.OnEvent("Click", (*) => this.OnRefreshDebug())
        this.testImageRecogBtn.OnEvent("Click", (*) => this.OnTestImageRecog())
    }

    OnResize() {
        ; 处理窗口大小改变
        if (this.guiHwnd.Hwnd) {
            ; 重新调整控件大小
            this.RefreshLayout()
        }
    }

    OnClose() {
        ; 隐藏窗口而不是关闭程序
        if (this.config.GetBool("general", "minimize_to_tray")) {
            this.Hide()
        }
        else {
            global App
            App.Exit()
        }
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
            ; 更新游戏窗口状态
            if (this.windowManager.IsGameRunning()) {
                this.guiHwnd["game_window"].Text := "已检测"
                this.guiHwnd["game_process"].Text := "运行中"
                this.guiHwnd["connection"].Text := "已连接"
            }
            else {
                this.guiHwnd["game_window"].Text := "未检测"
                this.guiHwnd["game_process"].Text := "未运行"
                this.guiHwnd["connection"].Text := "未连接"
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
            logFilePath := A_ScriptDir "\..\logs\app.log"
            if (FileExist(logFilePath)) {
                logContent := FileRead(logFilePath, "UTF-8")
                this.guiHwnd["LogEdit"].Text := logContent
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
            windowInfo := this.windowManager.GetDebugInfo()
            for key, value in windowInfo {
                debugInfo .= Format("{}: {}`n", key, value)
            }

            ; 图像识别信息
            debugInfo .= "`n=== 图像识别 ===`n"
            imageInfo := this.imageRecognition.GetDebugInfo()
            for key, value in imageInfo {
                debugInfo .= Format("{}: {}`n", key, value)
            }

            this.guiHwnd["DebugEdit"].Text := debugInfo

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
                "《百战沙场自动化脚本》使用说明`n`n"
                "快捷键：`n"
                "F10 - 启动自动化`n"
                "F11 - 停止自动化`n"
                "F12 - 退出程序`n`n"
                "注意事项：`n"
                "1. 请确保 QQ 游戏盒子和《百战沙场》已正常运行`n"
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
            . "一个专为《百战沙场》游戏设计的自动化脚本工具。`n`n"
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
            this.RefreshAll()
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
        this.guiHwnd["LogEdit"].Text := ""
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

    ; 按钮事件处理方法
    OnStartButton(*) {
        this.logger.Info("用户点击启动按钮")
        ; 通过全局App变量调用Start方法
        global App
        App.Start()
    }

    OnStopButton(*) {
        this.logger.Info("用户点击停止按钮")
        global App
        App.Stop()
    }

    OnExitButton(*) {
        this.logger.Info("用户点击退出按钮")
        global App
        App.Exit()
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
