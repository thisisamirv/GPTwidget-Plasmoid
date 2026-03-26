# GPTwidget

**GPTwidget** is a premium, lightweight ChatGPT Plasmoid for KDE Plasma. It provides a dedicated, privacy-hardened window for your daily AI interactions, perfectly integrated into your desktop.

![GPTwidget](/package/icon.svg)

## Features

- **Dedicated Experience**: Hardcoded for ChatGPT to ensure maximum stability and a focused UI.
- **Advanced Stability Layer**:
  - **Crash Recovery**: Auto-restarts the browser engine if it terminates unexpectedly.
  - **Load Watchdog**: Automatically recovers from "hung" or "stale" page loads.
  - **Memory Optimized**: Pauses background execution when the widget is hidden.
- **Privacy First**: Permanently disabled webcam, screensharing, and notification permissions.
- **Breeze Integration**: Automatically syncs with your Plasma Dark/Light theme to prevent "white flashes" on load.
- **Productivity Boosts**:
  - `Ctrl + F` for in-page search.
  - Automatic focus on the chat input area.
  - External links automatically open in your system's default browser.
  - Integrated Download Manager with path persistence.

## Installation

### Quick Install (Recommended)

Clone the repository and run the install script:

```bash
git clone https://github.com/thisisamirv/GPTwidget-Plasmoid.git
cd GPTwidget-Plasmoid
./dev/install.sh
```

### Manual Installation

You can also install the `package/` directory manually using `kpackagetool6`:

```bash
kpackagetool6 -t Plasma/Applet --install package/
```

## Developer Tools

The `dev/` directory contains several hardened scripts to assist with development:

- `./dev/test.sh`: Launch the widget in `plasmoidviewer` for isolated testing.
- `./dev/lint.sh`: Perform static analysis on QML and XML configuration schema.
- `./dev/install.sh`: Deploy the widget and system icons to your local machine.
- `./dev/uninstall.sh`: Cleanly remove the widget and its associated assets.

## Acknowledgements

GPTwidget was inspired by and initially derived from [ChatAI-Plasmoid](https://github.com/DenysMb/ChatAI-Plasmoid) by **Denys Madureira** and **Bruno Gonçalves**, and `config.qml` traces back to work by **Sora Steenvoort**. All three are credited in the relevant source files per the BSD 3-Clause License terms.

## License

GPTwidget is licensed under the **GPL-3.0-or-later**. See [LICENSE](LICENSE) for details.

Portions of this project are derived from [ChatAI-Plasmoid](https://github.com/DenysMb/ChatAI-Plasmoid), copyright © 2020 Sora Steenvoort, © 2024 Denys Madureira, © 2025 Bruno Gonçalves, used under the BSD 3-Clause License.

---
Created and maintained by **Amir Valizadeh**.
