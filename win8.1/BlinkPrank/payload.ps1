Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Prank Screen"
$form.StartPosition = "Manual"
$form.FormBorderStyle = "None"
$form.WindowState = "Maximized"
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::Black
$form.KeyPreview = $true

$form.Add_KeyDown({
    param($sender, $e)
    $e.Handled = $true
})

$screens = [System.Windows.Forms.Screen]::AllScreens
foreach ($screen in $screens) {
    $form.StartPosition = "Manual"
    $form.Location = $screen.Bounds.Location
    $form.Size = $screen.Bounds.Size
    $form.Show()
}

$label = New-Object System.Windows.Forms.Label
$label.Text = $text
$label.AutoSize = $false
$label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$label.Dock = [System.Windows.Forms.DockStyle]::Fill
$label.Font = New-Object System.Drawing.Font("Arial", 48, [System.Drawing.FontStyle]::Bold)
$label.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($label)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 100
$timer.Add_Tick({
    if ($form.BackColor -eq [System.Drawing.Color]::Black) {
        $form.BackColor = [System.Drawing.Color]::White
        $label.ForeColor = [System.Drawing.Color]::Black
    } else {
        $form.BackColor = [System.Drawing.Color]::Black
        $label.ForeColor = [System.Drawing.Color]::White
    }
})

$timer.Start()

$form.Add_FormClosing({
    param($sender, $e)
    $e.Cancel = $true
})

try {
    $signature = @'
[DllImport("user32.dll")]
public static extern bool BlockInput(bool block);
'@

    $blockInput = Add-Type -MemberDefinition $signature -Name Win32BlockInput -Namespace Win32Functions -PassThru
    $blockInput::BlockInput($true)
} catch {
    Write-Warning "Nije moguce blokirati ulazne uređaje: $_"
}

$form.Add_Click({})

Write-Host "Pokrećem prank skriptu. Pritisnite Ctrl+C u PowerShell prozoru da biste je zaustavili."
[System.Windows.Forms.Application]::Run($form)

$blockInput::BlockInput($false)
