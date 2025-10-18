/**
 * 窗口检测测试脚本
 * 用于验证修复后的窗口检测功能是否正常工作
 */

#Requires AutoHotkey v2.0
#SingleInstance Force

; 包含必要的模块
#Include "..\modules\Logger.ahk"
#Include "..\modules\Config.ahk"
#Include "..\modules\WindowManager.ahk"

class WindowDetectionTester {
    __New() {
        this.Logger := Logger()
        this.Config := Config()
        this.WindowManager := WindowManager()

        this.Logger.Info("窗口检测测试器初始化完成")
    }

    TestWindowDetection() {
        this.Logger.Info("开始测试窗口检测功能...")

        try {
            ; 初始化组件
            this.Config.Load()
            this.WindowManager.Initialize()

            ; 测试1：检查游戏窗口是否运行
            this.Logger.Info("测试1：检查游戏窗口是否运行")
            isRunning := this.WindowManager.IsGameRunning()

            if (isRunning) {
                this.Logger.Info("✅ 游戏窗口检测成功")

                ; 获取窗口信息
                hwnd := this.WindowManager.GetGameHwnd()
                pid := this.WindowManager.GetGamePid()

                this.Logger.Info(Format("游戏窗口句柄: 0x{:X}", hwnd))
                this.Logger.Info(Format("游戏进程ID: {}", pid))

                ; 测试激活窗口
                this.Logger.Info("测试2：激活游戏窗口")
                this.WindowManager.ActivateGameWindow()
                this.Logger.Info("✅ 游戏窗口激活成功")

                ; 显示成功消息
                MsgBox("窗口检测测试成功！`n`n游戏窗口已正确检测并激活。", "测试结果", "ICONINFORMATION")

            }
            else {
                this.Logger.Warn("❌ 游戏窗口未检测到")

                ; 显示调试信息
                debugInfo := this.WindowManager.GetDebugInfo()
                this.Logger.Info("调试信息:")
                this.Logger.Info(Format("  游戏窗口句柄: {}", debugInfo["gameHwnd"] || "未设置"))
                this.Logger.Info(Format("  游戏进程ID: {}", debugInfo["gamePid"] || "未设置"))
                this.Logger.Info(Format("  游戏激活状态: {}", debugInfo["isGameActive"] ? "是" : "否"))

                MsgBox("窗口检测测试失败！`n`n请确保游戏窗口已经打开。", "测试结果", "ICONWARNING")
            }

        }
        catch as e {
            this.Logger.Error(Format("测试过程中出错: {}", e.Message))
            MsgBox("测试过程中出错: " e.Message, "错误", "ICONERROR")
        }
    }

    ShowDebugInfo() {
        this.Logger.Info("显示调试信息")

        try {
            debugInfo := this.WindowManager.GetDebugInfo()

            info := "=== 窗口管理器调试信息 ===`n`n"
            info .= Format("游戏窗口句柄: 0x{:X}`n", debugInfo["gameHwnd"])
            info .= Format("游戏进程ID: {}`n", debugInfo["gamePid"])
            info .= Format("游戏激活状态: {}`n", debugInfo["isGameActive"] ? "是" : "否")
            info .= "`n窗口信息:`n"

            if (debugInfo["windowInfo"].Count > 0) {
                for key, value in debugInfo["windowInfo"] {
                    info .= Format("  {}: {}`n", key, value)
                }
            }
            else {
                info .= "  无窗口信息`n"
            }

            ; 添加配置信息
            info .= "`n配置信息:`n"
            info .= Format("  窗口类名: {}`n", ConfigInstance.GetString("game", "window_class"))
            info .= Format("  窗口标题: {}`n", ConfigInstance.GetString("game", "window_title"))
            info .= Format("  进程名: {}", ConfigInstance.GetString("game", "process_name"))

            MsgBox(info, "调试信息", "ICONINFORMATION")

        }
        catch as e {
            MsgBox("获取调试信息失败: " e.Message, "错误", "ICONERROR")
        }
    }
}

; 主程序
if (A_ScriptName = "TestWindowDetection.ahk") {
    tester := WindowDetectionTester()

    ; 创建简单的GUI
    gui := Gui("+Resize +MinSize300x200", "窗口检测测试器")

    gui.Add("Text", "w300", "选择要执行的操作:")
    gui.Add("Button", "w120 h30", "测试检测").OnEvent("Click", "TestBtn_Click")
    gui.Add("Button", "w120 h30 xm+130 yp", "显示调试信息").OnEvent("Click", "DebugBtn_Click")
    gui.Add("Button", "w120 h30 xm+260 yp", "退出").OnEvent("Click", "ExitBtn_Click")

    gui.Show()

    TestBtn_Click(ctrl, info) {
        tester.TestWindowDetection()
    }

    DebugBtn_Click(ctrl, info) {
        tester.ShowDebugInfo()
    }

    ExitBtn_Click(ctrl, info) {
        ExitApp
    }
}