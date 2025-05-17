# Discord InfoStealer Script

## Overview

This script collects comprehensive information about the system, hardware, network settings, Wi-Fi profiles with passwords, installed applications, user accounts, and active connections on Windows machines. The collected data is then sent to a Discord webhook in a neatly formatted report.

## Usage

Run the script via the Ducky payload or directly in PowerShell. The report will automatically truncate to avoid Discord message length limits.

## Configuration

Replace the `WEBHOOK_URL` variable in the script with your own Discord webhook URL before running the script.

## Notes

- Requires internet access to fetch public IP addresses.
- Sensitive data (Wi-Fi passwords, user info) is sent to the webhook.
- Use responsibly and only on authorized systems.
