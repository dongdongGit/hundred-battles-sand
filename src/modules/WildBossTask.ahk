/**
 * 野外BOSS任务模块
 * 处理野外BOSS挑战的图像识别和自动化操作
 */

#Requires AutoHotkey v2.0

class WildBossTask {
    __New(loggerInstance := "", configInstance := "", windowManagerInstance := "", imageRecognitionInstance := "") {
        ; 如果没有传入实例，使用全局实例（向后兼容）
        if (loggerInstance = "") {
            loggerInstance := LoggerInstance
        }
        if (configInstance = "") {
            configInstance := ConfigInstance
        }
        if (windowManagerInstance = "") {
            global App
            windowManagerInstance := App.WindowManager
        }
        if (imageRecognitionInstance = "") {
            global App
            imageRecognitionInstance := App.ImageRecognition
        }

        this.logger := loggerInstance
        this.config := configInstance
        this.windowManager := windowManagerInstance
        this.imageRecognition := imageRecognitionInstance

        ; 使用默认坐标配置（简化版本）
        this.bossIconArea := Map("x", 75, "y", 175)
        this.challengeButtonArea := Map("x", 275, "y", 275)
        this.bossListArea := Map("x1", 100, "y1", 350, "x2", 300, "y2", 600)
        this.locationArea := Map("x1", 350, "y1", 350, "x2", 550, "y2", 600)
    }

    Initialize() {
        this.logger.Info("初始化野外BOSS任务模块")
    }

    /**
     * 执行完整的野外BOSS挑战流程
     * @param location 要挑战的地点名称
     * @returns {boolean} 是否成功
     */
    ExecuteWildBossChallenge(location) {
        this.logger.Info(Format("开始野外BOSS挑战 - 地点: {}", location))

        try {
            ; 步骤1：检测并切换BOSS图标状态
            if (!this.ToggleBossIcon()) {
                this.logger.Error("无法切换BOSS图标状态")
                return false
            }

            ; 步骤2：点击挑战BOSS按钮
            if (!this.ClickChallengeBossButton()) {
                this.logger.Error("无法点击挑战BOSS按钮")
                return false
            }

            ; 步骤3：查找并挑战指定地点的BOSS
            if (!this.FindAndChallengeBoss(location)) {
                this.logger.Error(Format("无法在 {} 挑战BOSS", location))
                return false
            }

            this.logger.Info(Format("野外BOSS挑战成功完成 - {}", location))
            return true
        }
        catch as e {
            this.logger.Error(Format("野外BOSS挑战过程中出错: {}", e.Message))
            return false
        }
    }

    /**
     * 检测BOSS图标状态并切换
     * 根据箭头方向判断图标是否隐藏，然后点击切换
     */
    ToggleBossIcon() {
        this.logger.Debug("检测BOSS图标状态")

        try {
            ; 获取游戏窗口截图用于图像识别
            if (!this.windowManager.WindowExists()) {
                this.logger.Error("游戏窗口不存在")
                return false
            }

            ; 检测箭头方向判断图标状态
            arrowDirection := this.DetectArrowDirection()

            if (arrowDirection = "right_up") {
                ; 箭头朝向右上方，表示图标被隐藏，需要点击展开
                this.logger.Debug("检测到图标被隐藏，点击展开")
                return this.ClickBossIcon()
            }
            else if (arrowDirection = "left_down") {
                ; 箭头朝向左下方，表示图标已展开
                this.logger.Debug("图标已展开，无需切换")
                return true
            }
            else {
                ; 无法判断箭头方向，默认尝试点击
                this.logger.Debug("无法判断箭头方向，尝试点击切换")
                return this.ClickBossIcon()
            }
        }
        catch as e {
            this.logger.Error(Format("切换BOSS图标时出错: {}", e.Message))
            return false
        }
    }

    /**
     * 检测箭头方向判断图标状态
     * @returns {string} "right_up"（右上方，被隐藏）或 "left_down"（左下方，已展开）
     */
    DetectArrowDirection() {
        ; 这里需要实现图像识别逻辑来检测箭头方向
        ; 暂时返回默认状态，实际需要根据游戏截图分析

        this.logger.Debug("检测箭头方向（模拟实现）")
        return "left_down"  ; 假设已展开
    }

    /**
     * 点击BOSS图标切换展开/收起状态
     */
    ClickBossIcon() {
        try {
            ; 获取BOSS图标坐标（新的坐标结构是单个点）
            if (this.bossIconArea.Has("x") && this.bossIconArea.Has("y")) {
                ; 新的坐标结构：直接使用x,y坐标
                iconX := this.bossIconArea["x"]
                iconY := this.bossIconArea["y"]
            }
            else {
                ; 旧的坐标结构：计算中心点
                iconX := (this.bossIconArea["x1"] + this.bossIconArea["x2"]) // 2
                iconY := (this.bossIconArea["y1"] + this.bossIconArea["y2"]) // 2
            }

            ; 点击BOSS图标
            this.windowManager.ClickInGame(iconX, iconY)

            ; 等待切换动画完成
            Sleep(1500)

            this.logger.Debug("BOSS图标点击完成")
            return true
        }
        catch as e {
            this.logger.Error(Format("点击BOSS图标失败: {}", e.Message))
            return false
        }
    }

    /**
     * 点击挑战BOSS按钮
     */
    ClickChallengeBossButton() {
        try {
            ; 获取挑战按钮坐标（新的坐标结构是单个点）
            if (this.challengeButtonArea.Has("x") && this.challengeButtonArea.Has("y")) {
                ; 新的坐标结构：直接使用x,y坐标
                buttonX := this.challengeButtonArea["x"]
                buttonY := this.challengeButtonArea["y"]
            }
            else {
                ; 旧的坐标结构：计算中心点
                buttonX := (this.challengeButtonArea["x1"] + this.challengeButtonArea["x2"]) // 2
                buttonY := (this.challengeButtonArea["y1"] + this.challengeButtonArea["y2"]) // 2
            }

            ; 点击挑战BOSS按钮
            this.windowManager.ClickInGame(buttonX, buttonY)

            ; 等待界面加载
            Sleep(2000)

            this.logger.Debug("挑战BOSS按钮点击完成")
            return true
        }
        catch as e {
            this.logger.Error(Format("点击挑战BOSS按钮失败: {}", e.Message))
            return false
        }
    }

    /**
     * 查找并挑战指定地点的BOSS
     * @param location 地点名称
     */
    FindAndChallengeBoss(location) {
        this.logger.Debug(Format("查找并挑战BOSS - {}", location))

        try {
            ; 步骤1：在BOSS列表中滚动查找目标BOSS
            bossFound := this.ScrollToFindBoss(location)

            if (!bossFound) {
                this.logger.Error(Format("未找到BOSS: {}", location))
                return false
            }

            ; 步骤2：在地点区域内查找并点击进入
            if (!this.FindAndClickLocation(location)) {
                this.logger.Error(Format("无法进入地点: {}", location))
                return false
            }

            this.logger.Info(Format("成功挑战BOSS - {}", location))
            return true
        }
        catch as e {
            this.logger.Error(Format("挑战BOSS过程中出错: {}", e.Message))
            return false
        }
    }

    /**
     * 在BOSS列表中滚动查找目标BOSS
     * @param bossName 要查找的BOSS名称
     */
    ScrollToFindBoss(bossName) {
        this.logger.Debug(Format("滚动BOSS列表查找: {}", bossName))

        try {
            ; 获取当前挑战地点
            location := this.config.GetString("tasks", "wild_boss_location", "诡异神殿一层")

            ; 使用固定的挑战流程（简化版本）
            this.logger.Info(Format("开始挑战地点: {}", location))

            ; 获取BOSS列表区域坐标
            listX1 := this.bossListArea["x1"]
            listY1 := this.bossListArea["y1"]
            listX2 := this.bossListArea["x2"]
            listY2 := this.bossListArea["y2"]

            ; 使用地点配置中的滚动参数
            scrollInfo := locationInfo["scroll"]
            if (!scrollInfo) {
                this.logger.Error("地点配置中缺少滚动信息")
                return false
            }

            scrollDirection := scrollInfo["direction"]
            maxScrollDistance := scrollInfo["distance"]

            ; 计算滚动起始和结束坐标
            startX := (listX1 + listX2) // 2
            if (scrollDirection = "up") {
                startY := listY2 - 50
                endY := listY1 + 50
                stepY := -20  ; 向上滚动，每次20像素
            }
            else {
                startY := listY1 + 50
                endY := listY2 - 50
                stepY := 20   ; 向下滚动，每次20像素
            }

            ; 执行拖拽操作
            this.windowManager.MouseMoveInGame(startX, startY)
            Sleep(500)
            this.windowManager.MousePressInGame(startX, startY)
            Sleep(300)

            ; 缓慢滚动查找
            currentY := startY
            scrollDistance := 0

            while (scrollDistance < maxScrollDistance && currentY != endY) {
                currentY += stepY
                scrollDistance += Abs(stepY)
                this.windowManager.MouseMoveInGame(startX, currentY)
                Sleep(100)

                ; 检查是否找到目标BOSS
                if (this.CheckBossFound(bossName)) {
                    this.windowManager.MouseReleaseInGame(startX, currentY)
                    return true
                }
            }

            this.windowManager.MouseReleaseInGame(startX, currentY)
            return false
        }
        catch as e {
            this.logger.Error(Format("滚动BOSS列表失败: {}", e.Message))
            return false
        }
    }

    /**
     * 检查是否找到目标BOSS
     * @param bossName BOSS名称
     */
    CheckBossFound(bossName) {
        ; 这里需要实现图像识别或文字识别来检查是否找到目标BOSS
        ; 暂时返回false，表示需要继续滚动
        return false
    }

    /**
     * 在地点区域内查找并点击进入指定地点
     * @param location 地点名称
     */
    FindAndClickLocation(location) {
        this.logger.Debug(Format("查找地点并进入: {}", location))

        try {
            ; 模拟点击进入指定地点
            ; 这里需要图像识别找到指定地点的坐标并点击

            ; 暂时使用固定坐标模拟点击
            areaX1 := this.locationArea["x1"]
            areaY1 := this.locationArea["y1"]
            areaX2 := this.locationArea["x2"]
            areaY2 := this.locationArea["y2"]

            ; 点击区域中心作为进入按钮
            centerX := (areaX1 + areaX2) // 2
            centerY := (areaY1 + areaY2) // 2
            this.windowManager.ClickInGame(centerX, centerY)

            ; 等待进入动画完成
            Sleep(3000)

            this.logger.Debug(Format("成功进入地点: {}", location))
            return true
        }
        catch as e {
            this.logger.Error(Format("进入地点失败: {}", e.Message))
            return false
        }
    }

    /**
     * 执行完整的野外BOSS挑战流程
     */
    ExecuteFullCycle() {
        this.logger.Info("开始完整的野外BOSS挑战流程")

        try {
            ; 获取配置的挑战地点
            location := this.config.GetString("tasks", "wild_boss_location", "诡异神殿一层")

            ; 执行挑战流程
            success := this.ExecuteWildBossChallenge(location)

            if (success) {
                this.logger.Info("野外BOSS挑战流程完成")
            }
            else {
                this.logger.Warn("野外BOSS挑战流程失败")
            }

            return success
        }
        catch as e {
            this.logger.Error(Format("野外BOSS挑战流程出错: {}", e.Message))
            return false
        }
    }

    /**
     * 清理资源
     */
    Cleanup() {
        this.logger.Info("清理野外BOSS任务资源")
    }
}