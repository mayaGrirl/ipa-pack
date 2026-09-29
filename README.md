# 新纪28 iOS 壳包 — 完整搭建与打包教程

> 本文档面向已经会打 Android 壳包的人。页面、开关、版本号规则与 `apk-pack` 一致，差别只在环境：那边是 Android Studio，这边是 Xcode。  
> **约定：文中所有路径均为相对于本项目根目录的相对路径**（即包含 `XinJi28/`、`project.yml` 的那一层目录）。

Android 壳包已经在其他电脑验证可以打包。本仓库不改 APK 工程，只提供对应的 IPA。

---

## 目录

1. [项目简介](#1-项目简介)
2. [环境要求与安装](#2-环境要求与安装)
3. [用 Xcode 打开项目](#3-用-xcode-打开项目)
4. [App 启动流程（三种场景）](#4-app-启动流程三种场景)
5. [核心配置修改（必看）](#5-核心配置修改必看)
6. [修改 App 名称、图标、品牌色](#6-修改-app-名称图标品牌色)
7. [启动页与再次打开过渡页](#7-启动页与再次打开过渡页)
8. [隐私协议页](#8-隐私协议页)
9. [引导页与视频启动页](#9-引导页与视频启动页)
10. [下拉刷新](#10-下拉刷新)
11. [远程 URL 配置](#11-远程-url-配置)
12. [图片与资源规范](#12-图片与资源规范)
13. [打包 Debug IPA（测试用）](#13-打包-debug-ipa测试用)
14. [打包 Release IPA（正式分发）](#14-打包-release-ipa正式分发)
15. [安装到 iPhone](#15-安装到-iphone)
16. [真机测试清单](#16-真机测试清单)
17. [常见问题 FAQ](#17-常见问题-faq)
18. [项目文件结构](#18-项目文件结构)
19. [发版前检查清单](#19-发版前检查清单)

---

## 1. 项目简介

这是和 Android「新纪28」同一套 **WebView 壳包**。全屏网页加载远程 H5，外面包启动页、协议页、引导页。

| 项目 | 当前值 | 修改位置 | Android 对应 |
|------|--------|----------|----------------|
| App 显示名称 | 新记 | `app-config.json` → `app_name` | 同左 |
| Bundle ID | `com.xj28a.app` | `app-config.json` → `application_id` | 同左 |
| 默认加载网址 | `https://test.kaixin28.com` | `app-config.json` → `web_url` | 同左 |
| 最低系统 | iOS 15 | `project.yml` → `IPHONEOS_DEPLOYMENT_TARGET` | `minSdk 21` |
| 版本号 | 1.001 起，导出 IPA 成功后自动递增 | `version.properties` | 同左 |
| Debug 包文件名 | `新纪28-debug.ipa` | `scripts/build-ipa.sh` | `新纪28-debug.apk` |
| Release 包文件名 | `XJ28-release.ipa` | `scripts/build-ipa.sh adhoc` | `XJ28-release.apk` |

| 功能 | 说明 | 默认 |
|------|------|------|
| 品牌启动页 | Logo + 金色名称 + 标语，底部加载动画 | 开启 |
| 再次打开过渡页 | 从后台回到前台时盖同一张启动页 | 开启 |
| 隐私协议页 | 首次勾选同意，可关闭 | 开启 |
| 滑动引导页 | 首次 3 页，右上角可跳过 | 开启 |
| 视频引导页 | 引导第一页播 MP4 | 关闭 |
| WebView 主页 | 加载配置的 H5 | 开启 |
| 下拉刷新 | 主页面向下拉刷新 | 开启 |
| 远程 URL | 服务器 JSON 动态换网址 | 关闭 |
| 加载进度 | 品牌色加载页 + 百分比 | 开启 |
| 网络错误重试 | 断网时金色描边卡片 | 开启 |
| 相机 / 相册 / 定位 / 麦克风 | 网页内功能使用系统授权 | 开启 |

页面顺序与 Android 相同：

```
冷启动：启动页 → 隐私协议 → 引导页 → 网页
再次冷启动：启动页 → 网页
从后台回来：原来的网页上盖 2.5 秒过渡页
```

---

## 2. 环境要求与安装

### 2.1 必需软件

| 软件 | 说明 |
|------|------|
| **macOS** | 打包 IPA 只能在 Mac 上做 |
| **Xcode** | 完整版，不能只用 Command Line Tools |
| **Apple Developer** | 真机安装和导出 IPA 都要 Team ID |
| **XcodeGen** | `brew install xcodegen`，用来根据 `project.yml` 生成工程 |

Android Studio、JDK、Android SDK 属于 `apk-pack`，不要装进本目录。

### 2.2 安装 Xcode

Apple 下载 Xcode 需要登录 Apple ID。本机已安装 `xcodes` 时：

```bash
xcodes signin
xcodes install --latest --select --experimental-unxip
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

也可以从 App Store 安装 Xcode，装完后执行上面的 `xcode-select`。

确认不是 Command Line Tools：

```bash
xcode-select -p
```

输出应包含 `Xcode.app`。若是 `/Library/Developer/CommandLineTools`，还不能打包。

### 2.3 第一次生成工程

```bash
brew install xcodegen
chmod +x scripts/*.sh
./scripts/sync-version.sh
xcodegen generate
open XinJi28.xcodeproj
```

`XinJi28.xcodeproj` 可由 XcodeGen 重复生成。改 `project.yml` 或增删源文件后，再执行一次 `xcodegen generate`。

---

## 3. 用 Xcode 打开项目

1. 打开 **Xcode**
2. **File → Open**，选本目录下的 `XinJi28.xcodeproj`
3. 左侧选中工程 **XinJi28** → target **XinJi28** → **Signing & Capabilities**
4. 勾选 **Automatically manage signing**
5. **Team** 选中你的 Apple 开发者团队
6. 把 10 位 Team ID 记下来，命令行打包要用

模拟器可以直接 Run，不需要 Team。真机和 IPA 必须选 Team。

---

## 4. App 启动流程（三种场景）

### 4.1 首次安装

```
点击图标
    ↓
SplashViewController（约 2.5 秒）
    ↓
PrivacyViewController（勾选同意）     ← showPrivacyOnFirstLaunch
    ↓
GuideViewController（3 页，可跳过）   ← showGuideOnFirstLaunch
    ↓
MainViewController（网页）
```

### 4.2 完全关闭后再次打开

划掉 App 再点图标：跳过协议和引导，启动页结束后直接进网页。

### 4.3 切到后台再打开

`SceneDelegate` 发现从后台回到前台，且当前是主页时，盖上与启动页相同的过渡层，约 2.5 秒后淡出，底下仍是原来的网页。对应 Android 的 `layout_splash_overlay`。

### 4.4 各页面职责

| 类 | 文件 | 职责 | Android |
|----|------|------|---------|
| `SplashViewController` | 同名 | 冷启动入口，拉远程配置 | `SplashActivity` |
| `PrivacyViewController` | 同名 | 首次协议勾选 | `PrivacyActivity` |
| `GuideViewController` | 同名 | 首次滑动引导 | `GuideActivity` |
| `MainViewController` | 同名 | 网页、下拉刷新、加载/错误页 | `MainActivity` |
| `SceneDelegate` | 同名 | 从后台恢复时显示过渡页 | `App.java` |
| `AppNavigator` | 同名 | 决定下一页 | `AppNavigator` |
| `AppPrefs` | 同名 | 协议、引导、远程网址缓存 | `AppPrefs` |
| `RemoteConfig` | 同名 | 远程 URL | `RemoteConfig` |
| `ShellConfig` | `ShellConfig.swift` | 全部壳包开关 | `app/build.gradle` 的 `buildConfigField` |
| `Brand` | `Brand.swift` | 品牌色 | `colors.xml` |

删掉 App 重装，协议和引导会再出现一次。

---

## 5. 核心配置修改（必看）

**改配置不要改 Swift。** 和 Android 一样，复制 `app-config.example.json` 为 `app-config.json`，改完重新打包。`app-config.json` 已在 `.gitignore`，不会进 Git。没这个文件时，用模板里的默认值。

```bash
cp app-config.example.json app-config.json
```

打包脚本会打印和 Android 一样的一行：

```
>>> App 配置[app-config.json]: NAME=新记 | ID=com.xj28a.app | WEB_URL=https://test.kaixin28.com | ...
```

字段名、缺省值与 `apk-pack` 的 `app/build.gradle` 相同：`application_id`、`app_name`、`web_url`、`remote_config_url`、`enable_remote_url`、`remote_config_cache_hours`、`show_privacy_on_first_launch`、`privacy_policy_url`、`show_guide_on_first_launch`、`enable_video_splash`、`splash_duration_ms`、`enable_pull_to_refresh`、`user_agent_name`。以 `_` 开头的键只是注释。

`user_agent_name` 会拼成 `XJ28App/1.001` 这种后缀。

### 5.2 配置项

| 配置项 | 作用 | Android 对应 |
|--------|------|----------------|
| `webURL` | 默认网址 | `WEB_URL` |
| `userAgentSuffix` | 追加到系统 UA | `USER_AGENT_SUFFIX` |
| `splashDuration` | 启动页 / 过渡页秒数 | `SPLASH_DURATION_MS`（这里用秒） |
| `showPrivacyOnFirstLaunch` | 首次是否显示协议 | `SHOW_PRIVACY_ON_FIRST_LAUNCH` |
| `privacyPolicyURL` | 空则用包内 HTML，填 `https://` 则加载远程协议 | `PRIVACY_POLICY_URL` |
| `showGuideOnFirstLaunch` | 首次是否显示引导 | `SHOW_GUIDE_ON_FIRST_LAUNCH` |
| `enableVideoSplash` | 引导第一页是否播视频 | `ENABLE_VIDEO_SPLASH` |
| `enablePullToRefresh` | 下拉刷新 | `ENABLE_PULL_TO_REFRESH` |
| `enableRemoteURL` | 是否用 JSON 换网址 | `ENABLE_REMOTE_URL` |
| `remoteConfigURL` | JSON 地址 | `REMOTE_CONFIG_URL` |
| `remoteConfigCacheHours` | 缓存小时数 | `REMOTE_CONFIG_CACHE_HOURS` |

Bundle ID 不在这个文件里，改 `project.yml` 的 `PRODUCT_BUNDLE_IDENTIFIER`，然后重新 `xcodegen generate`。

### 5.3 常用组合

只要启动页 + 网页：

```swift
static let showPrivacyOnFirstLaunch = false
static let showGuideOnFirstLaunch = false
```

远程换域名，不用每次发包：

```swift
static let enableRemoteURL = true
static let remoteConfigURL = "https://你的域名.com/app-config.json"
```

缩短启动等待：

```swift
static let splashDuration: TimeInterval = 1.5
```

### 5.4 版本号（自动递增）

规则与 Android 相同。

```
1.001 → 1.002 → 1.003
```

| 文件 | 说明 |
|------|------|
| `version.properties` | 当前版本。导出 IPA **成功后** `VERSION_PATCH` 和 `VERSION_CODE` 各 +1 |
| `version.properties.example` | 模板，默认 `1.001` |
| `Config/Version.xcconfig` | 由 `scripts/sync-version.sh` 生成，不要手改 |

```properties
VERSION_MAJOR=1
VERSION_PATCH=1
VERSION_CODE=1
```

大版本改成 2.001：把 `VERSION_MAJOR` 改为 `2`，`VERSION_PATCH` 改回 `1`，`VERSION_CODE` 设成比已发布包更大的整数，然后重新打包。

只跑模拟器、Sync、或打包失败时，版本号不变。

---

## 6. 修改 App 名称、图标、品牌色

### 6.1 名称

桌面名称改 `app-config.json` 的 `app_name`。启动页标语写在 `XinJi28/ShellConfig.swift` 的 `splashTagline`，对应 Android `strings.xml`，当前是「畅享精彩 尽在XJ28」。

引导文案在 `GuideViewController.swift` 的三页标题和说明里，对应 Android 的 `strings.xml`。

### 6.2 图标

替换这两张 1024×1024 PNG，保持文件名不变：

| 路径 | 用途 |
|------|------|
| `XinJi28/Assets.xcassets/AppIcon.appiconset/AppIcon.png` | 桌面图标 |
| `XinJi28/Assets.xcassets/AppLogo.imageset/AppLogo.png` | 启动页、加载页 Logo |

Xcode 里也可以点开 `AppIcon`，把 1024 图拖进去。

### 6.3 品牌色

编辑 `XinJi28/Brand.swift`。当前色值与 Android `colors.xml` 相同：

| 名称 | 色值 | 用途 |
|------|------|------|
| `primary` | `#1A237E` | 主色 |
| `primaryDark` | `#0D1642` | 协议页顶栏、按钮文字 |
| `accent` | `#FFD700` | 名称、按钮、进度条 |
| `background` | `#0F1535` | 页面底色 |
| `surface` | `#1E2761` | 协议底栏、错误卡片 |
| `textSecondary` | `#B0BEC5` | 副标题 |
| `error` | `#EF5350` | 错误标记 |

---

## 7. 启动页与再次打开过渡页

启动页和从后台回来的过渡页是同一个 `SplashContentView`：居中 120pt Logo、金色应用名、标语，底部「正在加载…」。停留时间是 `splashDuration`。

系统自己的那一帧闪屏是 `XinJi28/Base.lproj/LaunchScreen.storyboard`，底色与壳一致。

---

## 8. 隐私协议页

顶栏深蓝、金色标题，中间网页，底部勾选后才能点「同意并继续」。「不同意并退出」会关掉 App。

正文文件：`XinJi28/Resources/privacy_policy.html`。

`privacyPolicyURL` 留空用这个本地文件；写成 `https://...` 则加载远程页面。JavaScript 在协议页是关闭的。

---

## 9. 引导页与视频启动页

右上角「跳过」，底部圆点 + 金色按钮（下一步 / 立即体验）。标题是金色。

三页文案与 Android 相同。要换成自己的图，把图片放进 `Assets.xcassets`，名称必须是：

- `guide_slide_1`
- `guide_slide_2`
- `guide_slide_3`

没有这些图时，用系统图标占位。

视频引导：把 `splash_video.mp4` 放到 `XinJi28/Resources/`，并把 `enableVideoSplash` 设为 `true`。然后执行 `xcodegen generate`，让新文件进工程。视频静音循环，作为第一页。

---

## 10. 下拉刷新

`enablePullToRefresh = true` 时，主页面向下拉会刷新当前网页。关掉后下拉没有刷新控件。

网页里的返回用手势：从屏幕左边缘右滑，相当于 Android 的返回键。iPhone 没有系统返回键，因此没有「再按一次退出」。

---

## 11. 远程 URL 配置

JSON 与 Android 相同，示例在 `docs/app-config.example.json`：

```json
{
  "web_url": "https://m.kaixin28.com"
}
```

`web_url` 必须以 `http://` 或 `https://` 开头。

开启后，启动页会请求 `remoteConfigURL`，跳转前最多再等 1.5 秒。缓存未过期时主页用缓存地址，失败则回到 `webURL`。

---

## 12. 图片与资源规范

| 资源 | 建议 |
|------|------|
| 桌面图标 / Logo | 1024×1024 PNG，单张尽量小于 500KB |
| 引导图 | 720×720 以内，小于 300KB |
| 引导视频 | 720p MP4，小于 5MB，文件名 `splash_video.mp4` |

资源名只用小写字母、数字、下划线。替换后在真机看：桌面图标、启动页 Logo、引导图。

---

## 13. 打包 Debug IPA（测试用）

Debug 包对应 Android 的 `assembleDebug`，装到已注册的开发设备，不能给任意手机。

### 13.1 先写签名（对应 Android 的 keystore.properties）

```bash
cp Config/Signing.xcconfig.example Config/Signing.xcconfig
```

编辑 `Config/Signing.xcconfig`：

```
DEVELOPMENT_TEAM = 你的10位TeamID
CODE_SIGN_STYLE = Automatic
```

这个文件已在 `.gitignore` 里，不要提交。

也可以不写文件，打包时临时指定：

```bash
TEAM_ID=XXXXXXXXXX ./scripts/build-ipa.sh
```

### 13.2 命令行打包

在项目根目录：

```bash
./scripts/build-ipa.sh
```

成功后：

```
build/ipa/新纪28-debug.ipa
```

控制台会提示版本号已递增。打开 `version.properties` 可核对下一次版本。

### 13.3 只编模拟器（不出 IPA）

不需要 Team：

```bash
./scripts/build-simulator.sh
```

或在 Xcode 里选模拟器，点 **Run ▶**。这种方式不递增版本号。

---

## 14. 打包 Release IPA（正式分发）

Release 对应 Android 的 `assembleRelease`。iOS 没有 `.jks`。签名是 Apple 的证书和描述文件，由 Xcode 按 Team 自动管理。

Ad Hoc 包可以装到在开发者后台登记过 UDID 的设备：

```bash
./scripts/build-ipa.sh adhoc
```

成功后：

```
build/ipa/XJ28-release.ipa
```

设备 UDID 要先加进 [Apple Developer](https://developer.apple.com/account) 的设备列表，并包含在描述文件里。Team 选错、设备没登记、或描述文件过期，导出都会失败。

证书和 Team 账号丢失后，不能给同一个 Bundle ID 发可无缝覆盖安装的更新，只能换 Bundle ID 或找回原开发者账号。这和 Android 丢了 keystore 是同一类问题。

---

## 15. 安装到 iPhone

1. iPhone 用数据线连上这台 Mac
2. 手机上点信任此电脑
3. Xcode → **Window → Devices and Simulators**，确认能看到设备
4. 把 `新纪28-debug.ipa` 或 `XJ28-release.ipa` 拖到设备详情里的 **Installed Apps**

或在 Xcode 里选中这台 iPhone，直接 **Run ▶**。首次安装若提示不受信任：手机 **设置 → 通用 → VPN 与设备管理**，信任你的开发者证书。

---

## 16. 真机测试清单

- 桌面名称是「新纪28」，图标正常
- 冷启动约 2.5 秒，名称是金色
- 首次有协议，不勾选不能继续；不同意会退出
- 引导可滑、可跳过，最后一页按钮是「立即体验」
- 主页打开 `app-config.json` 里的 `web_url`（热切换成功时用远程地址）
- 断网出现错误卡片，点重新加载能恢复
- 下拉能刷新
- 网页内选图、拍照、定位会弹出系统权限
- 划到后台再回来，会出现过渡页，结束后仍是刚才的网页
- 删掉重装后，协议和引导会再走一遍

---

## 17. 常见问题 FAQ

**提示只有 Command Line Tools**  
执行 `xcode-select -p`。若不是 Xcode.app，按第 2.2 节装完整 Xcode 并切换。

**打包要求 Team ID**  
按第 13.1 节写 `Config/Signing.xcconfig`，或运行时加 `TEAM_ID=`。

**签名失败 / 没有描述文件**  
Xcode 里打开 target 的 Signing，Team 选对，连上手机让 Xcode 自动创建描述文件。Ad Hoc 还要登记设备 UDID。

**改了 ShellConfig 但手机还是旧网址**  
重新打包安装。远程 URL 开着时，缓存期内会继续用旧的 `web_url`，可删 App 重装清缓存。

**改了图标仍是旧的**  
删掉手机上的 App 再装。iOS 会缓存桌面图标。

**协议或引导不再出现**  
这是首次标记，存在本机。删 App 重装即可。

**和 Android 包名一样，能装在同一部手机吗**  
不能互装。一边是 APK，一边是 IPA，系统不同。Bundle ID 与 `applicationId` 同为 `com.xinji28.app`，只是两边各自识别。

---

## 18. 项目文件结构

```
ipa-pack/
├── XinJi28/
│   ├── ShellConfig.swift              ← 壳包开关（对应 app/build.gradle）
│   ├── Brand.swift                    ← 品牌色（对应 colors.xml）
│   ├── SplashViewController.swift
│   ├── SplashContentView.swift
│   ├── PrivacyViewController.swift
│   ├── GuideViewController.swift
│   ├── MainViewController.swift
│   ├── Info.plist                     ← 桌面名称、权限文案
│   ├── Resources/privacy_policy.html
│   └── Assets.xcassets/               ← 图标、Logo、可选引导图
├── project.yml                        ← Bundle ID、最低系统
├── version.properties                 ← 版本号，打包成功后自动 +1
├── Config/Signing.xcconfig.example    ← 复制后填写 Team ID
├── scripts/build-ipa.sh               ← Debug / Release 打包
├── scripts/build-simulator.sh         ← 只编模拟器
├── docs/app-config.example.json
└── README.md
```

---

## 19. 发版前检查清单

- `ShellConfig.webURL` 是正式地址
- 协议、引导开关符合这次发布
- 桌面名称、图标、启动页 Logo 已换
- `version.properties` 的大版本正确
- `Config/Signing.xcconfig` 的 Team 是正式账号
- `./scripts/build-ipa.sh adhoc` 成功，产物是 `build/ipa/XJ28-release.ipa`
- 在登记过的真机安装，并走完第 16 节清单
