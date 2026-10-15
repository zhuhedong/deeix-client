# Deeix Client

[English](README.md) · **简体中文**

面向 DEEIX-Chat 的原生 **Flutter** 客户端 —— 为你自部署的 AI 对话后端提供精致的 Android 前端。

[![CI](https://github.com/zhuhedong/deeix-client/actions/workflows/ci.yml/badge.svg)](https://github.com/zhuhedong/deeix-client/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.44.6-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/platform-Android-informational)
![Version](https://img.shields.io/badge/version-v1.1.2-blue)

> 非官方、社区构建的客户端。它**只调用** DEEIX-Chat 的 HTTP API（已按 **v0.4.4** 校准），**不修改也不包含**任何后端代码 —— 需自备已部署的服务器。

| | |
|---|---|
| **应用版本** | `1.1.2+4`（标签 `v1.1.2`） |
| **后端目标** | DEEIX-Chat **v0.4.4** |
| **默认 API** | `https://chat.cli-help.com` |
| **发布页** | [github.com/zhuhedong/deeix-client/releases](https://github.com/zhuhedong/deeix-client/releases) |
| **仓库** | [github.com/zhuhedong/deeix-client](https://github.com/zhuhedong/deeix-client) |

正式发布的产物是 **Android APK**。仓库里有 `ios/` 工程可用于本地开发，但 CI **不会**构建或发布 iOS 包。

---

## 下载

从 **[GitHub Releases](https://github.com/zhuhedong/deeix-client/releases)** 获取 APK（最新：[v1.1.2](https://github.com/zhuhedong/deeix-client/releases/tag/v1.1.2)）：

| 产物 | 适用场景 |
|---|---|
| `deeix-client-v*-arm64-v8a.apk` | **推荐** —— 几乎所有现代手机 |
| `deeix-client-v*-armeabi-v7a.apk` | 较老的 32 位 ARM 设备 |
| `deeix-client-v*-x86_64.apk` | 模拟器 / x86 设备 |
| `deeix-client-v*-universal.apk` | 任意 ABI（体积更大） |
| `SHA256SUMS.txt` | 上述 APK 的校验和 |

安装前建议校验：

```bash
sha256sum -c SHA256SUMS.txt
```

安装后，Android 端可从新的 GitHub Releases **应用内更新**。详见 [应用内更新](#应用内更新)。

---

## 功能

以下均已在当前 `main` 分支（`lib/features/…`）实现，并对接 DEEIX-Chat v0.4.4。

### 对话

- 基于 NDJSON 的流式回复，带实时输入指示；可中途停止
- Markdown、LaTeX 公式（`$…$`、`$$…$$`）、代码块一键复制
- 可折叠的「思考 / 检索 / 工具」过程面板，展示 RAG 来源
- 编辑重发、重新生成、答案分支（◀ 1/2 ▶）
- 消息反馈、删除、从消息分支出新对话
- 图片与文件附件（含 PDF），支持应用内预览
- 单次对话可调 temperature 与 max tokens
- 输入框支持图片 / 视频**生成**模式（附图时走图片**编辑**）
- 每次对话最多选择 **8** 个知识库用于检索
- MCP 工具选择与提示词预设
- 导出为服务端 JSON 或本地 Markdown（剪贴板）

### 会话

- **对话优先**：每次进入都是全新的空**草稿**；历史收纳在侧边抽屉
- 只有发出第一条消息时才在服务端创建会话（不留空对话）
- 进行中 / 已归档筛选、重命名、置顶（星标）、标签、分享链接、导出 JSON、归入项目
- 服务端全文搜索
- **临时对话** —— 不在服务端持久化的会话

### 知识库

- 浏览内置与个人知识库
- 新建 / 更新 / 删除个人知识库；上传或添加已有文件；移除文件

### 我的模型服务（自带 API Key）

- 查看访问权限、探测 Provider、创建 / 更新 / 删除个人 Provider
- 选择可用模型、启用 / 停用、更换 Key

### 模型与工具

- 带搜索的模型列表；可在设置中指定默认模型
- 从 `/mcp/tools` 加载 MCP 工具，并选择当前对话启用哪些
- 从 `/prompt-presets` 加载提示词预设

### 账户与安全

- **用户名或邮箱 + 密码**登录（字段文案：「邮箱 / 用户名」）
- 服务端要求时，密码登录后进入 **2FA 验证**
- 服务端开启时支持邮箱注册与找回密码（`/auth/login-options`）
- 资料编辑、修改密码
- 活跃设备（会话）列表：撤销单个会话或退出全部设备
- 账户安全页：TOTP 两步验证的**开启 / 关闭 / 恢复码**
- **SSO**：服务端可能配置了 OAuth/OIDC，但登录页的 SSO 入口**有意隐藏**（`lib/features/auth/presentation/login_page.dart` 中 `_kShowSsoEntry = false`），待客户端适配 0.4.4 的 provider 鉴权桥接后再开放。当前支持的路径是账号密码登录。

### 账单、文件、公告

- 账单概览、用量，以及近 14 天活跃度图表（服务端支持 `/user/stats/activity` 时）
- 已上传文件管理
- 服务端公告，支持「今日不再显示」与关闭

### 个性化

- 「石墨 + 电光靛紫」设计系统 —— 浅色 / 深色 / 跟随系统
- 语言：English / 中文 / 跟随系统
- 字体缩放、气泡密度（舒适 / 紧凑）、回车发送
- **应用内可配置 API 地址**（登录页或 设置 → API 地址）
- 清理图片缓存；关于 / 隐私 / 条款入口

### 更新

- 通过 GitHub Releases 应用内更新（Android）：启动时最多每 24 小时自动检查一次，或在 **设置 → 检查更新** 手动检查
- 按设备 ABI 下载对应 APK（找不到时用通用包），校验大小与 SHA-256 后打开系统安装器
- iOS 只会打开 Releases 页面（不支持应用内安装 APK）

---

## 技术栈

| 方面 | 方案 |
|------|------|
| 状态管理 | Riverpod 3（`flutter_riverpod`、`riverpod_annotation`） |
| 路由 | `go_router` |
| 网络 | `dio` + `dio_cookie_manager` + `cookie_jar` |
| 模型 / 代码生成 | `freezed` + `json_serializable` |
| 认证存储 | `flutter_secure_storage`（Access Token）+ 持久化 Cookie（Refresh） |
| Markdown / 公式 | `flutter_markdown` + `flutter_math_fork` |
| 多媒体 | `image_picker`、`file_picker`、`cached_network_image`、`pdfrx`、`open_filex` |
| SSO（代码保留，UI 隐藏） | `flutter_web_auth_2`（PKCE） |
| 更新 | GitHub Releases API + `package_info_plus` + `permission_handler` |

---

## 环境要求

- **Flutter 3.44.6**（Dart **3.12.2**）—— 与 CI（`.github/workflows/ci.yml`）锁定版本一致
- 可通过 **HTTPS** 访问的 DEEIX-Chat **v0.4.4** 后端，并为本客户端配置 CORS
- 真机构建需要 Android SDK（JDK 17）；仅在本地构建 iOS 时才需要 Xcode

---

## 从源码构建

```bash
git clone https://github.com/zhuhedong/deeix-client.git
cd deeix-client
flutter pub get
flutter run
```

### Android 打包脚本

`scripts/build_android.sh` 封装常用流程，并把命名好的产物复制到 `dist/`：

```bash
scripts/build_android.sh                 # release 通用 APK
scripts/build_android.sh --split         # 按 ABI 拆分
scripts/build_android.sh --aab           # 上架 Google Play 的 App Bundle
scripts/build_android.sh --api https://your.domain
scripts/build_android.sh --obfuscate     # Dart 混淆
scripts/build_android.sh --help
```

### 本地签名（可选）

若没有 `android/key.properties`，release 会退回 **debug 签名**（可侧载，但不能上架）。正式签名：

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

`android/key.properties`、`*.jks` / `*.keystore` 与 `dist/` 均已 gitignore。**切勿提交 keystore 或密码。**

---

## 配置

### 默认服务器

编译期默认值在 `lib/core/constants/app_config.dart`：

- `API_BASE_URL` 默认 → `https://chat.cli-help.com`
- `apiPrefix` → `/api/v1`

只需填写**域名原点**（例如 `https://your.domain`），应用会自动追加 `/api/v1`。

### 构建 / 运行时覆盖

```bash
flutter run --dart-define=API_BASE_URL=https://your.domain
# 或
scripts/build_android.sh --api https://your.domain
```

### 运行时覆盖（无需重新打包）

- 登录页：点击服务器地址
- **设置 → API 地址**

运行时偏好会覆盖编译期默认值，直到被重置。

---

## 项目结构

```text
lib/
├── main.dart / app.dart       # 启动、MaterialApp
├── core/                      # 网络（dio、拦截器）、认证、设置、常量、工具
├── features/                  # 按功能划分的模块
│   ├── announcement/          # 服务端公告
│   ├── auth/                  # 登录、2FA、注册、重置、设备、资料、安全
│   ├── billing/               # 概览、用量、活跃度图表
│   ├── chat/                  # 流式控制器、聊天页、气泡、输入框
│   ├── conversation/          # 历史抽屉、列表、分享 / 标签 / 归档
│   ├── file/                  # 已上传文件
│   ├── knowledge/             # 知识库
│   ├── model_provider/        # 个人 BYO Key 模型服务
│   ├── models/                # 模型列表 DTO / Provider
│   ├── project/               # 会话项目分组
│   ├── prompt/                # 提示词预设
│   ├── search/                # 服务端全文搜索
│   ├── settings/              # 外观、API 地址、检查更新
│   ├── temporary_chat/        # 临时对话
│   ├── tools/                 # MCP 工具
│   └── update/                # GitHub Releases 更新器
├── shared/                    # 主题（AppTokens）、通用组件、模型、国际化（中/英）
└── router/                    # go_router 路由
```

各功能通常采用 `data/`（仓库、DTO）+ `presentation/`（控制器、页面、组件）。

Android 应用 ID：`com.deeix.deeix_client`（`minSdk` 跟随 Flutter；`targetSdk` / `compileSdk` 为 36）。

---

## 开发

```bash
flutter pub get
flutter analyze                 # 须无告警
flutter test                    # test/ 下的单元与组件测试
dart format .
dart run build_runner build --delete-conflicting-outputs
```

生成文件（`*.g.dart`、`*.freezed.dart`）已随仓库提交，克隆后无需先跑代码生成即可构建。

---

## 持续集成

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) 在推送到 `main` / `master`、Pull Request 以及手动 `workflow_dispatch` 时运行：

1. `dart format --set-exit-if-changed .`
2. `flutter analyze`
3. `flutter test`
4. `flutter build apk --debug`（产物 `app-debug-apk`）

CI 中的 Flutter 版本：**3.44.6**（JDK 17）。

---

## API 兼容性

按 **DEEIX-Chat API v0.4.4** 校准：

| 主题 | 行为 |
|------|------|
| 信封 | `{ "data": T, "errorMsg": "" }` |
| Access Token | `Authorization: Bearer …` |
| Refresh Token | HttpOnly Cookie（由 cookie jar 处理） |
| 流式 | `POST …/messages/stream` → `application/x-ndjson` |
| 会话 ID | publicID **字符串**（非数字） |
| 媒体 | 图片 / 视频生成（+ 图片编辑）NDJSON 流 |
| 临时对话 | `POST /temporary-chat/messages/stream` |
| 知识库 / 模型服务 | `/knowledge-bases…`、`/me/model-providers…` |
| 两步验证管理 | `/me/2fa…` |
| 活跃度 | `/user/stats/activity` |

默认部署的 Swagger：`https://chat.cli-help.com/swagger/doc.json`（`AppConfig.swaggerDocUrl`）。

---

## 发布

1. 修改 `pubspec.yaml` 中的 `version:`（例如 `1.2.0+4`），合并到 `main`。
2. 打标签并推送：

   ```bash
   git tag v1.2.0
   git push origin v1.2.0
   ```

3. 推送 `v*` 标签会触发 [`.github/workflows/release.yml`](.github/workflows/release.yml)，该工作流会：
   - 运行 `flutter test`
   - 构建按 ABI 拆分的 release APK（`arm64-v8a`、`armeabi-v7a`、`x86_64`）以及一个**通用** APK
   - 生成 `SHA256SUMS.txt`
   - 发布 GitHub Release（`Deeix Client vX.Y.Z`）

带预发布后缀的标签（如 `v1.2.0-beta.1`）会标记为 GitHub 预发布，**不会**被应用内更新推送给用户。

### 仓库 Secrets（Actions）

在 **Settings → Secrets and variables → Actions** 中配置（仅列出名称 —— 切勿把真实值写进仓库）：

| Secret | 用途 |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | release `.jks` 的 Base64（`base64 -w0 release.jks`） |
| `ANDROID_KEYSTORE_PASSWORD` | keystore 密码 |
| `ANDROID_KEY_ALIAS` | 密钥别名 |
| `ANDROID_KEY_PASSWORD` | 密钥密码 |

未配置时，发布包会用 **debug 签名**，且每次 CI 的 debug 密钥可能不同。Android 不允许签名变化的覆盖安装，因此**必须使用固定的正式 keystore，应用内更新才能可靠工作**。请妥善备份该 keystore —— 丢失后用户只能卸载重装。

---

## 应用内更新

- 检查地址：`https://api.github.com/repos/zhuhedong/deeix-client/releases/latest`（见 `lib/features/update/data/update_service.dart` 中的 `UpdateConfig`）
- 启动时最多每 **24 小时**自动检查一次；也可在 **设置 → 检查更新** 手动检查
- 跳过草稿、GitHub 预发布以及用户已忽略的版本
- Android：按 ABI 下载 APK → 校验大小与 SHA-256 → 打开系统安装器（需 `REQUEST_INSTALL_PACKAGES`；首次需允许「安装未知应用」）
- 使用独立 Dio 客户端，不会把 DEEIX Access Token 发给 GitHub

---

## 贡献

欢迎 Issue 与 PR。提交前请保持 `flutter analyze` 干净，运行 `flutter test`，并执行 `dart format .`。

---

## 许可

尚未包含许可证文件。**再分发前请先添加一个**（例如 [MIT](https://choosealicense.com/licenses/mit/) 或 [Apache-2.0](https://choosealicense.com/licenses/apache-2.0/)）。在此之前默认保留所有权利。

---

## 致谢

基于 Flutter 及上述开源包构建。DEEIX-Chat 是本客户端所对接的后端；本仓库**仅包含客户端**。

- 仓库：https://github.com/zhuhedong/deeix-client
- 发布：https://github.com/zhuhedong/deeix-client/releases
- 默认服务器：https://chat.cli-help.com
