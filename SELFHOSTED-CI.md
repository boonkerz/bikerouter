# Self-hosted CI (GitHub Actions + Fastlane on Mac VM)

Replaces Codemagic with a self-hosted GitHub Actions runner on the
existing macOS-in-Proxmox VM. Both iOS (incl. Watch) and Android (incl.
Wear OS) builds run on the same Mac runner, triggered automatically on
every push to `main`.

## Architecture

```
git push origin main
   └─ GitHub webhook
        └─ Workflow: .github/workflows/release.yml
             ├─ Job: build-ios   (runs-on: self-hosted Mac)
             │    └─ fastlane ios release  → TestFlight
             └─ Job: build-android (runs-on: self-hosted Mac)
                  └─ fastlane android release → Play Console internal track
```

Single Mac runner handles both jobs sequentially. Android builds on Mac
work fine for Flutter projects; the slight build-speed disadvantage vs.
a Linux runner is negligible for our codebase.

## One-time setup

### 0. Register the Watch bundle ID in the Apple Developer Portal

One-time, ~30 seconds. fastlane's `produce` action can't auto-register
identifiers via API key auth, so we do this by hand once:

1. https://developer.apple.com/account/resources/identifiers/list
2. **"+"** → **App IDs** → Continue
3. **App** → Continue
4. Description: `Wegwiesel Watch Companion`
5. Bundle ID: **Explicit** → `com.thomaspeterson.bikerouter.WegwieselWatch`
6. Capabilities: leave defaults
7. Continue → **Register**

The Phone bundle ID (`com.thomaspeterson.bikerouter`) already exists
from earlier Codemagic builds, no action needed.

### 1. App Store Connect API Key

1. Apple Developer Portal → **Users and Access** → **Integrations** →
   **App Store Connect API**.
2. Click **"+" → Generate API Key**.
   - Name: `Wegwiesel CI`
   - Access: **App Manager**.
3. Download the resulting `AuthKey_XXXX.p8` file. **You can only download
   it once** — store it safely.
4. Note down:
   - **Issuer ID** (top of the page, looks like `…-d3fe-…`).
   - **Key ID** (the `XXXX` part of the filename).

### 2. Android keystore + Play Console service account

Keystore: should already be on your dev machine (or grab from your
old Codemagic build settings). Convention: `keystore.jks` somewhere
safe + the password.

Service account JSON for Play uploads:
1. **Google Play Console** → **Setup** → **API access** → **Create new
   service account** (opens Google Cloud Console).
2. Role: **Service Account User** + grant access on the Play Console
   side after creation.
3. Download the JSON key.
4. In Play Console → Users & permissions → invite the service account
   email with **"Release manager"** role.

### 3. GitHub Actions secrets

Repo → **Settings** → **Secrets and variables** → **Actions** → **New
repository secret** for each:

| Name | Value |
|---|---|
| `APP_STORE_CONNECT_KEY_ID` | the `Key ID` from step 1 |
| `APP_STORE_CONNECT_ISSUER_ID` | the `Issuer ID` from step 1 |
| `APP_STORE_CONNECT_KEY_CONTENT` | **base64-encoded** `.p8` file. Generate with `base64 -i AuthKey_XXXX.p8` (macOS) — paste the single-line output. We use base64 because GitHub Actions secrets occasionally mangle multi-line PEM content during paste, leading to opaque "Authentication credentials missing" errors at `sigh` time. |
| `ANDROID_KEYSTORE_BASE64` | `base64 -i keystore.jks` output (single line) |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | key alias inside the keystore |
| `ANDROID_KEY_PASSWORD` | key password |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | full content of the Play service-account JSON |

### 4. macOS runner setup

Inside the macOS VM, install the GitHub-provided self-hosted runner:

1. Repo → Settings → **Actions** → **Runners** → **New self-hosted
   runner** → choose **macOS** + your architecture (M-series = ARM,
   Intel = x64).
2. Follow GitHub's three-line install script. Drop the runner into
   `/Users/thomas/actions-runner/` (or wherever; the script asks).
3. When prompted for labels: keep the defaults (`self-hosted`,
   `macOS`) and additionally add `m1` or `intel` so we can target this
   machine in workflows.
4. Install as a service so the runner auto-starts after VM reboot:
   ```bash
   cd ~/actions-runner
   ./svc.sh install
   ./svc.sh start
   ```

### 5. Mac VM prerequisites

Inside the VM, install once:

```bash
# Homebrew (if not already)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Flutter SDK
brew install --cask flutter

# CocoaPods via Homebrew-Ruby
brew install ruby
echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.zshrc
exec zsh
gem install cocoapods

# Fastlane
gem install fastlane

# Verify
flutter doctor
fastlane --version
```

Xcode is already installed by you, presumably with iOS simulators +
the Apple Developer team selected in Xcode → Settings → Accounts.

### 6. (Optional) Wake-on-LAN

If you don't keep the Mac VM running 24/7:

- Proxmox: enable WoL on the VM's virtual NIC.
- A separate small Linux VM (or your homeserver) can receive the GitHub
  webhook via a tiny relay and wake the Mac before re-forwarding the
  webhook. Out of scope for this README — add later if needed.

## Triggering a release

Just push to `main`. Both workflows run automatically.

Manually re-trigger via GitHub UI: Repo → Actions → **Release** → "Run
workflow".

## Build-number policy

`pubspec.yaml` is the source of truth. Bump the `+N` part manually
before pushing the release commit. Fastlane reads the value from
`pubspec.yaml` and applies it to both iOS + Android builds.

If you'd rather have Fastlane auto-bump from "latest TestFlight build
number + 1": uncomment the `increment_build_number` line in
`app/ios/fastlane/Fastfile` lane `:release`.

## Migrating off Codemagic

After three or four successful self-hosted releases:

1. Codemagic → App → Settings → **Pause builds** (or **Disconnect
   repository**) — stops auto-triggering and bills.
2. Delete the `codemagic.yaml` from the repo (or keep as
   documented backup).
3. Cancel the Codemagic subscription if you have a paid plan.
