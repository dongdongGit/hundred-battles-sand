/**
 * 百战沙城自动化脚本 - 主程序入口
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
global AppName := "百战沙城自动化"
global AppVersion := "1.0.0"
global ConfigFile := A_ScriptDir "\..\resources\config\config.ini"
global LogFile := A_ScriptDir "\logs\app.log"

; 包含模块
#Include "modules\Logger.ahk"
#Include "modules\Config.ahk"
#Include "modules\WindowManager.ahk"
#Include "modules\GameController.ahk"
#Include "modules\ImageRecognition.ahk"
#Include "modules\DemonPurgeTemplates.ahk"
#Include "modules\TaskManager.ahk"
#Include "modules\DemonPurgeTask.ahk"
#Include "modules\WildBossTask.ahk"
#Include "modules\DemonPurgeTemplates.ahk"
#Include "modules\ImageRecognition.ahk"
#Include "modules\GameController.ahk"
#Include "utils\DemonPurgeTest.ahk"
#Include "gui\MainGUI.ahk"

class AutomationApp {
    __New() {
        ; 创建配置实例（需要先创建以便读取日志配置）
        this.Config := Config("", "")

        ; 创建日志器并配置
        this.Logger := Logger()
        logConfig := Map(
            "level", this.Config.GetString("logging", "level", "INFO"),
            "file", LogFile,
            "console", this.Config.GetBool("logging", "enable_console_output", true),
            "fileOutput", this.Config.GetBool("logging", "enable_file_output", true),
            "maxFileSize", this.Config.GetInt("logging", "max_file_size", 10485760),
            "backupCount", this.Config.GetInt("logging", "backup_count", 5)
        )
        this.Logger.Configure(logConfig)

        ; 重新设置Config的日志实例
        this.Config.logger := this.Logger

        ; 创建依赖于Config的组件
        this.WindowManager := WindowManager(this.Config, this.Logger)
        this.ImageRecognition := ImageRecognition(this.Config, this.WindowManager)
        this.TaskManager := TaskManager(this.Logger, this.Config)
        this.WildBossTask := WildBossTask(this.Logger, this.Config, this.WindowManager, this.ImageRecognition)
        this.GameController := GameController(this.Logger, this.WindowManager, this.ImageRecognition, this.Config, this.TaskManager)
        this.MainGUI := MainGUI(this.Logger, this.Config, this.WindowManager, this.ImageRecognition, this.TaskManager)

        ; 加载配置
        this.Config.Load()

        ; 初始化日志器
        this.Logger.Initialize()

        ; 初始化日志
        this.Logger.Info(Format("{} v{} 启动中...", AppName, AppVersion))

        ; 初始化组件
        this.InitializeComponents()

        ; 显示主界面
        this.MainGUI.Show()

        ; 设置状态更新定时器（每秒更新一次）
        this.statusUpdateTimer := (*) => this.UpdateGUIStatus()
        SetTimer(this.statusUpdateTimer, 1000)

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

            ; 初始化野外BOSS任务
            this.WildBossTask.Initialize()

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
            ToolTip("正在检查游戏窗口...")
            Sleep(1000)

            ; 检查游戏窗口
            if (!this.WindowManager.IsGameRunning()) {
                ToolTip("游戏窗口未找到，正在搜索...")
                this.Logger.Warn("游戏窗口未找到，开始搜索")

                ; 显示搜索进度
                found := false
                for i in [1, 2, 3] {
                    ToolTip(Format("搜索中... 第 {} 次尝试", i))
                    Sleep(1000)

                    if (this.WindowManager.FindGameWindow()) {
                        found := true
                        this.Logger.Info("找到游戏窗口")
                        break
                    }
                }

                if (!found) {
                    this.Logger.Info("游戏窗口未找到，请确保QQ游戏和《百战沙城》已正常运行")
                    ToolTip("游戏窗口未找到，请确保游戏已启动")
                    Sleep(2000)

                    ; 尝试启动游戏
                    if (!this.GameController.StartGame()) {
                        ; 显示更详细的错误信息和解决方案
                        errorMsg := "请手动启动QQ游戏并打开《百战沙城》，`n" .
                            "然后点击启动按钮重新开始自动化。`n`n" .
                            "如果游戏已运行但检测不到，请：`n" .
                            "1. 打开调试信息页面`n" .
                            "2. 点击『窗口检测测试』按钮`n" .
                            "3. 查看检测到了哪些窗口`n" .
                            "4. 确认游戏窗口是否在列表中`n`n" .
                            "如果问题仍然存在，请联系开发者获取帮助。"

                        this.MainGUI.ShowInfo("游戏未运行", errorMsg)
                        ToolTip("")
                        return
                    }
                }
            }

            ToolTip("游戏窗口已找到，正在测试连接...")
            ; 测试游戏连接
            if (!this.GameController.TestConnection()) {
                ToolTip("游戏连接测试失败，但窗口已运行。将继续执行任务...")
                this.Logger.Info("游戏连接测试失败，但窗口已运行。将继续执行任务")
            }

            ToolTip("正在激活游戏窗口...")
            ; 激活游戏窗口
            this.WindowManager.ActivateGameWindow()
            ToolTip("游戏窗口激活完成")

            ToolTip("正在启动任务管理器...")
            ; 开始任务执行
            this.TaskManager.Start()

            ToolTip("自动化任务已开始执行")
            Sleep(2000)
            ToolTip("")
            this.Logger.Info("自动化任务开始执行")
        }
        catch as e {
            ToolTip("")
            this.Logger.Error(Format("启动失败: {}", e.Message))
            this.MainGUI.ShowError("启动失败", e.Message)
        }
    }

    Stop() {
        this.Logger.Info("停止自动化任务")
        ToolTip("正在停止自动化任务...")
        Sleep(500)

        try {
            ; 停止任务管理器
            this.TaskManager.Stop()
            ToolTip("任务管理器已停止")

            ; 释放资源
            this.GameController.Cleanup()
            ToolTip("资源清理完成")

            this.Logger.Info("自动化任务已停止")
            ToolTip("")
        }
        catch as e {
            this.Logger.Error(Format("停止时出错: {}", e.Message))
            ToolTip("")
        }
    }

    Exit() {
        this.Logger.Info("退出应用程序")

        try {
            ; 停止状态更新定时器
            if (this.HasOwnProp("statusUpdateTimer")) {
                SetTimer(this.statusUpdateTimer, 0)
            }

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

    ShowMainWindow() {
        this.Logger.Info("显示主界面")
        this.MainGUI.ShowWindow()
    }

    UpdateGUIStatus() {
        try {
            ; 更新GUI状态
            this.MainGUI.UpdateGameStatus()
        }
        catch as e {
            ; 静默处理错误，避免定时器被中断
        }
    }

    Cleanup() {
        ; 清理资源
        this.TaskManager.Cleanup()
        this.WildBossTask.Cleanup()
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
Hotkey("F9", (*) => App.ShowMainWindow())  ; 添加显示主界面的快捷键

; 退出处理
OnExit((*) => App.Exit())

; 设置托盘图标提示（在AutoHotkey v2.0中托盘菜单比较复杂，先简化实现）
A_IconTip := AppName

; 双击托盘图标显示主界面（简化版，使用快捷键代替）

; 脚本启动完成提示
TrayTip(AppName " 已启动", Format("按 F10 开始, F11 停止, F12 退出`n按 F9 显示界面`n日志文件: {}", LogFile), "ICONI")

; 主消息循环
return

; 包含错误处理
#Include "modules\ErrorHandler.ahk"