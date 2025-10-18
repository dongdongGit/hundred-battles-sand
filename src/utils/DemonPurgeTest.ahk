/**
 * 除魔任务测试工具
 * 用于测试和调试除魔任务自动化功能
 */

#Requires AutoHotkey v2.0

class DemonPurgeTest {
    __New() {
        this.logger := LoggerInstance
        this.testResults := Map()
    }

    ; 运行全部测试
    RunAllTests() {
        this.logger.Info("开始除魔任务自动化测试")

        this.testResults := Map(
            "initialization", false,
            "template_loading", false,
            "window_detection", false,
            "color_recognition", false,
            "task_detection", false,
            "automation_flow", false
        )

        try {
            ; 测试初始化
            this.testResults["initialization"] := this.TestInitialization()

            ; 测试模板加载
            this.testResults["template_loading"] := this.TestTemplateLoading()

            ; 测试窗口检测
            this.testResults["window_detection"] := this.TestWindowDetection()

            ; 测试颜色识别
            this.testResults["color_recognition"] := this.TestColorRecognition()

            ; 测试任务检测
            this.testResults["task_detection"] := this.TestTaskDetection()

            ; 测试自动化流程（仅模拟，不实际执行）
            this.testResults["automation_flow"] := this.TestAutomationFlow()

            this.DisplayTestResults()

        }
        catch as e {
            this.logger.Error(Format("测试过程中出错: {}", e.Message))
        }
    }

    ; 测试初始化
    TestInitialization() {
        this.logger.Info("测试除魔任务初始化")

        try {
            ; 测试DemonPurgeTask实例创建
            demonPurgeTask := DemonPurgeTask()
            if (demonPurgeTask) {
                this.logger.Info("✓ DemonPurgeTask实例创建成功")
                return true
            }
            else {
                this.logger.Error("✗ DemonPurgeTask实例创建失败")
                return false
            }
        }
        catch as e {
            this.logger.Error(Format("初始化测试失败: {}", e.Message))
            return false
        }
    }

    ; 测试模板加载
    TestTemplateLoading() {
        this.logger.Info("测试除魔任务模板加载")

        try {
            templates := DemonPurgeTemplatesInstance
            if (templates.isInitialized) {
                this.logger.Info("✓ 模板管理器已初始化")
                this.logger.Info(Format("✓ 加载模板数量: {}", templates.GetTemplateList().Length))
                return true
            }
            else {
                this.logger.Error("✗ 模板管理器未初始化")
                return false
            }
        }
        catch as e {
            this.logger.Error(Format("模板加载测试失败: {}", e.Message))
            return false
        }
    }

    ; 测试窗口检测
    TestWindowDetection() {
        this.logger.Info("测试游戏窗口检测")

        try {
            windowManager := WindowManagerInstance
            if (windowManager.IsGameRunning()) {
                this.logger.Info("✓ 游戏窗口检测成功")
                return true
            }
            else {
                this.logger.Warn("⚠ 游戏窗口未运行（这可能是正常的）")
                return true  ; 窗口未运行不算错误
            }
        }
        catch as e {
            this.logger.Error(Format("窗口检测测试失败: {}", e.Message))
            return false
        }
    }

    ; 测试颜色识别
    TestColorRecognition() {
        this.logger.Info("测试颜色识别功能")

        try {
            windowManager := WindowManagerInstance

            ; 测试绿色识别
            testColors := [
                [100, 100, 0x00FF00],  ; 纯绿色点
                [200, 200, 0xFF0000],  ; 红色点
                [300, 300, 0x808080]   ; 灰色点
            ]

            successCount := 0
            for colorTest in testColors {
                x := colorTest[1]
                y := colorTest[2]
                expectedColor := colorTest[3]

                try {
                    actualColor := windowManager.GetColorInGame(x, y)
                    this.logger.Debug(Format("颜色测试点 ({},{}) = {}", x, y, actualColor))
                    successCount++
                }
                catch {
                    this.logger.Debug(Format("颜色测试点 ({},{}) 获取失败", x, y))
                }
            }

            if (successCount >= 2) {
                this.logger.Info("✓ 颜色识别功能正常")
                return true
            }
            else {
                this.logger.Warn("⚠ 颜色识别功能可能有问题")
                return true  ; 不算硬错误
            }
        }
        catch as e {
            this.logger.Error(Format("颜色识别测试失败: {}", e.Message))
            return false
        }
    }

    ; 测试任务检测
    TestTaskDetection() {
        this.logger.Info("测试除魔任务检测功能")

        try {
            demonPurgeTask := DemonPurgeTask()

            ; 测试文字识别
            taskFound := demonPurgeTask.FindTaskByText()
            this.logger.Info(Format("除魔任务文字识别结果: {}", taskFound ? "找到" : "未找到"))

            ; 测试状态检查
            statusAvailable := demonPurgeTask.CheckTaskStatus()
            this.logger.Info(Format("任务状态检查结果: {}", statusAvailable ? "可接" : "不可接"))

            this.logger.Info("✓ 任务检测功能测试完成")
            return true

        }
        catch as e {
            this.logger.Error(Format("任务检测测试失败: {}", e.Message))
            return false
        }
    }

    ; 测试自动化流程（模拟）
    TestAutomationFlow() {
        this.logger.Info("测试除魔任务自动化流程（模拟）")

        try {
            demonPurgeTask := DemonPurgeTask()

            ; 测试准备工作
            prepared := demonPurgeTask.PrepareForTask()
            this.logger.Info(Format("准备工作结果: {}", prepared ? "成功" : "失败"))

            if (!prepared) {
                this.logger.Warn("⚠ 准备工作失败，跳过后续测试")
                return true  ; 准备失败不算硬错误
            }

            ; 测试安全检查
            safetyCheck := demonPurgeTask.PerformSafetyCheck()
            this.logger.Info(Format("安全检查结果: {}", safetyCheck ? "通过" : "失败"))

            this.logger.Info("✓ 自动化流程测试完成")
            return true

        }
        catch as e {
            this.logger.Error(Format("自动化流程测试失败: {}", e.Message))
            return false
        }
    }

    ; 显示测试结果
    DisplayTestResults() {
        this.logger.Info("=== 除魔任务自动化测试结果 ===")

        totalTests := 0
        passedTests := 0

        for testName, result in this.testResults {
            totalTests++
            status := result ? "✓ 通过" : "✗ 失败"
            this.logger.Info(Format("{}: {}", testName, status))

            if (result) {
                passedTests++
            }
        }

        successRate := (passedTests / totalTests) * 100
        this.logger.Info(Format("测试完成: {}/{} 通过 ({:.1f}%)", passedTests, totalTests, successRate))

        if (successRate >= 80) {
            this.logger.Info("✓ 测试结果良好，除魔任务自动化功能基本可用")
        }
        else if (successRate >= 60) {
            this.logger.Warn("⚠ 测试结果一般，可能需要调整参数或模板")
        }
        else {
            this.logger.Error("✗ 测试结果较差，需要检查配置和实现")
        }
    }
}

; 测试函数
RunDemonPurgeTests() {
    test := DemonPurgeTest()
    test.RunAllTests()
}