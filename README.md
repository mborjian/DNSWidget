# DNS Widget

A small macOS app that lives in your menu bar and lets you switch DNS servers with one click. It comes with a desktop widget that shows which DNS you're using right now.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift 6](https://img.shields.io/badge/Swift-6-orange) ![SwiftUI](https://img.shields.io/badge/SwiftUI-Purple)

## What it does

- **Switch DNS instantly** — click any server in the menu bar and it's applied. One more click resets back to automatic.
- **8 built-in servers** — Google, Cloudflare, Quad9, OpenDNS, AdGuard, NextDNS, Comodo, and Level3. You can also add your own with a name, a color, and IP addresses.
- **Pinned servers** — pin the servers you use most (pin icon) and they stay at the top of the list. The active server is always shown as the first item. Lists show four rows at a time and scroll if you add more.
- **Manual order** — drag any server to rearrange the list; dragging across the pinned section pins or unpins it. Your order is saved.
- **Latency testing** — hit the Ping button to measure every server's response time, color-coded from green (fast) to red (slow).
- **Wi-Fi auto-switch** — set a rule per network: join your home Wi-Fi and the right DNS is applied automatically.
- **Launch at login** — optional, toggled from the settings panel.
- **Desktop widget** — a WidgetKit widget (small, medium, and large) showing your active DNS, refreshed every few minutes.

## Building with Xcode

You'll need **Xcode 16 or newer** (free from the Mac App Store) and [XcodeGen](https://github.com/yonaskolb/XcodeGen) — a small tool that turns `project.yml` into an Xcode project. The `.xcodeproj` is generated on purpose and not stored in the repo, so this is a one-time step.

1. **Generate the project once** — run `xcodegen generate` in the project folder. You only need to run it again if `project.yml` changes.
2. **Open the project** — double-click `DNSWidget.xcodeproj`, or open it via File → Open in Xcode.
3. **Pick the scheme** — choose **DNSWidget** from the scheme menu at the top of the window.
4. **Run** — press **⌘R** (Product → Run).

The app builds two targets:

- **DNSWidget** — the menu bar app
- **DNSWidgetExtension** — the widget for Notification Center and the desktop

After it launches you'll see a network icon in your menu bar. For a release build you can use Product → Archive, or just keep running it from Xcode while you develop.

> The first time you change DNS, macOS asks for permission to modify network settings — that's normal and only happens once.

## Project layout

```
DNSWidget/
├── project.yml                          # XcodeGen spec — source of the Xcode project
├── Sources/
│   ├── App/                             # App entry point, Info.plist, icon assets
│   ├── Models/                          # DNS server model + the 8 built-in servers
│   ├── Design/                          # Colors, fonts, spacing, reusable components
│   ├── Views/                           # Menu bar popover, add/edit form, Wi-Fi rules
│   ├── Services/                        # Network, storage, latency, Wi-Fi monitoring
│   └── Widget/                          # The WidgetKit extension
```

## How DNS switching works

The app applies DNS through macOS's own network configuration system (SystemConfiguration), the same way the system applies it for DHCP — so **no admin password is ever asked**. Your choice is remembered: if you restart your Mac or switch networks, the app silently puts your DNS back without prompting. Only if that mechanism is unavailable does it fall back to `networksetup`, which may ask for permission once.

Latency is measured with `ping`, and when you join a Wi-Fi network the app detects the change and applies your rule for that network automatically.

## Releases

Push a tag like `v1.0.0` (or run the workflow manually from the Actions tab) and GitHub Actions builds a release `.zip` and attaches it to a GitHub Release. The version number is taken from the tag itself, so `v2.3.4` ships as version 2.3.4. Every push and pull request is also built by a separate CI check so problems surface before you tag.

- **Without an Apple Developer account** — the build is ad-hoc signed, so macOS may ask you to right-click the app and choose Open the first time.
- **With an Apple Developer account** — add the secrets below and releases are signed with your Developer ID certificate and notarized by Apple, so there's no warning at all:

| Secret | Value |
| --- | --- |
| `DEVELOPER_ID_CERT_P12_BASE64` | Base64 of your exported **Developer ID Application** `.p12` certificate |
| `DEVELOPER_ID_CERT_PASSWORD` | Password of that `.p12` |
| `APPLE_API_KEY_ID` | App Store Connect API key ID (role: App Manager) |
| `APPLE_API_KEY_ISSUER_ID` | App Store Connect API key issuer ID |
| `APPLE_API_KEY_P8_BASE64` | Base64 of the API key `.p8` file |

## Permissions

- **DNS changes** — macOS may prompt for network configuration permission the first time.
- **Wi-Fi SSID** — reading the current network name uses the private `airport` tool.
- **WidgetKit** — the widget reads shared data via App Groups.

