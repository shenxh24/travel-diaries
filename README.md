# 驻迹

驻迹 is a private, local-first iPhone travel diary for saving visited places, photos, notes, weather, timelines, calendars, slideshows, and travel statistics on an interactive Apple map.

## Installation

Requirements: macOS, Xcode 16.4 or newer, and iOS 17 or newer.

1. Open `ZhuJi.xcodeproj` in Xcode.
2. Select the **ZhuJi** target and open **Signing & Capabilities**.
3. Enable **Automatically manage signing** and select your Apple ID team.
4. Choose an iPhone Simulator and press `⌘R`.

To install on an iPhone:

1. Connect the iPhone to the Mac and trust the computer.
2. Enable **Settings → Privacy & Security → Developer Mode** on the iPhone.
3. Select the iPhone as the Xcode run destination and press `⌘R`.

No map API key is required. Existing data is preserved when updating with the same bundle ID: `com.xhshen.traveldiary`.
