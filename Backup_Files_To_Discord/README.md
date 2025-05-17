# Discord File Backup

## Overview  
This payload runs a PowerShell script on a Windows machine that recursively finds common document files (.doc, .pdf, .xls, .txt, etc.), compresses them into zip archives capped at 10MB each, and uploads the archives to a Discord webhook.

## Usage  
- Replace `DISCORD_WEBHOOK_HERE` in the DuckyScript `.txt` payload with your actual Discord webhook URL.  
- Run the payload on the target Windows 10 or 11 machine.  
- The script silently compresses files and uploads them to the webhook.

## Target  
Windows 10 and Windows 11.

## Notes  
- Skips system folders like Windows and Program Files to avoid large unnecessary files.  
- Uploads archives in chunks not exceeding 10MB.  
- Requires internet access.  
- Intended for educational and prank purposes only.

## Disclaimer  
Use responsibly and with permission. Unauthorized use may violate laws.

---

**Author:** hooker01  
**GitHub:** [github.com/hooker01](https://github.com/hooker01)
