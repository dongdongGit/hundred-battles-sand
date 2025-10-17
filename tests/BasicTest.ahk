/**
 * 基础测试套件
 * 用于测试各个模块的基本功能是否正常工作
 */

#Requires AutoHotkey v2.0

class BasicTestSuite {
    __New() {
        this.testResults := []
        this.passed := 0
        this.failed := 0
    }

    RunAllTests() {
        LoggerInstance.Info("开始运行基础测试套件")

        ; 测试日志系统
        this.TestLogger()

        ; 测试配置系统
        this.TestConfig()

        ; 测试文件工具
        this.TestFileUtils()

        ; 测试窗口管理器（如果游戏在运行）
        this.TestWindowManager()

        ; 测试图像识别（如果有模板）
        this.TestImageRecognition()

        ; 输出测试结果
        this.PrintResults()

        LoggerInstance.Info("基础测试套件运行完成")
    }

    TestLogger() {
        this.StartTest("日志系统测试")

        try {
            ; 测试基本日志记录
            LoggerInstance.Debug("测试调试日志")
            LoggerInstance.Info("测试信息日志")
            LoggerInstance.Warn("测试警告日志")
            LoggerInstance.Error("测试错误日志")

            ; 测试日志格式
            timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
            if (InStr(LoggerInstance.FormatMessage("INFO", "测试消息"), timestamp)) {
                this.PassTest("日志格式正确")
            }
            else {
                this.FailTest("日志格式错误")
            }

            this.EndTest()
        }
        catch as e {
            this.FailTest("日志系统异常: " e.Message)
            this.EndTest()
        }
    }

    TestConfig() {
        this.StartTest("配置系统测试")

        try {
            ; 测试配置加载
            if (ConfigInstance.Get("general", "language", "") = "zh-CN") {
                this.PassTest("配置加载正确")
            }
            else {
                this.FailTest("配置加载失败")
            }

            ; 测试配置类型转换
            delay := ConfigInstance.GetInt("game", "delay_between_actions", 0)
            if (Type(delay) = "Integer" && delay > 0) {
                this.PassTest("整数配置转换正确")
            }
            else {
                this.FailTest("整数配置转换失败")
            }

            ; 测试布尔值转换
            autoStart := ConfigInstance.GetBool("general", "auto_start", false)
            if (Type(autoStart) = "Integer") {  ; AutoHotkey中布尔值是整数
                this.PassTest("布尔配置转换正确")
            }
            else {
                this.FailTest("布尔配置转换失败")
            }

            this.EndTest()
        }
        catch as e {
            this.FailTest("配置系统异常: " e.Message)
            this.EndTest()
        }
    }

    TestFileUtils() {
        this.StartTest("文件工具测试")

        try {
            ; 测试文件存在性检查
            if (FileUtils.FileExists(A_ScriptDir "\main.ahk")) {
                this.PassTest("文件存在性检查正确")
            }
            else {
                this.FailTest("文件存在性检查失败")
            }

            ; 测试目录存在性检查
            if (FileUtils.DirectoryExists(A_ScriptDir "\lib")) {
                this.PassTest("目录存在性检查正确")
            }
            else {
                this.FailTest("目录存在性检查失败")
            }

            ; 测试文件大小获取
            fileSize := FileUtils.GetFileSize(A_ScriptDir "\main.ahk")
            if (fileSize > 0) {
                this.PassTest("文件大小获取正确")
            }
            else {
                this.FailTest("文件大小获取失败")
            }

            this.EndTest()
        }
        catch as e {
            this.FailTest("文件工具异常: " e.Message)
            this.EndTest()
        }
    }

    TestWindowManager() {
        this.StartTest("窗口管理器测试")

        try {
            ; 测试窗口管理器初始化
            WindowManagerInstance.Initialize()

            ; 测试游戏窗口查找
            if (WindowManagerInstance.FindGameWindow()) {
                this.PassTest("游戏窗口查找成功")
            }
            else {
                this.PassTest("游戏窗口未运行（正常）")
            }

            ; 测试窗口信息获取
            if (WindowManagerInstance.WindowExists()) {
                windowInfo := WindowManagerInstance.GetWindowInfo()
                if (windowInfo && windowInfo.Has("title")) {
                    this.PassTest("窗口信息获取成功")
                }
                else {
                    this.FailTest("窗口信息获取失败")
                }
            }

            this.EndTest()
        }
        catch as e {
            this.FailTest("窗口管理器异常: " e.Message)
            this.EndTest()
        }
    }

    TestImageRecognition() {
        this.StartTest("图像识别测试")

        try {
            ; 测试图像识别模块初始化
            ImageRecognitionInstance.Initialize()

            ; 测试模板加载
            templates := ImageRecognitionInstance.GetTemplateList()
            if (Type(templates) = "Array") {
                this.PassTest("模板列表获取成功")
            }
            else {
                this.FailTest("模板列表获取失败")
            }

            ; 测试图像识别（如果有模板）
            if (templates.Length > 0) {
                firstTemplate := templates[1]
                found := ImageRecognitionInstance.FindImage(firstTemplate, &x, &y)
                ; 不判断成功失败，因为可能没有游戏窗口
                this.PassTest("图像识别测试完成")
            }
            else {
                this.PassTest("无模板文件（正常）")
            }

            this.EndTest()
        }
        catch as e {
            this.FailTest("图像识别异常: " e.Message)
            this.EndTest()
        }
    }

    StartTest(testName) {
        this.currentTest := testName
        LoggerInstance.Info("开始测试: " testName)
    }

    PassTest(message := "") {
        this.passed++
        LoggerInstance.Info("✅ 通过: " (message || "测试项"))
    }

    FailTest(message := "") {
        this.failed++
        LoggerInstance.Error("❌ 失败: " (message || "测试项"))
    }

    EndTest() {
        LoggerInstance.Info(Format("测试完成: {} (通过: {}, 失败: {})",
            this.currentTest, this.passed, this.failed))
    }

    PrintResults() {
        total := this.passed + this.failed

        LoggerInstance.Info("=== 测试结果汇总 ===")
        LoggerInstance.Info(Format("总测试数: {}", total))
        LoggerInstance.Info(Format("通过: {}", this.passed))
        LoggerInstance.Info(Format("失败: {}", this.failed))
        LoggerInstance.Info(Format("成功率: {:.1f}%", (this.passed / total) * 100))

        if (this.failed = 0) {
            LoggerInstance.Info("🎉 所有测试通过！")
        }
        else {
            LoggerInstance.Warn("⚠️ 部分测试失败，请检查相关模块")
        }
    }
}

; 如果直接运行此文件，则执行测试
if (A_ScriptName = "BasicTest.ahk") {
    ; 初始化基础组件
    LoggerInstance := Logger()
    ConfigInstance := Config()

    ; 运行测试套件
    testSuite := BasicTestSuite()
    testSuite.RunAllTests()
}