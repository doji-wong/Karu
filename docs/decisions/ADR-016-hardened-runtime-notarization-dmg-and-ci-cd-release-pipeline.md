# ADR-016: Hardened Runtime, Standalone DMG Distribution, Apple Notarization, and Automated CI/CD Release Pipeline

## Status
Accepted

## Date
2026-09-18

## Context
As Karu reached release readiness, shipping a professional, standalone native macOS application outside the Mac App Store required addressing several platform, security, and distribution challenges:

1. **macOS Gatekeeper & Hardened Runtime Requirements:** Starting in macOS 10.14+ and strictly enforced in macOS 14 Sonoma and macOS 15 Sequoia, applications distributed directly to users must run under Apple's **Hardened Runtime** (`--options runtime`), be signed with an Apple Developer ID Application certificate with secure timestamps, and declare explicit entitlements. Without this, Gatekeeper blocks execution or displays untrusted developer warnings.
2. **Standard macOS Installer UX:** While `.zip` archives can package an application bundle, they provide poor installation ergonomics (users frequently run apps directly from `~/Downloads`, leading to permissions and translocated path issues). A standard read-only disk image (`.dmg`) with branded Finder window styling, centered application icon, and a direct drag-and-drop symlink to `/Applications` is the expected standard for native Mac software.
3. **Apple Notarization & Offline Stapling:** Direct-distributed macOS applications must be submitted to Apple's Notary Service to verify they are free of malicious components. For seamless offline installation, the resulting notarization ticket must be permanently stapled directly onto the `.dmg` using `xcrun stapler`.
4. **CI/CD Automation & Reproducibility:** Manual local builds risk subtle environment variations, uncommitted dependencies, or missing code signatures. An automated continuous integration and release pipeline was necessary to enforce strict compilation warnings, run unit tests in parallel, build and sign release binaries, and publish GitHub Releases on semantic version tags.

---

## Decision

### 1. Hardened Runtime Entitlements (`Packaging/Karu.entitlements`)
Created an explicit, minimal entitlements configuration for the application:
- `com.apple.security.cs.allow-jit: false`
- `com.apple.security.cs.allow-unsigned-executable-memory: false`
- `com.apple.security.cs.disable-library-validation: false`

These flags strictly enforce Apple's hardened runtime boundaries with zero unnecessary security bypasses, conforming to modern macOS sandboxing and security best practices.

### 2. Parameterized Code Signing & Hardened Runtime in `build_app.sh`
Enhanced `scripts/build_app.sh` with parameterized signing:
- Supports `CODESIGN_IDENTITY` (defaults to ad-hoc `-` for local non-developer builds).
- When a valid signing identity (e.g. `Developer ID Application: ...`) is specified:
  - Signs nested plugins first (`KaruWidgets.appex`) with entitlements and runtime options.
  - Signs the outer `Karu.app` with `--options runtime`, `--timestamp`, and `--entitlements Packaging/Karu.entitlements`.
  - Validates signatures using `codesign --verify --deep --strict --verbose=2`.

### 3. Native Zero-Dependency Standalone DMG Packager (`scripts/create_dmg.sh`)
Implemented a completely native, zero-dependency disk image packaging script:
- Uses macOS built-in `hdiutil` to stage the `.app` bundle, create an `/Applications` symlink, and copy `.VolumeIcon.icns`.
- Mounts a temporary read-write disk image (`UDRW`) and executes inline AppleScript to programmatically format the Finder window:
  - Window bounds calibrated to 540x380 px.
  - Toolbar and status bar hidden.
  - Custom icon sizes (110 pt) with precise layout coordinates: `Karu.app` at `{130, 180}` and `/Applications` at `{410, 180}`.
- Converts the image to compressed, read-only `UDZO` format (`zlib-level=9`).
- Signs the resulting `.dmg` with `codesign --timestamp` if a developer identity is present.
- Computes SHA-256 checksums automatically.

### 4. Apple Notarization & Stapling Utility (`scripts/notarize_app.sh`)
Built a dedicated notarization helper wrapping Apple's command-line tools:
- Submits target `.dmg` or `.zip` artifacts to Apple Notary Service via `xcrun notarytool submit --wait`.
- Supports dual authentication paths:
  - **Method A (Keychain Profile):** `KEYCHAIN_PROFILE` (for secure local developer environments).
  - **Method B (Environment Secrets):** `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, and `APPLE_TEAM_ID` (for headless CI runners).
- Automatically invokes `xcrun stapler staple` on DMG artifacts upon successful notary clearance and validates the ticket with `xcrun stapler validate`.

### 5. Automated GitHub Actions CI/CD Pipeline
Configured two GitHub Actions workflows on `macos-14` (Apple Silicon runners):
1. **`build-and-test.yml` (Continuous Integration):**
   - Triggers on every push and pull request to `main`.
   - Compiles targets with `swift build -Xswiftc -warnings-as-errors` to enforce strict zero-warning quality gates.
   - Executes unit tests in parallel with `swift test --parallel`.
2. **`release.yml` (Continuous Deployment):**
   - Triggers on semantic version tag pushes (`v*`).
   - Securely decodes and imports the Apple Developer Certificate into a temporary ephemeral keychain.
   - Assembles `Karu.app` and `KaruWidgets.appex` via `build_app.sh`.
   - Packages the release DMG via `create_dmg.sh`.
   - Submits for Apple Notarization and staples the ticket via `notarize_app.sh` when credentials exist.
   - Generates `checksums.txt` (SHA-256).
   - Automatically drafts and publishes a GitHub Release using `softprops/action-gh-release@v2` with `.dmg`, `.zip`, and `checksums.txt` attached.

---

## Alternatives Considered

1. **Third-Party DMG Packaging Tools (e.g. `create-dmg`, `appdmg`):**
   - *Proposal:* Use Node.js-based `appdmg` or Homebrew `create-dmg` scripts to generate disk images.
   - *Rejected:* Introduces external toolchains (Node.js, npm, or Homebrew) to build infrastructure. Using native macOS `hdiutil` and AppleScript keeps the build 100% self-contained on any fresh macOS installation or CI runner.
2. **Fastlane for Code Signing & Notarization:**
   - *Proposal:* Integrate Fastlane (`match`, `notarize`) for build management.
   - *Rejected:* Fastlane requires a Ruby runtime and gem maintenance. Apple's native `xcrun notarytool` and `security` CLI tools provide superior performance, lower complexity, and zero external language dependencies.
3. **In-App Auto-Update Frameworks (e.g. Sparkle):**
   - *Proposal:* Embed Sparkle.framework for background updates.
   - *Rejected:* Kept out of scope for initial v1.0 release to preserve the `< 45 MB` memory budget and zero-third-party dependency architectural rule. May be evaluated as a modular opt-in capability in future updates.

---

## Consequences

- **Positive:** Karu distributes as a polished, notarized `.dmg` that passes macOS Gatekeeper with zero warnings on macOS 14 Sonoma and macOS 15 Sequoia.
- **Positive:** Zero external dependencies: The entire build, package, sign, and notarize pipeline uses exclusively built-in macOS tools (`swift`, `hdiutil`, `osascript`, `codesign`, `xcrun notarytool`, `xcrun stapler`).
- **Positive:** Automated CI on PRs catches regressions and compiler warnings early; pushing a git tag (`v1.0.0`) automatically publishes release assets to GitHub Releases.
- **Positive:** Users who prefer building from source or installing locally can run `./scripts/install_app.sh` or `./scripts/create_dmg.sh` with automatic ad-hoc signing fallback.
- **Trade-off:** Notarization requires Apple Developer Program membership ($99/year) and configuration of GitHub Actions repository secrets (`BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`, `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID`). The workflow gracefully skips notarization when secrets are omitted, permitting community forks to build cleanly.
