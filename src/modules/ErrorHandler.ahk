/**
 * 错误处理工具类
 * 提供统一的错误处理机制，支持异常捕获、错误分类和用户友好的错误显示
 */

#Requires AutoHotkey v2.0

class ErrorHandler {
    __New(logger := unset) {
        this.logger := IsSet(logger) ? logger : (IsSet(LoggerInstance) ? LoggerInstance : "")
        this.errorHistory := []
        this.maxHistorySize := 100
        this.showUserErrors := true
        this.autoRetryAttempts := 3
    }

    /**
     * 安全获取 App.MainGUI
     */
    SafeGetMainGUI() {
        gui := ""
        if (IsSet(App) && IsObject(App)) {
            try gui := App.MainGUI
            catch
                gui := ""
        }
        return gui
    }

    /**
     * 处理异常
     * @param {Exception} exception - 要处理的异常对象
     * @param {String} context - 错误发生的上下文信息
     * @param {Boolean} showToUser - 是否显示给用户
     */
    HandleException(exception, context := "", showToUser := true) {
        errorInfo := this.CreateErrorInfo(exception, context, "EXCEPTION")

        ; 记录错误
        this.LogError(errorInfo)

        ; 添加到历史记录
        this.AddToHistory(errorInfo)

        ; 显示给用户（如果需要）
        if (showToUser && this.showUserErrors) {
            this.ShowErrorToUser(errorInfo)
        }

        return errorInfo
    }

    /**
     * 处理一般错误
     * @param {String} message - 错误消息
     * @param {String} context - 错误发生的上下文信息
     * @param {String} level - 错误级别
     */
    HandleError(message, context := "", level := "ERROR") {
        errorInfo := this.CreateErrorInfo(message, context, level)

        ; 记录错误
        this.LogError(errorInfo)

        ; 添加到历史记录
        this.AddToHistory(errorInfo)

        return errorInfo
    }

    /**
     * 创建错误信息对象
     * @param {Exception|String} error - 异常对象或错误消息
     * @param {String} context - 上下文信息
     * @param {String} type - 错误类型
     */
    CreateErrorInfo(error, context, type) {
        timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")

        errorInfo := {
            timestamp: timestamp,
            type: type,
            context: context,
            stackTrace: "",
            userMessage: "",
            canRetry: false,
            retryCount: 0
        }

        if (type = "EXCEPTION") {
            errorInfo.message := error.Message
            errorInfo.what := error.What
            errorInfo.file := error.File
            errorInfo.line := error.Line
            errorInfo.stackTrace := this.GetStackTrace(error)
            errorInfo.userMessage := this.GetUserFriendlyMessage(error, context)
            errorInfo.canRetry := this.DetermineIfRetryable(error, context)
        } else {
            errorInfo.message := error
            errorInfo.userMessage := this.GetUserFriendlyMessage(error, context)
            errorInfo.canRetry := false
        }

        return errorInfo
    }

    /**
     * 记录错误到日志系统
     * @param {Object} errorInfo - 错误信息对象
     */
    LogError(errorInfo) {
        try {
            if !this.HasProp("logger") || this.logger = ""
                return
        } catch {
            return
        }

        message := Format("[{}] {} - {}", errorInfo.type, errorInfo.context, errorInfo.message)

        switch errorInfo.type {
        case "EXCEPTION":
            this.logger.Error(message)
            if (errorInfo.stackTrace)
                this.logger.Debug("堆栈跟踪: " errorInfo.stackTrace)
        case "FATAL":
            this.logger.Fatal(message)
        default:
            this.logger.Error(message)
        }
    }

    /**
     * 添加错误到历史记录
     * @param {Object} errorInfo - 错误信息对象
     */
    AddToHistory(errorInfo) {
        this.errorHistory.Push(errorInfo)

        ; 限制历史记录大小
        if (this.errorHistory.Length > this.maxHistorySize) {
            this.errorHistory.RemoveAt(1)
        }
    }

    /**
     * 获取用户友好的错误消息
     * @param {Exception|String} error - 异常对象或错误消息
     * @param {String} context - 上下文信息
     */
    GetUserFriendlyMessage(error, context) {
        message := ""

        if (Type(error) = "Exception") {
            message := error.Message
        } else {
            message := error
        }

        ; 根据上下文和错误类型提供更友好的消息
        if (InStr(message, "找不到文件") || InStr(message, "File not found")) {
            return "无法找到必要的文件，请检查文件路径是否正确。"
        }
        else if (InStr(message, "权限") || InStr(message, "access")) {
            return "权限不足，无法执行此操作。"
        }
        else if (InStr(message, "网络") || InStr(message, "connection")) {
            return "网络连接错误，请检查网络连接。"
        }
        else if (InStr(message, "游戏") || InStr(context, "游戏")) {
            return "游戏相关操作失败，请确保游戏正常运行。"
        }
        else if (InStr(message, "内存") || InStr(message, "memory")) {
            return "内存不足，请关闭其他程序后重试。"
        }

        ; 如果没有特定的友好消息，返回原始消息
        return message
    }

    /**
     * 判断错误是否可以重试
     * @param {Exception} error - 异常对象
     * @param {String} context - 上下文信息
     */
    DetermineIfRetryable(error, context) {
        message := error.Message

        ; 可以重试的错误类型
        retryableErrors := [
        "网络连接",
        "暂时",
        "超时",
        "忙碌",
        "锁定",
        "临时"
        ]

        for retryableError in retryableErrors {
            if (InStr(message, retryableError))
                return true
        }

        return false
    }

    /**
     * 获取堆栈跟踪信息
     * @param {Exception} error - 异常对象
     */
    GetStackTrace(error) {
        try {
            return error.Stack
        } catch {
            return ""
        }
    }

    /**
     * 显示错误给用户
     * @param {Object} errorInfo - 错误信息对象
     */
    ShowErrorToUser(errorInfo) {
        ; 使用安全方法获取 GUI
        gui := this.SafeGetMainGUI()
        if (IsSet(gui) && IsObject(gui)) {
            try {
                gui.ShowError(errorInfo.userMessage, errorInfo.message)
                return
            } catch {
                ; 如果 GUI 出错，则 fallback
            }
        }

        ; 备选方案：使用消息框
        MsgBox(errorInfo.userMessage, "错误", "ICONERROR")
    }

    /**
     * 执行带错误处理的操作
     * @param {Func} operation - 要执行的操作函数
     * @param {String} context - 操作上下文
     * @param {Number} maxRetries - 最大重试次数
     */
    ExecuteWithErrorHandling(operation, context := "", maxRetries := unset) {
        if (!IsSet(maxRetries))
            maxRetries := this.autoRetryAttempts

        lastError := ""
        retryCount := 0

        while (retryCount <= maxRetries) {
            try {
                return operation()
            }
            catch as e {
                lastError := e
                retryCount++

                ; 如果是最后一次重试或错误不可重试，直接处理并抛出
                if (retryCount > maxRetries || !this.DetermineIfRetryable(e, context)) {
                    this.HandleException(e, context, true)
                    throw e
                }

                ; 等待后重试（递增延时）
                sleepTime := retryCount * 1000
                Sleep(sleepTime)

                if IsObject(this.logger) {
                    try {
                        this.logger.Warn(Format("操作 '{}' 重试第 {} 次，{}ms 后...", context, retryCount, sleepTime))
                    } catch {
                        ; 忽略日志报错
                    }
                }
            }
        }
    }

    /**
     * 获取错误历史记录
     * @param {Number} count - 返回最近的错误数量，不指定则返回所有
     */
    GetErrorHistory(count := unset) {
        if (!IsSet(count))
            return this.errorHistory.Clone()

        return this.errorHistory.Slice(-count)
    }

    /**
     * 清除错误历史记录
     */
    ClearErrorHistory() {
        this.errorHistory := []
    }

    /**
     * 获取错误统计信息
     */
    GetErrorStats() {
        stats := {
            total: this.errorHistory.Length,
            byType: Map(),
            byContext: Map(),
            recentCount: 0
        }

        ; 统计最近24小时内的错误
        oneDayAgo := DateAdd(A_Now, -1, "Days")
        recentErrors := []

        for error in this.errorHistory {
            ; 按类型统计
            typeKey := error.type
            if (!stats.byType.Has(typeKey))
                stats.byType[typeKey] := 0
            stats.byType[typeKey]++

            ; 按上下文统计
            contextKey := error.context ? error.context : "未知"
            if (!stats.byContext.Has(contextKey))
                stats.byContext[contextKey] := 0
            stats.byContext[contextKey]++

            ; 检查是否为最近错误
            errorTime := DateParse(error.timestamp, "yyyy-MM-dd HH:mm:ss")
            if (errorTime > oneDayAgo) {
                recentErrors.Push(error)
            }
        }

        stats.recentCount := recentErrors.Length
        return stats
    }

    /**
     * 清理资源
     */
    Cleanup() {
        this.ClearErrorHistory()
    }
}

; 注意：不再创建全局实例，由主程序统一管理

; 便捷函数
HandleError(message, context := "") => ErrorHandlerInstance.HandleError(message, context)
HandleException(exception, context := "", showToUser := true) => ErrorHandlerInstance.HandleException(exception, context, showToUser)