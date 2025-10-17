# 百战沙场自动化脚本 - 项目结构概览

## 项目根目录结构

```
百战沙场自动化/
├── 📁 src/                       # 源代码主目录
│   ├── 📄 main.ahk              # 主程序入口
│   ├── 📁 modules/              # 功能模块（原lib/）
│   │   ├── Logger.ahk           # 日志记录系统
│   │   ├── Config.ahk           # 配置管理
│   │   ├── WindowManager.ahk    # 窗口和句柄管理
│   │   ├── ImageRecognition.ahk # 图像识别模块
│   │   ├── TaskManager.ahk      # 任务管理器
│   │   ├── GameController.ahk   # 游戏控制器
│   │   └── Interception.ahk     # Interception驱动接口
│   ├── 📁 gui/                  # 图形界面
│   │   └── MainGUI.ahk          # 主界面
│   └── 📁 utils/                # 工具模块
│       └── FileUtils.ahk        # 文件操作工具
├── 📁 resources/                 # 资源文件
│   ├── config/
│   │   └── config.ini           # 默认配置文件
│   └── images/                  # 游戏图片模板目录
│       ├── buttons/             # 按钮图片
│       ├── icons/               # 图标图片
│       ├── ui/                  # 界面元素
│       └── templates/           # 模板文件
├── 📁 docs/                      # 文档（预留）
├── 📁 tests/                     # 测试文件（预留）
├── 📁 logs/                      # 日志文件目录
├── 📁 .vscode/                   # VSCode 配置
│   ├── settings.json            # 编辑器设置
│   └── extensions.json          # 推荐扩展
├── 📁 .roo/                      # 项目配置
├── 📄 LICENSE                    # 开源协议文件
├── 📄 README.md                  # 项目说明
├── 📄 PROJECT_STRUCTURE.md       # 项目结构说明
├── 📄 project-design.md          # 项目设计文档
└── 📄 .prettierrc.json           # 代码格式化配置
```

## 核心文件说明

### 主程序入口
- **`main.ahk`** - 应用程序的主入口点，负责初始化所有组件和管理程序生命周期

### 核心库模块 (lib/)
- **`Logger.ahk`** - 多级别日志记录系统，支持文件输出和控制台输出
- **`Config.ahk`** - 配置管理系统，支持INI文件读写和内存配置管理
- **`WindowManager.ahk`** - 专门处理QQ游戏盒子窗口的识别、控制和管理
- **`ImageRecognition.ahk`** - 图像识别模块，支持模板匹配和颜色识别
- **`TaskManager.ahk`** - 任务调度和执行管理器，支持多任务并发执行
- **`GameController.ahk`** - 游戏自动化流程的核心控制器，协调各模块工作
- **`Interception.ahk`** - Interception驱动集成，提供低级键盘鼠标控制

### 工具模块 (utils/)
- **`FileUtils.ahk`** - 文件操作工具类，提供读写、复制、格式转换等功能

### 资源文件 (resources/)
- **`config/config.ini`** - 应用程序的默认配置文件，包含所有配置项
- **`images/`** - 存放游戏界面模板图片的目录，用于图像识别

### 图形界面 (gui/)
- **`MainGUI.ahk`** - 主图形界面，提供程序控制和状态监控功能

### 开发配置
- **`.vscode/`** - VSCode编辑器配置和扩展推荐
- **`.prettierrc.json`** - 代码格式化配置，支持AutoHotkey语法
- **`README.md`** - 详细的项目说明和使用指南

## 技术架构

### 模块化设计
项目采用高度模块化的设计，各模块职责明确：

```
┌─────────────────┐    ┌──────────────────┐
│   Main.ahk      │    │   MainGUI.ahk    │
│   主程序入口     │◄──►│   图形界面       │
└─────────────────┘    └──────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌──────────────────┐
│ GameController  │◄──►│  TaskManager     │
│ 游戏控制器       │    │ 任务管理器       │
└─────────────────┘    └──────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌──────────────────┐
│WindowManager    │    │ImageRecognition  │
│窗口管理器       │    │图像识别模块     │
└─────────────────┘    └──────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│  Interception   │◄──►│   Logger         │
│ 驱动接口        │    │  日志系统         │
└─────────────────┘    └──────────────────┘
```

### 数据流向
1. **配置加载**：Config.ahk → 各模块初始化参数
2. **窗口识别**：WindowManager.ahk → GameController.ahk
3. **图像识别**：ImageRecognition.ahk → 游戏操作指令
4. **任务执行**：TaskManager.ahk → GameController.ahk → 具体操作
5. **日志记录**：各模块 → Logger.ahk → 文件/控制台输出
6. **用户交互**：MainGUI.ahk ↔ 各核心模块

## 开发环境配置

### 必需扩展
- **AutoHotkey Plus Plus** - AHK v2语法高亮和自动完成
- **AutoHotkey Debugger** - 调试支持
- **AHK v2 Language Support** - 语言服务器协议支持
- **Prettier** - 代码格式化

### 推荐扩展
- **GitLens** - Git集成和代码历史
- **Code Runner** - 代码运行和测试
- **JSON Tools** - JSON文件格式化和验证

## 部署说明

### 开发环境部署
1. 安装 AutoHotkey v2.0+
2. 安装推荐的 VSCode 扩展
3. 克隆项目代码到本地
4. 双击运行 `main.ahk` 启动程序

### 生产环境部署
1. 打包项目为独立可执行文件（需要Ahk2Exe）
2. 提供配置文件和资源文件
3. 创建桌面快捷方式
4. 添加系统自启动（可选）

## 扩展开发

### 添加新任务类型
1. 在 `TaskManager.ahk` 中定义任务逻辑
2. 在 `Config.ahk` 中添加配置项
3. 在图形界面中添加控制选项
4. 实现具体的游戏操作逻辑

### 添加图像模板
1. 截取游戏界面图片
2. 放置到 `resources/images/` 目录
3. 在 `ImageRecognition.ahk` 中注册模板
4. 测试识别准确度

### 自定义配置
1. 在 `resources/config/config.ini` 中添加配置项
2. 在 `Config.ahk` 中实现配置读写逻辑
3. 在相关模块中使用配置值

## 维护和更新

### 版本管理
- 使用语义化版本号（v1.0.0）
- 定期更新依赖库和工具
- 维护详细的更新日志

### 问题排查
- 查看日志文件获取详细错误信息
- 使用调试界面监控系统状态
- 检查配置文件和资源文件完整性

### 性能优化
- 监控内存和CPU使用情况
- 优化图像识别算法
- 调整任务执行频率和延迟参数

---

这个项目结构设计合理，模块化程度高，便于维护和扩展。每个模块都有明确的职责，相互之间通过清晰的接口进行通信。