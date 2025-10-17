/**
 * 百战沙场自动化脚本 - 主程序入口
 * AutoHotkey v2.0
 *
 * 功能：
 * - 游戏自动化控制
 * - 图形界面管理
 * - 任务调度和执行
 * - 日志记录和管理
 * - 后台运行支持
 */

#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

; 全局变量
global AppName := "百战沙场自动化"
global AppVersion := "1.0.0"
global ConfigFile := A_ScriptDir "\..\resources\config\config.ini"
global LogFile := A_ScriptDir "\..\logs\app.log"
global GameWindowClass := "MainView_9F956014-12FC-42d8-80C7-9A90D4D567E3"
global GameWindowTitle := "百战沙场"

; 包含模块
#Include "modules\Logger.ahk"
#Include "modules\Config.ahk"
#Include "modules\WindowManager.ahk"
#Include "modules\GameController.ahk"
#Include "modules\ImageRecognition.ahk"
#Include "modules\TaskManager.ahk"
#Include "gui\MainGUI.ahk"

class AutomationApp {
    __New() {
        this.Logger := Logger()
        this.Config := Config()
        this.WindowManager := WindowManager()
        this.GameController := GameController()
        this.ImageRecognition := ImageRecognition()
        this.TaskManager := TaskManager()
        this.MainGUI := MainGUI()

        ; 初始化日志
        this.Logger.Info(Format("{} v{} 启动中...", AppName, AppVersion))

        ; 加载配置
        this.Config.Load()

        ; 初始化组件
        this.InitializeComponents()

        ; 显示主界面
        this.MainGUI.Show()

        this.Logger.Info("应用程序初始化完成")
    }

    InitializeComponents() {
        try {
            ; 初始化窗口管理器
            this.WindowManager.Initialize()

            ; 初始化图像识别
            this.ImageRecognition.Initialize()

            ; 初始化游戏控制器
            this.GameController.Initialize()

            ; 初始化任务管理器
            this.TaskManager.Initialize()

            this.Logger.Info("所有组件初始化完成")
        }
        catch as e {
            this.Logger.Error(Format("组件初始化失败: {}", e.Message))
            throw e
        }
    }

    Start() {
        this.Logger.Info("开始执行自动化任务")

        try {
            ; 检查游戏窗口
            if (!this.WindowManager.IsGameRunning()) {
                this.Logger.Warn("游戏窗口未找到，尝试启动游戏")
                if (!this.GameController.StartGame()) {
                    throw Error("无法启动游戏，请手动打开游戏")
                }
            }

            ; 激活游戏窗口
            this.WindowManager.ActivateGameWindow()

            ; 开始任务执行
            this.TaskManager.Start()

            this.Logger.Info("自动化任务开始执行")
        }
        catch as e {
            this.Logger.Error(Format("启动失败: {}", e.Message))
            this.MainGUI.ShowError("启动失败", e.Message)
        }
    }

    Stop() {
        this.Logger.Info("停止自动化任务")

        try {
            ; 停止任务管理器
            this.TaskManager.Stop()

            ; 释放资源
            this.GameController.Cleanup()

            this.Logger.Info("自动化任务已停止")
        }
        catch as e {
            this.Logger.Error(Format("停止时出错: {}", e.Message))
        }
    }

    Exit() {
        this.Logger.Info("退出应用程序")

        try {
            ; 保存配置
            this.Config.Save()

            ; 停止所有任务
            this.Stop()

            ; 释放所有资源
            this.Cleanup()

            this.Logger.Info("应用程序退出完成")
        }
        catch as e {
            this.Logger.Error(Format("退出时出错: {}", e.Message))
        }
    }

    Cleanup() {
        ; 清理资源
        this.TaskManager.Cleanup()
        this.GameController.Cleanup()
        this.WindowManager.Cleanup()
    }

    ; 热键处理
    OnHotkey(key) {
        switch key {
            case "F12":
                this.Exit()
            case "F11":
                this.Stop()
            case "F10":
                this.Start()
        }
    }
}

; 创建应用程序实例
global App := AutomationApp()

; 热键设置
Hotkey("F10", (*) => App.Start())
Hotkey("F11", (*) => App.Stop())
Hotkey("F12", (*) => App.Exit())

; 退出处理
OnExit((*) => App.Exit())

; 脚本启动完成提示
TrayTip(AppName " 已启动", Format("按 F10 开始, F11 停止, F12 退出`n日志文件: {}", LogFile), "ICONI")

; 主消息循环
return

; 包含错误处理
#Include "modules\ErrorHandler.ahk"