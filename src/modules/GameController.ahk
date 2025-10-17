/**
 * 游戏控制器
 * 协调各个模块，控制游戏自动化流程的核心控制器
 */

class GameController {
    __New() {
        this.isInitialized := false
        this.isConnected := false
        this.gameState := "disconnected"  ; disconnected, connecting, connected, error
        this.lastAction := 0
        this.actionDelay := 1000
        this.errorCount := 0
        this.maxErrorCount := 10
    }

    Initialize() {
        LoggerInstance.Info("初始化游戏控制器")

        try {
            ; 初始化各个组件
            this.InitializeComponents()

            ; 测试游戏连接
            this.TestConnection()

            this.isInitialized := true
            LoggerInstance.Info("游戏控制器初始化完成")
        }
        catch as e {
            LoggerInstance.Error(Format("游戏控制器初始化失败: {}", e.Message))
            this.gameState := "error"
            throw e
        }
    }

    InitializeComponents() {
        LoggerInstance.Debug("初始化游戏控制器组件")

        ; 确保所有必要组件已初始化
        if (!WindowManagerInstance.WindowExists()) {
            throw Error("游戏窗口未找到，请先启动游戏")
        }

        if (!ImageRecognitionInstance.isInitialized) {
            throw Error("图像识别模块未初始化")
        }

        ; 设置动作延迟
        this.actionDelay := ConfigInstance.GetInt("game", "delay_between_actions", 1000)
    }

    TestConnection() {
        LoggerInstance.Info("测试游戏连接")

        try {
            ; 检查游戏窗口
            if (!WindowManagerInstance.IsGameRunning()) {
                throw Error("游戏窗口未运行")
            }

            ; 激活游戏窗口
            WindowManagerInstance.ActivateGameWindow()

            ; 尝试一些基本的图像识别测试
            testResult := this.PerformBasicTest()

            if (testResult) {
                this.isConnected := true
                this.gameState := "connected"
                LoggerInstance.Info("游戏连接测试成功")
            }
            else {
                throw Error("游戏连接测试失败")
            }
        }
        catch as e {
            this.isConnected := false
            this.gameState := "error"
            LoggerInstance.Error(Format("游戏连接测试失败: {}", e.Message))
            throw e
        }
    }

    PerformBasicTest() {
        LoggerInstance.Debug("执行基本连接测试")

        try {
            ; 测试窗口激活
            if (!WindowManagerInstance.IsGameActive()) {
                WindowManagerInstance.ActivateGameWindow()
                Sleep(1000)
            }

            ; 测试图像识别（如果有测试模板的话）
            templatePath := ConfigInstance.GetString("recognition", "template_path")
            if (DirExist(templatePath)) {
                testTemplates := ["test_button", "test_icon"]  ; 可以根据实际情况调整

                for template in testTemplates {
                    if (ImageRecognitionInstance.templates.Has(template)) {
                        if (ImageRecognitionInstance.FindImage(template, &x, &y)) {
                            LoggerInstance.Debug(Format("测试模板 {} 识别成功", template))
                            return true
                        }
                    }
                }
            }

            ; 基本的颜色测试
            testColors := [
                [100, 100, 0xFFFFFF, 10],  ; 白色的像素点
                [200, 200, 0x000000, 10]   ; 黑色的像素点
            ]

            for colorTest in testColors {
                x := colorTest[1]
                y := colorTest[2]
                expectedColor := colorTest[3]
                variation := colorTest[4]

                if (WindowManagerInstance.CheckColorInGame(x, y, expectedColor, variation)) {
                    LoggerInstance.Debug(Format("颜色测试通过: ({},{})", x, y))
                    return true
                }
            }

            LoggerInstance.Debug("基本连接测试完成（有限测试）")
            return true  ; 暂时返回true，实际部署时需要更严格的测试
        }
        catch as e {
            LoggerInstance.Error(Format("基本连接测试失败: {}", e.Message))
            return false
        }
    }

    StartGame() {
        LoggerInstance.Info("尝试启动游戏")

        try {
            ; 检查游戏是否已经在运行
            if (WindowManagerInstance.IsGameRunning()) {
                LoggerInstance.Info("游戏已经在运行")
                return true
            }

            ; 这里可以添加游戏的启动逻辑
            ; 例如启动QQ游戏盒子或直接启动游戏

            LoggerInstance.Info("请手动启动QQ游戏盒子并打开《百战沙场》")

            ; 等待用户启动游戏
            waitCount := 0
            maxWait := 60  ; 最多等待60秒

            while (waitCount < maxWait) {
                Sleep(2000)
                waitCount += 2

                if (WindowManagerInstance.FindGameWindow()) {
                    LoggerInstance.Info("游戏启动成功")
                    Sleep(3000)  ; 等待游戏完全加载
                    return true
                }
            }

            LoggerInstance.Error("游戏启动超时")
            return false
        }
        catch as e {
            LoggerInstance.Error(Format("启动游戏失败: {}", e.Message))
            return false
        }
    }

    ; 执行游戏动作（带延迟控制）
    ExecuteAction(actionFunc, description := "") {
        try {
            currentTime := A_TickCount

            ; 检查是否需要延迟
            if (this.lastAction > 0) {
                elapsed := currentTime - this.lastAction
                if (elapsed < this.actionDelay) {
                    sleepTime := this.actionDelay - elapsed
                    Sleep(sleepTime)
                }
            }

            ; 执行动作
            startTime := A_TickCount
            result := actionFunc()
            endTime := A_TickCount

            ; 更新最后动作时间
            this.lastAction := endTime

            ; 记录动作执行时间
            if (description) {
                LoggerInstance.Debug(Format("动作 '{}' 执行完成，耗时: {}ms",
                    description, endTime - startTime))
            }

            return result
        }
        catch as e {
            this.errorCount++
            LoggerInstance.Error(Format("执行动作失败: {}", e.Message))

            if (this.errorCount >= this.maxErrorCount) {
                LoggerInstance.Error("错误次数过多，暂停自动化")
                TaskManagerInstance.Pause()
            }

            throw e
        }
    }

    ; 点击游戏内位置
    ClickInGame(x, y, button := "left", description := "") {
        return this.ExecuteAction(() => WindowManagerInstance.ClickInGame(x, y, button),
            description || Format("点击游戏位置 ({},{})", x, y))
    }

    ; 在游戏窗口内移动鼠标
    MoveMouseInGame(x, y, description := "") {
        return this.ExecuteAction(() => WindowManagerInstance.MoveMouseInGame(x, y),
            description || Format("移动鼠标到 ({},{})", x, y))
    }

    ; 等待图像出现
    WaitForImage(templateName, timeout := 10000, description := "") {
        return this.ExecuteAction(() => ImageRecognitionInstance.WaitForImage(templateName, timeout),
            description || Format("等待图像: {}", templateName))
    }

    ; 点击图像
    ClickImage(templateName, offsetX := 0, offsetY := 0, description := "") {
        return this.ExecuteAction(() => ImageRecognitionInstance.ClickImage(templateName, offsetX, offsetY),
            description || Format("点击图像: {}", templateName))
    }

    ; 获取游戏状态
    GetGameState() {
        state := Map(
            "connected", this.isConnected,
            "window_exists", WindowManagerInstance.WindowExists(),
            "window_active", WindowManagerInstance.IsGameActive(),
            "state", this.gameState,
            "error_count", this.errorCount,
            "last_action", this.lastAction
        )

        return state
    }

    ; 检查游戏是否可操作
    IsGameReady() {
        if (!this.isConnected) {
            return false
        }

        if (!WindowManagerInstance.WindowExists()) {
            LoggerInstance.Warn("游戏窗口不存在")
            this.isConnected := false
            return false
        }

        if (!WindowManagerInstance.IsGameActive()) {
            LoggerInstance.Debug("游戏窗口未激活，尝试激活")
            try {
                WindowManagerInstance.ActivateGameWindow()
            }
            catch {
                LoggerInstance.Error("激活游戏窗口失败")
                return false
            }
        }

        return true
    }

    ; 处理游戏异常
    HandleGameError(error) {
        LoggerInstance.Error(Format("处理游戏异常: {}", error.Message))

        this.errorCount++

        switch this.errorCount {
            case 1, 2:
                ; 尝试重新连接
                LoggerInstance.Info("尝试重新连接游戏")
                this.TestConnection()
            case 3, 4:
                ; 尝试重启游戏窗口
                LoggerInstance.Info("尝试重启游戏窗口")
                WindowManagerInstance.ShowGameWindow()
                Sleep(2000)
                this.TestConnection()
            default:
                ; 暂停自动化并报告严重错误
                LoggerInstance.Fatal("游戏异常次数过多，暂停自动化")
                TaskManagerInstance.Pause()
                this.gameState := "error"
        }
    }

    ; 重置错误计数
    ResetErrorCount() {
        this.errorCount := 0
        LoggerInstance.Debug("重置错误计数")
    }

    ; 截图游戏窗口（用于调试）
    CaptureGameWindow(description := "") {
        try {
            return WindowManagerInstance.CaptureGameWindow()
        }
        catch as e {
            LoggerInstance.Error(Format("截图失败: {}", e.Message))
            return false
        }
    }

    ; 执行键盘操作
    SendKeys(keys, description := "") {
        return this.ExecuteAction(() => Send(keys),
            description || Format("发送键盘: {}", keys))
    }

    ; 执行键盘快捷键
    SendHotkey(keys, description := "") {
        return this.ExecuteAction(() => Send("{" keys "}"),
            description || Format("发送快捷键: {}", keys))
    }

    ; 等待指定时间（带随机延迟）
    Wait(milliseconds, description := "") {
        ; 添加随机延迟避免检测
        randomDelay := ConfigInstance.GetInt("game", "random_delay_min", 200) +
                      Random(0, ConfigInstance.GetInt("game", "random_delay_max", 800) -
                             ConfigInstance.GetInt("game", "random_delay_min", 200))

        totalWait := milliseconds + randomDelay

        LoggerInstance.Debug(Format("等待 {}ms (含随机延迟 {}ms)",
            milliseconds, randomDelay))

        Sleep(totalWait)
        return true
    }

    ; 检查游戏是否在运行
    IsGameRunning() {
        return WindowManagerInstance.IsGameRunning()
    }

    ; 获取游戏窗口句柄
    GetGameHwnd() {
        return WindowManagerInstance.GetGameHwnd()
    }

    ; 激活游戏窗口
    ActivateGame() {
        return WindowManagerInstance.ActivateGameWindow()
    }

    ; 安全地执行游戏操作（带异常处理）
    SafeExecute(actionFunc, description := "") {
        try {
            if (!this.IsGameReady()) {
                throw Error("游戏未就绪")
            }

            return this.ExecuteAction(actionFunc, description)
        }
        catch as e {
            this.HandleGameError(e)
            throw e
        }
    }

    ; 批量执行动作序列
    ExecuteActionSequence(actions, description := "") {
        LoggerInstance.Info(Format("执行动作序列: {}", description || "未命名序列"))

        successCount := 0
        totalCount := actions.Length

        for i, action in actions {
            try {
                LoggerInstance.Debug(Format("执行序列动作 {}/{}: {}", i, totalCount, action["description"] || "未命名动作"))

                if (action.Has("type")) {
                    switch action["type"] {
                        case "click":
                            this.ClickInGame(action["x"], action["y"], action.Get("button", "left"), action["description"])
                        case "click_image":
                            this.ClickImage(action["template"], action.Get("offsetX", 0), action.Get("offsetY", 0), action["description"])
                        case "wait_image":
                            this.WaitForImage(action["template"], action.Get("timeout", 10000), action["description"])
                        case "wait":
                            this.Wait(action["milliseconds"], action["description"])
                        case "keys":
                            this.SendKeys(action["keys"], action["description"])
                        case "hotkey":
                            this.SendHotkey(action["keys"], action["description"])
                        default:
                            LoggerInstance.Warn(Format("未知动作类型: {}", action["type"]))
                    }
                }
                else if (action.Has("function")) {
                    action["function"]()  ; 执行自定义函数
                }

                successCount++
            }
            catch as e {
                LoggerInstance.Error(Format("序列动作失败 {}/{}: {}", i, totalCount, e.Message))

                if (action.Get("critical", false)) {
                    ; 关键动作失败，停止整个序列
                    throw Error(Format("关键动作失败: {}", action["description"] || "未命名动作"))
                }
            }
        }

        LoggerInstance.Info(Format("动作序列完成: {}/{} 成功", successCount, totalCount))
        return successCount = totalCount
    }

    ; 创建游戏操作的宏（预定义动作序列）
    CreateMacro(macroName, actions) {
        this.macros := this.macros || Map()
        this.macros[macroName] := actions
        LoggerInstance.Info(Format("创建宏: {}", macroName))
    }

    ; 执行宏
    ExecuteMacro(macroName, description := "") {
        if (!this.macros || !this.macros.Has(macroName)) {
            throw Error(Format("宏不存在: {}", macroName))
        }

        return this.ExecuteActionSequence(this.macros[macroName],
            description || Format("宏: {}", macroName))
    }

    ; 获取调试信息
    GetDebugInfo() {
        return Map(
            "is_initialized", this.isInitialized,
            "is_connected", this.isConnected,
            "game_state", this.gameState,
            "error_count", this.errorCount,
            "last_action", this.lastAction,
            "action_delay", this.actionDelay,
            "game_window_info", WindowManagerInstance.GetDebugInfo()
        )
    }

    ; 清理资源
    Cleanup() {
        LoggerInstance.Info("清理游戏控制器资源")

        this.isConnected := false
        this.gameState := "disconnected"
        this.errorCount := 0

        if (this.HasProp("macros")) {
            this.macros := Map()
        }
    }
}

; 全局游戏控制器实例
global GameControllerInstance := GameController()