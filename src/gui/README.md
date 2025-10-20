# GUI模块架构说明

## 概述

本GUI模块采用分离式架构设计，将界面展示与业务逻辑分离，提高代码的可维护性和可测试性。

## 文件结构

```
src/gui/
├── MainGUI.ahk              # 主GUI类 - 纯界面控件创建和布局
├── GUIBusinessLogic.ahk     # GUI业务逻辑处理类
├── WindowDetectionHandler.ahk # 窗口检测处理器
├── GUIEventCoordinator.ahk   # 事件处理协调器
├── GUIUsageExample.ahk       # 使用示例
└── README.md                 # 本文档
```

## 架构设计

### 1. MainGUI.ahk - 纯界面类

**职责：**
- GUI窗口创建和管理
- 控件布局和定位
- 基本的事件绑定框架

**特点：**
- 只负责界面展示
- 不包含业务逻辑
- 依赖事件协调器处理事件

### 2. GUIBusinessLogic.ahk - 业务逻辑类

**职责：**
- 通用业务逻辑处理
- 数据验证和转换
- 配置管理辅助功能

**包含方法：**
- `ShowHelp()` - 显示帮助信息
- `ShowAbout()` - 显示关于信息
- `GetLocationsForLevel()` - 获取等级对应地点
- `SaveGameWindowConfig()` - 保存窗口配置
- `RestartApp()` - 重启应用程序

### 3. WindowDetectionHandler.ahk - 窗口检测处理器

**职责：**
- 游戏窗口检测相关功能
- 窗口选择对话框管理
- 窗口配置保存和读取

**包含方法：**
- `ShowWindowDetectionDialog()` - 显示窗口检测对话框
- `GetCandidateWindows()` - 获取候选窗口列表
- `SaveGameWindowConfig()` - 保存游戏窗口配置
- `TryAutoDetectGameWindow()` - 自动检测游戏窗口

### 4. GUIEventCoordinator.ahk - 事件协调器

**职责：**
- 协调GUI事件和业务逻辑
- 状态更新和管理
- 连接各个业务逻辑组件

**包含方法：**
- `OnResize()` - 处理窗口大小改变
- `OnClose()` - 处理窗口关闭
- `UpdateGameStatus()` - 更新游戏状态
- `RefreshLogOutput()` - 刷新日志输出
- `OnWildBossLevelChange()` - 处理BOSS等级变化

## 使用方式

### 基本使用

```ahk
; 创建GUI实例
mainGui := MainGUI()

; 创建事件协调器
eventCoordinator := GUIEventCoordinator()
eventCoordinator.SetGUI(mainGui)

; 显示界面
mainGui.Show()
```

### 事件处理设置

```ahk
; 设置事件处理委托
mainGui.startBtn.OnEvent("Click", (*) => eventCoordinator.OnStartButton())
mainGui.guiHwnd.OnEvent("Close", (*) => eventCoordinator.OnClose())
```

### 状态更新

```ahk
; 主程序中更新状态
GUIUsageExample.UpdateGameStatus()
GUIUsageExample.RefreshLogOutput()
```

## 架构优势

### 1. 单一职责原则
- 每个类都有明确的职责范围
- 便于独立测试和维护

### 2. 松耦合设计
- 类之间通过接口通信
- 易于替换和扩展

### 3. 高内聚低耦合
- 相关功能集中在同一类中
- 类之间依赖关系清晰

### 4. 可扩展性
- 新功能可以轻松添加到对应类中
- 不影响其他模块

## 迁移指南

### 从旧架构迁移

1. **识别业务逻辑**：将MainGUI中的业务方法移动到对应类中
2. **更新事件处理**：修改事件处理函数，委托给事件协调器
3. **更新引用**：修改主程序中的GUI调用方式
4. **测试验证**：确保所有功能正常工作

### 新功能开发

1. **确定职责归属**：判断新功能属于哪个类
2. **遵循接口规范**：保持与现有架构的一致性
3. **添加测试**：为新功能编写单元测试
4. **文档更新**：更新相关文档

## 注意事项

1. **依赖管理**：确保所有类正确引用所需的依赖
2. **错误处理**：在类边界处正确处理和传递错误
3. **性能考虑**：避免在GUI线程中执行耗时操作
4. **内存管理**：及时清理不再使用的资源

## 未来改进

1. **接口抽象**：定义明确的接口规范
2. **依赖注入**：使用依赖注入容器管理依赖关系
3. **事件驱动**：采用更完善的事件驱动架构
4. **异步处理**：支持异步业务逻辑处理