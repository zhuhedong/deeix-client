# Deeix Client

**English** · [简体中文](README.zh-CN.md)

A native **Flutter** client for DEEIX-Chat — a polished Android front end for your self-hosted AI chat backend.

[![CI](https://github.com/zhuhedong/deeix-client/actions/workflows/ci.yml/badge.svg)](https://github.com/zhuhedong/deeix-client/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.44.6-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/platform-Android-informational)
![Version](https://img.shields.io/badge/version-v1.1.1-blue)

> Unofficial, community-built client. It **only calls** the DEEIX-Chat HTTP API (calibrated to **v0.4.4**) and does **not** modify or ship any backend. You bring your own deployed server.

| | |
|---|---|
| **App version** | `1.1.1+3` (tag `v1.1.1`) |
| **Backend target** | DEEIX-Chat **v0.4.4** |
| **Default API** | `https://chat.cli-help.com` |
| **Releases** | [github.com/zhuhedong/deeix-client/releases](https://github.com/zhuhedong/deeix-client/releases) |
| **Repository** | [github.com/zhuhedong/deeix-client](https://github.com/zhuhedong/deeix-client) |

Published artifacts are **Android APKs**. An `ios/` project tree exists for local development, but CI does not build or publish iOS binaries.

---

## Download

Get APKs from **[GitHub Releases](https://github.com/zhuhedong/deeix-client/releases)** (latest: [v1.1.1](https://github.com/zhuhedong/deeix-client/releases/tag/v1.1.1)):

| Asset | Use when |
|---|---|
| `deeix-client-v*-arm64-v8a.apk` | **Recommended** — nearly all modern phones |
| `deeix-client-v*-armeabi-v7a.apk` | Older 32-bit ARM devices |
| `deeix-client-v*-x86_64.apk` | Emulators / x86 devices |
| `deeix-client-v*-universal.apk` | Any ABI (larger download) |
| `SHA256SUMS.txt` | Checksums for all APKs above |

Verify before installing:

```bash
sha256sum -c SHA256SUMS.txt
```

After install, the app can update itself from new GitHub Releases on Android. See [In-app updates](#in-app-updates).

---

## Features

Everything below is implemented in the current `main` tree (`lib/features/…`) against DEEIX-Chat v0.4.4.

### Chat

- Streaming replies over NDJSON with a live typing indicator; stop mid-stream
- Markdown rendering, LaTeX math (`$…$`, `$$…$$`), code blocks with copy
- Collapsible thinking / retrieval / tools traces and RAG sources
- Edit and resend, regenerate, answer branches (◀ 1/2 ▶)
- Message feedback, delete, and fork into a new conversation
- Image and file attachments (including PDF) with in-app preview
- Per-chat generation options: temperature and max tokens
- Image / video **generation** mode in the composer (image **edit** when files are attached)
- Pick up to **8** knowledge bases per chat for retrieval
- MCP tool selection and prompt presets
- Export conversation as server JSON or local Markdown (clipboard)

### Conversations

- Chat-first UX: each launch opens a fresh empty **draft**; history lives in the side drawer
- A server conversation is created only when you send the first message (no empty chats left behind)
- Active / archived filter, rename, star (pin), labels, share links, export JSON, assign to a project
- Server full-text search across conversations
- **Temporary chat** — unsaved session that is not persisted on the server

### Knowledge bases

- Browse built-in and personal knowledge bases
- Create / update / delete personal bases; upload or attach existing files; remove files

### Model providers (bring your own key)

- List access, probe a provider, create / update / delete personal providers
- Choose available models, enable / disable, rotate API key

### Models and tools

- Model list with search; set a default model in Settings
- MCP tools from `/mcp/tools`; select which tools are active for a chat
- Prompt presets from `/prompt-presets`

### Account and security

- **Username or email + password** login (field label: “Email / username”)
- Optional **2FA challenge** after password login when the server requires it
- Email registration and password reset when the server enables them (`/auth/login-options`)
- Profile edit; change password
- Active device (session) list: revoke one session or log out everywhere
- Account security page: TOTP two-factor **setup / disable / recovery codes**
- **SSO**: the server may expose OAuth/OIDC providers, but the login-screen SSO entry is **intentionally hidden** (`_kShowSsoEntry = false` in `lib/features/auth/presentation/login_page.dart`) until the client is adapted to the 0.4.4 provider auth bridge. Password login is the supported path.

### Billing, files, announcements

- Billing overview, usage, and a 14-day activity chart (when the server supports `/user/stats/activity`)
- Uploaded-files management
- Server announcements with dismiss-today / close

### Personalization

- “Graphite + Electric Indigo” design system — light / dark / follow system
- Locale: English / 中文 / follow system
- Font scale, bubble density (comfortable / compact), send-with-Enter
- **In-app configurable API address** (login screen or Settings → API address)
- Clear image cache; about / privacy / terms links

### Updates

- In-app update from GitHub Releases (Android): auto-check at most every 24 hours on launch, or **Settings → 检查更新**
- Downloads the APK matching the device ABI (falls back to universal), verifies size + SHA-256, then opens the system installer
- On iOS the updater only opens the Releases page (no in-app APK install)

---

## Tech stack

| Area | Choice |
|------|--------|
| State | Riverpod 3 (`flutter_riverpod`, `riverpod_annotation`) |
| Routing | `go_router` |
| Networking | `dio` + `dio_cookie_manager` + `cookie_jar` |
| Models / codegen | `freezed` + `json_serializable` |
| Auth storage | `flutter_secure_storage` (access token) + persisted cookies (refresh) |
| Markdown / math | `flutter_markdown` + `flutter_math_fork` |
| Media | `image_picker`, `file_picker`, `cached_network_image`, `pdfrx`, `open_filex` |
| SSO (code present, UI hidden) | `flutter_web_auth_2` (PKCE) |
| Updates | GitHub Releases API + `package_info_plus` + `permission_handler` |

---

## Requirements

- **Flutter 3.44.6** (Dart **3.12.2**) — same pin as CI (`.github/workflows/ci.yml`)
- A reachable DEEIX-Chat **v0.4.4** backend over **HTTPS**, with CORS allowing this client
- For device builds: Android SDK (JDK 17). Xcode only if you build the iOS tree locally

---

## Build from source

```bash
git clone https://github.com/zhuhedong/deeix-client.git
cd deeix-client
flutter pub get
flutter run
```

### Android release helpers

`scripts/build_android.sh` wraps common flows and copies named artifacts to `dist/`:

```bash
scripts/build_android.sh                 # release APK (universal)
scripts/build_android.sh --split         # per-ABI APKs
scripts/build_android.sh --aab           # App Bundle for Play
scripts/build_android.sh --api https://your.domain
scripts/build_android.sh --obfuscate     # Dart obfuscation
scripts/build_android.sh --help
```

### Local signing (optional)

Without `android/key.properties`, release builds fall back to **debug signing** (sideloadable, not Play-ready). For a real keystore:

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

`android/key.properties`, `*.jks` / `*.keystore`, and `dist/` are gitignored. **Never commit a keystore or its passwords.**

---

## Configuration

### Default server

Compile-time default in `lib/core/constants/app_config.dart`:

- `API_BASE_URL` default → `https://chat.cli-help.com`
- `apiPrefix` → `/api/v1`

Enter only the **origin** (for example `https://your.domain`). The app appends `/api/v1` itself.

### Override at build / run time

```bash
flutter run --dart-define=API_BASE_URL=https://your.domain
# or
scripts/build_android.sh --api https://your.domain
```

### Override at runtime (no rebuild)

- Login screen: tap the server address
- **Settings → API address**

Runtime preference wins over the compile-time default until reset.

---

## Project structure

```text
lib/
├── main.dart / app.dart       # bootstrap, MaterialApp
├── core/                      # network (dio, interceptors), auth, settings, constants, utils
├── features/                  # feature-first modules
│   ├── announcement/          # server banners
│   ├── auth/                  # login, 2FA, register, reset, sessions, profile, security
│   ├── billing/               # overview, usage, activity chart
│   ├── chat/                  # streaming controller, chat page, bubbles, composer
│   ├── conversation/          # history drawer, list, share / labels / archive
│   ├── file/                  # uploaded files
│   ├── knowledge/             # knowledge bases
│   ├── model_provider/        # personal BYO-key providers
│   ├── models/                # model list DTOs / providers
│   ├── project/               # conversation projects
│   ├── prompt/                # prompt presets
│   ├── search/                # server full-text search UI
│   ├── settings/              # appearance, API URL, update check
│   ├── temporary_chat/        # unsaved chat
│   ├── tools/                 # MCP tools
│   └── update/                # GitHub Releases updater
├── shared/                    # theme (AppTokens), widgets, models, l10n (en/zh)
└── router/                    # go_router routes
```

Each feature typically uses `data/` (repositories, DTOs) + `presentation/` (controllers, pages, widgets).

Android application id: `com.deeix.deeix_client` (`minSdk` from Flutter; `targetSdk` / `compileSdk` 36).

---

## Development

```bash
flutter pub get
flutter analyze                 # must be clean
flutter test                    # unit / widget tests under test/
dart format .
dart run build_runner build --delete-conflicting-outputs
```

Generated files (`*.g.dart`, `*.freezed.dart`) are **committed**, so a fresh clone builds without running the generator first.

---

## Continuous integration

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs on pushes to `main` / `master`, on pull requests, and via `workflow_dispatch`:

1. `dart format --set-exit-if-changed .`
2. `flutter analyze`
3. `flutter test`
4. `flutter build apk --debug` (artifact `app-debug-apk`)

Flutter version in CI: **3.44.6** (JDK 17).

---

## API compatibility

Aligned with **DEEIX-Chat API v0.4.4**:

| Topic | Behavior |
|------|----------|
| Envelope | `{ "data": T, "errorMsg": "" }` |
| Access token | `Authorization: Bearer …` |
| Refresh token | HttpOnly cookie (cookie jar) |
| Streaming | `POST …/messages/stream` → `application/x-ndjson` |
| Conversation ids | publicID **strings** (not numeric) |
| Media | image/video generation (+ image edit) NDJSON streams |
| Temporary chat | `POST /temporary-chat/messages/stream` |
| Knowledge / providers | `/knowledge-bases…`, `/me/model-providers…` |
| 2FA management | `/me/2fa…` |
| Activity | `/user/stats/activity` |

Swagger for the default deployment: `https://chat.cli-help.com/swagger/doc.json` (`AppConfig.swaggerDocUrl`).

---

## Releasing

1. Bump `version:` in `pubspec.yaml` (for example `1.2.0+4`) and merge to `main`.
2. Tag and push:

   ```bash
   git tag v1.2.0
   git push origin v1.2.0
   ```

3. Pushing a `v*` tag triggers [`.github/workflows/release.yml`](.github/workflows/release.yml), which:
   - runs `flutter test`
   - builds **split-per-ABI** release APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`) plus a **universal** APK
   - writes `SHA256SUMS.txt`
   - publishes a GitHub Release (`Deeix Client vX.Y.Z`)

Tags with a pre-release suffix (`v1.2.0-beta.1`) are marked as GitHub pre-releases and are **not** offered by the in-app updater.

### Repository secrets (Actions)

Configure under **Settings → Secrets and variables → Actions** (names only — never commit values):

| Secret | Purpose |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64 of the release `.jks` (`base64 -w0 release.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias |
| `ANDROID_KEY_PASSWORD` | Key password |

Without these, release APKs are **debug-signed** with a throwaway key that can change between CI runs. Android refuses to update an app whose signing key changed, so **in-app updates only work reliably with a fixed release keystore**. Keep that keystore backed up — losing it forces users to uninstall to update.

---

## In-app updates

- Checks `https://api.github.com/repos/zhuhedong/deeix-client/releases/latest` (`UpdateConfig` in `lib/features/update/data/update_service.dart`)
- Auto-check at most once every **24 hours** on launch; manual check from **Settings → 检查更新**
- Skips drafts, GitHub pre-releases, and ignored versions
- Android: download ABI-matched APK → verify size + SHA-256 → system installer (`REQUEST_INSTALL_PACKAGES`; user must allow “install unknown apps” once)
- Uses a dedicated Dio client so the DEEIX access token is never sent to GitHub

---

## Contributing

Issues and PRs are welcome. Please keep `flutter analyze` clean, run `flutter test`, and `dart format .` before submitting.

---

## License

No license file is included yet. **Add one before redistributing** (for example [MIT](https://choosealicense.com/licenses/mit/) or [Apache-2.0](https://choosealicense.com/licenses/apache-2.0/)). Until then, all rights are reserved by default.

---

## Acknowledgements

Built with Flutter and the packages listed above. DEEIX-Chat is the backend this client talks to; this repository contains the **client only**.

- Repository: https://github.com/zhuhedong/deeix-client
- Releases: https://github.com/zhuhedong/deeix-client/releases
- Default server: https://chat.cli-help.com
