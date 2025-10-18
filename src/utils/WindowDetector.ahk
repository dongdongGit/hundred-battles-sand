/**
 * 窗口检测调试工具
 * 用于检测游戏窗口的实际属性，帮助诊断窗口检测问题
 */

#Requires AutoHotkey v2.0
#SingleInstance Force

class WindowDetector {
    __New() {
        this.windows := []
        this.targetKeywords := ["百战沙场", "MainView", "QQMicroGameBox", "QQ游戏", "游戏盒子"]
    }

    ; 扫描所有窗口
    ScanWindows() {
        this.windows := []

        try {
            ; 方法1：获取所有顶级窗口
            windows := WinGetList()

            for hwnd in windows {
                try {
                    title := WinGetTitle(hwnd)
                    className := WinGetClass(hwnd)
                    processName := WinGetProcessName(hwnd)
                    processPath := WinGetProcessPath(hwnd)

                    ; 检查是否是游戏相关窗口
                    isGameRelated := this.IsGameRelated(title, className, processName)

                    windowInfo := Map(
                        "hwnd", hwnd,
                        "title", title,
                        "class", className,
                        "processName", processName,
                        "processPath", processPath,
                        "isGameRelated", isGameRelated,
                        "isVisible", this.IsWindowVisible(hwnd),
                        "isMinimized", this.IsWindowMinimized(hwnd)
                    )

                    this.windows.Push(windowInfo)

                }
                catch as e {
                    ; 跳过无法获取信息的窗口
                    continue
                }
            }

            ; 按相关性排序
            this.windows := this.SortByRelevance(this.windows)

            return this.windows
        }
        catch as e {
            MsgBox("扫描窗口失败: " e.Message, "错误", "ICONERROR")
            return []
        }
    }

    ; 判断窗口是否游戏相关
    IsGameRelated(title, className, processName) {
        for keyword in this.targetKeywords {
            if (InStr(title, keyword) || InStr(className, keyword) || InStr(processName, keyword)) {
                return true
            }
        }
        return false
    }

    ; 按相关性排序
    SortByRelevance(windows) {
        sorted := []

        ; 优先级：标题包含"百战沙场" > 标题包含其他游戏关键词 > 类名匹配 > 进程名匹配
        for window in windows {
            relevance := 0

            if (InStr(window["title"], "百战沙场")) {
                relevance += 100
            }
            if (window["isGameRelated"]) {
                relevance += 50
            }
            if (window["isVisible"]) {
                relevance += 10
            }
            if (!window["isMinimized"]) {
                relevance += 5
            }

            window["relevance"] := relevance
        }

        ; 排序
        sorted := windows
        sorted.Sort((a, b) => b["relevance"] - a["relevance"])

        return sorted
    }

    ; 检查窗口是否可见
    IsWindowVisible(hwnd) {
        try {
            return (WinGetStyle(hwnd) & 0x10000000) != 0  ; WS_VISIBLE
        }
        catch {
            return false
        }
    }

    ; 检查窗口是否最小化
    IsWindowMinimized(hwnd) {
        try {
            return WinGetMinMax(hwnd) = -1
        }
        catch {
            return false
        }
    }

    ; 显示扫描结果
    ShowResults() {
        windows := this.ScanWindows()

        if (windows.Length = 0) {
            MsgBox("未找到任何窗口", "扫描结果", "ICONWARNING")
            return
        }

        ; 创建结果文本
        result := "=== 窗口扫描结果 ===`n`n"
        result .= Format("共找到 {} 个窗口，按相关性排序：`n`n", windows.Length)

        for i, window in windows {
            result .= Format("=== 窗口 #{} (相关度: {}) ===`n", i, window["relevance"])
            result .= Format("句柄 (HWND): 0x{:X}`n", window["hwnd"])
            result .= Format("标题: {}`n", window["title"])
            result .= Format("类名: {}`n", window["class"])
            result .= Format("进程名: {}`n", window["processName"])
            result .= Format("进程路径: {}`n", window["processPath"])
            result .= Format("可见: {} | 最小化: {}`n", window["isVisible"] ? "是" : "否", window["isMinimized"] ? "是" : "否")
            result .= Format("游戏相关: {}`n", window["isGameRelated"] ? "是" : "否")
            result .= "`n"
        }

        ; 显示前几个最相关的窗口详情
        if (windows.Length > 0) {
            result .= "=== 推荐的游戏窗口 ===`n"
            for i := 1 to Min(3, windows.Length) {
                if (windows[i]["isGameRelated"]) {
                    result .= Format("推荐窗口 #{}:`n", i)
                    result .= Format("  标题: {}`n", windows[i]["title"])
                    result .= Format("  类名: {}`n", windows[i]["class"])
                    result .= Format("  进程名: {}`n", windows[i]["processName"])
                    result .= "`n"
                }
            }
        }

        ; 保存到文件
        try {
            FileDelete("window_scan_results.txt")
            FileAppend(result, "window_scan_results.txt")
            result .= "`n`n结果已保存到: window_scan_results.txt"
        }
        catch {
            result .= "`n`n注意: 无法保存结果到文件"
        }

        ; 显示结果
        MsgBox(result, "窗口扫描结果", "ICONINFORMATION")
    }

    ; 激活指定窗口进行测试
    TestWindow(hwnd) {
        try {
            WinActivate(hwnd)
            WinWaitActive(hwnd, , 3)

            if (WinActive("ahk_id " hwnd)) {
                MsgBox("窗口激活成功！`n`n这表明窗口可以正常激活。", "测试结果", "ICONINFORMATION")
                return true
            }
            else {
                MsgBox("窗口激活失败！`n`n可能是窗口被其他程序遮挡或有保护机制。", "测试结果", "ICONWARNING")
                return false
            }
        }
        catch as e {
            MsgBox("激活窗口时出错: " e.Message, "错误", "ICONERROR")
            return false
        }
    }
}

; 创建主GUI
class WindowDetectorGUI {
    __New() {
        this.detector := WindowDetector()
        this.windows := []
        this.CreateGUI()
    }

    CreateGUI() {
        this.gui := Gui("+Resize +MinSize400x300", "窗口检测工具")

        ; 按钮区域
        this.gui.Add("Button", "w120 h30", "扫描窗口").OnEvent("Click", "ScanBtn_Click")
        this.gui.Add("Button", "w120 h30 xm+130 yp", "刷新列表").OnEvent("Click", "RefreshBtn_Click")
        this.gui.Add("Button", "w120 h30 xm+260 yp", "测试激活").OnEvent("Click", "TestBtn_Click")
        this.gui.Add("Button", "w120 h30 xm+390 yp", "退出").OnEvent("Click", "ExitBtn_Click")

        ; 窗口列表
        this.gui.Add("Text", "xm y+20 w500", "检测到的窗口:")
        this.windowList := this.gui.Add("ListView", "xm y+5 w500 h200", ["句柄", "标题", "类名", "进程名", "状态"])
        this.windowList.OnEvent("DoubleClick", "ListView_DoubleClick")

        ; 状态栏
        this.statusBar := this.gui.Add("Text", "xm y+10 w500 h20", "就绪")

        this.gui.Show()
    }

    ScanBtn_Click(ctrl, info) {
        this.statusBar.Text := "正在扫描窗口..."
        this.windows := this.detector.ScanWindows()

        this.RefreshListView()
        this.statusBar.Text := Format("扫描完成，共找到 {} 个窗口", this.windows.Length)
    }

    RefreshBtn_Click(ctrl, info) {
        if (this.windows.Length = 0) {
            this.ScanBtn_Click(ctrl, info)
        }
        else {
            this.RefreshListView()
            this.statusBar.Text := "列表已刷新"
        }
    }

    RefreshListView() {
        this.windowList.Delete()

        for window in this.windows {
            status := ""
            if (window["isGameRelated"]) {
                status .= "游戏相关 "
            }
            if (window["isVisible"]) {
                status .= "可见 "
            }
            if (window["isMinimized"]) {
                status .= "最小化"
            }
            if (status = "") {
                status := "普通窗口"
            }

            this.windowList.Add("", Format("0x{:X}", window["hwnd"]), window["title"],
                window["class"], window["processName"], status)
        }
    }

    TestBtn_Click(ctrl, info) {
        if (this.windowList.GetCount() = 0) {
            MsgBox("请先扫描窗口", "提示", "ICONINFORMATION")
            return
        }

        focusedRow := this.windowList.GetNext()
        if (focusedRow = 0) {
            MsgBox("请选择一个窗口进行测试", "提示", "ICONINFORMATION")
            return
        }

        hwnd := this.windows[focusedRow]["hwnd"]
        this.detector.TestWindow(hwnd)
    }

    ListView_DoubleClick(ctrl, info) {
        focusedRow := ctrl.GetNext()
        if (focusedRow > 0 && focusedRow <= this.windows.Length) {
            hwnd := this.windows[focusedRow]["hwnd"]
            this.detector.TestWindow(hwnd)
        }
    }

    ExitBtn_Click(ctrl, info) {
        ExitApp
    }
}

; 主程序
if (A_ScriptName = "WindowDetector.ahk") {
    gui := WindowDetectorGUI()
}

; 热键：Ctrl+Shift+W 快速扫描
^+w:: {
    detector := WindowDetector()
    detector.ShowResults()
}