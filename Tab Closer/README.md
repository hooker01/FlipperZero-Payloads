### Tab Closer

Simulates `Ctrl+W` every 10 seconds using PowerShell, effectively closing tabs, apps, or documents repeatedly—commonly used in browsers or text editors.

#### Overview

This script launches a hidden PowerShell process that:
- Loads `System.Windows.Forms` for input simulation
- Sends the `Ctrl+W` keystroke in a loop
- Runs silently in the background

#### Usage

1. Deploy via HID device (e.g. Rubber Ducky, Digispark)
2. Script executes in the background with no visible window
3. Affected applications will start closing tabs or windows periodically

#### Customization

To adjust the interval between each close action, change:

```powershell
Start-Sleep -Seconds 10
```


## TARGET

Windows 10 and Windows 11.

---

*Author: hooker01*  
*GitHub: [github.com/hooker01](https://github.com/hooker01)*
