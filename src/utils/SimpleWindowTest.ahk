/**
 * 简单的窗口检测测试工具
 * 双击运行，自动检测游戏窗口并显示结果
 */

#Requires AutoHotkey v2.0

MsgBox("🔍 开始检测游戏窗口...", "窗口检测", "0x40")

; 查找游戏窗口
windows := WinGetList()
gameWindows := []

for hwnd in windows {
    try {
        title := WinGetTitle(hwnd)
        className := WinGetClass(hwnd)
        processName := WinGetProcessName(hwnd)

        ; 跳过自身窗口
        if (InStr(title, "百战沙城自动化") || InStr(className, "AutoHotkeyGUI")) {
            continue
        }

        ; 寻找游戏相关窗口
        if (InStr(title, "QQ游戏")
            || InStr(title, "百战沙城")
            || InStr(title, "百战沙场")
            || InStr(processName, "QQGame")
            || className = "GRootViewClass") {

            gameWindows.Push(Map(
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

; 显示结果
if (gameWindows.Length = 0) {
    resultText := "❌ 未找到游戏窗口！`n`n请检查：`n✅ QQ游戏盒子是否已启动？`n✅ 《百战沙城》是否已进入游戏？`n✅ 游戏窗口是否未最小化？`n`n如果游戏已运行但检测不到，请将游戏窗口截图发给开发者。"

    ; 保存结果到文件
    try {
        FileAppend(resultText, A_ScriptDir "\window_detection_result.txt", "UTF-8")
        resultText .= "`n`n💾 结果已保存到文件：src\utils\window_detection_result.txt"
    }
} else {
    resultText := "✅ 找到游戏窗口！`n`n📋 窗口信息：`n"

    for i, window in gameWindows {
        resultText .= Format("窗口 {}:`n", i)
        resultText .= Format("  标题: {}`n", window["title"])
        resultText .= Format("  类名: {}`n", window["class"])
        resultText .= Format("  进程: {}`n", window["process"])
        resultText .= Format("  句柄: {}`n`n", window["hwnd"])
    }

    resultText .= "请将以上信息发给开发者，帮助完善游戏窗口配置。"

    ; 保存结果到文件
    try {
        FileAppend(resultText, A_ScriptDir "\window_detection_result.txt", "UTF-8")
        resultText .= "`n`n💾 结果已保存到文件：src\utils\window_detection_result.txt"
    }
}

MsgBox(resultText, "检测结果", "0x40")