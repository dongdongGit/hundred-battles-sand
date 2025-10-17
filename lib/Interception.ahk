/**
 * Interception驱动集成模块
 * 提供低级键盘鼠标控制功能，支持后台操作
 */

class InterceptionManager {
    __New() {
        this.isInstalled := false
        this.isInitialized := false
        this.context := 0
        this.mouseDevice := 0
        this.keyboardDevice := 0
        this.interceptionDll := ""

        this.CheckInstallation()
    }

    CheckInstallation() {
        LoggerInstance.Info("检查Interception驱动安装状态")

        try {
            ; 检查驱动文件是否存在
            programFiles := EnvGet("ProgramFiles(x86)") || EnvGet("ProgramFiles")
            interceptionPath := programFiles "\Interception"

            if (DirExist(interceptionPath)) {
                ; 检查必要的DLL文件
                dllFiles := [
                    "interception.dll",
                    "interception.dll"
                ]

                allFilesExist := true
                for dllFile in dllFiles {
                    dllPath := interceptionPath "\" dllFile
                    if (!FileExist(dllPath)) {
                        allFilesExist := false
                        break
                    }
                }

                if (allFilesExist) {
                    this.isInstalled := true
                    this.interceptionDll := interceptionPath "\interception.dll"
                    LoggerInstance.Info("Interception驱动已安装")
                }
                else {
                    LoggerInstance.Warn("Interception驱动文件不完整")
                }
            }
            else {
                LoggerInstance.Warn("Interception驱动未安装")
            }
        }
        catch as e {
            LoggerInstance.Error(Format("检查驱动安装失败: {}", e.Message))
        }
    }

    Initialize() {
        if (!this.isInstalled) {
            throw Error("Interception驱动未安装，请先安装驱动")
        }

        LoggerInstance.Info("初始化Interception驱动")

        try {
            ; 加载DLL
            if (!DllCall("LoadLibrary", "Str", this.interceptionDll)) {
                throw Error("无法加载Interception DLL")
            }

            ; 创建Interception上下文
            this.context := DllCall("interception_create_context", "Ptr")
            if (!this.context) {
                throw Error("无法创建Interception上下文")
            }

            ; 获取鼠标和键盘设备
            this.mouseDevice := DllCall("interception_get_mouse_device", "Ptr", this.context)
            this.keyboardDevice := DllCall("interception_get_keyboard_device", "Ptr", this.context)

            if (!this.mouseDevice || !this.keyboardDevice) {
                throw Error("无法获取输入设备")
            }

            this.isInitialized := true
            LoggerInstance.Info("Interception驱动初始化完成")

        }
        catch as e {
            LoggerInstance.Error(Format("初始化Interception失败: {}", e.Message))
            this.Cleanup()
            throw e
        }
    }

    ; 鼠标操作方法
    class MouseStroke {
        __New(x := 0, y := 0, state := 0, flags := 0, rolling := 0, information := 0) {
            this.x := x
            this.y := y
            this.state := state
            this.flags := flags
            this.rolling := rolling
            this.information := information
        }
    }

    ; 键盘操作方法
    class KeyboardStroke {
        __New(code := 0, state := 0, information := 0) {
            this.code := code
            this.state := state
            this.information := information
        }
    }

    ; 发送鼠标输入
    SendMouseInput(x, y, state := 0, flags := 0) {
        if (!this.isInitialized) {
            throw Error("Interception未初始化")
        }

        try {
            stroke := InterceptionManager.MouseStroke(x, y, state, flags)

            ; 发送鼠标输入
            result := DllCall("interception_send", "Ptr", this.context, "Ptr", this.mouseDevice,
                "Ptr", &stroke, "Int", 1)

            return result > 0
        }
        catch as e {
            LoggerInstance.Error(Format("发送鼠标输入失败: {}", e.Message))
            return false
        }
    }

    ; 发送键盘输入
    SendKeyboardInput(code, state := 0) {
        if (!this.isInitialized) {
            throw Error("Interception未初始化")
        }

        try {
            stroke := InterceptionManager.KeyboardStroke(code, state)

            ; 发送键盘输入
            result := DllCall("interception_send", "Ptr", this.context, "Ptr", this.keyboardDevice,
                "Ptr", &stroke, "Int", 1)

            return result > 0
        }
        catch as e {
            LoggerInstance.Error(Format("发送键盘输入失败: {}", e.Message))
            return false
        }
    }

    ; 鼠标点击（在指定位置）
    Click(x, y, button := "left") {
        LoggerInstance.Debug(Format("Interception鼠标点击: ({},{}) {}", x, y, button))

        ; 转换为相对坐标（如果需要）
        ; 这里假设x,y已经是屏幕坐标

        switch button {
            case "left":
                state := 0x001  ; 左键按下
            case "right":
                state := 0x002  ; 右键按下
            case "middle":
                state := 0x004  ; 中键按下
            default:
                state := 0x001  ; 默认左键
        }

        ; 按下鼠标
        if (!this.SendMouseInput(x, y, state)) {
            return false
        }

        Sleep(50)  ; 短暂延迟模拟真实点击

        ; 释放鼠标
        state := state | 0x800  ; 添加释放标志
        return this.SendMouseInput(x, y, state)
    }

    ; 鼠标双击
    DoubleClick(x, y, button := "left") {
        LoggerInstance.Debug(Format("Interception鼠标双击: ({},{}) {}", x, y, button))

        ; 第一次点击
        if (!this.Click(x, y, button)) {
            return false
        }

        Sleep(100)  ; 双击间隔

        ; 第二次点击
        return this.Click(x, y, button)
    }

    ; 鼠标移动到指定位置
    MoveTo(x, y) {
        LoggerInstance.Debug(Format("Interception鼠标移动到: ({},{})", x, y))

        ; 鼠标移动（无按键状态）
        return this.SendMouseInput(x, y, 0, 0x800)  ; 鼠标移动标志
    }

    ; 键盘按键
    KeyPress(keyCode, duration := 50) {
        LoggerInstance.Debug(Format("Interception键盘按键: {} ({}ms)", keyCode, duration))

        ; 按下按键
        if (!this.SendKeyboardInput(keyCode, 0)) {
            return false
        }

        Sleep(duration)

        ; 释放按键
        return this.SendKeyboardInput(keyCode, 0x800)  ; 释放标志
    }

    ; 发送键盘快捷键组合
    SendHotkey(keys) {
        LoggerInstance.Debug(Format("Interception发送快捷键: {}", keys))

        ; 这里需要解析快捷键字符串并发送相应的按键
        ; 简化版：直接发送按键码

        keyMap := Map(
            "F1", 0x3B, "F2", 0x3C, "F3", 0x3D, "F4", 0x3E,
            "F5", 0x3F, "F6", 0x40, "F7", 0x41, "F8", 0x42,
            "F9", 0x43, "F10", 0x44, "F11", 0x45, "F12", 0x46,
            "A", 0x41, "B", 0x42, "C", 0x43, "D", 0x44,
            "E", 0x45, "F", 0x46, "G", 0x47, "H", 0x48,
            "I", 0x49, "J", 0x4A, "K", 0x4B, "L", 0x4C,
            "M", 0x4D, "N", 0x4E, "O", 0x4F, "P", 0x50,
            "Q", 0x51, "R", 0x52, "S", 0x53, "T", 0x54,
            "U", 0x55, "V", 0x56, "W", 0x57, "X", 0x58,
            "Y", 0x59, "Z", 0x5A
        )

        ; 解析快捷键（支持组合键，如Ctrl+C）
        ; 这里简化处理，只处理单个按键
        if (keyMap.Has(keys)) {
            return this.KeyPress(keyMap[keys])
        }

        LoggerInstance.Warn(Format("未识别的快捷键: {}", keys))
        return false
    }

    ; 获取鼠标位置
    GetMousePosition(ByRef x, ByRef y) {
        if (!this.isInitialized) {
            return false
        }

        try {
            ; 使用系统API获取鼠标位置
            point := Buffer(8)
            DllCall("GetCursorPos", "Ptr", point)

            x := NumGet(point, 0, "Int")
            y := NumGet(point, 4, "Int")

            return true
        }
        catch {
            return false
        }
    }

    ; 设置鼠标位置
    SetMousePosition(x, y) {
        if (!this.isInitialized) {
            return false
        }

        try {
            ; 使用系统API设置鼠标位置
            DllCall("SetCursorPos", "Int", x, "Int", y)
            return true
        }
        catch as e {
            LoggerInstance.Error(Format("设置鼠标位置失败: {}", e.Message))
            return false
        }
    }

    ; 鼠标滚轮
    MouseWheel(direction := "up", amount := 1) {
        LoggerInstance.Debug(Format("Interception鼠标滚轮: {} {}", direction, amount))

        ; 滚轮状态（正数向上，负数向下）
        state := direction = "up" ? 0x0780 : 0xFF880000

        loop amount {
            if (!this.SendMouseInput(0, 0, state)) {
                return false
            }
            Sleep(10)
        }

        return true
    }

    ; 检查是否初始化
    IsInitialized() {
        return this.isInitialized
    }

    ; 安装驱动（管理员权限）
    InstallDriver() {
        LoggerInstance.Info("安装Interception驱动")

        try {
            ; 这里应该调用官方安装脚本
            ; 由于权限限制，这里只是提示用户手动安装
            LoggerInstance.Info("请以管理员身份运行安装脚本")

            ; 可以尝试调用系统命令安装
            RunWait("cmd.exe /c echo 请手动安装Interception驱动", , "Hide")

            return false
        }
        catch as e {
            LoggerInstance.Error(Format("安装驱动失败: {}", e.Message))
            return false
        }
    }

    ; 卸载驱动（管理员权限）
    UninstallDriver() {
        LoggerInstance.Info("卸载Interception驱动")

        try {
            ; 这里应该调用官方卸载脚本
            LoggerInstance.Info("请以管理员身份运行卸载脚本")

            return false
        }
        catch as e {
            LoggerInstance.Error(Format("卸载驱动失败: {}", e.Message))
            return false
        }
    }

    ; 接收输入（用于监控）
    ReceiveInput() {
        if (!this.isInitialized) {
            return false
        }

        try {
            ; 接收鼠标输入
            strokeSize := 10  ; MouseStroke结构体大小

            while (DllCall("interception_receive", "Ptr", this.context, "Ptr", this.mouseDevice,
                "Ptr", 0, "Int", 1) > 0) {
                ; 处理接收到的鼠标输入
                ; 这里可以添加输入监控逻辑
            }

            return true
        }
        catch {
            return false
        }
    }

    ; 获取设备信息
    GetDeviceInfo() {
        if (!this.isInitialized) {
            return Map("error", "未初始化")
        }

        return Map(
            "context", this.context,
            "mouse_device", this.mouseDevice,
            "keyboard_device", this.keyboardDevice,
            "dll_path", this.interceptionDll,
            "installed", this.isInstalled
        )
    }

    ; 测试功能
    Test() {
        LoggerInstance.Info("测试Interception功能")

        try {
            if (!this.isInitialized) {
                throw Error("驱动未初始化")
            }

            ; 测试鼠标移动
            this.MoveTo(100, 100)

            Sleep(500)

            ; 测试鼠标点击
            this.Click(100, 100)

            Sleep(500)

            ; 测试键盘输入
            this.KeyPress(0x41)  ; A键

            LoggerInstance.Info("Interception功能测试完成")
            return true

        }
        catch as e {
            LoggerInstance.Error(Format("功能测试失败: {}", e.Message))
            return false
        }
    }

    ; 清理资源
    Cleanup() {
        LoggerInstance.Info("清理Interception资源")

        if (this.context) {
            try {
                DllCall("interception_destroy_context", "Ptr", this.context)
                this.context := 0
            }
            catch {
                ; 忽略清理错误
            }
        }

        this.isInitialized := false
        this.mouseDevice := 0
        this.keyboardDevice := 0
    }

    ; 获取调试信息
    GetDebugInfo() {
        return Map(
            "is_installed", this.isInstalled,
            "is_initialized", this.isInitialized,
            "context", this.context,
            "mouse_device", this.mouseDevice,
            "keyboard_device", this.keyboardDevice,
            "dll_path", this.interceptionDll,
            "device_info", this.GetDeviceInfo()
        )
    }
}

; 全局Interception管理器实例
global InterceptionManagerInstance := InterceptionManager()