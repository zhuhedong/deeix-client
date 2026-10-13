# Deeix Client

[English](README.md) · **简体中文**

**DEEIX‑Chat API 的原生跨平台 Flutter 客户端** —— 为你自部署的 AI 对话后端提供一个快速、精致的移动端。

[![CI](https://github.com/zhuhedong/deeix-client/actions/workflows/ci.yml/badge.svg)](https://github.com/zhuhedong/deeix-client/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS-informational)

> 非官方、社区构建的客户端。它**只调用** DEEIX‑Chat 的 HTTP API(已按 **v0.4.4** 校准),**不修改也不包含**任何后端代码 —— 需自备已部署的服务器。

**当前版本：v1.1.0**（`1.1.0+2`），适配 DEEIX‑Chat **v0.4.4** 后端。

## 📥 下载

从 [GitHub Releases](https://github.com/zhuhedong/deeix-client/releases) 下载 APK：

| 文件 | 适用 |
|---|---|
| `arm64-v8a` APK | **推荐**，几乎所有现代安卓手机 |
| `armeabi-v7a` APK | 较老的 32 位设备 |
| `x86_64` APK | 模拟器 / x86 设备 |
| 通用(universal) APK | 所有设备（体积更大） |

可用 `SHA256SUMS.txt` 校验（`sha256sum -c SHA256SUMS.txt`）。安装后，App 会从新的 Release 自动更新。

---

## ✨ 功能

**对话**
- 基于 NDJSON 的流式回复,带实时输入指示
- Markdown + LaTeX 公式(`$…$`、`$$…$$`)、代码块一键复制
- 可折叠的「思考 / 检索 / 工具」过程面板,展示 RAG 来源
- 编辑重发、重新生成、答案分支(◀ 1/2 ▶)、流式中途停止
- 图片与文件(PDF/文档)附件,应用内预览

**会话**
- **对话优先**:每次进来都是一个全新的空草稿 —— 历史记录收纳进侧边抽屉
- 搜索、进行中/已归档筛选、重命名、置顶、分享链接、导出 JSON、项目分组
- 不留空对话:只有发出第一条消息时才真正创建会话

**模型与工具**
- 带搜索的模型切换;设置默认模型;调节 temperature / max tokens
- MCP 工具选择;提示词预设

**账户**
- 用户名/邮箱 + 密码登录、二次验证(2FA)(登录页的 SSO 入口已隐藏，见 `login_page.dart` 中的 `_kShowSsoEntry`)
- 注册、找回密码、资料编辑、活跃设备管理
- 用量与订阅概览、已上传文件管理

**个性化**
- 「石墨 + 电光靛紫」设计系统,浅色 / 深色
- **应用内可配置服务地址**、字体缩放、气泡密度、中文 / English


**v1.1.0 新增（适配 DEEIX‑Chat 0.4.4）**
- 知识库：浏览内置/个人知识库、新建、上传或添加文件；聊天时最多选 8 个用于检索
- 我的模型服务（自带 API Key）：检测、选择模型、启用/停用、更换 Key
- 聊天中的图片 / 视频生成模式（附图时为图片编辑）
- 临时对话（不保存）
- 删除消息、从消息分支出新对话、会话标签、服务端全文搜索
- 账户安全：两步验证（TOTP）开启/关闭/恢复码；近 14 天活跃度图表
- 通过 GitHub Releases 应用内更新

---

## 🧱 技术栈

| 方面 | 方案 |
|------|------|
| 状态管理 | Riverpod 3(`flutter_riverpod`、`riverpod_annotation`) |
| 路由 | `go_router` |
| 网络 | `dio` + `dio_cookie_manager` + `cookie_jar` |
| 模型 / 代码生成 | `freezed` + `json_serializable` |
| 认证存储 | `flutter_secure_storage`(Access Token)+ 持久化 Cookie(Refresh) |
| Markdown / 公式 | `flutter_markdown` + `flutter_math_fork` |
| 多媒体 | `image_picker`、`file_picker`、`cached_network_image`、`pdfrx` |
| SSO | `flutter_web_auth_2`(PKCE) |

---

## 🚀 快速开始

### 环境要求
- Flutter **3.44+**(Dart **3.12+**)
- 一个通过 **HTTPS** 可达、并为本客户端配置了 CORS 的 DEEIX‑Chat 后端
- 用于真机构建的 Android Studio / Xcode 工具链

### 运行
```bash
git clone https://github.com/zhuhedong/deeix-client.git
cd deeix-client
flutter pub get
flutter run
```

### 指向你的服务器
服务地址是**运行时设置**,无需重新打包:
- 应用内:在**登录页**点击地址,或进入 **设置 → API 地址**。
- 或在构建/运行时设置默认值:
  ```bash
  flutter run --dart-define=API_BASE_URL=https://your.domain
  ```

> 只需填写域名(如 `https://your.domain`),应用会自动追加 `/api/v1`。
> 编译期默认值在 `lib/core/constants/app_config.dart` —— 发布你的 fork 前请修改它。

---

## 📦 打包发布(Android)

内置脚本封装了常用流程,并把命名好的产物输出到 `dist/`:

```bash
scripts/build_android.sh                 # release APK
scripts/build_android.sh --split         # 按 ABI 拆分(体积更小)
scripts/build_android.sh --aab           # 上架 Google Play 的 App Bundle
scripts/build_android.sh --obfuscate     # 正式签名 + Dart 混淆
scripts/build_android.sh --help          # 全部选项
```

**签名**:若没有 `android/key.properties`,release 会退回 debug 签名(可侧载,但不能上架)。正式签名:

```bash
keytool -genkey -v -keystore ~/deeix-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias deeix

cat > android/key.properties <<'EOF'
storeFile=/绝对路径/deeix-release.jks
storePassword=…
keyAlias=deeix
keyPassword=…
EOF
```

`key.properties`、`*.jks/*.keystore` 与 `dist/` 均已被 git 忽略。**切勿提交你的 keystore 或密码。**

---

## 🗂 项目结构

```text
lib/
├── main.dart / app.dart          # 启动、MaterialApp
├── core/                         # 网络(dio、拦截器)、认证、设置、常量、工具
├── features/                     # 按功能划分的模块
│   ├── auth/                     # 密码登录、2FA、注册、重置、设备、资料
│   ├── chat/                     # 流式控制器、聊天页、气泡、输入框
│   ├── conversation/             # 历史抽屉 + 列表控制器
│   ├── models/ tools/ prompt/    # 模型列表、MCP 工具、提示词预设
│   ├── knowledge/ model_provider/ temporary_chat/ update/
│   ├── file/ project/ billing/ search/ announcement/ settings/
├── shared/                       # 主题(设计令牌)、通用组件、模型、国际化
└── router/                       # go_router 配置
```

每个功能遵循 `data/`(仓库、DTO)+ `presentation/`(控制器、页面、组件)。

---

## 🧑‍💻 开发

```bash
flutter analyze                          # 静态分析(须无告警)
dart format .                            # 规范化格式
dart run build_runner build \
  --delete-conflicting-outputs           # 重新生成 *.freezed.dart / *.g.dart
```

CI 会在推送到 `main`、PR 以及手动触发时运行(`.github/workflows/ci.yml`):格式检查 → `flutter analyze` → 构建 debug APK 并作为产物上传。

生成文件(`*.g.dart`、`*.freezed.dart`)已随仓库提交,克隆后无需先跑代码生成即可构建。

---

## 🔌 API 兼容性

按 **DEEIX‑Chat API v0.4.4** 校准。要点:
- 统一信封 `{ "data": T, "errorMsg": "" }`
- Access Token 走 `Authorization: Bearer …`;Refresh Token 在 HttpOnly Cookie 中(由 cookie jar 处理)
- 流式:`POST …/messages/stream`,返回 `application/x-ndjson`
- 会话 id 为 **publicID** 字符串(非数字)

---


## 🚀 发布与应用内更新

1. 修改 `pubspec.yaml` 里的 `version:`（如 `1.2.0+3`），合并到 `main`。
2. 打标签并推送：`git tag v1.2.0 && git push origin v1.2.0`
3. 推送 `v*` 标签会触发 `.github/workflows/release.yml`，构建按 ABI 拆分的 APK（`arm64-v8a`、`armeabi-v7a`、`x86_64`）和一个通用 APK，生成 `SHA256SUMS.txt`，并发布 GitHub Release。带后缀的标签（如 `v1.2.0-beta.1`）会作为预发布，**不会**推送给用户。

App 启动时最多每 24 小时检查一次 `zhuhedong/deeix-client` 的 `releases/latest`（地址在 `lib/features/update/data/update_service.dart` 的 `UpdateConfig`），也可以在 **设置 › 检查更新** 手动检查。Android 会按设备 ABI 下载对应 APK（找不到时用通用包），校验大小和 SHA‑256 后打开系统安装界面（首次需允许“安装未知应用”）。iOS 只会打开发布页面。

**签名所需的仓库 Secrets**（Settings › Secrets and variables › Actions）：

| Secret | 内容 |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 release.jks` 的输出 |
| `ANDROID_KEYSTORE_PASSWORD` | keystore 密码 |
| `ANDROID_KEY_ALIAS` | 密钥别名 |
| `ANDROID_KEY_PASSWORD` | 密钥密码 |

> ⚠️ 没配置这些时，发布包会用 **debug 签名**，而且每次 CI 的 debug 密钥都不同。Android 不允许签名变化的覆盖安装，所以必须先配好固定的正式签名，应用内更新才能正常使用。可用 `keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias deeix` 生成，并妥善保管 —— 丢失后用户只能卸载重装。

---

## 🤝 贡献

欢迎 Issue 与 PR。提交前请保持 `flutter analyze` 干净,并执行 `dart format .`。

## 📄 许可

尚未包含许可证文件 —— **发布前请先添加一个**(如 [MIT](https://choosealicense.com/licenses/mit/) 或 [Apache‑2.0](https://choosealicense.com/licenses/apache-2.0/))。在此之前默认保留所有权利。

## 🙏 致谢

基于 Flutter 及上述开源包构建。DEEIX‑Chat 是本客户端所对接的后端;本仓库仅包含客户端。
