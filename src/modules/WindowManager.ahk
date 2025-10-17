/**
 * 窗口管理器
 * 专门处理QQ游戏盒子和游戏窗口的识别、控制和管理
 */

class WindowManager {
    __New() {
        this.gameWindowClass := ConfigInstance.GetString("game", "window_class")
        this.gameWindowTitle := ConfigInstance.GetString("game", "window_title")
        this.gameProcessName := ConfigInstance.GetString("game", "process_name")

        this.gameHwnd := 0
        this.gamePid := 0
        this.isGameActive := false
        this.windowInfo := Map()

        this.retryCount := 3
        this.retryDelay := 1000
    }

    Initialize() {
        LoggerInstance.Info("初始化窗口管理器")

        ; 查找游戏窗口
        this.FindGameWindow()

        if (this.gameHwnd) {
            this.GetWindowInfo()
            LoggerInstance.Info(Format("游戏窗口已找到: hwnd={}", this.gameHwnd))
        }
        else {
            LoggerInstance.Warn("游戏窗口未找到，将在需要时自动查找")
        }
    }

    FindGameWindow() {
        LoggerInstance.Debug("查找游戏窗口")

        ; 方法1：通过窗口类名查找
        this.gameHwnd := WinExist("ahk_class " this.gameWindowClass)

        if (this.gameHwnd) {
            LoggerInstance.Debug("通过窗口类名找到游戏窗口")
            return true
        }

        ; 方法2：通过窗口标题查找
        this.gameHwnd := WinExist(this.gameWindowTitle)

        if (this.gameHwnd) {
            LoggerInstance.Debug("通过窗口标题找到游戏窗口")
            return true
        }

        ; 方法3：枚举所有窗口查找
        gameHwnd := 0
        WinGetList(,(title, class, exe, hwnd) => (
            (class = this.gameWindowClass || InStr(title, this.gameWindowTitle))
            && (gameHwnd := hwnd, false)
        ))

        if (gameHwnd) {
            this.gameHwnd := gameHwnd
            LoggerInstance.Debug("通过枚举找到游戏窗口")
            return true
        }

        ; 方法4：查找游戏进程
        if (this.FindGameProcess()) {
            ; 等待窗口出现
            loop this.retryCount {
                Sleep(this.retryDelay)

                this.gameHwnd := WinExist("ahk_class " this.gameWindowClass)
                if (this.gameHwnd) {
                    LoggerInstance.Debug("通过进程等待找到游戏窗口")
                    return true
                }
            }
        }

        LoggerInstance.Warn("未找到游戏窗口")
        return false
    }

    FindGameProcess() {
        LoggerInstance.Debug("查找游戏进程")

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
                LoggerInstance.Debug(Format("找到游戏进程: pid={}", this.gamePid))
                return true
            }
        }
        catch as e {
            LoggerInstance.Error(Format("查找游戏进程失败: {}", e.Message))
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
            LoggerInstance.Error(Format("获取窗口信息失败: {}", e.Message))
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

            this.isGameActive := true
            LoggerInstance.Debug("游戏窗口已激活")
            return true
        }
        catch as e {
            LoggerInstance.Error(Format("激活游戏窗口失败: {}", e.Message))
            this.isGameActive := false
            throw e
        }
    }

    MinimizeGameWindow() {
        if (!this.gameHwnd) {
            return false
        }

        try {
            WinMinimize(this.gameHwnd)
            this.isGameActive := false
            LoggerInstance.Debug("游戏窗口已最小化")
            return true
        }
        catch as e {
            LoggerInstance.Error(Format("最小化游戏窗口失败: {}", e.Message))
            return false
        }
    }

    MaximizeGameWindow() {
        if (!this.gameHwnd) {
            return false
        }

        try {
            WinMaximize(this.gameHwnd)
            this.isGameActive := true
            LoggerInstance.Debug("游戏窗口已最大化")
            return true
        }
        catch as e {
            LoggerInstance.Error(Format("最大化游戏窗口失败: {}", e.Message))
            return false
        }
    }

    HideGameWindow() {
        if (!this.gameHwnd) {
            return false
        }

        try {
            WinHide(this.gameHwnd)
            this.isGameActive := false
            LoggerInstance.Debug("游戏窗口已隐藏")
            return true
        }
        catch as e {
            LoggerInstance.Error(Format("隐藏游戏窗口失败: {}", e.Message))
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
            this.isGameActive := true
            LoggerInstance.Debug("游戏窗口已显示")
            return true
        }
        catch as e {
            LoggerInstance.Error(Format("显示游戏窗口失败: {}", e.Message))
            return false
        }
    }

    ; 获取游戏窗口截图（用于图像识别）
    CaptureGameWindow(x := 0, y := 0, width := -1, height := -1) {
        if (!this.IsGameRunning()) {
            throw Error("游戏窗口未运行")
        }

        try {
            ; 获取完整窗口区域
            if (width = -1 || height = -1) {
                this.GetWindowInfo()
                width := this.windowInfo["width"]
                height := this.windowInfo["height"]
                x := this.windowInfo["x"]
                y := this.windowInfo["y"]
            }

            ; 截图
            bitmap := GdipBitmapFromScreen(x "|" y "|" width "|" height)

            LoggerInstance.Debug(Format("窗口截图完成: {}x{} at ({},{})", width, height, x, y))
            return bitmap
        }
        catch as e {
            LoggerInstance.Error(Format("截图失败: {}", e.Message))
            throw e
        }
    }

    ; 点击游戏窗口内指定位置
    ClickInGame(x, y, button := "left") {
        if (!this.IsGameRunning()) {
            throw Error("游戏窗口未运行")
        }

        try {
            ; 确保窗口激活
            this.ActivateGameWindow()

            ; 转换为屏幕坐标
            screenX := this.windowInfo["x"] + x
            screenY := this.windowInfo["y"] + y

            ; 点击
            Click(screenX, screenY, button)

            LoggerInstance.Debug(Format("在游戏窗口内点击: ({},{})", x, y))
            return true
        }
        catch as e {
            LoggerInstance.Error(Format("游戏窗口内点击失败: {}", e.Message))
            throw e
        }
    }

    ; 在游戏窗口内移动鼠标
    MoveMouseInGame(x, y) {
        if (!this.IsGameRunning()) {
            throw Error("游戏窗口未运行")
        }

        try {
            ; 转换为屏幕坐标
            screenX := this.windowInfo["x"] + x
            screenY := this.windowInfo["y"] + y

            ; 移动鼠标
            MouseMove(screenX, screenY)

            LoggerInstance.Debug(Format("鼠标移动到游戏窗口内: ({},{})", x, y))
            return true
        }
        catch as e {
            LoggerInstance.Error(Format("鼠标移动失败: {}", e.Message))
            throw e
        }
    }

    ; 获取游戏窗口内指定位置的颜色
    GetColorInGame(x, y) {
        if (!this.IsGameRunning()) {
            throw Error("游戏窗口未运行")
        }

        try {
            ; 转换为屏幕坐标
            screenX := this.windowInfo["x"] + x
            screenY := this.windowInfo["y"] + y

            ; 获取颜色
            color := PixelGetColor(screenX, screenY)

            LoggerInstance.Debug(Format("获取游戏窗口内颜色: ({},{}) = {}", x, y, color))
            return color
        }
        catch as e {
            LoggerInstance.Error(Format("获取颜色失败: {}", e.Message))
            throw e
        }
    }

    ; 检查游戏窗口内指定位置的颜色
    CheckColorInGame(x, y, expectedColor, variation := 0) {
        try {
            actualColor := this.GetColorInGame(x, y)
            return this.ColorsMatch(actualColor, expectedColor, variation)
        }
        catch {
            return false
        }
    }

    ; 颜色匹配（支持变异）
    ColorsMatch(color1, color2, variation := 0) {
        if (variation = 0) {
            return color1 = color2
        }

        ; 解析颜色值
        r1 := (color1 >> 16) & 0xFF
        g1 := (color1 >> 8) & 0xFF
        b1 := color1 & 0xFF

        r2 := (color2 >> 16) & 0xFF
        g2 := (color2 >> 8) & 0xFF
        b2 := color2 & 0xFF

        ; 计算差异
        rDiff := Abs(r1 - r2)
        gDiff := Abs(g1 - g2)
        bDiff := Abs(b1 - b2)

        return Max(rDiff, gDiff, bDiff) <= variation
    }

    ; 等待游戏窗口内指定颜色出现
    WaitForColorInGame(x, y, expectedColor, timeout := 5000, variation := 0) {
        startTime := A_TickCount

        while (A_TickCount - startTime < timeout) {
            if (this.CheckColorInGame(x, y, expectedColor, variation)) {
                LoggerInstance.Debug(Format("颜色出现: ({},{}) = {}", x, y, expectedColor))
                return true
            }
            Sleep(100)
        }

        LoggerInstance.Warn(Format("等待颜色超时: ({},{}) = {}", x, y, expectedColor))
        return false
    }

    ; 等待游戏窗口内指定颜色消失
    WaitForColorGoneInGame(x, y, expectedColor, timeout := 5000, variation := 0) {
        startTime := A_TickCount

        while (A_TickCount - startTime < timeout) {
            if (!this.CheckColorInGame(x, y, expectedColor, variation)) {
                LoggerInstance.Debug(Format("颜色消失: ({},{}) = {}", x, y, expectedColor))
                return true
            }
            Sleep(100)
        }

        LoggerInstance.Warn(Format("等待颜色消失超时: ({},{}) = {}", x, y, expectedColor))
        return false
    }

    ; 获取游戏窗口句柄
    GetGameHwnd() {
        return this.gameHwnd
    }

    ; 获取游戏进程ID
    GetGamePid() {
        return this.gamePid
    }

    ; 检查游戏是否激活
    IsGameActive() {
        return this.isGameActive && WinActive("ahk_id " this.gameHwnd)
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
        LoggerInstance.Info("尝试启动游戏")

        try {
            ; 检查游戏是否已经在运行
            if (this.IsGameRunning()) {
                LoggerInstance.Info("游戏已经在运行")
                return true
            }

            ; 这里可以添加游戏的启动逻辑
            ; 例如：Run("游戏的启动命令或路径")

            LoggerInstance.Info("请手动启动QQ游戏盒子并打开《百战沙场》")

            ; 等待用户启动游戏
            loop 30 {
                Sleep(2000)
                if (this.FindGameWindow()) {
                    LoggerInstance.Info("游戏启动成功")
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

    ; 关闭游戏
    CloseGame() {
        if (!this.gameHwnd) {
            return false
        }

        try {
            WinClose(this.gameHwnd)
            Sleep(2000)  ; 等待关闭

            if (this.gamePid) {
                ProcessClose(this.gamePid)
            }

            this.gameHwnd := 0
            this.gamePid := 0
            this.isGameActive := false

            LoggerInstance.Info("游戏已关闭")
            return true
        }
        catch as e {
            LoggerInstance.Error(Format("关闭游戏失败: {}", e.Message))
            return false
        }
    }

    ; 清理资源
    Cleanup() {
        LoggerInstance.Info("清理窗口管理器资源")

        this.gameHwnd := 0
        this.gamePid := 0
        this.isGameActive := false
        this.windowInfo := Map()
    }

    ; 获取调试信息
    GetDebugInfo() {
        return Map(
            "gameHwnd", this.gameHwnd,
            "gamePid", this.gamePid,
            "isGameActive", this.isGameActive,
            "windowInfo", this.windowInfo.Clone()
        )
    }
}

; 全局窗口管理器实例
global WindowManagerInstance := WindowManager()