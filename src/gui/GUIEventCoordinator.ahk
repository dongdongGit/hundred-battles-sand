/**
 * GUI事件协调器
 * 负责协调GUI事件和业务逻辑的调用，遵循单一职责原则
 */

#Requires AutoHotkey v2.0

class GUIEventCoordinator {
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

        ; 创建业务逻辑实例
        this.businessLogic := GUIBusinessLogic(this.logger, this.config)
        this.windowDetectionHandler := WindowDetectionHandler(this.logger, this.config)

        ; GUI引用（将在SetGUI方法中设置）
        this.guiHwnd := 0
        this.isVisible := false
    }

    /**
     * 设置GUI引用
     */
    SetGUI(guiInstance) {
        this.guiInstance := guiInstance
        this.guiHwnd := guiInstance.guiHwnd
        this.isVisible := guiInstance.isVisible
    }

    /**
     * 处理窗口大小改变事件
     */
    OnResize() {
        ; 处理窗口大小改变
        if (this.guiHwnd.Hwnd) {
            ; 重新调整控件大小
            this.RefreshLayout()
        }
    }

    /**
     * 处理窗口关闭事件
     */
    OnClose() {
        ; 点击右上角x按钮时最小化窗口而不是退出程序
        this.logger.Info("用户点击关闭按钮，最小化窗口到托盘")
        this.Hide()

        ; 显示托盘提示
        TrayTip("程序已最小化到托盘", "百战沙城自动化", 0x1)

        ; 如果需要完全退出，可以右键托盘图标选择退出
        ; 或者使用快捷键 Ctrl+Shift+Q 退出程序
    }

    /**
     * 刷新布局
     */
    RefreshLayout() {
        ; 刷新布局（根据窗口大小调整控件）
        this.logger.Debug("刷新界面布局")
    }

    /**
     * 更新游戏状态
     */
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
                if (this.businessLogic.TryLooseGameDetection()) {
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

    /**
     * 更新任务状态
     */
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

    /**
     * 刷新任务列表
     */
    RefreshTaskList() {
        ; 刷新任务列表（应该从任务管理器获取数据）
        this.logger.Debug("刷新任务列表")
    }

    /**
     * 刷新日志输出
     */
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

    /**
     * 刷新调试信息
     */
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

    /**
     * 处理启动按钮点击
     */
    OnStartButton() {
        this.logger.Info("用户点击启动按钮")
        ToolTip("正在启动自动化...")
        ; 通过全局App变量调用Start方法
        global App
        App.Start()
        ToolTip("")
    }

    /**
     * 处理停止按钮点击
     */
    OnStopButton() {
        this.logger.Info("用户点击停止按钮")
        ToolTip("正在停止自动化...")
        global App
        App.Stop()
        ToolTip("")
    }

    /**
     * 处理退出按钮点击
     */
    OnExitButton() {
        this.logger.Info("用户点击退出按钮")
        ToolTip("正在退出程序...")
        global App
        App.Exit()
        ToolTip("")
    }

    /**
     * 处理BOSS等级选择变化
     */
    OnWildBossLevelChange() {
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

    /**
     * 更新BOSS地点选项
     */
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
                locations := this.businessLogic.GetLocationsForLevel(level)
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
            MsgBox("无法获取该等级的地点信息，请检查配置。", "地点更新失败", "Icon!")
        }
    }

    /**
     * 显示设置窗口
     */
    ShowSettings() {
        ; 显示设置窗口
        this.logger.Info("显示设置窗口")
        MsgBox("设置功能开发中...", "设置", "IconI")
    }

    /**
     * 显示任务管理器
     */
    ShowTaskManager() {
        ; 显示任务管理器
        this.logger.Info("显示任务管理器")
        MsgBox("任务管理器功能开发中...", "任务管理器", "IconI")
    }

    /**
     * 显示日志查看器
     */
    ShowLogViewer() {
        ; 显示日志查看器
        this.logger.Info("显示日志查看器")
        MsgBox("日志查看器功能开发中...", "日志查看器", "IconI")
    }

    /**
     * 显示图像识别测试工具
     */
    ShowImageRecognitionTest() {
        ; 显示图像识别测试工具
        this.logger.Info("显示图像识别测试")
        MsgBox("图像识别测试功能开发中...", "图像识别测试", "IconI")
    }

    /**
     * 显示窗口检测测试
     */
    OnTestWindowDetection() {
        ; 显示窗口检测对话框
        this.logger.Info("显示窗口检测对话框")
        this.windowDetectionHandler.ShowWindowDetectionDialog()
    }

    /**
     * 处理刷新任务按钮
     */
    OnRefreshTasks() {
        this.RefreshTaskList()
    }

    /**
     * 处理清空任务按钮
     */
    OnClearTasks() {
        ; 清空任务列表
        this.logger.Info("清空任务列表")
    }

    /**
     * 处理清空日志按钮
     */
    OnClearLog() {
        ; 清空日志显示
        this.guiHwnd["LogEdit"].Value := ""
    }

    /**
     * 处理保存日志按钮
     */
    OnSaveLog() {
        ; 保存日志到文件
        this.logger.Info("保存日志文件")
    }

    /**
     * 处理刷新日志按钮
     */
    OnRefreshLog() {
        this.RefreshLogOutput()
    }

    /**
     * 处理刷新调试信息按钮
     */
    OnRefreshDebug() {
        this.RefreshDebugInfo()
    }

    /**
     * 处理测试图像识别按钮
     */
    OnTestImageRecog() {
        this.ShowImageRecognitionTest()
    }

    /**
     * 显示帮助信息
     */
    ShowHelp() {
        this.businessLogic.ShowHelp()
    }

    /**
     * 显示关于信息
     */
    ShowAbout() {
        this.businessLogic.ShowAbout()
    }

    /**
     * 重启应用程序
     */
    RestartApp() {
        this.businessLogic.RestartApp()
    }

    /**
     * 隐藏窗口
     */
    Hide() {
        if (this.guiHwnd.Hwnd) {
            this.guiHwnd.Hide()
            this.isVisible := false
        }
    }

    /**
     * 显示窗口
     */
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

    /**
     * 刷新所有状态
     */
    RefreshAll() {
        this.UpdateGameStatus()
        this.RefreshLogOutput()
        this.RefreshDebugInfo()
    }
}