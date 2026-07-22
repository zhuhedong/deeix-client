# Deeix Client

**English** · [简体中文](README.zh-CN.md)

A native, cross-platform **Flutter client for the DEEIX‑Chat API** — a fast, polished mobile front‑end for your self‑hosted AI chat backend.

[![CI](https://github.com/zhuhedong/deeix-client/actions/workflows/ci.yml/badge.svg)](https://github.com/zhuhedong/deeix-client/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS-informational)

> Unofficial, community‑built client. It **only calls** the DEEIX‑Chat HTTP API (calibrated to **v0.3.3**) and does **not** modify or ship any backend. You bring your own deployed server.

---

## ✨ Features

**Chat**
- Streaming replies over NDJSON, with a live typing indicator
- Markdown + LaTeX math (`$…$`, `$$…$$`) and code blocks with copy
- Collapsible “thinking / retrieval / tools” trace, RAG sources
- Edit & resend, regenerate, answer branches (◀ 1/2 ▶), stop mid‑stream
- Image & file attachments (PDF/docs) with in‑app preview

**Conversations**
- **Chat‑first UX**: opens a fresh, empty draft each launch — history lives in a side drawer
- Search, active/archived filter, rename, star/pin, share links, export JSON, projects
- No empty chats left behind — a conversation is created only when you send the first message

**Models & tools**
- Switch model with search; set a default; tune temperature / max tokens
- MCP tool selection; prompt presets

**Account**
- Username/email login, 2FA challenge, SSO (OIDC/OAuth via system browser + PKCE)
- Registration, password reset, profile edit, active‑device management
- Usage & billing overview, uploaded‑files management

**Personalization**
- “Graphite + Electric Indigo” design system, light / dark
- **In‑app configurable server address**, font scale, bubble density, English / 中文

---

## 🧱 Tech stack

| Area | Choice |
|------|--------|
| State management | Riverpod 3 (`flutter_riverpod`, `riverpod_annotation`) |
| Routing | `go_router` |
| Networking | `dio` + `dio_cookie_manager` + `cookie_jar` |
| Models / codegen | `freezed` + `json_serializable` |
| Auth storage | `flutter_secure_storage` (access token) + persisted cookies (refresh) |
| Markdown / math | `flutter_markdown` + `flutter_math_fork` |
| Media | `image_picker`, `file_picker`, `cached_network_image`, `pdfrx` |
| SSO | `flutter_web_auth_2` (PKCE) |

---

## 🚀 Getting started

### Requirements
- Flutter **3.44+** (Dart **3.12+**)
- A reachable DEEIX‑Chat backend over **HTTPS**, with CORS configured for this client
- Android Studio / Xcode toolchains for device builds

### Run
```bash
git clone https://github.com/zhuhedong/deeix-client.git
cd deeix-client
flutter pub get
flutter run
```

### Point it at your server
The server address is a **runtime setting** — you don’t have to rebuild:
- In‑app: tap the address on the **login screen**, or **Settings → API address**.
- Or set the default at build/run time:
  ```bash
  flutter run --dart-define=API_BASE_URL=https://your.domain
  ```

> Enter only the origin (e.g. `https://your.domain`); the app appends `/api/v1` itself.
> The compile‑time default lives in `lib/core/constants/app_config.dart` — change it before publishing your fork.

---

## 📦 Building a release (Android)

A helper script wraps the common flows and writes named artifacts to `dist/`:

```bash
scripts/build_android.sh                 # release APK
scripts/build_android.sh --split         # per‑ABI APKs (smaller)
scripts/build_android.sh --aab           # App Bundle for Google Play
scripts/build_android.sh --obfuscate     # signed + Dart obfuscation
scripts/build_android.sh --help          # all options
```

**Signing.** Without `android/key.properties`, release builds fall back to debug signing (installable, not Play‑ready). To sign for real:

```bash
keytool -genkey -v -keystore ~/deeix-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias deeix

cat > android/key.properties <<'EOF'
storeFile=/absolute/path/to/deeix-release.jks
storePassword=…
keyAlias=deeix
keyPassword=…
EOF
```

`key.properties`, `*.jks/*.keystore` and `dist/` are git‑ignored. **Never commit your keystore or its passwords.**

---

## 🗂 Project structure

```text
lib/
├── main.dart / app.dart          # bootstrap, MaterialApp
├── core/                         # network (dio, interceptors), auth, settings, constants, utils
├── features/                     # feature‑first modules
│   ├── auth/                     # login, 2FA, SSO, register, reset, sessions, profile
│   ├── chat/                     # streaming controller, chat page, bubbles, composer
│   ├── conversation/             # history drawer + list controller
│   ├── models/ tools/ prompt/    # model list, MCP tools, prompt presets
│   ├── file/ project/ billing/ search/ announcement/ settings/
├── shared/                       # theme (design tokens), reusable widgets, models, i18n
└── router/                       # go_router config
```

Each feature follows `data/` (repositories, DTOs) + `presentation/` (controllers, pages, widgets).

---

## 🧑‍💻 Development

```bash
flutter analyze                          # static analysis (must be clean)
dart format .                            # canonical formatting
dart run build_runner build \
  --delete-conflicting-outputs           # regenerate *.freezed.dart / *.g.dart
```

CI runs on every push/PR (`.github/workflows/ci.yml`): format check → `flutter analyze` → debug APK build, uploaded as an artifact.

Generated files (`*.g.dart`, `*.freezed.dart`) are committed so the app builds without running the generator first.

---

## 🔌 API compatibility

Calibrated to **DEEIX‑Chat API v0.3.3**. Highlights:
- Unified envelope `{ "data": T, "errorMsg": "" }`
- Access token via `Authorization: Bearer …`; refresh token in an HttpOnly cookie (handled by the cookie jar)
- Streaming: `POST …/messages/stream` returning `application/x-ndjson`
- Conversation ids are **publicID** strings (not numeric)

---

## 🤝 Contributing

Issues and PRs welcome. Please keep `flutter analyze` clean and run `dart format .` before submitting.

## 📄 License

No license file is included yet — **add one before publishing** (e.g. [MIT](https://choosealicense.com/licenses/mit/) or [Apache‑2.0](https://choosealicense.com/licenses/apache-2.0/)). Until then, all rights reserved by default.

## 🙏 Acknowledgements

Built with Flutter and the packages listed above. DEEIX‑Chat is the backend this client talks to; this repository contains the client only.
