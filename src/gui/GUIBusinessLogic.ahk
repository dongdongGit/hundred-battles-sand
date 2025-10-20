/**
 * GUI业务逻辑处理类
 * 处理界面相关的业务逻辑，与界面展示分离
 */

#Requires AutoHotkey v2.0

class GUIBusinessLogic {
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
     * 显示帮助信息
     */
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

    /**
     * 显示关于信息
     */
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

    /**
     * 根据等级获取地点列表
     */
    GetLocationsForLevel(level) {
        ; 获取指定等级的地点列表（模拟数据）
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
     * 尝试自动检测游戏窗口
     */
    TryAutoDetectGameWindow() {
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
                    MsgBox("✅ 配置已保存", "游戏窗口配置已更新！`n`n请重新启动程序以应用新配置。")
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

    /**
     * 查找最可能的游戏窗口
     */
    FindMostLikelyGameWindow() {
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

    /**
     * 尝试宽松的游戏检测条件
     */
    TryLooseGameDetection() {
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

    /**
     * 重启应用程序
     */
    RestartApp() {
        this.logger.Info("重启应用程序")
        global App
        App.Stop()
        Sleep(1000)
        Reload()  ; 在AutoHotkey v2.0中需要括号
    }
}