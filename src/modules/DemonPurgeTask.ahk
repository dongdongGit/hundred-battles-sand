/**
 * 除魔任务自动化类
 * 处理除魔任务的完整自动化流程，包括接取、执行和奖励领取
 */

class DemonPurgeTask {
    __New() {
        this.gameController := GameControllerInstance
        this.windowManager := WindowManagerInstance
        this.imageRecognition := ImageRecognitionInstance
        this.templates := DemonPurgeTemplatesInstance
        this.logger := LoggerInstance

        ; 任务状态
        this.taskStatus := "idle"  ; idle, checking, accepting, executing, claiming, completed
        this.currentCycle := 0
        this.maxCycles := 10  ; 每日最大执行次数
        this.cycleDelay := 2000  ; 循环间隔

        ; 任务栏相关
        this.taskBarArea := Map()  ; 任务栏滚动区域
        this.taskBarArea["x1"] := 100
        this.taskBarArea["y1"] := 200
        this.taskBarArea["x2"] := 300
        this.taskBarArea["y2"] := 600

        ; 颜色定义
        this.colors := Map()
        this.colors["green_available"] := 0x00FF00  ; 绿色"可接"
        this.colors["gray_completed"] := 0x808080   ; 灰色"完成"

        ; 文字识别区域（基于用户提供的截图）
        this.textAreas := Map()
        this.textAreas["task_name"] := "50|300|150|320"     ; 除魔任务文字区域
        this.textAreas["task_status"] := "200|300|250|320"   ; 任务状态文字区域
        this.textAreas["accept_button"] := "400|500|480|530"  ; 接受任务按钮区域
        this.textAreas["goto_button"] := "400|550|480|580"    ; 前往完成按钮区域
        this.textAreas["claim_button"] := "400|600|480|630"   ; 领取奖励按钮区域

        ; 图标位置（鞋子图标等）
        this.iconPositions := Map()
        this.iconPositions["shoe_icon"] := "350|400"  ; 鞋子图标位置

        ; 任务执行统计
        this.stats := Map()
        this.stats["total_attempts"] := 0
        this.stats["successful_cycles"] := 0
        this.stats["failed_cycles"] := 0
        this.stats["last_execution"] := 0

        this.Initialize()
    }

    Initialize() {
        this.logger.Info("初始化除魔任务模块")

        ; 从配置加载参数
        this.LoadConfig()

        ; 验证游戏连接
        if (!this.gameController.IsGameReady()) {
            throw Error("游戏未就绪，无法执行除魔任务")
        }

        this.logger.Info("除魔任务模块初始化完成")
    }

    LoadConfig() {
        ; 从配置加载任务相关参数
        this.maxCycles := ConfigInstance.GetInt("demon_purge", "max_daily_cycles", 10)
        this.cycleDelay := ConfigInstance.GetInt("demon_purge", "cycle_delay", 2000)

        ; 加载区域配置（如果有的话）
        taskBarConfig := ConfigInstance.GetString("demon_purge", "taskbar_area", "")
        if (taskBarConfig) {
            coords := StrSplit(taskBarConfig, "|")
            if (coords.Length >= 4) {
                this.taskBarArea["x1"] := Integer(coords[1])
                this.taskBarArea["y1"] := Integer(coords[2])
                this.taskBarArea["x2"] := Integer(coords[3])
                this.taskBarArea["y2"] := Integer(coords[4])
            }
        }
    }

    ; 执行完整任务流程
    ExecuteFullCycle() {
        this.logger.Info("开始执行除魔任务完整流程")
        this.taskStatus := "checking"
        this.stats["total_attempts"]++

        try {
            ; 准备工作
            if (!this.PrepareForTask()) {
                this.logger.Error("除魔任务准备工作失败")
                return false
            }

            ; 步骤1：检查是否有可接的除魔任务
            if (!this.CheckForAvailableTask()) {
                this.logger.Info("没有找到可接的除魔任务")
                return false
            }

            ; 步骤2：接取任务
            if (!this.AcceptTask()) {
                this.logger.Error("接取除魔任务失败")
                this.stats["failed_cycles"]++
                return false
            }

            ; 步骤3：执行任务（前往完成）
            if (!this.ExecuteTask()) {
                this.logger.Error("执行除魔任务失败")
                this.stats["failed_cycles"]++
                return false
            }

            ; 步骤4：领取奖励
            if (!this.ClaimReward()) {
                this.logger.Error("领取除魔任务奖励失败")
                this.stats["failed_cycles"]++
                return false
            }

            ; 成功完成一个循环
            this.currentCycle++
            this.stats["successful_cycles"]++
            this.stats["last_execution"] := A_TickCount
            this.taskStatus := "completed"

            this.logger.Info(Format("除魔任务完成，第 {} 次执行成功", this.currentCycle))
            return true

        }
        catch as e {
            this.logger.Error(Format("除魔任务执行出错: {}", e.Message))
            this.taskStatus := "idle"
            this.stats["failed_cycles"]++
            return false
        }
    }

    ; 检查是否有可接的除魔任务
    CheckForAvailableTask() {
        this.logger.Debug("检查可接的除魔任务")

        try {
            ; 激活游戏窗口
            this.windowManager.ActivateGameWindow()

            ; 模拟鼠标上下拖动来查找任务
            this.ScrollTaskBar()

            ; 查找"除魔任务"文字（红色方框内）
            taskFound := this.FindTaskByText()

            if (!taskFound) {
                this.logger.Debug("未找到除魔任务")
                return false
            }

            ; 检查任务状态是否为"可接"（绿色文字）
            statusAvailable := this.CheckTaskStatus()

            if (statusAvailable) {
                this.logger.Info("找到可接的除魔任务")
                return true
            }
            else {
                this.logger.Info("除魔任务状态不可接")
                return false
            }
        }
        catch as e {
            this.logger.Error(Format("检查任务时出错: {}", e.Message))
            return false
        }
    }

    ; 模拟鼠标拖动任务栏
    ScrollTaskBar() {
        this.logger.Debug("滚动任务栏查找除魔任务")

        try {
            ; 获取任务栏区域中心点
            centerX := (this.taskBarArea["x1"] + this.taskBarArea["x2"]) // 2
            centerY := (this.taskBarArea["y1"] + this.taskBarArea["y2"]) // 2

            ; 向上拖动
            this.windowManager.MoveMouseInGame(centerX, this.taskBarArea["y1"] + 50)
            Sleep(500)
            this.windowManager.ClickInGame(centerX, this.taskBarArea["y1"] + 50, "left", true)
            Sleep(500)

            ; 模拟向上滚动（多次小幅滚动）
            loop 5 {
                MouseMove(0, -20, 0, "R")
                Sleep(200)
            }

            Sleep(1000)

            ; 向下拖动查找
            loop 3 {
                MouseMove(0, 40, 0, "R")
                Sleep(300)
            }

        }
        catch as e {
            this.logger.Error(Format("滚动任务栏出错: {}", e.Message))
        }
    }

    ; 通过文字识别查找除魔任务
    FindTaskByText() {
        this.logger.Debug("通过文字识别查找除魔任务")

        try {
            ; 使用模板匹配来查找除魔任务文字
            if (this.templates.FindTemplate("demon_task_text", &foundX, &foundY)) {
                this.logger.Debug(Format("找到除魔任务文字模板 at ({},{})", foundX, foundY))
                return true
            }

            ; 如果模板匹配失败，使用颜色特征识别
            taskArea := this.textAreas["task_name"]
            coords := StrSplit(taskArea, "|")
            x := Integer(coords[1])
            y := Integer(coords[2])
            width := Integer(coords[3]) - x
            height := Integer(coords[4]) - y

            ; 查找任务名称区域内的红色文字特征
            found := false
            loop 15 {
                checkX := x + (A_Index - 1) * (width // 14)
                checkY := y + (height // 2)

                pixelColor := this.windowManager.GetColorInGame(checkX, checkY)

                ; 查找红色文字（除魔任务标题颜色）
                if (this.IsColorRed(pixelColor, 0xFF0000, 20)) {
                    found := true
                    this.logger.Debug(Format("发现红色文字特征 at ({},{})", checkX, checkY))
                    break
                }
            }

            return found

        }
        catch as e {
            this.logger.Error(Format("文字识别查找失败: {}", e.Message))
            return false
        }
    }

    ; 检查任务状态是否为"可接"
    CheckTaskStatus() {
        this.logger.Debug("检查除魔任务状态")

        try {
            ; 首先尝试使用模板匹配查找"可接"状态
            if (this.templates.FindTemplate("available_status", &foundX, &foundY)) {
                this.logger.Debug("模板匹配找到可接状态")
                return true
            }

            ; 如果模板匹配失败，使用颜色识别
            statusArea := this.textAreas["task_status"]
            coords := StrSplit(statusArea, "|")
            x := Integer(coords[1])
            y := Integer(coords[2])
            width := Integer(coords[3]) - x
            height := Integer(coords[4]) - y

            ; 查找绿色"可接"文字
            foundGreen := false
            greenPixelCount := 0

            loop 8 {
                checkX := x + (A_Index - 1) * (width // 7)
                checkY := y + (height // 2)

                pixelColor := this.windowManager.GetColorInGame(checkX, checkY)

                ; 检查是否为绿色（可接状态）
                if (this.IsColorGreen(pixelColor)) {
                    greenPixelCount++
                }
            }

            ; 如果找到足够多的绿色像素，认为状态为"可接"
            foundGreen := greenPixelCount >= 3

            if (foundGreen) {
                this.logger.Debug(Format("颜色识别找到绿色像素 {} 个，确认可接状态", greenPixelCount))
            }

            return foundGreen

        }
        catch as e {
            this.logger.Error(Format("状态检查失败: {}", e.Message))
            return false
        }
    }

    ; 判断颜色是否为绿色
    IsColorGreen(color) {
        r := (color >> 16) & 0xFF
        g := (color >> 8) & 0xFF
        b := color & 0xFF

        ; 绿色通道最强，且与其他通道差异明显
        return g > r + 30 && g > b + 30 && g > 100
    }

    ; 判断颜色是否为红色（带容差）
    IsColorRed(color, targetColor, variation := 20) {
        r1 := (color >> 16) & 0xFF
        g1 := (color >> 8) & 0xFF
        b1 := color & 0xFF

        r2 := (targetColor >> 16) & 0xFF
        g2 := (targetColor >> 8) & 0xFF
        b2 := targetColor & 0xFF

        ; 计算颜色差异
        rDiff := Abs(r1 - r2)
        gDiff := Abs(g1 - g2)
        bDiff := Abs(b1 - b2)

        return Max(rDiff, gDiff, bDiff) <= variation
    }

    ; 判断颜色是否为灰色
    IsColorGray(color) {
        r := (color >> 16) & 0xFF
        g := (color >> 8) & 0xFF
        b := color & 0xFF

        ; 灰色的RGB值比较接近
        return Abs(r - g) < 15 && Abs(g - b) < 15 && Abs(b - r) < 15
    }

    ; 接取任务
    AcceptTask() {
        this.logger.Info("开始接取除魔任务")
        this.taskStatus := "accepting"

        try {
            ; 点击鞋子图标
            if (!this.ClickShoeIcon()) {
                this.logger.Error("点击鞋子图标失败")
                return false
            }

            Sleep(1500)

            ; 点击"接受任务"按钮
            if (!this.ClickAcceptButton()) {
                this.logger.Error("点击接受任务按钮失败")
                return false
            }

            Sleep(1000)
            this.logger.Info("除魔任务接取成功")
            return true

        }
        catch as e {
            this.logger.Error(Format("接取任务失败: {}", e.Message))
            return false
        }
    }

    ; 点击鞋子图标
    ClickShoeIcon() {
        this.logger.Debug("点击鞋子图标")

        try {
            ; 首先尝试使用模板匹配
            if (this.templates.ClickTemplate("shoe_icon")) {
                this.logger.Debug("使用模板匹配点击鞋子图标成功")
                return true
            }

            ; 如果模板匹配失败，回退到坐标点击
            iconPos := this.iconPositions["shoe_icon"]
            coords := StrSplit(iconPos, "|")
            x := Integer(coords[1])
            y := Integer(coords[2])

            this.windowManager.ClickInGame(x, y)
            this.logger.Debug("使用坐标点击鞋子图标成功")
            return true

        }
        catch as e {
            this.logger.Error(Format("点击鞋子图标失败: {}", e.Message))
            return false
        }
    }

    ; 点击接受任务按钮
    ClickAcceptButton() {
        this.logger.Debug("点击接受任务按钮")

        try {
            ; 首先尝试使用模板匹配
            if (this.templates.ClickTemplate("accept_button")) {
                this.logger.Debug("使用模板匹配点击接受任务按钮成功")
                return true
            }

            ; 如果模板匹配失败，回退到坐标点击
            buttonArea := this.textAreas["accept_button"]
            coords := StrSplit(buttonArea, "|")
            x := Integer(coords[1])
            y := Integer(coords[2])
            width := Integer(coords[3]) - x
            height := Integer(coords[4]) - y

            ; 在按钮区域内查找并点击
            centerX := x + (width // 2)
            centerY := y + (height // 2)

            this.windowManager.ClickInGame(centerX, centerY)
            this.logger.Debug("使用坐标点击接受任务按钮成功")
            return true

        }
        catch as e {
            this.logger.Error(Format("点击接受任务按钮失败: {}", e.Message))
            return false
        }
    }

    ; 执行任务（前往完成）
    ExecuteTask() {
        this.logger.Info("开始执行除魔任务")
        this.taskStatus := "executing"

        try {
            ; 点击"前往完成"按钮
            if (!this.ClickGotoCompleteButton()) {
                this.logger.Error("点击前往完成按钮失败")
                return false
            }

            Sleep(2000)

            ; 等待任务完成（模拟等待时间）
            this.WaitForTaskCompletion()

            this.logger.Info("除魔任务执行完成")
            return true

        }
        catch as e {
            this.logger.Error(Format("执行任务失败: {}", e.Message))
            return false
        }
    }

    ; 点击前往完成按钮
    ClickGotoCompleteButton() {
        this.logger.Debug("点击前往完成按钮")

        try {
            ; 首先尝试使用模板匹配
            if (this.templates.ClickTemplate("goto_button")) {
                this.logger.Debug("使用模板匹配点击前往完成按钮成功")
                return true
            }

            ; 如果模板匹配失败，回退到坐标点击
            buttonArea := this.textAreas["goto_button"]
            coords := StrSplit(buttonArea, "|")
            x := Integer(coords[1])
            y := Integer(coords[2])
            width := Integer(coords[3]) - x
            height := Integer(coords[4]) - y

            centerX := x + (width // 2)
            centerY := y + (height // 2)

            this.windowManager.ClickInGame(centerX, centerY)
            this.logger.Debug("使用坐标点击前往完成按钮成功")
            return true

        }
        catch as e {
            this.logger.Error(Format("点击前往完成按钮失败: {}", e.Message))
            return false
        }
    }

    ; 等待任务完成
    WaitForTaskCompletion() {
        this.logger.Debug("等待除魔任务完成")

        maxWaitTime := 30000  ; 最大等待30秒
        checkInterval := 1000  ; 每秒检查一次
        startTime := A_TickCount

        while (A_TickCount - startTime < maxWaitTime) {
            try {
                ; 检查任务是否已完成
                if (this.IsTaskCompleted()) {
                    this.logger.Info("检测到除魔任务已完成")
                    return true
                }

                ; 检查是否有异常情况（比如任务失败）
                if (this.IsTaskFailed()) {
                    this.logger.Warn("检测到除魔任务失败")
                    return false
                }

                Sleep(checkInterval)

            }
            catch as e {
                this.logger.Error(Format("检查任务状态时出错: {}", e.Message))
                Sleep(checkInterval)
            }
        }

        this.logger.Warn("等待任务完成超时")
        return false
    }

    ; 检查任务是否已完成
    IsTaskCompleted() {
        try {
            ; 首先尝试使用模板匹配查找"完成"状态
            if (this.templates.FindTemplate("completed_status", &foundX, &foundY)) {
                return true
            }

            ; 如果模板匹配失败，使用颜色识别检查状态区域是否有灰色文字
            statusArea := this.textAreas["task_status"]
            coords := StrSplit(statusArea, "|")
            x := Integer(coords[1])
            y := Integer(coords[2])
            width := Integer(coords[3]) - x
            height := Integer(coords[4]) - y

            grayPixelCount := 0
            loop 8 {
                checkX := x + (A_Index - 1) * (width // 7)
                checkY := y + (height // 2)

                pixelColor := this.windowManager.GetColorInGame(checkX, checkY)

                if (this.IsColorGray(pixelColor)) {
                    grayPixelCount++
                }
            }

            ; 如果找到足够多的灰色像素，认为任务已完成
            return grayPixelCount >= 3

        }
        catch as e {
            this.logger.Error(Format("检查任务完成状态失败: {}", e.Message))
            return false
        }
    }

    ; 检查任务是否失败
    IsTaskFailed() {
        try {
            ; 这里可以检查是否有错误提示或其他失败标志
            ; 目前暂时返回false，表示任务进行中
            return false

        }
        catch as e {
            this.logger.Error(Format("检查任务失败状态出错: {}", e.Message))
            return false
        }
    }

    ; 领取奖励
    ClaimReward() {
        this.logger.Info("开始领取除魔任务奖励")
        this.taskStatus := "claiming"

        try {
            ; 再次点击鞋子图标
            if (!this.ClickShoeIcon()) {
                this.logger.Error("点击鞋子图标失败")
                return false
            }

            Sleep(1500)

            ; 点击"领取奖励"按钮
            if (!this.ClickClaimButton()) {
                this.logger.Error("点击领取奖励按钮失败")
                return false
            }

            Sleep(1000)
            this.logger.Info("除魔任务奖励领取成功")
            return true

        }
        catch as e {
            this.logger.Error(Format("领取奖励失败: {}", e.Message))
            return false
        }
    }

    ; 点击领取奖励按钮
    ClickClaimButton() {
        this.logger.Debug("点击领取奖励按钮")

        try {
            ; 首先尝试使用模板匹配
            if (this.templates.ClickTemplate("claim_button")) {
                this.logger.Debug("使用模板匹配点击领取奖励按钮成功")
                return true
            }

            ; 如果模板匹配失败，回退到坐标点击
            buttonArea := this.textAreas["claim_button"]
            coords := StrSplit(buttonArea, "|")
            x := Integer(coords[1])
            y := Integer(coords[2])
            width := Integer(coords[3]) - x
            height := Integer(coords[4]) - y

            centerX := x + (width // 2)
            centerY := y + (height // 2)

            this.windowManager.ClickInGame(centerX, centerY)
            this.logger.Debug("使用坐标点击领取奖励按钮成功")
            return true

        }
        catch as e {
            this.logger.Error(Format("点击领取奖励按钮失败: {}", e.Message))
            return false
        }
    }

    ; 获取任务统计信息
    GetStats() {
        stats := this.stats.Clone()
        stats["current_cycle"] := this.currentCycle
        stats["task_status"] := this.taskStatus
        stats["max_cycles"] := this.maxCycles

        return stats
    }

    ; 重置统计信息
    ResetStats() {
        this.stats["total_attempts"] := 0
        this.stats["successful_cycles"] := 0
        this.stats["failed_cycles"] := 0
        this.currentCycle := 0
        this.taskStatus := "idle"
    }

    ; 检查是否可以继续执行
    CanContinue() {
        return this.currentCycle < this.maxCycles
    }

    ; 执行安全检查
    PerformSafetyCheck() {
        this.logger.Debug("执行除魔任务安全检查")

        try {
            ; 检查游戏窗口是否仍然激活
            if (!this.windowManager.IsGameActive()) {
                this.logger.Warn("游戏窗口未激活，尝试重新激活")
                this.windowManager.ActivateGameWindow()

                if (!this.windowManager.IsGameActive()) {
                    throw Error("无法激活游戏窗口")
                }
            }

            ; 检查是否有弹出错误对话框或其他异常
            if (this.IsErrorDialogPresent()) {
                this.logger.Warn("检测到错误对话框，尝试关闭")
                this.CloseErrorDialog()
            }

            return true

        }
        catch as e {
            this.logger.Error(Format("安全检查失败: {}", e.Message))
            return false
        }
    }

    ; 检查是否有错误对话框
    IsErrorDialogPresent() {
        try {
            ; 这里可以检查是否有特定的错误标志
            ; 目前暂时返回false
            return false

        }
        catch as e {
            this.logger.Error(Format("检查错误对话框失败: {}", e.Message))
            return false
        }
    }

    ; 关闭错误对话框
    CloseErrorDialog() {
        this.logger.Debug("尝试关闭错误对话框")

        try {
            ; 发送ESC键关闭可能的对话框
            Send("{Esc}")
            Sleep(1000)

            ; 也可以尝试点击右上角的关闭按钮
            ; 这里需要根据实际游戏界面调整坐标
            this.windowManager.ClickInGame(900, 100)  ; 假设关闭按钮在右上角

        }
        catch as e {
            this.logger.Error(Format("关闭错误对话框失败: {}", e.Message))
        }
    }

    ; 执行任务前的准备工作
    PrepareForTask() {
        this.logger.Debug("准备执行除魔任务")

        try {
            ; 执行安全检查
            if (!this.PerformSafetyCheck()) {
                return false
            }

            ; 确保鼠标位置不会干扰操作
            this.windowManager.MoveMouseInGame(100, 100)  ; 移动到安全位置
            Sleep(500)

            return true

        }
        catch as e {
            this.logger.Error(Format("任务准备失败: {}", e.Message))
            return false
        }
    }
}

; 全局除魔任务实例
global DemonPurgeTaskInstance := DemonPurgeTask()