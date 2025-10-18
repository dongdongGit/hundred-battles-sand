/**
 * 图像识别模块
 * 处理游戏界面的图像识别、按钮定位、文字识别等功能
 */

#Requires AutoHotkey v2.0

class ImageRecognition {
    __New(configInstance := "", windowManagerInstance := "") {
        ; 如果没有传入配置实例，使用全局实例（向后兼容）
        if (configInstance = "") {
            configInstance := ConfigInstance
        }
        if (windowManagerInstance = "") {
            windowManagerInstance := WindowManagerInstance
        }

        this.config := configInstance
        this.windowManager := windowManagerInstance
        this.logger := Logger()

        ; 获取模板路径并确保是绝对路径
        templatePath := this.config.GetString("recognition", "template_path")
        if (!InStr(templatePath, ":") && !InStr(templatePath, "\\")) {
            ; 相对路径，转为绝对路径
            templatePath := A_ScriptDir "\" templatePath
        }
        this.templatePath := templatePath
        this.confidenceThreshold := this.config.GetFloat("recognition", "confidence_threshold")
        this.maxSearchTime := this.config.GetInt("recognition", "max_search_time")
        this.useGrayscale := this.config.GetBool("recognition", "use_grayscale")
        this.enableTextRecognition := this.config.GetBool("recognition", "enable_text_recognition")

        this.templates := Map()
        this.isInitialized := false
    }

    Initialize() {
        this.logger.Info("初始化图像识别模块")

        try {
            ; 确保模板目录存在
            if (!DirExist(this.templatePath)) {
                DirCreate(this.templatePath)
                this.logger.Info("创建模板目录: " this.templatePath)
            }
            else {
                this.logger.Debug("模板目录已存在: " this.templatePath)
            }

            ; 加载模板图片
            this.LoadTemplates()

            this.isInitialized := true
            this.logger.Info("图像识别模块初始化完成")
        }
        catch as e {
            this.logger.Error(Format("图像识别模块初始化失败: {}", e.Message))
            throw e
        }
    }

    LoadTemplates() {
        this.logger.Debug("加载图像模板")

        ; 遍历模板目录加载图片
        if (DirExist(this.templatePath)) {
            loop files this.templatePath "\*.*", "R" {
                if (A_LoopFileExt ~= "i)^(png|jpg|jpeg|bmp)$") {
                    try {
                        templateName := RegExReplace(A_LoopFileName, "\.[^.]*$")
                        this.templates[templateName] := Map(
                            "path", A_LoopFileFullPath,
                            "bitmap", "",
                            "width", 0,
                            "height", 0
                        )

                        this.logger.Debug(Format("加载模板: {} -> {}", templateName, A_LoopFileFullPath))
                    }
                    catch as e {
                        this.logger.Warn(Format("加载模板失败 {}: {}", A_LoopFileName, e.Message))
                    }
                }
            }
        }

        this.logger.Info(Format("模板加载完成，共加载 {} 个模板", this.templates.Count))
    }

    ; 在游戏窗口中查找图像
    FindImage(templateName, &foundX, &foundY, searchArea := "") {
        if (!this.isInitialized) {
            throw Error("图像识别模块未初始化")
        }

        if (!this.templates.Has(templateName)) {
            throw Error(Format("模板不存在: {}", templateName))
        }

        try {
            template := this.templates[templateName]
            startTime := A_TickCount

            ; 截取游戏窗口
            bitmap := this.windowManager.CaptureGameWindow()

            ; 加载模板图片
            if (!template["bitmap"]) {
                template["bitmap"] := GdipCreateBitmapFromFile(template["path"])
                GdipGetImageDimension(template["bitmap"], &w, &h)
                template["width"] := w
                template["height"] := h
            }

            ; 图像搜索
            searchResult := this.ImageSearchInBitmap(
                bitmap, template["bitmap"],
                &foundX, &foundY,
                searchArea
            )

            ; 释放位图资源
            GdipDisposeImage(bitmap)

            if (searchResult) {
                this.logger.Debug(Format(
                    "图像识别成功: {} at ({},{}) 耗时: {}ms",
                    templateName, foundX, foundY, A_TickCount - startTime
                ))
                return true
            }
            else {
                this.logger.Debug(Format(
                    "图像识别失败: {} 耗时: {}ms",
                    templateName, A_TickCount - startTime
                ))
                return false
            }
        }
        catch as e {
            this.logger.Error(Format("图像识别出错: {}", e.Message))
            return false
        }
    }

    ImageSearchInBitmap(haystack, needle, &foundX, &foundY, searchArea := "") {
        ; 解析搜索区域
        if (searchArea) {
            ; 格式: "x1|y1|x2|y2"
            coords := StrSplit(searchArea, "|")
            if (coords.Length >= 4) {
                x1 := Integer(coords[1])
                y1 := Integer(coords[2])
                x2 := Integer(coords[3])
                y2 := Integer(coords[4])
            }
        }

        ; 这里需要实现实际的图像搜索算法
        ; 可以使用多种方法：模板匹配、特征点检测等

        ; 临时实现：简单的像素比较（实际项目中应该使用更高级的算法）
        return this.SimpleImageSearch(haystack, needle, &foundX, &foundY, x1?, y1?, x2?, y2?)
    }

    SimpleImageSearch(haystack, needle, &foundX, &foundY, x1 := 0, y1 := 0, x2 := -1, y2 := -1) {
        ; 获取位图尺寸
        GdipGetImageDimension(haystack, &hWidth, &hHeight)
        GdipGetImageDimension(needle, &nWidth, &nHeight)

        if (x2 = -1) {
            x2 := hWidth - nWidth
        }
        if (y2 = -1) {
            y2 := hHeight - nHeight
        }

        ; 逐像素搜索
        loop (y2 - y1) {
            y := y1 + A_Index - 1
            loop (x2 - x1) {
                x := x1 + A_Index - 1

                if (this.CompareImagesAtPosition(haystack, needle, x, y, nWidth, nHeight)) {
                    foundX := x
                    foundY := y
                    return true
                }
            }
        }

        return false
    }

    CompareImagesAtPosition(haystack, needle, x, y, width, height) {
        ; 比较两个图像在指定位置的像素
        matchCount := 0
        totalPixels := 0

        ; 采样比较（为了性能，只比较部分像素）
        step := Max(1, width // 20)  ; 比较约20个点

        loop (height // step) {
            cy := y + (A_Index - 1) * step
            if (cy >= y + height) {
                break
            }

            loop (width // step) {
                cx := x + (A_Index - 1) * step
                if (cx >= x + width) {
                    break
                }

                ; 获取像素颜色
                hColor := GdipGetPixel(haystack, cx, cy)
                nColor := GdipGetPixel(needle, cx - x, cy - y)

                ; 计算颜色差异
                if (this.CalculateColorDifference(hColor, nColor) <= 10) {  ; 允许10点差异
                    matchCount++
                }
                totalPixels++
            }
        }

        ; 计算匹配率
        if (totalPixels = 0) {
            return false
        }

        matchRate := matchCount / totalPixels
        return matchRate >= this.confidenceThreshold
    }

    CalculateColorDifference(color1, color2) {
        r1 := (color1 >> 16) & 0xFF
        g1 := (color1 >> 8) & 0xFF
        b1 := color1 & 0xFF

        r2 := (color2 >> 16) & 0xFF
        g2 := (color2 >> 8) & 0xFF
        b2 := color2 & 0xFF

        return Max(Abs(r1 - r2), Abs(g1 - g2), Abs(b1 - b2))
    }

    ; 等待图像出现
    WaitForImage(templateName, timeout := 10000, searchArea := "") {
        startTime := A_TickCount

        this.logger.Debug(Format("等待图像出现: {} 超时: {}ms", templateName, timeout))

        while (A_TickCount - startTime < timeout) {
            try {
                if (this.FindImage(templateName, &foundX, &foundY, searchArea)) {
                    this.logger.Info(Format("图像出现: {} at ({},{})", templateName, foundX, foundY))
                    return true
                }
            }
            catch {
                ; 忽略错误，继续等待
            }

            Sleep(500)  ; 每500ms检查一次
        }

        this.logger.Warn(Format("等待图像超时: {}", templateName))
        return false
    }

    ; 等待图像消失
    WaitForImageGone(templateName, timeout := 10000, searchArea := "") {
        startTime := A_TickCount

        this.logger.Debug(Format("等待图像消失: {} 超时: {}ms", templateName, timeout))

        while (A_TickCount - startTime < timeout) {
            try {
                if (!this.FindImage(templateName, &foundX, &foundY, searchArea)) {
                    this.logger.Info(Format("图像消失: {}", templateName))
                    return true
                }
            }
            catch {
                ; 图像不存在，说明已经消失
                return true
            }

            Sleep(500)
        }

        this.logger.Warn(Format("等待图像消失超时: {}", templateName))
        return false
    }

    ; 点击图像位置
    ClickImage(templateName, offsetX := 0, offsetY := 0, searchArea := "") {
        try {
            if (!this.FindImage(templateName, &foundX, &foundY, searchArea)) {
                throw Error(Format("未找到图像: {}", templateName))
            }

            ; 计算点击位置（图像中心 + 偏移）
            clickX := foundX + offsetX
            clickY := foundY + offsetY

            ; 点击
            this.windowManager.ClickInGame(clickX, clickY)

            this.logger.Debug(Format("点击图像: {} at ({},{})", templateName, clickX, clickY))
            return true
        }
        catch as e {
            this.logger.Error(Format("点击图像失败: {}", e.Message))
            return false
        }
    }

    ; 多图像识别（查找多个模板中的任意一个）
    FindAnyImage(templateNames, &foundTemplate, &foundX, &foundY, searchArea := "") {
        for templateName in templateNames {
            if (this.FindImage(templateName, &foundX, &foundY, searchArea)) {
                foundTemplate := templateName
                return true
            }
        }
        return false
    }

    ; 颜色识别（在指定区域查找特定颜色）
    FindColorInArea(color, x1, y1, x2, y2, variation := 0) {
        try {
            ; 截取指定区域
            bitmap := this.windowManager.CaptureGameWindow(x1, y1, x2 - x1, y2 - y1)

            ; 在位图中查找颜色
            found := false
            foundX := 0
            foundY := 0

            loop (y2 - y1) {
                y := y1 + A_Index - 1
                loop (x2 - x1) {
                    x := x1 + A_Index - 1

                    pixelColor := this.windowManager.GetColorInGame(x, y)
                    if (this.windowManager.ColorsMatch(pixelColor, color, variation)) {
                        found := true
                        foundX := x
                        foundY := y
                        break
                    }
                }
                if (found) {
                    break
                }
            }

            GdipDisposeImage(bitmap)

            if (found) {
                this.logger.Debug(Format("颜色找到: {} at ({},{})", color, foundX, foundY))
            }

            return found
        }
        catch as e {
            this.logger.Error(Format("颜色识别失败: {}", e.Message))
            return false
        }
    }

    ; 文字识别（如果启用）
    RecognizeText(x, y, width, height) {
        if (!this.enableTextRecognition) {
            this.logger.Warn("文字识别已禁用")
            return ""
        }

        try {
            ; 这里可以集成OCR库，如Tesseract
            ; 目前返回空字符串，等待具体实现
            this.logger.Debug(Format("文字识别区域: ({},{}) {}x{}", x, y, width, height))
            return ""
        }
        catch as e {
            this.logger.Error(Format("文字识别失败: {}", e.Message))
            return ""
        }
    }

    ; 添加自定义模板
    AddTemplate(name, imagePath) {
        try {
            if (!FileExist(imagePath)) {
                throw Error(Format("模板文件不存在: {}", imagePath))
            }

            this.templates[name] := Map(
                "path", imagePath,
                "bitmap", "",
                "width", 0,
                "height", 0
            )

            this.logger.Info(Format("添加模板: {} -> {}", name, imagePath))
            return true
        }
        catch as e {
            this.logger.Error(Format("添加模板失败: {}", e.Message))
            return false
        }
    }

    ; 移除模板
    RemoveTemplate(name) {
        if (this.templates.Has(name)) {
            template := this.templates[name]
            if (template["bitmap"]) {
                GdipDisposeImage(template["bitmap"])
            }
            this.templates.Delete(name)
            this.logger.Info(Format("移除模板: {}", name))
            return true
        }
        return false
    }

    ; 获取模板列表
    GetTemplateList() {
        return this.templates.Keys()
    }

    ; 清理资源
    Cleanup() {
        this.logger.Info("清理图像识别资源")

        ; 释放所有位图资源
        for name, template in this.templates {
            if (template["bitmap"]) {
                GdipDisposeImage(template["bitmap"])
            }
        }

        this.templates := Map()
        this.isInitialized := false
    }

    ; 获取调试信息
    GetDebugInfo() {
        return Map(
            "isInitialized", this.isInitialized,
            "templateCount", this.templates.Count,
            "templatePath", this.templatePath,
            "confidenceThreshold", this.confidenceThreshold,
            "templates", this.templates.Keys()
        )
    }
}

; 注意：不再创建全局实例，由主程序统一管理
