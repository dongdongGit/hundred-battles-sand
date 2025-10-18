/**
 * 除魔任务图像模板管理器
 * 处理除魔任务相关的图像识别模板和规则
 */

#Requires AutoHotkey v2.0

class DemonPurgeTemplates {
    __New() {
        this.templatePath := A_ScriptDir "\..\resources\templates\demon_purge"
        this.templates := Map()
        this.isInitialized := false

        ; 模板定义
        this.templateDefinitions := Map()

        ; 除魔任务文字模板（红框内）
        this.templateDefinitions["demon_task_text"] := Map(
            "description", "除魔任务文字模板",
            "confidence", 0.8,
            "search_area", "50|300|200|350"
        )

        ; 绿色"可接"文字模板
        this.templateDefinitions["available_status"] := Map(
            "description", "可接状态绿色文字模板",
            "confidence", 0.85,
            "search_area", "200|300|280|330"
        )

        ; 鞋子图标模板
        this.templateDefinitions["shoe_icon"] := Map(
            "description", "鞋子图标模板",
            "confidence", 0.9,
            "search_area", "300|350|400|450"
        )

        ; 接受任务按钮模板
        this.templateDefinitions["accept_button"] := Map(
            "description", "接受任务按钮模板",
            "confidence", 0.8,
            "search_area", "350|480|500|520"
        )

        ; 前往完成按钮模板
        this.templateDefinitions["goto_button"] := Map(
            "description", "前往完成按钮模板",
            "confidence", 0.8,
            "search_area", "350|530|500|570"
        )

        ; 领取奖励按钮模板
        this.templateDefinitions["claim_button"] := Map(
            "description", "领取奖励按钮模板",
            "confidence", 0.8,
            "search_area", "350|580|500|620"
        )

        ; 任务完成状态模板
        this.templateDefinitions["completed_status"] := Map(
            "description", "任务完成状态模板",
            "confidence", 0.85,
            "search_area", "200|300|280|330"
        )

        this.Initialize()
    }

    Initialize() {
        LoggerInstance.Info("初始化除魔任务模板管理器")

        try {
            ; 确保模板目录存在
            if (!DirExist(this.templatePath)) {
                DirCreate(this.templatePath)
                LoggerInstance.Info("创建除魔任务模板目录: " this.templatePath)
            }

            ; 加载现有模板
            this.LoadExistingTemplates()

            ; 创建默认模板（如果不存在）
            this.CreateDefaultTemplates()

            this.isInitialized := true
            LoggerInstance.Info(Format("除魔任务模板管理器初始化完成，共 {} 个模板", this.templates.Count))

        }
        catch as e {
            LoggerInstance.Error(Format("除魔任务模板管理器初始化失败: {}", e.Message))
            throw e
        }
    }

    ; 加载现有的图像模板
    LoadExistingTemplates() {
        LoggerInstance.Debug("加载除魔任务图像模板")

        if (!DirExist(this.templatePath)) {
            return
        }

        ; 遍历模板目录
        loop files this.templatePath "\*.*", "R" {
            if (A_LoopFileExt ~= "i)^(png|jpg|jpeg|bmp)$") {
                try {
                    templateName := RegExReplace(A_LoopFileName, "\.[^.]*$")
                    templateInfo := this.templateDefinitions[templateName]

                    if (templateInfo) {
                        this.templates[templateName] := Map(
                            "path", A_LoopFileFullPath,
                            "bitmap", "",
                            "width", 0,
                            "height", 0,
                            "confidence", templateInfo["confidence"],
                            "search_area", templateInfo["search_area"],
                            "description", templateInfo["description"]
                        )

                        LoggerInstance.Debug(Format("加载模板: {} -> {}", templateName, A_LoopFileFullPath))
                    }
                }
                catch as e {
                    LoggerInstance.Warn(Format("加载模板失败 {}: {}", A_LoopFileName, e.Message))
                }
            }
        }
    }

    ; 创建默认模板（纯色块模板）
    CreateDefaultTemplates() {
        LoggerInstance.Debug("创建默认除魔任务模板")

        ; 为每个模板定义创建默认的纯色图像
        for templateName, templateInfo in this.templateDefinitions {
            if (!FileExist(this.templatePath "\" templateName ".png")) {
                this.CreateColorTemplate(templateName, templateInfo)
            }
        }
    }

    ; 创建颜色模板（用于测试）
    CreateColorTemplate(templateName, templateInfo) {
        try {
            templateFile := this.templatePath "\" templateName ".png"

            ; 根据模板类型创建不同颜色的图像
            switch templateName {
                case "demon_task_text":
                    color := 0xFF0000  ; 红色文字
                case "available_status":
                    color := 0x00FF00  ; 绿色文字
                case "shoe_icon":
                    color := 0x8B4513  ; 鞋子颜色（棕色）
                case "accept_button":
                    color := 0x4CAF50  ; 绿色按钮
                case "goto_button":
                    color := 0x2196F3  ; 蓝色按钮
                case "claim_button":
                    color := 0xFF9800  ; 橙色按钮
                case "completed_status":
                    color := 0x808080  ; 灰色文字
                default:
                    color := 0xFFFFFF  ; 默认白色
            }

            ; 创建一个小的位图（20x20像素）
            width := 60
            height := 30

            ; 使用GDI+创建图像
            pBitmap := GdipCreateBitmap(width, height)
            G := GdipGraphicsFromImage(pBitmap)

            ; 填充颜色
            pBrush := GdipBrushCreateSolid(color)
            GdipFillRectangle(G, pBrush, 0, 0, width, height)

            ; 保存为PNG文件
            GdipSaveBitmapToFile(pBitmap, templateFile)

            ; 释放资源
            GdipDeleteBrush(pBrush)
            GdipDeleteGraphics(G)
            GdipDisposeImage(pBitmap)

            LoggerInstance.Debug(Format("创建颜色模板: {} -> {}", templateName, templateFile))

        }
        catch as e {
            LoggerInstance.Error(Format("创建颜色模板失败 {}: {}", templateName, e.Message))
        }
    }

    ; 获取模板信息
    GetTemplate(templateName) {
        if (this.templates.Has(templateName)) {
            return this.templates[templateName]
        }
        return false
    }

    ; 添加自定义模板
    AddTemplate(name, imagePath, confidence := 0.8, searchArea := "") {
        try {
            if (!FileExist(imagePath)) {
                throw Error(Format("模板文件不存在: {}", imagePath))
            }

            this.templates[name] := Map(
                "path", imagePath,
                "bitmap", "",
                "width", 0,
                "height", 0,
                "confidence", confidence,
                "search_area", searchArea,
                "description", "自定义模板: " name
            )

            LoggerInstance.Info(Format("添加自定义模板: {} -> {}", name, imagePath))
            return true

        }
        catch as e {
            LoggerInstance.Error(Format("添加模板失败: {}", e.Message))
            return false
        }
    }

    ; 查找图像模板
    FindTemplate(templateName, &foundX, &foundY) {
        if (!this.isInitialized) {
            throw Error("除魔任务模板管理器未初始化")
        }

        if (!this.templates.Has(templateName)) {
            throw Error(Format("模板不存在: {}", templateName))
        }

        try {
            template := this.templates[templateName]

            ; 如果是首次使用，加载位图
            if (!template["bitmap"]) {
                template["bitmap"] := GdipCreateBitmapFromFile(template["path"])
                GdipGetImageDimension(template["bitmap"], &w, &h)
                template["width"] := w
                template["height"] := h
            }

            ; 在指定区域内搜索图像
            searchArea := template["search_area"]
            if (searchArea) {
                coords := StrSplit(searchArea, "|")
                if (coords.Length >= 4) {
                    x1 := Integer(coords[1])
                    y1 := Integer(coords[2])
                    x2 := Integer(coords[3])
                    y2 := Integer(coords[4])
                }
                else {
                    ; 使用默认搜索区域
                    x1 := 0
                    y1 := 0
                    x2 := -1
                    y2 := -1
                }
            }

            ; 调用图像识别模块进行搜索
            return ImageRecognitionInstance.FindImage(templateName, &foundX, &foundY, searchArea)

        }
        catch as e {
            LoggerInstance.Error(Format("查找模板失败: {}", e.Message))
            return false
        }
    }

    ; 等待模板出现
    WaitForTemplate(templateName, timeout := 10000) {
        startTime := A_TickCount

        while (A_TickCount - startTime < timeout) {
            try {
                if (this.FindTemplate(templateName, &foundX, &foundY)) {
                    LoggerInstance.Debug(Format("模板出现: {} at ({},{})", templateName, foundX, foundY))
                    return true
                }
            }
            catch {
                ; 忽略错误，继续等待
            }

            Sleep(500)  ; 每500ms检查一次
        }

        LoggerInstance.Warn(Format("等待模板超时: {}", templateName))
        return false
    }

    ; 点击模板位置
    ClickTemplate(templateName, offsetX := 0, offsetY := 0) {
        try {
            if (!this.FindTemplate(templateName, &foundX, &foundY)) {
                throw Error(Format("未找到模板: {}", templateName))
            }

            ; 计算点击位置（模板中心 + 偏移）
            template := this.templates[templateName]
            clickX := foundX + (template["width"] // 2) + offsetX
            clickY := foundY + (template["height"] // 2) + offsetY

            ; 点击
            WindowManagerInstance.ClickInGame(clickX, clickY)

            LoggerInstance.Debug(Format("点击模板: {} at ({},{})", templateName, clickX, clickY))
            return true

        }
        catch as e {
            LoggerInstance.Error(Format("点击模板失败: {}", e.Message))
            return false
        }
    }

    ; 获取模板列表
    GetTemplateList() {
        return this.templates.Keys()
    }

    ; 获取模板统计信息
    GetStats() {
        return Map(
            "total_templates", this.templates.Count,
            "initialized", this.isInitialized,
            "template_path", this.templatePath,
            "definitions", this.templateDefinitions.Count
        )
    }

    ; 清理资源
    Cleanup() {
        LoggerInstance.Info("清理除魔任务模板资源")

        ; 释放所有位图资源
        for name, template in this.templates {
            if (template["bitmap"]) {
                GdipDisposeImage(template["bitmap"])
                template["bitmap"] := ""
            }
        }

        this.templates := Map()
        this.isInitialized := false
    }

    ; 获取调试信息
    GetDebugInfo() {
        debugInfo := this.GetStats()

        templateDetails := []
        for name, template in this.templates {
            templateDetails.Push(Map(
                "name", name,
                "path", template["path"],
                "confidence", template["confidence"],
                "search_area", template["search_area"],
                "description", template["description"]
            ))
        }
        debugInfo["templates"] := templateDetails

        return debugInfo
    }

    ; 重新加载模板
    ReloadTemplates() {
        LoggerInstance.Info("重新加载除魔任务模板")

        this.Cleanup()
        this.Initialize()
    }

    ; 验证模板有效性
    ValidateTemplates() {
        LoggerInstance.Info("验证除魔任务模板有效性")

        validCount := 0
        totalCount := 0

        for name, template in this.templates {
            totalCount++
            try {
                if (FileExist(template["path"])) {
                    validCount++
                    LoggerInstance.Debug(Format("模板有效: {}", name))
                }
                else {
                    LoggerInstance.Warn(Format("模板文件不存在: {}", name))
                }
            }
            catch as e {
                LoggerInstance.Error(Format("验证模板失败 {}: {}", name, e.Message))
            }
        }

        LoggerInstance.Info(Format("模板验证完成: {}/{} 有效", validCount, totalCount))
        return validCount = totalCount
    }
}

; 注意：不再创建全局实例，由主程序统一管理
