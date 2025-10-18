/**
 * 日志记录工具类
 * 支持多级别日志记录、文件输出、控制台输出
 */

#Requires AutoHotkey v2.0

class Logger {
    static Levels := Map(
        "DEBUG", 0,
        "INFO", 1,
        "WARN", 2,
        "ERROR", 3,
        "FATAL", 4
    )

    __New(config := unset) {
        this.logLevel := "INFO"
        this.logFile := ""
        this.consoleOutput := true
        this.fileOutput := true
        this.maxFileSize := 10 * 1024 * 1024  ; 10MB
        this.backupCount := 5

        if (IsSet(config)) {
            this.Configure(config)
        }

        this.logQueue := []
        this.isInitialized := false
    }

    Configure(config) {
        if (config.Has("level"))
            this.logLevel := config["level"]
        if (config.Has("file"))
            this.logFile := config["file"]
        if (config.Has("console"))
            this.consoleOutput := config["console"]
        if (config.Has("fileOutput"))
            this.fileOutput := config["fileOutput"]
        if (config.Has("maxFileSize"))
            this.maxFileSize := config["maxFileSize"]
        if (config.Has("backupCount"))
            this.backupCount := config["backupCount"]
    }

    Initialize() {
        if (this.fileOutput && this.logFile) {
            this.CreateLogDirectory()
            this.RotateLogFile()
        }
        this.isInitialized := true
    }

    CreateLogDirectory() {
        logDir := RegExReplace(this.logFile, "\\[^\\]*$")
        if (logDir && !DirExist(logDir)) {
            DirCreate(logDir)
        }
    }

    RotateLogFile() {
        if (!FileExist(this.logFile))
            return

        fileSize := FileGetSize(this.logFile)
        if (fileSize < this.maxFileSize)
            return

        ; 备份旧日志文件
        for i in Range(this.backupCount, 1, -1) {
            oldFile := this.logFile "." i
            newFile := this.logFile "." (i + 1)
            if (FileExist(oldFile))
                FileMove(oldFile, newFile, true)
        }

        ; 移动当前日志文件
        if (FileExist(this.logFile))
            FileMove(this.logFile, this.logFile ".1", true)
    }

    ShouldLog(level) {
        return Logger.Levels[level] >= Logger.Levels[this.logLevel]
    }

    FormatMessage(level, message) {
        timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        return Format("[{}] [{}] {}", timestamp, level, message)
    }

    WriteToConsole(message) {
        if (this.consoleOutput) {
            ; 使用OutputDebug而不是直接输出，避免干扰
            OutputDebug(message)
        }
    }

    WriteToFile(message) {
        if (this.fileOutput && this.logFile) {
            try {
                FileAppend(message "`n", this.logFile, "UTF-8")
            }
            catch as e {
                ; 如果文件写入失败，回退到控制台输出
                this.WriteToConsole("日志文件写入失败：" e.Message)
            }
        }
    }

    Log(level, message) {
        if (!this.ShouldLog(level))
            return

        formattedMessage := this.FormatMessage(level, message)

        ; 添加到队列进行异步处理
        this.logQueue.Push([level, formattedMessage])

        ; 如果队列过长，立即处理
        if (this.logQueue.Length > 100) {
            this.ProcessLogQueue()
        }
    }

    ProcessLogQueue() {
        for item in this.logQueue {
            level := item[1]
            message := item[2]

            this.WriteToConsole(message)
            this.WriteToFile(message)
        }
        this.logQueue.Clear()
    }

    Debug(message) {
        this.Log("DEBUG", message)
    }

    Info(message) {
        this.Log("INFO", message)
    }

    Warn(message) {
        this.Log("WARN", message)
    }

    Error(message) {
        this.Log("ERROR", message)
    }

    Fatal(message) {
        this.Log("FATAL", message)
    }

    ; 便捷方法：记录异常信息
    LogException(what, extra := "") {
        message := what
        if (extra)
            message .= " - " extra
        this.Error(message)
    }

    ; 性能监控日志
    LogPerformance(operation, startTime) {
        duration := A_TickCount - startTime
        this.Debug(Format("操作 '{}' 执行耗时: {}ms", operation, duration))
    }

    ; 清理资源
    Cleanup() {
        if (this.logQueue.Length > 0) {
            this.ProcessLogQueue()
        }
        this.isInitialized := false
    }
}

; 注意：不再创建全局实例，由主程序统一管理

; 便捷函数
LogDebug(message) => LoggerInstance.Debug(message)
LogInfo(message) => LoggerInstance.Info(message)
LogWarn(message) => LoggerInstance.Warn(message)
LogError(message) => LoggerInstance.Error(message)
LogFatal(message) => LoggerInstance.Fatal(message)