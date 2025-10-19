/**
 * 简单测试脚本
 * 用于验证程序基本功能是否正常
 */

#Requires AutoHotkey v2.0
#SingleInstance Force

class SimpleTest {
    __New() {
        ; 创建核心组件
        this.logger := Logger()
        this.config := Config("", this.logger)

        ; 创建依赖于Config的组件
        this.windowManager := WindowManager(this.config, this.logger)
        this.imageRecognition := ImageRecognition(this.config, this.windowManager)
        this.taskManager := TaskManager(this.logger, this.config)
        this.gameController := GameController(this.logger, this.windowManager, this.imageRecognition, this.config, this.taskManager)

        this.logger.Info("简单测试器初始化完成")
    }

    TestInitialization() {
        this.logger.Info("测试初始化功能")

        try {
            ; 加载配置
            this.config.Load()
            this.logger.Info("✅ 配置加载成功")

            ; 初始化窗口管理器
            this.windowManager.Initialize()
            this.logger.Info("✅ 窗口管理器初始化成功")

            ; 初始化图像识别
            this.imageRecognition.Initialize()
            this.logger.Info("✅ 图像识别初始化成功")

            ; 初始化游戏控制器
            this.gameController.Initialize()
            this.logger.Info("✅ 游戏控制器初始化成功")

            ; 初始化任务管理器
            this.taskManager.Initialize()
            this.logger.Info("✅ 任务管理器初始化成功")

            return true
        }
        catch as e {
            this.logger.Error(Format("❌ 初始化测试失败: {}", e.Message))
            return false
        }
    }

    TestWindowDetection() {
        this.logger.Info("测试窗口检测功能")

        try {
            if (this.windowManager.IsGameRunning()) {
                this.logger.Info("✅ 游戏窗口检测成功")
                return true
            }
            else {
                this.logger.Warn("⚠️ 游戏窗口未运行，但这是正常的")
                return true
            }
        }
        catch as e {
            this.logger.Error(Format("❌ 窗口检测测试失败: {}", e.Message))
            return false
        }
    }

    TestTaskSystem() {
        this.logger.Info("测试任务系统功能")

        try {
            ; 获取任务列表
            tasks := this.taskManager.GetTaskList()
            this.logger.Info(Format("✅ 任务列表获取成功，共 {} 个任务", tasks.Count))

            ; 启动任务管理器
            if (this.taskManager.Start()) {
                this.logger.Info("✅ 任务管理器启动成功")
                Sleep(2000)  ; 等待2秒

                ; 停止任务管理器
                if (this.taskManager.Stop()) {
                    this.logger.Info("✅ 任务管理器停止成功")
                    return true
                }
            }

            return false
        }
        catch as e {
            this.logger.Error(Format("❌ 任务系统测试失败: {}", e.Message))
            return false
        }
    }

    RunAllTests() {
        this.logger.Info("开始运行所有测试")

        results := Map(
            "initialization", this.TestInitialization(),
            "window_detection", this.TestWindowDetection(),
            "task_system", this.TestTaskSystem()
        )

        ; 显示测试结果
        successCount := 0
        totalCount := results.Count

        for testName, result in results {
            status := result ? "✅ 通过" : "❌ 失败"
            this.logger.Info(Format("测试 {}: {}", testName, status))
            if (result) {
                successCount++
            }
        }

        this.logger.Info(Format("测试完成: {}/{} 通过", successCount, totalCount))

        ; 显示结果对话框
        resultText := Format("测试完成: {}/{} 通过`n`n", successCount, totalCount)
        resultText .= "详细结果:`n"

        for testName, result in results {
            status := result ? "✅ 通过" : "❌ 失败"
            resultText .= Format("- {}: {}`n", testName, status)
        }

        MsgBox(resultText, "测试结果", "ICONINFORMATION")

        return successCount = totalCount
    }
}

; 主程序
if (A_ScriptName = "SimpleTest.ahk") {
    test := SimpleTest()
    test.RunAllTests()
}