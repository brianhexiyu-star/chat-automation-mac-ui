# Chat Automator — Build Guide

## 项目结构

```
UI for social bot/
├── Package.swift                          # Swift Package 配置
└── Sources/ChatAutomationApp/
    ├── ChatAutomationApp.swift            # App 入口 (@main)
    ├── AppDelegate.swift                  # 窗口布局 & 服务初始化
    ├── DesignSystem.swift                 # 颜色、字体、间距 Token
    ├── Models/
    │   └── AppState.swift                 # 全局状态 (ObservableObject)
    ├── Views/
    │   ├── MainWindowView.swift           # 右半边主窗口 + Tab Bar
    │   ├── SidebarView.swift              # 侧边栏 (App 列表管理)
    │   ├── TabContentViews.swift          # 4 个标签页内容
    │   └── TrackerWindowView.swift        # 左下角视觉追踪窗口
    ├── Services/
    │   ├── WindowManager.swift            # AXUIElement 窗口控制
    │   └── PythonBridge.swift             # Python 子进程通信
    └── Resources/
        └── Info.plist                     # 权限声明 & App 元数据
```

## 方法一：使用 Xcode 打开（推荐）

Xcode 能自动处理 Swift Package，并让你添加正确的 Entitlements（权限证书）。

1. 打开 Xcode → File → Open → 选择 `UI for social bot/` 文件夹。
2. Xcode 会识别 `Package.swift` 并自动配置。
3. 在 Xcode 中添加 Entitlements 文件（见下方步骤）。
4. 按 `⌘R` 运行。

### 添加 Entitlements（Accessibility 权限必须）

1. 在 Xcode 的 Project Navigator 中，右键 → New File → Property List → 命名为 `ChatAutomator.entitlements`
2. 添加以下键值：
   - `com.apple.security.automation.apple-events` = `YES`
   - `com.apple.security.app-sandbox` = `NO`（开发阶段）
3. 在 Target → Build Settings → Code Signing Entitlements 中指向此文件。

## 方法二：命令行构建（快速验证）

```bash
cd "/Users/xiyuhe/UI for social bot"
swift build
.build/debug/ChatAutomationApp
```

> **注意**：命令行构建无法添加 Entitlements，Accessibility API 将无法使用。
> 主 UI 布局和设计可以正常预览，但点击 App 时窗口吸附功能会有权限警告。

## Python 后端集成

在 Config 标签页中配置 Python 脚本路径，或通过代码修改：

```swift
// 在 AppDelegate.swift 的 applicationDidFinishLaunching 中
PythonBridge.shared.start(
    scriptPath: "/Users/xiyuhe/Desktop/antigravity/social_bot/social_bot.py",
    pythonPath: "/usr/bin/python3"
)
```

### Python 脚本输出协议

Python 脚本通过 stdout 输出 JSON，Swift 会自动解析并更新 UI：

```python
import json, sys

# 普通日志
print(json.dumps({"type": "log", "level": "info", "message": "Bot started"}))
sys.stdout.flush()

# OCR 扫描结果（更新左下角追踪面板）
print(json.dumps({
    "type": "ocr_result",
    "screenshot_path": "/tmp/screenshot.png",  # 截图文件路径
    "annotations": [
        {"x": 100, "y": 200, "w": 150, "h": 30, "label": "Send Button", "type": "clickTarget"},
        {"x": 50,  "y": 100, "w": 200, "h": 20, "label": "Hello World",  "type": "ocrText"}
    ]
}))
sys.stdout.flush()
```

## 当前实现的功能

- [x] 双窗口布局（启动时自动定位到右半边和左下角）
- [x] CapCut 风格深色主题设计系统
- [x] 侧边栏 App 管理（添加/选中，状态标记）
- [x] 4 个标签页（Logs / Editor / Config / Chat Feed）
- [x] 配置模式 ↔ 自动化模式切换
- [x] 自动化模式下标签页 4 秒轮播
- [x] 左下角视觉追踪面板（截图 + OCR 标注叠加绘制）
- [x] AXUIElement 窗口吸附（Accessibility API）
- [x] Python 子进程管理（启动、停止、JSON 通信）

## 下一步

- [ ] Config 标签页的设置持久化（UserDefaults）
- [ ] Flow Editor 标签页真正的节点编辑器
- [ ] Python 路径和脚本路径的 UI 文件选择器
- [ ] 菜单栏快捷 Kill Switch
