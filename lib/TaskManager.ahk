/**
 * 任务管理器
 * 负责任务调度、执行监控、状态管理等核心功能
 */

class TaskManager {
    __New() {
        this.tasks := Map()
        this.runningTasks := Map()
        this.taskQueue := []
        this.isRunning := false
        this.maxConcurrentTasks := 3
        this.taskStats := Map()

        this.InitializeDefaultTasks()
    }

    Initialize() {
        LoggerInstance.Info("初始化任务管理器")

        ; 从配置加载任务设置
        this.LoadTaskSettings()

        ; 初始化统计信息
        this.ResetStats()

        LoggerInstance.Info("任务管理器初始化完成")
    }

    InitializeDefaultTasks() {
        ; 定义默认任务类型
        this.defaultTasks := Map(
            "daily_signin", Map(
                "name", "每日签到",
                "description", "自动完成每日签到任务",
                "enabled", true,
                "interval", 86400,  ; 24小时
                "priority", 10,
                "timeout", 300
            ),
            "daily_tasks", Map(
                "name", "日常任务",
                "description", "自动完成各种日常任务",
                "enabled", true,
                "interval", 3600,   ; 1小时
                "priority", 8,
                "timeout", 600
            ),
            "resource_collection", Map(
                "name", "资源采集",
                "description", "自动采集游戏资源点",
                "enabled", true,
                "interval", 1800,   ; 30分钟
                "priority", 7,
                "timeout", 900
            ),
            "equipment_upgrade", Map(
                "name", "装备强化",
                "description", "自动强化装备到指定等级",
                "enabled", true,
                "interval", 7200,   ; 2小时
                "priority", 6,
                "timeout", 1200
            ),
            "hangup_farming", Map(
                "name", "挂机刷元宝",
                "description", "长时间自动挂机刷取元宝",
                "enabled", true,
                "interval", 0,      ; 持续执行
                "priority", 5,
                "timeout", 0        ; 无超时
            ),
            "friend_interaction", Map(
                "name", "好友互动",
                "description", "自动与好友互动获得奖励",
                "enabled", true,
                "interval", 3600,   ; 1小时
                "priority", 4,
                "timeout", 600
            )
        )
    }

    LoadTaskSettings() {
        LoggerInstance.Debug("加载任务设置")

        ; 从配置读取任务启用状态
        for taskId, taskInfo in this.defaultTasks {
            enabled := ConfigInstance.GetBool("tasks", "enable_" taskId, taskInfo["enabled"])

            if (enabled) {
                this.tasks[taskId] := this.CreateTask(taskId, taskInfo)
                LoggerInstance.Debug(Format("启用任务: {} - {}", taskId, taskInfo["name"]))
            }
        }
    }

    CreateTask(taskId, taskInfo) {
        task := Map()
        task["id"] := taskId
        task["name"] := taskInfo["name"]
        task["description"] := taskInfo["description"]
        task["enabled"] := true
        task["status"] := "idle"  ; idle, running, completed, failed, paused
        task["priority"] := taskInfo["priority"]
        task["interval"] := taskInfo["interval"]
        task["timeout"] := taskInfo["timeout"]
        task["lastRun"] := 0
        task["runCount"] := 0
        task["successCount"] := 0
        task["failCount"] := 0
        task["totalTime"] := 0
        task["progress"] := 0

        return task
    }

    Start() {
        if (this.isRunning) {
            LoggerInstance.Warn("任务管理器已经在运行中")
            return false
        }

        LoggerInstance.Info("启动任务管理器")

        this.isRunning := true
        this.ResetStats()

        ; 启动任务调度循环
        this.StartScheduler()

        LoggerInstance.Info("任务管理器启动完成")
        return true
    }

    Stop() {
        if (!this.isRunning) {
            return false
        }

        LoggerInstance.Info("停止任务管理器")

        this.isRunning := false

        ; 停止所有运行中的任务
        this.StopAllTasks()

        LoggerInstance.Info("任务管理器已停止")
        return true
    }

    StartScheduler() {
        ; 创建调度器线程（简化版，使用定时器模拟）
        this.schedulerTimer := (*) => this.SchedulerLoop()
        SetTimer(this.schedulerTimer, 1000)  ; 每秒执行一次调度
    }

    SchedulerLoop() {
        if (!this.isRunning) {
            return
        }

        try {
            ; 检查并启动符合条件的任务
            this.CheckAndStartTasks()

            ; 更新运行中的任务状态
            this.UpdateRunningTasks()

            ; 清理已完成的任务
            this.CleanupCompletedTasks()

            ; 更新统计信息
            this.UpdateStats()
        }
        catch as e {
            LoggerInstance.Error(Format("调度循环出错: {}", e.Message))
        }
    }

    CheckAndStartTasks() {
        currentTime := A_TickCount

        for taskId, task in this.tasks {
            if (!this.CanStartTask(task, currentTime)) {
                continue
            }

            if (this.runningTasks.Count < this.maxConcurrentTasks) {
                this.StartTask(taskId)
            }
        }
    }

    CanStartTask(task, currentTime) {
        ; 检查任务是否启用
        if (!task["enabled"] || task["status"] = "running") {
            return false
        }

        ; 检查是否达到执行间隔
        if (task["interval"] > 0) {
            elapsed := (currentTime - task["lastRun"]) / 1000  ; 转换为秒
            if (elapsed < task["interval"]) {
                return false
            }
        }

        ; 检查是否超过每日最大执行次数
        if (this.CheckDailyLimit(task)) {
            return false
        }

        return true
    }

    CheckDailyLimit(task) {
        maxRuns := ConfigInstance.GetInt("tasks", "max_daily_runs", 10)

        ; 这里应该检查今天的执行次数
        ; 简化版：检查总执行次数
        if (task["runCount"] >= maxRuns) {
            LoggerInstance.Debug(Format("任务 {} 已达到每日最大执行次数", task["name"]))
            return true
        }

        return false
    }

    StartTask(taskId) {
        task := this.tasks[taskId]
        task["status"] := "running"
        task["startTime"] := A_TickCount
        task["progress"] := 0

        this.runningTasks[taskId] := task

        LoggerInstance.Info(Format("开始执行任务: {}", task["name"]))

        ; 执行任务（异步）
        this.ExecuteTask(taskId)
    }

    ExecuteTask(taskId) {
        task := this.tasks[taskId]

        ; 创建任务执行函数
        executeFunc := (*) => this.TaskExecutor(taskId)

        ; 使用SetTimer异步执行，避免阻塞调度器
        SetTimer(executeFunc, -10)  ; 10ms后执行
    }

    TaskExecutor(taskId) {
        try {
            task := this.tasks[taskId]
            taskName := task["name"]

            LoggerInstance.Debug(Format("执行任务: {}", taskName))

            ; 根据任务类型执行相应操作
            switch taskId {
                case "daily_signin":
                    this.ExecuteDailySignin(task)
                case "daily_tasks":
                    this.ExecuteDailyTasks(task)
                case "resource_collection":
                    this.ExecuteResourceCollection(task)
                case "equipment_upgrade":
                    this.ExecuteEquipmentUpgrade(task)
                case "hangup_farming":
                    this.ExecuteHangupFarming(task)
                case "friend_interaction":
                    this.ExecuteFriendInteraction(task)
                default:
                    throw Error("未知任务类型: " taskId)
            }

            ; 任务执行成功
            this.CompleteTask(taskId, true)

        }
        catch as e {
            LoggerInstance.Error(Format("任务执行失败 {}: {}", taskId, e.Message))
            this.CompleteTask(taskId, false, e.Message)
        }
    }

    ExecuteDailySignin(task) {
        LoggerInstance.Info("执行每日签到任务")

        ; 模拟任务执行过程
        Sleep(2000)

        ; 这里应该实现具体的签到逻辑：
        ; 1. 识别签到按钮
        ; 2. 点击签到
        ; 3. 确认奖励领取

        LoggerInstance.Info("每日签到完成")
    }

    ExecuteDailyTasks(task) {
        LoggerInstance.Info("执行日常任务")

        ; 模拟任务执行
        Sleep(3000)

        LoggerInstance.Info("日常任务完成")
    }

    ExecuteResourceCollection(task) {
        LoggerInstance.Info("执行资源采集任务")

        Sleep(5000)

        LoggerInstance.Info("资源采集完成")
    }

    ExecuteEquipmentUpgrade(task) {
        LoggerInstance.Info("执行装备强化任务")

        Sleep(4000)

        LoggerInstance.Info("装备强化完成")
    }

    ExecuteHangupFarming(task) {
        LoggerInstance.Info("开始挂机刷元宝")

        ; 挂机任务持续时间（从配置读取）
        duration := ConfigInstance.GetInt("tasks", "hangup_duration", 3600) * 1000

        startTime := A_TickCount
        while (A_TickCount - startTime < duration && this.isRunning) {
            Sleep(10000)  ; 每10秒检查一次

            ; 这里应该实现挂机逻辑：
            ; 1. 检查游戏状态
            ; 2. 执行刷怪动作
            ; 3. 检查背包容量
            ; 4. 处理异常情况
        }

        LoggerInstance.Info("挂机刷元宝完成")
    }

    ExecuteFriendInteraction(task) {
        LoggerInstance.Info("执行好友互动任务")

        Sleep(3000)

        LoggerInstance.Info("好友互动完成")
    }

    CompleteTask(taskId, success, errorMsg := "") {
        task := this.tasks[taskId]

        if (success) {
            task["status"] := "completed"
            task["successCount"]++
            LoggerInstance.Info(Format("任务完成: {}", task["name"]))
        }
        else {
            task["status"] := "failed"
            task["failCount"]++
            LoggerInstance.Error(Format("任务失败: {} - {}", task["name"], errorMsg))
        }

        task["runCount"]++
        task["lastRun"] := A_TickCount

        if (task.Has("startTime")) {
            duration := A_TickCount - task["startTime"]
            task["totalTime"] += duration
        }

        ; 从运行中任务移除
        this.runningTasks.Delete(taskId)

        ; 更新统计
        this.UpdateTaskStats(taskId, success)
    }

    StopAllTasks() {
        LoggerInstance.Info("停止所有运行中的任务")

        for taskId, task in this.runningTasks.Clone() {
            this.StopTask(taskId)
        }
    }

    StopTask(taskId) {
        if (!this.runningTasks.Has(taskId)) {
            return false
        }

        task := this.tasks[taskId]
        task["status"] := "paused"

        this.runningTasks.Delete(taskId)

        LoggerInstance.Info(Format("停止任务: {}", task["name"]))
        return true
    }

    UpdateRunningTasks() {
        currentTime := A_TickCount

        for taskId, task in this.runningTasks.Clone() {
            ; 检查任务是否超时
            if (task["timeout"] > 0) {
                elapsed := (currentTime - task["startTime"]) / 1000
                if (elapsed > task["timeout"]) {
                    LoggerInstance.Warn(Format("任务超时: {}", task["name"]))
                    this.CompleteTask(taskId, false, "任务执行超时")
                }
            }

            ; 更新任务进度（模拟）
            if (task["status"] = "running") {
                progress := Mod(task["progress"] + 10, 100)
                task["progress"] := progress
            }
        }
    }

    CleanupCompletedTasks() {
        ; 清理已完成的任务，准备下次执行
        for taskId, task in this.tasks {
            if (task["status"] = "completed" || task["status"] = "failed") {
                task["status"] := "idle"
                task["progress"] := 0
            }
        }
    }

    UpdateStats() {
        this.taskStats["total_tasks"] := this.tasks.Count
        this.taskStats["running_tasks"] := this.runningTasks.Count
        this.taskStats["completed_today"] := 0
        this.taskStats["failed_today"] := 0

        for task in this.tasks {
            this.taskStats["completed_today"] += task["successCount"]
            this.taskStats["failed_today"] += task["failCount"]
        }
    }

    UpdateTaskStats(taskId, success) {
        ; 更新详细的任务统计
        ; 这里可以实现更详细的统计逻辑
    }

    ResetStats() {
        this.taskStats := Map(
            "total_tasks", 0,
            "running_tasks", 0,
            "completed_today", 0,
            "failed_today", 0,
            "start_time", A_TickCount
        )
    }

    ; 获取任务列表
    GetTaskList() {
        return this.tasks.Clone()
    }

    ; 获取运行中的任务
    GetRunningTasks() {
        return this.runningTasks.Clone()
    }

    ; 获取任务统计信息
    GetStats() {
        return this.taskStats.Clone()
    }

    ; 启用/禁用任务
    EnableTask(taskId, enabled := true) {
        if (this.tasks.Has(taskId)) {
            this.tasks[taskId]["enabled"] := enabled
            LoggerInstance.Info(Format("任务 {} {}", taskId, enabled ? "已启用" : "已禁用"))
            return true
        }
        return false
    }

    ; 获取任务信息
    GetTaskInfo(taskId) {
        if (this.tasks.Has(taskId)) {
            return this.tasks[taskId].Clone()
        }
        return false
    }

    ; 设置任务优先级
    SetTaskPriority(taskId, priority) {
        if (this.tasks.Has(taskId)) {
            this.tasks[taskId]["priority"] := priority
            LoggerInstance.Info(Format("任务 {} 优先级设为 {}", taskId, priority))
            return true
        }
        return false
    }

    ; 添加自定义任务
    AddTask(taskId, taskInfo) {
        if (!this.tasks.Has(taskId)) {
            task := this.CreateTask(taskId, taskInfo)
            this.tasks[taskId] := task
            LoggerInstance.Info(Format("添加自定义任务: {}", taskId))
            return true
        }
        return false
    }

    ; 移除任务
    RemoveTask(taskId) {
        if (this.tasks.Has(taskId)) {
            ; 停止运行中的任务
            if (this.runningTasks.Has(taskId)) {
                this.StopTask(taskId)
            }

            this.tasks.Delete(taskId)
            LoggerInstance.Info(Format("移除任务: {}", taskId))
            return true
        }
        return false
    }

    ; 暂停/恢复任务管理器
    Pause() {
        if (this.isRunning) {
            this.isRunning := false
            LoggerInstance.Info("任务管理器已暂停")
            return true
        }
        return false
    }

    Resume() {
        if (!this.isRunning) {
            this.isRunning := true
            LoggerInstance.Info("任务管理器已恢复")
            return true
        }
        return false
    }

    ; 检查任务管理器状态
    IsRunning() {
        return this.isRunning
    }

    ; 获取运行状态
    GetStatus() {
        return Map(
            "is_running", this.isRunning,
            "total_tasks", this.tasks.Count,
            "running_tasks", this.runningTasks.Count,
            "task_stats", this.GetStats()
        )
    }

    ; 清理资源
    Cleanup() {
        LoggerInstance.Info("清理任务管理器资源")

        this.Stop()

        ; 重置所有任务状态
        for taskId, task in this.tasks {
            task["status"] := "idle"
            task["progress"] := 0
        }

        this.runningTasks := Map()
        this.ResetStats()
    }

    ; 获取调试信息
    GetDebugInfo() {
        debugInfo := Map(
            "is_running", this.isRunning,
            "task_count", this.tasks.Count,
            "running_count", this.runningTasks.Count,
            "stats", this.GetStats()
        )

        ; 添加任务详细信息
        taskDetails := []
        for taskId, task in this.tasks {
            taskDetails.Push(Map(
                "id", taskId,
                "name", task["name"],
                "status", task["status"],
                "progress", task["progress"],
                "run_count", task["runCount"]
            ))
        }
        debugInfo["tasks"] := taskDetails

        return debugInfo
    }
}

; 全局任务管理器实例
global TaskManagerInstance := TaskManager()