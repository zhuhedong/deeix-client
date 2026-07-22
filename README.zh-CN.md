# Deeix Client

[English](README.md) · **简体中文**

**DEEIX‑Chat API 的原生跨平台 Flutter 客户端** —— 为你自部署的 AI 对话后端提供一个快速、精致的移动端。

[![CI](https://github.com/zhuhedong/deeix-client/actions/workflows/ci.yml/badge.svg)](https://github.com/zhuhedong/deeix-client/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS-informational)

> 非官方、社区构建的客户端。它**只调用** DEEIX‑Chat 的 HTTP API(已按 **v0.3.3** 校准),**不修改也不包含**任何后端代码 —— 需自备已部署的服务器。

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
- 用户名/邮箱登录、二次验证(2FA)、SSO(系统浏览器 + PKCE 的 OIDC/OAuth)
- 注册、找回密码、资料编辑、活跃设备管理
- 用量与订阅概览、已上传文件管理

**个性化**
- 「石墨 + 电光靛紫」设计系统,浅色 / 深色
- **应用内可配置服务地址**、字体缩放、气泡密度、中文 / English

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
│   ├── auth/                     # 登录、2FA、SSO、注册、重置、设备、资料
│   ├── chat/                     # 流式控制器、聊天页、气泡、输入框
│   ├── conversation/             # 历史抽屉 + 列表控制器
│   ├── models/ tools/ prompt/    # 模型列表、MCP 工具、提示词预设
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

CI 会在每次 push/PR 运行(`.github/workflows/ci.yml`):格式检查 → `flutter analyze` → 构建 debug APK 并作为产物上传。

生成文件(`*.g.dart`、`*.freezed.dart`)已随仓库提交,克隆后无需先跑代码生成即可构建。

---

## 🔌 API 兼容性

按 **DEEIX‑Chat API v0.3.3** 校准。要点:
- 统一信封 `{ "data": T, "errorMsg": "" }`
- Access Token 走 `Authorization: Bearer …`;Refresh Token 在 HttpOnly Cookie 中(由 cookie jar 处理)
- 流式:`POST …/messages/stream`,返回 `application/x-ndjson`
- 会话 id 为 **publicID** 字符串(非数字)

---

## 🤝 贡献

欢迎 Issue 与 PR。提交前请保持 `flutter analyze` 干净,并执行 `dart format .`。

## 📄 许可

尚未包含许可证文件 —— **发布前请先添加一个**(如 [MIT](https://choosealicense.com/licenses/mit/) 或 [Apache‑2.0](https://choosealicense.com/licenses/apache-2.0/))。在此之前默认保留所有权利。

## 🙏 致谢

基于 Flutter 及上述开源包构建。DEEIX‑Chat 是本客户端所对接的后端;本仓库仅包含客户端。
