# iOS 壳包 — 搭建与打包

> **约定：文中所有路径均为相对于本项目根目录的相对路径**（即包含 `XinJi28/`、`project.yml` 的那一层目录）。

---

## 目录

1. [项目简介](#1-项目简介)
2. [环境要求与安装](#2-环境要求与安装)
3. [用 Xcode 打开项目](#3-用-xcode-打开项目)
4. [启动流程](#4-启动流程)
5. [核心配置修改](#5-核心配置修改)
6. [修改名称、图标、品牌色](#6-修改名称图标品牌色)
7. [启动页与再次打开过渡页](#7-启动页与再次打开过渡页)
8. [隐私协议页](#8-隐私协议页)
9. [引导页与视频页](#9-引导页与视频页)
10. [下拉刷新](#10-下拉刷新)
11. [远程 URL 配置](#11-远程-url-配置)
12. [图片与资源规范](#12-图片与资源规范)
13. [打包 Debug IPA](#13-打包-debug-ipa)
14. [打包 Release IPA](#14-打包-release-ipa)
15. [安装到 iPhone](#15-安装到-iphone)
16. [真机测试清单](#16-真机测试清单)
17. [常见问题](#17-常见问题)
18. [项目文件结构](#18-项目文件结构)
19. [发版前检查清单](#19-发版前检查清单)

---

## 1. 项目简介

这是一个 WebView 壳。全屏打开远程网页，外面包启动页、协议页和引导页。

| 项目 | 当前值 | 修改位置 |
|------|--------|----------|
| 显示名称 | 新记 | `app-config.json` → `app_name` |
| Bundle ID | `com.xj28a.app` | `app-config.json` → `application_id` |
| 默认加载网址 | `https://test.kaixin28.com` | `app-config.json` → `web_url` |
| 最低系统 | iOS 15 | `project.yml` → `IPHONEOS_DEPLOYMENT_TARGET` |
| 版本号 | 1.001 起，导出 IPA 成功后自动递增 | `version.properties` |
| Debug 包 | `XJ28-debug.ipa` | `./scripts/build-ipa.sh` |
| Release 包 | `XJ28-release.ipa` | `./scripts/build-ipa.sh adhoc` |

| 功能 | 说明 | 默认 |
|------|------|------|
| 启动页 | 全屏启动图，底部加载 | 开启 |
| 再次打开过渡页 | 从后台回到前台时盖同一张启动图 | 开启 |
| 隐私协议页 | 首次勾选同意 | 开启 |
| 滑动引导页 | 首次 3 页，右上角可跳过 | 开启 |
| 视频引导页 | 引导第一页播 MP4 | 关闭 |
| 网页主页 | 加载配置的网址 | 开启 |
| 下拉刷新 | 主页面向下拉刷新 | 开启 |
| 远程换网址 | 服务器 JSON 动态换网址 | 开启 |
| 加载进度 | 加载页显示百分比 | 开启 |
| 网络错误重试 | 断网时显示重试 | 开启 |
| 相机 / 相册 / 定位 / 麦克风 | 网页内功能使用系统授权 | 开启 |

```
冷启动：启动页 → 隐私协议 → 引导页 → 网页
再次冷启动：启动页 → 网页
从后台回来：原来的网页上盖约 2.5 秒过渡页
```

---

## 2. 环境要求与安装

### 2.1 必需软件

| 软件 | 说明 |
|------|------|
| **macOS** | 打包 IPA 只能在 Mac 上做 |
| **Xcode** | 完整版，不能只用 Command Line Tools |
| **Apple 开发者账号** | 真机安装和导出 IPA 都要 Team ID |
| **XcodeGen** | `brew install xcodegen`，用来根据 `project.yml` 生成工程 |

### 2.2 安装 Xcode

下载 Xcode 需要登录 Apple ID。已安装 `xcodes` 时：

```bash
xcodes signin
xcodes install --latest --select --experimental-unxip
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

也可以从 App Store 安装，装完后执行上面的 `xcode-select`。

```bash
xcode-select -p
```

输出应包含 `Xcode.app`。若是 `/Library/Developer/CommandLineTools`，还不能打包。

### 2.3 第一次生成工程

```bash
brew install xcodegen
chmod +x scripts/*.sh
./scripts/sync-config.sh
./scripts/sync-version.sh
xcodegen generate
open XinJi28.xcodeproj
```

改 `project.yml` 或增删源文件后，再执行一次 `xcodegen generate`。

---

## 3. 用 Xcode 打开项目

1. 打开 **Xcode**
2. **File → Open**，选本目录下的 `XinJi28.xcodeproj`
3. 左侧选中工程 **XinJi28** → target **XinJi28** → **Signing & Capabilities**
4. 勾选 **Automatically manage signing**
5. **Team** 选中开发者团队
6. 把 10 位 Team ID 记下来，命令行打包要用

模拟器可以直接 Run，不需要 Team。真机和 IPA 必须选 Team。

---

## 4. 启动流程

### 4.1 首次安装

```
点击图标
    ↓
SplashViewController（约 2.5 秒）
    ↓
PrivacyViewController（勾选同意）     ← show_privacy_on_first_launch
    ↓
GuideViewController（3 页，可跳过）   ← show_guide_on_first_launch
    ↓
MainViewController（网页）
```

### 4.2 完全关闭后再次打开

划掉后再点图标：跳过协议和引导，启动页结束后直接进网页。

### 4.3 切到后台再打开

`SceneDelegate` 发现从后台回到前台，且当前是主页时，盖上与启动页相同的过渡层，约 2.5 秒后淡出，底下仍是原来的网页。

### 4.4 各页面职责

| 类 | 职责 |
|----|------|
| `SplashViewController` | 冷启动入口，拉取远程配置 |
| `PrivacyViewController` | 首次协议勾选 |
| `GuideViewController` | 首次滑动引导 |
| `MainViewController` | 网页、下拉刷新、加载和错误页 |
| `SceneDelegate` | 从后台恢复时显示过渡页 |
| `AppNavigator` | 决定下一页 |
| `AppPrefs` | 协议、引导、远程网址缓存 |
| `RemoteConfig` | 远程网址 |
| `ShellConfig` | 读取打包时写入的配置 |
| `Brand` | 品牌色 |

删掉重装后，协议和引导会再出现一次。

---

## 5. 核心配置修改

复制 `app-config.example.json` 为 `app-config.json`，改完重新打包。`app-config.json` 已在 `.gitignore` 里。没有这个文件时，使用模板里的默认值。

```bash
cp app-config.example.json app-config.json
```

打包时会打印：

```
>>> App 配置[app-config.json]: NAME=新记 | ID=com.xj28a.app | WEB_URL=https://test.kaixin28.com | ...
```

以 `_` 开头的键只是说明，打包不读取。

| 字段 | 作用 | 默认 |
|------|------|------|
| `application_id` | Bundle ID。改动后是另一个 App | `com.xj28a.app` |
| `app_name` | 桌面名称 | `新记` |
| `web_url` | 兜底网址 | `https://test.kaixin28.com` |
| `remote_config_url` | 热切换 JSON 地址。留空则不请求 | 模板中的地址 |
| `enable_remote_url` | 是否请求热切换 | `true` |
| `remote_config_cache_hours` | 热切换结果缓存小时数 | `1` |
| `show_privacy_on_first_launch` | 首次是否显示协议 | `true` |
| `privacy_policy_url` | 空则用包内 HTML，填 `https://` 则加载远程协议 | `""` |
| `show_guide_on_first_launch` | 首次是否显示引导 | `true` |
| `enable_video_splash` | 引导第一页是否播视频 | `false` |
| `splash_duration_ms` | 启动页和过渡页毫秒数 | `2500` |
| `enable_pull_to_refresh` | 下拉刷新 | `true` |
| `user_agent_name` | UA 前缀，打包后拼成 `名称/版本号` | `XJ28App` |

只要启动页和网页时：

```json
"show_privacy_on_first_launch": false,
"show_guide_on_first_launch": false
```

缩短启动等待时，把 `splash_duration_ms` 改成 `1500`。

### 版本号

导出 IPA 成功后，`VERSION_PATCH` 和 `VERSION_CODE` 各加 1。格式是 `1.001`、`1.002`。

| 文件 | 说明 |
|------|------|
| `version.properties` | 当前版本，打包成功后自动更新 |
| `version.properties.example` | 模板 |
| `Config/Version.xcconfig` | 由 `scripts/sync-version.sh` 生成，不要手改 |

大版本改成 2.001：把 `VERSION_MAJOR` 改为 `2`，`VERSION_PATCH` 改回 `1`，`VERSION_CODE` 设成比已发布包更大的整数，然后重新打包。

只跑模拟器或打包失败时，版本号不变。

---

## 6. 修改名称、图标、品牌色

桌面名称改 `app-config.json` 的 `app_name`。

引导文案在 `GuideViewController.swift` 的三页标题和说明里。

图标替换这两张图，保持文件名不变：

| 路径 | 用途 |
|------|------|
| `XinJi28/Assets.xcassets/AppIcon.appiconset/AppIcon.png` | 桌面图标 |
| `XinJi28/Assets.xcassets/AppLogo.imageset/AppLogo.png` | 加载页 Logo |

品牌色在 `XinJi28/Brand.swift`：

| 名称 | 色值 | 用途 |
|------|------|------|
| `primary` | `#1A237E` | 主色、协议标题 |
| `primaryDark` | `#0D1642` | 按钮文字 |
| `accent` | `#FFD700` | 按钮、进度条 |
| `background` | `#FFFFFF` | 页面底色 |
| `surface` | `#F5F6F8` | 协议底栏、错误卡片 |
| `textPrimary` | `#1B1F27` | 正文 |
| `textSecondary` | `#6B7280` | 副标题 |
| `error` | `#EF5350` | 错误标记 |

---

## 7. 启动页与再次打开过渡页

启动页和从后台回来的过渡页是同一个 `SplashContentView`：全屏 `SplashBackground`，底部显示「正在加载…」。停留时间是 `splash_duration_ms`。

系统闪屏是 `XinJi28/Base.lproj/LaunchScreen.storyboard`。

---

## 8. 隐私协议页

标题在上方，中间是协议网页，底部勾选后才能点「同意并继续」。「不同意并退出」会关掉 App。

正文文件：`XinJi28/Resources/privacy_policy.html`。

`privacy_policy_url` 留空用这个本地文件；写成 `https://...` 则加载远程页面。

---

## 9. 引导页与视频页

右上角「跳过」，底部圆点和按钮（下一步 / 立即体验）。

要换成自己的图，放进 `Assets.xcassets`，名称必须是 `guide_slide_1`、`guide_slide_2`、`guide_slide_3`。没有这些图时用系统图标占位。

视频引导：把 `splash_video.mp4` 放到 `XinJi28/Resources/`，把 `enable_video_splash` 设为 `true`，再执行 `xcodegen generate`。视频静音循环，作为第一页。

---

## 10. 下拉刷新

`enable_pull_to_refresh` 为 `true` 时，主页面向下拉会刷新当前网页。

网页返回用屏幕左边缘右滑。

---

## 11. 远程 URL 配置

示例在 `docs/app-config.example.json`：

```json
{
  "web_url": "https://test.kaixin28.com"
}
```

`web_url` 必须以 `http://` 或 `https://` 开头。

`enable_remote_url` 为 `true` 且 `remote_config_url` 不为空时，启动页会请求该地址，跳转前最多再等 1.5 秒。缓存未过期时主页用缓存地址，失败则回到 `web_url`。

---

## 12. 图片与资源规范

| 资源 | 建议 |
|------|------|
| 桌面图标 / Logo | 1024×1024 PNG，单张尽量小于 500KB |
| 引导图 | 720×720 以内，小于 300KB |
| 引导视频 | 720p MP4，小于 5MB，文件名 `splash_video.mp4` |

资源名只用小写字母、数字、下划线。替换后在真机上看桌面图标、启动图和引导图。

---

## 13. 打包 Debug IPA

Debug 包装到已注册的开发设备上。

```bash
cp Config/Signing.xcconfig.example Config/Signing.xcconfig
```

编辑 `Config/Signing.xcconfig`：

```
DEVELOPMENT_TEAM = 你的10位TeamID
CODE_SIGN_STYLE = Automatic
```

这个文件已在 `.gitignore` 里。也可以打包时临时指定：

```bash
TEAM_ID=XXXXXXXXXX ./scripts/build-ipa.sh
```

在项目根目录执行：

```bash
./scripts/build-ipa.sh
```

成功后：

```
build/ipa/XJ28-debug.ipa
```

装到真机必须签名。模拟器不需要 Team，也不出 IPA：

```bash
./scripts/build-simulator.sh
```

或在 Xcode 里选模拟器点 Run。这种方式不递增版本号。

---

## 14. 打包 Release IPA

签名使用 Apple 证书和描述文件，由 Xcode 按 Team 管理。

Ad Hoc 包装到在开发者后台登记过 UDID 的设备：

```bash
./scripts/build-ipa.sh adhoc
```

成功后：

```
build/ipa/XJ28-release.ipa
```

设备 UDID 要先加进 [Apple Developer](https://developer.apple.com/account) 的设备列表，并包含在描述文件里。Team 选错、设备没登记或描述文件过期，导出都会失败。

证书和 Team 账号丢失后，不能用同一个 Bundle ID 覆盖安装更新，只能换 Bundle ID，或找回原来的开发者账号。

---

## 15. 安装到 iPhone

1. iPhone 用数据线连上这台 Mac
2. 手机上点信任此电脑
3. 在 Mac 上打开 Xcode，点屏幕最上方菜单栏的 **窗口（Window）→ 设备与模拟器（Devices and Simulators）**，确认能看到这台 iPhone
4. 把 `XJ28-debug.ipa` 或 `XJ28-release.ipa` 拖到设备详情里的 **Installed Apps**

或在 Xcode 里选中这台 iPhone，直接 Run。首次安装若提示不受信任：手机 **设置 → 通用 → VPN 与设备管理**，信任开发者证书。

---

## 16. 真机测试清单

- 桌面名称和 `app_name` 一致，图标正常
- 冷启动能看到启动图，结束后进入后续页面
- 首次有协议，不勾选不能继续；不同意会退出
- 引导可滑、可跳过，最后一页按钮是「立即体验」
- 主页打开配置里的网址；热切换成功时用远程地址
- 断网出现错误页，点重新加载能恢复
- 下拉能刷新
- 网页内选图、拍照、定位会弹出系统权限
- 划到后台再回来，会出现过渡页，结束后仍是刚才的网页
- 删掉重装后，协议和引导会再走一遍

---

## 17. 常见问题

**提示只有 Command Line Tools**  
执行 `xcode-select -p`。若不是 Xcode.app，按第 2.2 节安装完整 Xcode 并切换。

**打包要求 Team ID**  
按第 13 节写 `Config/Signing.xcconfig`，或运行时加 `TEAM_ID=`。

**未签名的 IPA 能装到手机吗**  
不能。真机安装必须有开发者签名。模拟器运行不需要签名。

**签名失败或没有描述文件**  
在 Xcode 里打开 target 的 Signing，Team 选对，连上手机让 Xcode 创建描述文件。Ad Hoc 还要登记设备 UDID。

**改了配置但手机还是旧网址**  
重新打包安装。远程换网址开着时，缓存期内会继续用旧地址，可删掉重装清缓存。

**改了图标仍是旧的**  
删掉手机上的 App 再装。

**协议或引导不再出现**  
这是首次标记，存在本机。删掉重装即可。

---

## 18. 项目文件结构

```
ipa-pack/
├── XinJi28/
│   ├── ShellConfig.swift
│   ├── AppConfig.swift              ← 打包时由 app-config.json 生成
│   ├── Brand.swift
│   ├── SplashViewController.swift
│   ├── PrivacyViewController.swift
│   ├── GuideViewController.swift
│   ├── MainViewController.swift
│   ├── Info.plist
│   ├── Resources/privacy_policy.html
│   └── Assets.xcassets/
├── app-config.example.json          ← 复制为 app-config.json 后修改
├── project.yml
├── version.properties
├── Config/Signing.xcconfig.example
├── scripts/build-ipa.sh
├── scripts/build-simulator.sh
├── docs/app-config.example.json
└── README.md
```

---

## 19. 发版前检查清单

- `app-config.json` 里的 `web_url` 是正式地址
- 协议、引导开关符合这次发布
- 桌面名称、图标、启动图已换
- `version.properties` 的大版本正确
- `Config/Signing.xcconfig` 的 Team 是要使用的账号
- `./scripts/build-ipa.sh adhoc` 成功，产物是 `build/ipa/XJ28-release.ipa`
- 在登记过的真机安装，并走完第 16 节清单
