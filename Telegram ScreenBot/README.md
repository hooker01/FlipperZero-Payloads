# TELEGRAM Screenshot Tool



## Overview

This payload deploys a PowerShell-based Telegram Remote Screenshot connected Bot. It captures screenshots and can terminate itself when commanded.



## Usage

- Replace `YOUR\_BOT\_TOKEN\_HERE` with your actual Telegram bot token.

- Replace `$PU ` with valid user IDs who are allowed to control the Bot.

- Copy the edited Ducky payload to a Flipper Zero.

- Execute the payload on a target Windows 10/11 machine.

- Send `/screenshot` to capture and send a screenshot via Telegram.

- Send `/terminate` to delete the script and exit.



## Features

- Takes full desktop screenshots and sends them via Telegram.

- Supports user permission control for command access.

- Automatically cleans up traces after termination.

- Runs in hidden mode (window hidden).

- May not work on systems with strict AV/GPO policies.

- Requires no admin privileges to execute.

- `/terminate` also clears:

&nbsp; - Run box history

&nbsp; - PowerShell command history

&nbsp; - Recycle Bin contents



## Target

Windows 10 and Windows 11



## Disclaimer

Use responsibly and only with permission.



---

**Author:** hooker01  
**GitHub:** [github.com/hooker01](https://github.com/hooker01)




