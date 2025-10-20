/**
 * 窗口检测处理器
 * 处理游戏窗口检测相关的业务逻辑
 */

#Requires AutoHotkey v2.0

class WindowDetectionHandler {
    __New(loggerInstance := "", configInstance := "") {
        ; 如果没有传入实例，使用全局实例
        if (loggerInstance = "") {
            loggerInstance := LoggerInstance
        }
        if (configInstance = "") {
            configInstance := ConfigInstance
        }

        this.logger := loggerInstance
        this.config := configInstance
    }

    /**
     * 显示窗口检测对话框
     */
    ShowWindowDetectionDialog() {
        ; 创建窗口检测对话框
        dialogGui := Gui("+Resize +MinSize400x300", "游戏窗口检测")

        ; 添加说明文本
        dialogGui.Add("Text", "x10 y10 w380",
            "请选择您的游戏窗口。程序将列出所有检测到的候选窗口：")

        ; 创建ListView显示候选窗口
        LV := dialogGui.Add("ListView", "x10 y40 w380 h200",
            ["编号", "窗口标题", "类名", "进程名"])

        ; 获取候选窗口
        candidateWindows := this.GetCandidateWindows()
        rowNum := 0

        for hwnd in candidateWindows {
            rowNum++
            ; 添加到ListView
            LV.Add("", rowNum, candidateWindows[rowNum].title,
                candidateWindows[rowNum].class,
                candidateWindows[rowNum].process)
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

    /**
     * 获取候选窗口列表
     */
    GetCandidateWindows() {
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
                }
            }
            catch {
                continue
            }
        }

        return candidateWindows
    }

    /**
     * 处理对话框选择
     */
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
            MsgBox("✅ 配置已保存", "游戏窗口配置已更新！`n`n请重新启动程序以应用新配置。")
            dialogGui.Destroy()
        }
    }

    /**
     * 刷新窗口列表
     */
    RefreshWindowList(dialogGui, LV, &candidateWindows) {
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

    /**
     * 显示手动窗口选择界面
     */
    ShowManualWindowSelection() {
        this.logger.Info("显示手动窗口选择界面")

        ; 查找所有候选窗口
        candidateWindows := this.GetCandidateWindows()

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

    /**
     * 处理窗口选择
     */
    OnWindowSelected(selectedWindow) {
        ; 处理用户选择的窗口
        try {
            infoText := Format("🎯 您选择了以下窗口：`n`n📋 窗口信息：`n窗口标题：{}`n窗口类名：{}`n进程名：{}`n窗口句柄：{}`n`n❓ 确认保存此配置？",
                selectedWindow["title"], selectedWindow["class"], selectedWindow["process"], selectedWindow["hwnd"])

            result := MsgBox(infoText, "确认游戏窗口", "YesNo")
            if (result = "Yes") {
                this.SaveGameWindowConfig(selectedWindow)
                MsgBox("✅ 配置已保存", "游戏窗口配置已更新！`n`n请重新启动程序以应用新配置。")
            }
        }
        catch as e {
            this.ShowError("保存配置失败", e.Message)
        }
    }

    /**
     * 保存游戏窗口配置
     */
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

    /**
     * 显示警告信息
     */
    ShowWarning(title, message) {
        MsgBox(message, title, "Icon!")
        this.logger.Warn(Format("{}: {}", title, message))
    }

    /**
     * 显示错误信息
     */
    ShowError(title, message) {
        MsgBox(message, title, "IconX")
        this.logger.Error(Format("{}: {}", title, message))
    }
}