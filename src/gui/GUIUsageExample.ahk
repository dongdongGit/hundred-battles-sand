/**
 * GUI使用示例
 * 展示如何使用新的分离式GUI架构
 */

#Requires AutoHotkey v2.0

class GUIUsageExample {
    static mainGui := ""
    static eventCoordinator := ""

    /**
     * 创建GUI实例
     */
    static CreateGUI() {
        ; 创建主GUI实例
        this.mainGui := MainGUI()

        ; 创建事件协调器
        this.eventCoordinator := GUIEventCoordinator()

        ; 将GUI实例传递给协调器
        this.eventCoordinator.SetGUI(this.mainGui)

        ; 显示GUI
        this.mainGui.Show()

        ; 设置事件处理（将GUI事件委托给协调器）
        this.SetupEventHandlers()
    }

    /**
     * 设置事件处理
     */
    static SetupEventHandlers() {
        ; 窗口事件
        this.mainGui.guiHwnd.OnEvent("Size", (*) => this.eventCoordinator.OnResize())
        this.mainGui.guiHwnd.OnEvent("Close", (*) => this.eventCoordinator.OnClose())

        ; 按钮事件委托给协调器
        this.mainGui.startBtn.OnEvent("Click", (*) => this.eventCoordinator.OnStartButton())
        this.mainGui.stopBtn.OnEvent("Click", (*) => this.eventCoordinator.OnStopButton())
        this.mainGui.exitBtn.OnEvent("Click", (*) => this.eventCoordinator.OnExitButton())
        this.mainGui.settingsBtn.OnEvent("Click", (*) => this.eventCoordinator.ShowSettings())

        ; 其他控件事件
        if (this.mainGui.guiHwnd.HasProp("WildBossLevel") && this.mainGui.guiHwnd["WildBossLevel"]) {
            this.mainGui.guiHwnd["WildBossLevel"].OnEvent("Change", (*) => this.eventCoordinator.OnWildBossLevelChange())
        }

        ; 标签页按钮事件
        this.mainGui.refreshTasksBtn.OnEvent("Click", (*) => this.eventCoordinator.OnRefreshTasks())
        this.mainGui.clearTasksBtn.OnEvent("Click", (*) => this.eventCoordinator.OnClearTasks())
        this.mainGui.clearLogBtn.OnEvent("Click", (*) => this.eventCoordinator.OnClearLog())
        this.mainGui.saveLogBtn.OnEvent("Click", (*) => this.eventCoordinator.OnSaveLog())
        this.mainGui.refreshLogBtn.OnEvent("Click", (*) => this.eventCoordinator.OnRefreshLog())
        this.mainGui.refreshDebugBtn.OnEvent("Click", (*) => this.eventCoordinator.OnRefreshDebug())
        this.mainGui.testImageRecogBtn.OnEvent("Click", (*) => this.eventCoordinator.OnTestImageRecog())
        this.mainGui.testWindowDetectBtn.OnEvent("Click", (*) => this.eventCoordinator.OnTestWindowDetection())
    }

    /**
     * 更新游戏状态（由主程序调用）
     */
    static UpdateGameStatus() {
        if (this.eventCoordinator) {
            this.eventCoordinator.UpdateGameStatus()
        }
    }

    /**
     * 刷新日志输出（由主程序调用）
     */
    static RefreshLogOutput() {
        if (this.eventCoordinator) {
            this.eventCoordinator.RefreshLogOutput()
        }
    }

    /**
     * 刷新调试信息（由主程序调用）
     */
    static RefreshDebugInfo() {
        if (this.eventCoordinator) {
            this.eventCoordinator.RefreshDebugInfo()
        }
    }

    /**
     * 显示或隐藏GUI
     */
    static ToggleGUI() {
        if (this.mainGui.isVisible) {
            this.mainGui.Hide()
        } else {
            this.mainGui.ShowWindow()
        }
    }

    /**
     * 清理资源
     */
    static Cleanup() {
        if (this.mainGui) {
            this.mainGui.Cleanup()
        }
    }
}