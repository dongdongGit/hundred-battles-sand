/**
 * 配置管理类
 * 支持INI文件读写、内存配置管理、配置验证
 */

class Config {
    __New(configFile := "") {
        this.configFile := configFile || A_ScriptDir "\resources\config\config.ini"
        this.configData := Map()
        this.defaultConfig := this.GetDefaultConfig()
        this.isDirty := false
    }

    GetDefaultConfig() {
        return Map(
            "general", Map(
                "auto_start", false,
                "minimize_to_tray", true,
                "check_updates", true,
                "language", "zh-CN"
            ),
            "game", Map(
                "window_class", "MainView_9F956014-12FC-42d8-80C7-9A90D4D567E3",
                "window_title", "百战沙场",
                "process_name", "QQMicroGameBox.exe",
                "delay_between_actions", 1000,
                "random_delay_min", 200,
                "random_delay_max", 800
            ),
            "tasks", Map(
                "enable_daily_signin", true,
                "enable_daily_tasks", true,
                "enable_resource_collection", true,
                "enable_equipment_upgrade", true,
                "enable_hangup_farming", true,
                "enable_friend_interaction", true,
                "enable_mall_purchase", false,
                "max_daily_runs", 10,
                "hangup_duration", 3600,
                "resource_threshold", 1000
            ),
            "recognition", Map(
                "confidence_threshold", 0.8,
                "max_search_time", 5000,
                "template_path", A_ScriptDir "\resources\images",
                "use_grayscale", false,
                "enable_text_recognition", true
            ),
            "safety", Map(
                "emergency_stop_key", "F12",
                "enable_anti_detection", true,
                "max_continuous_work", 7200,
                "rest_interval", 300,
                "enable_screenshot_protection", true,
                "cpu_usage_limit", 50
            ),
            "logging", Map(
                "level", "INFO",
                "max_file_size", 10485760,
                "backup_count", 5,
                "enable_console_output", true,
                "enable_file_output", true
            )
        )
    }

    Load() {
        try {
            ; 如果配置文件不存在，创建默认配置
            if (!FileExist(this.configFile)) {
                this.Save()
                return
            }

            ; 读取配置文件
            for section, values in this.defaultConfig {
                if (!this.configData.Has(section))
                    this.configData[section] := Map()

                for key, defaultValue in values {
                    try {
                        value := IniRead(this.configFile, section, key, defaultValue)
                        this.configData[section][key] := this.ParseValue(value, defaultValue)
                    }
                    catch {
                        ; 如果读取失败，使用默认值
                        this.configData[section][key] := defaultValue
                    }
                }
            }

            LoggerInstance.Info("配置文件加载完成: " this.configFile)
        }
        catch as e {
            LoggerInstance.Error("加载配置文件失败: " e.Message)
            throw e
        }
    }

    Save() {
        try {
            ; 确保配置目录存在
            configDir := RegExReplace(this.configFile, "\\[^\\]*$")
            if (!DirExist(configDir)) {
                DirCreate(configDir)
            }

            ; 写入配置文件
            for section, values in this.configData {
                for key, value in values {
                    IniWrite(this.FormatValue(value), this.configFile, section, key)
                }
            }

            this.isDirty := false
            LoggerInstance.Info("配置文件保存完成: " this.configFile)
        }
        catch as e {
            LoggerInstance.Error("保存配置文件失败: " e.Message)
            throw e
        }
    }

    ParseValue(value, defaultValue) {
        ; 根据默认值的类型解析配置值
        if (Type(defaultValue) = "Integer") {
            return Integer(value)
        }
        else if (Type(defaultValue) = "Float") {
            return Float(value)
        }
        else if (Type(defaultValue) = "Integer") {
            return Integer(value)
        }
        else if (Type(defaultValue) = "Integer") {
            return Integer(value)
        }
        else if (defaultValue is Boolean) {
            return value in ["1", "true", "True", "TRUE", "yes", "Yes", "YES"]
        }
        else {
            return String(value)
        }
    }

    FormatValue(value) {
        if (value is Boolean) {
            return value ? "1" : "0"
        }
        return String(value)
    }

    Get(section, key, defaultValue := unset) {
        if (this.configData.Has(section) && this.configData[section].Has(key)) {
            return this.configData[section][key]
        }

        if (IsSet(defaultValue)) {
            return defaultValue
        }

        if (this.defaultConfig.Has(section) && this.defaultConfig[section].Has(key)) {
            return this.defaultConfig[section][key]
        }

        throw Error(Format("配置项不存在: {} -> {}", section, key))
    }

    Set(section, key, value) {
        if (!this.configData.Has(section)) {
            this.configData[section] := Map()
        }

        this.configData[section][key] := value
        this.isDirty := true
    }

    Has(section, key := unset) {
        if (IsSet(key)) {
            return this.configData.Has(section) && this.configData[section].Has(key)
        }
        return this.configData.Has(section)
    }

    GetSection(section) {
        if (this.configData.Has(section)) {
            return this.configData[section].Clone()
        }

        if (this.defaultConfig.Has(section)) {
            return this.defaultConfig[section].Clone()
        }

        return Map()
    }

    SetSection(section, values) {
        if (!this.configData.Has(section)) {
            this.configData[section] := Map()
        }

        for key, value in values {
            this.configData[section][key] := value
        }

        this.isDirty := true
    }

    ; 获取带类型的配置值
    GetInt(section, key, defaultValue := 0) {
        value := this.Get(section, key, defaultValue)
        return Type(value) = "String" ? Integer(value) : value
    }

    GetBool(section, key, defaultValue := false) {
        value := this.Get(section, key, defaultValue)
        return Type(value) = "String" ? value in ["1", "true", "True", "TRUE", "yes", "Yes", "YES"] : !!value
    }

    GetFloat(section, key, defaultValue := 0.0) {
        value := this.Get(section, key, defaultValue)
        return Type(value) = "String" ? Float(value) : value
    }

    GetString(section, key, defaultValue := "") {
        value := this.Get(section, key, defaultValue)
        return String(value)
    }

    ; 批量更新配置
    Update(updates) {
        for section, values in updates {
            for key, value in values {
                this.Set(section, key, value)
            }
        }
    }

    ; 重置为默认配置
    Reset() {
        this.configData := Map()
        for section, values in this.defaultConfig {
            this.configData[section] := values.Clone()
        }
        this.isDirty := true
    }

    ; 导出配置到对象
    Export() {
        result := Map()
        for section, values in this.configData {
            result[section] := values.Clone()
        }
        return result
    }

    ; 从对象导入配置
    Import(configData) {
        for section, values in configData {
            if (!this.configData.Has(section)) {
                this.configData[section] := Map()
            }

            for key, value in values {
                this.configData[section][key] := value
            }
        }
        this.isDirty := true
    }

    ; 获取配置统计信息
    GetStats() {
        stats := Map(
            "total_sections", this.configData.Count,
            "total_keys", 0,
            "modified", this.isDirty
        )

        for section in this.configData {
            stats["total_keys"] += section.Count
        }

        return stats
    }

    ; 验证配置完整性
    Validate() {
        errors := []

        ; 检查必需的配置项
        requiredItems := [
            ["game", "window_class"],
            ["game", "window_title"],
            ["logging", "level"]
        ]

        for item in requiredItems {
            section := item[1]
            key := item[2]

            if (!this.Has(section, key)) {
                errors.Push(Format("缺少必需配置: {} -> {}", section, key))
            }
        }

        ; 检查配置值的有效性
        if (this.GetInt("game", "delay_between_actions", 0) < 0) {
            errors.Push("游戏延迟不能为负数")
        }

        if (this.GetFloat("recognition", "confidence_threshold", 0) < 0 ||
            this.GetFloat("recognition", "confidence_threshold", 1) > 1) {
            errors.Push("识别置信度必须在0-1之间")
        }

        return errors
    }

    ; 清理资源
    Cleanup() {
        if (this.isDirty) {
            this.Save()
        }
        this.configData := Map()
    }
}

; 全局配置实例
global ConfigInstance := Config()