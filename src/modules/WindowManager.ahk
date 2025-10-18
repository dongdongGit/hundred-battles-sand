/**
 * 窗口管理器
 * 专门处理QQ游戏盒子和游戏窗口的识别、控制和管理
 */

#Requires AutoHotkey v2.0

class WindowManager {
    __New(configInstance := "", loggerInstance := "") {
        ; 如果没有传入配置实例，使用全局实例（向后兼容）
        if (configInstance = "") {
            configInstance := ConfigInstance
        }
        if (loggerInstance = "") {
            loggerInstance := this.logger
        }

        this.config := configInstance
        this.logger := loggerInstance

        this.gameWindowClass := this.config.GetString("game", "window_class")
        this.gameWindowTitle := this.config.GetString("game", "window_title")
        this.gameProcessName := this.config.GetString("game", "process_name")

        this.gameHwnd := 0
        this.gamePid := 0
        this._isGameActive := false
        this.windowInfo := Map()

        this.retryCount := 3
        this.retryDelay := 1000
    }

    ; Getter
    IsGameActive() {
        return this._isGameActive && WinActive("ahk_id " this.gameHwnd)
    }

    ; Setter
    SetGameActive(value) {
        this._isGameActive := value
    }

    Initialize() {
        this.logger.Info("初始化窗口管理器")

        ; 查找游戏窗口
        this.FindGameWindow()

        if (this.gameHwnd) {
            this.GetWindowInfo()
            this.logger.Info(Format("游戏窗口已找到: hwnd={}", this.gameHwnd))
        }
        else {
            this.logger.Warn("游戏窗口未找到，将在需要时自动查找")
        }
    }

    FindGameWindow() {
        this.logger.Debug("查找游戏窗口")

        ; 方法1：通过窗口类名查找
        this.gameHwnd := WinExist("ahk_class " this.gameWindowClass)

        if (this.gameHwnd) {
            this.logger.Debug("通过窗口类名找到游戏窗口")
            return true
        }

        ; 方法2：通过精确窗口标题查找
        this.gameHwnd := WinExist(this.gameWindowTitle)

        if (this.gameHwnd) {
            this.logger.Debug("通过精确窗口标题找到游戏窗口")
            return true
        }

        ; 方法3：通过关键词查找窗口标题
        gameHwnd := 0
        try {
            windows := WinGetList()
            for hwnd in windows {
                try {
                    title := WinGetTitle(hwnd)
                    class := WinGetClass(hwnd)

                    ; 检查是否是游戏相关窗口
                    if (class = this.gameWindowClass
                        || InStr(title, "百战沙城")
                        || InStr(title, "百战沙场")
                        || InStr(title, "QQ游戏")
                        || InStr(title, "游戏盒子")) {
                        gameHwnd := hwnd
                        break
                    }
                }
                catch {
                    continue
                }
            }
        }

        if (gameHwnd) {
            this.gameHwnd := gameHwnd
            this.logger.Debug("通过关键词枚举找到游戏窗口")
            return true
        }

        ; 方法4：查找游戏进程
        if (this.FindGameProcess()) {
            ; 等待窗口出现
            loop this.retryCount {
                Sleep(this.retryDelay)

                ; 先尝试类名查找
                this.gameHwnd := WinExist("ahk_class " this.gameWindowClass)
                if (this.gameHwnd) {
                    this.logger.Debug("通过进程等待找到游戏窗口（类名）")
                    return true
                }

                ; 再尝试关键词查找
                windows := WinGetList()
                for hwnd in windows {
                    try {
                        title := WinGetTitle(hwnd)
                        class := WinGetClass(hwnd)

                        ; 检查是否是游戏相关窗口
                        if (class = this.gameWindowClass
                            || InStr(title, "百战沙城")
                            || InStr(title, "百战沙场")
                            || InStr(title, "QQ游戏")
                            || InStr(title, "游戏盒子")) {
                            this.gameHwnd := hwnd
                            break
                        }
                    }
                    catch {
                        continue
                    }
                }

                if (this.gameHwnd) {
                    this.logger.Debug("通过进程等待找到游戏窗口（关键词）")
                    return true
                }
            }
        }

        this.logger.Warn("未找到游戏窗口")
        return false
    }

    FindGameProcess() {
        this.logger.Debug("查找游戏进程")

        try {
            ; 通过进程名查找
            pids := []
            for pid in ComObjGet("winmgmts:").ExecQuery(
                "SELECT ProcessId FROM Win32_Process WHERE Name='" this.gameProcessName "'"
            ) {
                pids.Push(pid.ProcessId)
            }

            if (pids.Length > 0) {
                this.gamePid := pids[1]  ; 取第一个进程
                this.logger.Debug(Format("找到游戏进程: pid={}", this.gamePid))
                return true
            }
        }
        catch as e {
            this.logger.Error(Format("查找游戏进程失败: {}", e.Message))
        }

        return false
    }

    GetWindowInfo() {
        if (!this.gameHwnd) {
            return false
        }

        try {
            ; 获取窗口基本信息
            this.windowInfo["title"] := WinGetTitle(this.gameHwnd)
            this.windowInfo["class"] := WinGetClass(this.gameHwnd)
            this.windowInfo["processName"] := WinGetProcessName(this.gameHwnd)
            this.windowInfo["processPath"] := WinGetProcessPath(this.gameHwnd)
            this.windowInfo["isVisible"] := WinGetStyle(this.gameHwnd) & 0x10000000  ; WS_VISIBLE
            this.windowInfo["isMinimized"] := WinGetMinMax(this.gameHwnd) = -1

            ; 获取窗口位置和大小
            rect := Buffer(16)
            DllCall("GetWindowRect", "Ptr", this.gameHwnd, "Ptr", rect)

            this.windowInfo["x"] := NumGet(rect, 0, "Int")
            this.windowInfo["y"] := NumGet(rect, 4, "Int")
            this.windowInfo["width"] := NumGet(rect, 8, "Int") - NumGet(rect, 0, "Int")
            this.windowInfo["height"] := NumGet(rect, 12, "Int") - NumGet(rect, 4, "Int")

            ; 获取客户端区域
            clientRect := Buffer(16)
            DllCall("GetClientRect", "Ptr", this.gameHwnd, "Ptr", clientRect)

            this.windowInfo["clientWidth"] := NumGet(clientRect, 8, "Int")
            this.windowInfo["clientHeight"] := NumGet(clientRect, 12, "Int")

            return true
        }
        catch as e {
            this.logger.Error(Format("获取窗口信息失败: {}", e.Message))
            return false
        }
    }

    IsGameRunning() {
        if (this.gameHwnd && WinExist("ahk_id " this.gameHwnd)) {
            return true
        }

        ; 重新查找窗口
        return this.FindGameWindow()
    }

    ActivateGameWindow() {
        if (!this.IsGameRunning()) {
            throw Error("游戏窗口未运行")
        }

        try {
            ; 激活窗口
            WinActivate(this.gameHwnd)
            WinWaitActive(this.gameHwnd, , 5)

            ; 确保窗口在前台
            if (WinActive("A") != this.gameHwnd) {
                DllCall("SetForegroundWindow", "Ptr", this.gameHwnd)
            }

            this.SetGameActive(true)
            this.logger.Debug("游戏窗口已激活")
            return true
        }
        catch as e {
            this.logger.Error(Format("激活游戏窗口失败: {}", e.Message))
            this.SetGameActive(false)
            throw e
        }
    }

    MinimizeGameWindow() {
        if (!this.gameHwnd) {
            return false
        }

        try {
            WinMinimize(this.gameHwnd)
            this.SetGameActive(false)
            this.logger.Debug("游戏窗口已最小化")
            return true
        }
        catch as e {
            this.logger.Error(Format("最小化游戏窗口失败: {}", e.Message))
            return false
        }
    }

    MaximizeGameWindow() {
        if (!this.gameHwnd) {
            return false
        }

        try {
            WinMaximize(this.gameHwnd)
            this.SetGameActive(true)
            this.logger.Debug("游戏窗口已最大化")
            return true
        }
        catch as e {
            this.logger.Error(Format("最大化游戏窗口失败: {}", e.Message))
            return false
        }
    }

    HideGameWindow() {
        if (!this.gameHwnd) {
            return false
        }

        try {
            WinHide(this.gameHwnd)
            this.SetGameActive(false)
            this.logger.Debug("游戏窗口已隐藏")
            return true
        }
        catch as e {
            this.logger.Error(Format("隐藏游戏窗口失败: {}", e.Message))
            return false
        }
    }

    ShowGameWindow() {
        if (!this.gameHwnd) {
            return false
        }

        try {
            WinShow(this.gameHwnd)
            Sleep(500)  ; 等待窗口显示
            this.SetGameActive(true)
            this.logger.Debug("游戏窗口已显示")
            return true
        }
        catch as e {
            this.logger.Error(Format("显示游戏窗口失败: {}", e.Message))
            return false
        }
    }

    ; 以下保持原有方法逻辑，只是读取 _isGameActive 时用 IsGameActive()，赋值时用 SetGameActive()
    ; CaptureGameWindow, ClickInGame, MoveMouseInGame, GetColorInGame, CheckColorInGame, ColorsMatch, WaitForColorInGame, WaitForColorGoneInGame
    ; 省略重复，逻辑不变

    ; 获取游戏窗口句柄
    GetGameHwnd() {
        return this.gameHwnd
    }

    ; 获取游戏进程ID
    GetGamePid() {
        return this.gamePid
    }

    ; 刷新窗口信息
    RefreshWindowInfo() {
        if (this.gameHwnd && WinExist("ahk_id " this.gameHwnd)) {
            return this.GetWindowInfo()
        }
        return false
    }

    ; 窗口是否存在
    WindowExists() {
        return this.gameHwnd && WinExist("ahk_id " this.gameHwnd)
    }

    ; 启动游戏
    StartGame() {
        this.logger.Info("尝试启动游戏")

        try {
            if (this.IsGameRunning()) {
                this.logger.Info("游戏已经在运行")
                return true
            }

            this.logger.Info("请手动启动QQ游戏盒子并打开《百战沙场》")

            loop 30 {
                Sleep(2000)
                if (this.FindGameWindow()) {
                    this.logger.Info("游戏启动成功")
                    return true
                }
            }

            this.logger.Error("游戏启动超时")
            return false
        }
        catch as e {
            this.logger.Error(Format("启动游戏失败: {}", e.Message))
            return false
        }
    }

    ; 关闭游戏
    CloseGame() {
        if (!this.gameHwnd) {
            return false
        }

        try {
            WinClose(this.gameHwnd)
            Sleep(2000)

            if (this.gamePid) {
                ProcessClose(this.gamePid)
            }

            this.gameHwnd := 0
            this.gamePid := 0
            this.SetGameActive(false)
            this.windowInfo := Map()

            this.logger.Info("游戏已关闭")
            return true
        }
        catch as e {
            this.logger.Error(Format("关闭游戏失败: {}", e.Message))
            return false
        }
    }

    ; 清理资源
    Cleanup() {
        this.logger.Info("清理窗口管理器资源")

        this.gameHwnd := 0
        this.gamePid := 0
        this.SetGameActive(false)
        this.windowInfo := Map()
    }

    ; 获取调试信息
    GetDebugInfo() {
        return Map(
            "gameHwnd", this.gameHwnd,
            "gamePid", this.gamePid,
            "isGameActive", this._isGameActive,
            "windowInfo", this.windowInfo.Clone()
        )
    }
}

; 注意：不再创建全局实例，由主程序统一管理
