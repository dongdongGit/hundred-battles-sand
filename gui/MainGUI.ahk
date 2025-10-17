/**
 * 主图形界面
 * 提供程序控制、状态监控、配置管理的图形界面
 */

class MainGUI {
    __New() {
        this.guiHwnd := 0
        this.isVisible := false
        this.statusText := ""
        this.logText := ""

        this.controlButtons := Map()
        this.statusLabels := Map()
        this.configControls := Map()
    }

    Show() {
        LoggerInstance.Info("显示主界面")

        try {
            ; 创建主窗口
            this.guiHwnd := Gui("+Resize +MinSize400x300", AppName " v" AppVersion)

            ; 设置字体
            this.guiHwnd.SetFont("s10", "Microsoft YaHei UI")

            ; 创建菜单栏
            this.CreateMenuBar()

            ; 创建工具栏
            this.CreateToolBar()

            ; 创建主内容区域
            this.CreateMainContent()

            ; 创建状态栏
            this.CreateStatusBar()

            ; 设置窗口事件处理
            this.SetupEventHandlers()

            ; 显示窗口
            this.guiHwnd.Show("w800 h600")
            this.isVisible := true

            ; 初始化状态
            this.UpdateStatus("就绪")

            LoggerInstance.Info("主界面显示完成")
        }
        catch as e {
            LoggerInstance.Error(Format("显示主界面失败: {}", e.Message))
            throw e
        }
    }

    CreateMenuBar() {
        ; 文件菜单
        fileMenu := Menu()
        fileMenu.Add("&启动程序", (*) => App.Start())
        fileMenu.Add("&停止程序", (*) => App.Stop())
        fileMenu.Add("&重启程序", (*) => this.RestartApp())
        fileMenu.Add()
        fileMenu.Add("&设置", (*) => this.ShowSettings())
        fileMenu.Add()
        fileMenu.Add("退出(&X)", (*) => App.Exit())

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

        this.guiHwnd.MenuBar := mainMenu
    }

    CreateToolBar() {
        toolbar := this.guiHwnd.Add("ToolBar", "wr")

        ; 添加工具按钮
        toolbar.Add("启动", "btn_start", "启动自动化")
        toolbar.Add("停止", "btn_stop", "停止自动化")
        toolbar.Add("设置", "btn_settings", "程序设置")

        this.controlButtons["start"] := "btn_start"
        this.controlButtons["stop"] := "btn_stop"
        this.controlButtons["settings"] := "btn_settings"
    }

    CreateMainContent() {
        ; 创建标签页控件
        tabControl := this.guiHwnd.Add("Tab3", "xm ym w780 h500", ["主控制", "任务状态", "日志输出", "调试信息"])

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
        gameGroup := this.guiHwnd.Add("GroupBox", "xm+10 ym+40 w360 h120", "游戏状态")

        this.guiHwnd.Add("Text", "xp+10 yp+20 w80 h20", "游戏窗口:")
        this.statusLabels["game_window"] := this.guiHwnd.Add("Text", "xp+90 yp w250 h20", "未检测")

        this.guiHwnd.Add("Text", "xp-90 yp+25 w80 h20", "游戏进程:")
        this.statusLabels["game_process"] := this.guiHwnd.Add("Text", "xp+90 yp w250 h20", "未运行")

        this.guiHwnd.Add("Text", "xp-90 yp+25 w80 h20", "连接状态:")
        this.statusLabels["connection"] := this.guiHwnd.Add("Text", "xp+90 yp w250 h20", "未连接")

        ; 任务控制组
        taskGroup := this.guiHwnd.Add("GroupBox", "xp+370 yp-85 w360 h120", "任务控制")

        this.guiHwnd.Add("CheckBox", "xp+10 yp+20 w100 h20 vEnableDailySignin", "每日签到")
        this.guiHwnd.Add("CheckBox", "xp+120 yp w100 h20 vEnableDailyTasks", "日常任务")
        this.guiHwnd.Add("CheckBox", "xp+240 yp w100 h20 vEnableHangup", "挂机刷元宝")

        this.guiHwnd.Add("CheckBox", "xp-360 yp+25 w100 h20 vEnableResource", "资源采集")
        this.guiHwnd.Add("CheckBox", "xp+120 yp w100 h20 vEnableEquipment", "装备强化")
        this.guiHwnd.Add("CheckBox", "xp+240 yp w100 h20 vEnableFriend", "好友互动")

        ; 控制按钮
        this.guiHwnd.Add("Button", "xm+10 yp+140 w80 h30 gOnStart", "启动")
        this.guiHwnd.Add("Button", "xp+90 yp w80 h30 gOnStop", "停止")
        this.guiHwnd.Add("Button", "xp+90 yp w80 h30 gOnSettings", "设置")
        this.guiHwnd.Add("Button", "xp+90 yp w80 h30 gOnExit", "退出")

        ; 进度条
        this.guiHwnd.Add("Text", "xm+10 yp+45 w80 h20", "执行进度:")
        this.guiHwnd.Add("Progress", "xp+90 yp w300 h20 vTaskProgress", 0)
        this.statusLabels["progress"] := "TaskProgress"
    }

    CreateTaskStatusTab() {
        this.guiHwnd.Add("ListView", "xm+10 ym+40 w740 h400 vTaskListView", ["任务名称", "状态", "进度", "开始时间", "耗时"])
        this.guiHwnd.Add("Button", "xm+10 yp+410 w80 h30 gOnRefreshTasks", "刷新")
        this.guiHwnd.Add("Button", "xp+90 yp w80 h30 gOnClearTasks", "清空")
    }

    CreateLogOutputTab() {
        this.guiHwnd.Add("Edit", "xm+10 ym+40 w740 h400 vLogEdit ReadOnly")
        this.guiHwnd.Add("Button", "xm+10 yp+410 w80 h30 gOnClearLog", "清空")
        this.guiHwnd.Add("Button", "xp+90 yp w80 h30 gOnSaveLog", "保存")
        this.guiHwnd.Add("Button", "xp+90 yp w80 h30 gOnRefreshLog", "刷新")
    }

    CreateDebugInfoTab() {
        this.guiHwnd.Add("Edit", "xm+10 ym+40 w740 h400 vDebugEdit ReadOnly")
        this.guiHwnd.Add("Button", "xm+10 yp+410 w80 h30 gOnRefreshDebug", "刷新")
        this.guiHwnd.Add("Button", "xp+90 yp w80 h30 gOnTestImageRecog", "图像识别测试")
    }

    CreateStatusBar() {
        ; 创建状态栏
        this.guiHwnd.Add("StatusBar")
        this.statusText := "就绪"
        this.guiHwnd[StatusBar].SetText(this.statusText)
    }

    SetupEventHandlers() {
        ; 窗口大小改变事件
        this.guiHwnd.OnEvent("Size", (*) => this.OnResize())

        ; 关闭事件
        this.guiHwnd.OnEvent("Close", (*) => this.OnClose())

        ; 按钮事件
        this.guiHwnd["OnStart"].OnEvent("Click", (*) => App.Start())
        this.guiHwnd["OnStop"].OnEvent("Click", (*) => App.Stop())
        this.guiHwnd["OnSettings"].OnEvent("Click", (*) => this.ShowSettings())
        this.guiHwnd["OnExit"].OnEvent("Click", (*) => App.Exit())
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
        if (ConfigInstance.GetBool("general", "minimize_to_tray")) {
            this.Hide()
        }
        else {
            App.Exit()
        }
    }

    RefreshLayout() {
        ; 刷新布局（根据窗口大小调整控件）
        LoggerInstance.Debug("刷新界面布局")
    }

    UpdateStatus(status) {
        this.statusText := status
        if (this.guiHwnd.Hwnd) {
            this.guiHwnd[StatusBar].SetText(status)
        }
    }

    UpdateGameStatus() {
        if (!this.isVisible) {
            return
        }

        try {
            ; 更新游戏窗口状态
            if (WindowManagerInstance.IsGameRunning()) {
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
            LoggerInstance.Error(Format("更新游戏状态失败: {}", e.Message))
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
            LoggerInstance.Error(Format("更新任务状态失败: {}", e.Message))
        }
    }

    RefreshTaskList() {
        ; 刷新任务列表（应该从任务管理器获取数据）
        LoggerInstance.Debug("刷新任务列表")
    }

    RefreshLogOutput() {
        if (!this.isVisible) {
            return
        }

        try {
            ; 从日志文件读取最新内容
            if (FileExist(LogFile)) {
                logContent := FileRead(LogFile, "UTF-8")
                this.guiHwnd["LogEdit"].Text := logContent
                ; 滚动到底部
                SendMessage(0x115, 7, 0, this.guiHwnd["LogEdit"].Hwnd)  ; WM_VSCROLL, SB_BOTTOM
            }
        }
        catch as e {
            LoggerInstance.Error(Format("刷新日志输出失败: {}", e.Message))
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
            windowInfo := WindowManagerInstance.GetDebugInfo()
            for key, value in windowInfo {
                debugInfo .= Format("{}: {}`n", key, value)
            }

            ; 图像识别信息
            debugInfo .= "`n=== 图像识别 ===`n"
            imageInfo := ImageRecognitionInstance.GetDebugInfo()
            for key, value in imageInfo {
                debugInfo .= Format("{}: {}`n", key, value)
            }

            this.guiHwnd["DebugEdit"].Text := debugInfo

        }
        catch as e {
            LoggerInstance.Error(Format("刷新调试信息失败: {}", e.Message))
        }
    }

    ShowError(title, message) {
        if (this.isVisible) {
            MsgBox(message, title, "IconX")
        }
        LoggerInstance.Error(Format("{}: {}", title, message))
    }

    ShowInfo(title, message) {
        if (this.isVisible) {
            MsgBox(message, title, "IconI")
        }
        LoggerInstance.Info(Format("{}: {}", title, message))
    }

    ShowWarning(title, message) {
        if (this.isVisible) {
            MsgBox(message, title, "Icon!")
        }
        LoggerInstance.Warn(Format("{}: {}", title, message))
    }

    ShowSettings() {
        ; 显示设置窗口
        LoggerInstance.Info("显示设置窗口")
        this.ShowInfo("设置", "设置功能开发中...")
    }

    ShowTaskManager() {
        ; 显示任务管理器
        LoggerInstance.Info("显示任务管理器")
        this.ShowInfo("任务管理器", "任务管理器功能开发中...")
    }

    ShowLogViewer() {
        ; 显示日志查看器
        LoggerInstance.Info("显示日志查看器")
        this.ShowInfo("日志查看器", "日志查看器功能开发中...")
    }

    ShowImageRecognitionTest() {
        ; 显示图像识别测试工具
        LoggerInstance.Info("显示图像识别测试")
        this.ShowInfo("图像识别测试", "图像识别测试功能开发中...")
    }

    ShowHelp() {
        ; 显示帮助文档
        helpText := "
《百战沙场自动化脚本》使用说明

快捷键：
F10 - 启动自动化
F11 - 停止自动化
F12 - 退出程序

注意事项：
1. 请确保QQ游戏盒子和《百战沙场》已正常运行
2. 首次使用请先进行图像识别测试和校准
3. 建议在测试环境中先试运行一段时间
4. 如遇到问题请查看日志文件

支持：
如有问题请联系开发者或查看项目文档。
        "
        MsgBox(helpText, "帮助", "0x40")
    }

    ShowAbout() {
        ; 显示关于信息
        aboutText := Format("
{} v{}

一个专为《百战沙场》游戏设计的自动化脚本工具。

技术栈：
- AutoHotkey v2.0
- GDI+图像处理
- Interception驱动支持

开发者：代码生成助手
项目主页：https://github.com/your-repo/bzzc-automation

© 2025 版权所有
        ", AppName, AppVersion)

        MsgBox(aboutText, "关于", "0x40")
    }

    RestartApp() {
        LoggerInstance.Info("重启应用程序")
        App.Stop()
        Sleep(1000)
        Reload()
    }

    Hide() {
        if (this.guiHwnd.Hwnd) {
            this.guiHwnd.Hide()
            this.isVisible := false
        }
    }

    Show() {
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
        LoggerInstance.Info("清空任务列表")
    }

    OnClearLog(*) {
        ; 清空日志显示
        this.guiHwnd["LogEdit"].Text := ""
    }

    OnSaveLog(*) {
        ; 保存日志到文件
        LoggerInstance.Info("保存日志文件")
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

    ; 托盘图标相关方法
    ShowTrayMenu() {
        trayMenu := A_TrayMenu
        trayMenu.Delete()
        trayMenu.Add("显示主界面", (*) => this.Show())
        trayMenu.Add("启动", (*) => App.Start())
        trayMenu.Add("停止", (*) => App.Stop())
        trayMenu.Add()
        trayMenu.Add("退出", (*) => App.Exit())

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

; 全局主GUI实例
global MainGUIInstance := MainGUI()