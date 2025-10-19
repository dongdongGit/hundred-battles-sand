/**
 * 窗口检测测试工具
 * 用于帮助用户找出游戏窗口的正确信息
 */

#Requires AutoHotkey v2.0

; 查找所有窗口并显示信息
windows := WinGetList()
windowInfo := []

for hwnd in windows {
    try {
        title := WinGetTitle(hwnd)
        className := WinGetClass(hwnd)
        processName := WinGetProcessName(hwnd)

        ; 收集游戏相关窗口
        if (InStr(title, "QQ游戏")
            || InStr(title, "百战沙城")
            || InStr(processName, "QQGame")
            || InStr(processName, "QQMicroGameBox")
            || className = "GRootViewClass") {

            windowInfo.Push(Map(
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
if (windowInfo.Length = 0) {
    MsgBox("未找到游戏相关窗口！`n`n请确保：`n1. QQ游戏盒子已启动`n2. 《百战沙城》游戏已进入`n3. 游戏窗口未最小化", "窗口检测结果", "Icon!")
    ExitApp()
}

; 创建结果文本
resultText := "找到以下游戏相关窗口：`n`n"
for i, window in windowInfo {
    resultText .= Format("窗口 {}:`n", i)
    resultText .= Format("  标题: {}`n", window["title"])
    resultText .= Format("  类名: {}`n", window["class"])
    resultText .= Format("  进程: {}`n", window["process"])
    resultText .= Format("  句柄: {}`n`n", window["hwnd"])
}

resultText .= "请将以上信息提供给开发者，`n帮助更新游戏窗口配置。"

MsgBox(resultText, "窗口检测结果", "0x40")