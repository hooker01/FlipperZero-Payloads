# USB Auto Backup to Discord

## Overview  
This Flipper Zero payload runs a PowerShell script that monitors for USB device insertions. When a USB is plugged in, it copies all files (excluding videos), compresses them into 10MB zip chunks, and uploads them to a specified Discord webhook.

## Usage  
- Replace `WEBHOOK_LINK` in the `.txt` script with your actual Discord webhook URL.  
- Run the payload on a **WINDOWS 8.1** system.  
- On USB insertion, files are silently copied, compressed, and uploaded.  

## Features  
- Ignores video formats to save bandwidth.  
- Automatically skips already processed USB devices.  
- Temporary data is deleted after upload.  
- Runs indefinitely in the background.

## Target  
Windows **WINDOWS 8.1**

## Notes  
- Internet access is required for uploading to Discord.  
- Archives are limited to 10MB to ensure webhook compatibility.  
- Does not modify the USB drive contents.

## Disclaimer  
Use responsibly and only on authorized systems. 

---

**Author:** hooker01  
**GitHub:** [github.com/hooker01](https://github.com/hooker01)
