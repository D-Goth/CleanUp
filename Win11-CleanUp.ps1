<#
    .SYNOPSIS
    Black-Lab Windows CleanUp - Outil de desinfection de Windows 11/10
    .DESCRIPTION
    Script complet pour desactiver Xbox, Game Bar, telemetrie, bloatware et autres
    composants indesirables de Windows.
    .AUTHOR
    D-Goth - Black-Lab.fr
    .VERSION
    2.0
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Verification des droits admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    [System.Windows.Forms.MessageBox]::Show("Ce programme doit etre execute en tant qu'Administrateur !`n`nFais un clic droit sur le fichier > Executer avec PowerShell", "Black-Lab Debloater - Erreur", "OK", "Error")
    exit
}

# ---------------------------------------------
# FENETRE PRINCIPALE
# ---------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Black-Lab Windows CleanUp v2.0"
$form.Size = New-Object System.Drawing.Size(720, 680)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(34, 34, 34)

$header = New-Object System.Windows.Forms.Label
$header.Text = "BLACK-LAB WINDOWS CLEANUP"
$header.Font = New-Object System.Drawing.Font("Consolas", 18, [System.Drawing.FontStyle]::Bold)
$header.ForeColor = [System.Drawing.Color]::FromArgb(255, 22, 84)
$header.Size = New-Object System.Drawing.Size(670, 40)
$header.Location = New-Object System.Drawing.Point(25, 20)
$header.TextAlign = "MiddleCenter"
$form.Controls.Add($header)

$subHeader = New-Object System.Windows.Forms.Label
$subHeader.Text = "Black-Lab | Windows CleanUp | Desinfecte ton Windows en un clic"
$subHeader.Font = New-Object System.Drawing.Font("Consolas", 9)
$subHeader.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 180)
$subHeader.Size = New-Object System.Drawing.Size(670, 25)
$subHeader.Location = New-Object System.Drawing.Point(25, 60)
$subHeader.TextAlign = "MiddleCenter"
$form.Controls.Add($subHeader)

$separator = New-Object System.Windows.Forms.Label
$separator.Text = "--------------------------------------------------------------------------------"
$separator.Font = New-Object System.Drawing.Font("Consolas", 8)
$separator.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 100)
$separator.Size = New-Object System.Drawing.Size(670, 20)
$separator.Location = New-Object System.Drawing.Point(25, 85)
$form.Controls.Add($separator)

# Barre de progression
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(25, 275)
$progressBar.Size = New-Object System.Drawing.Size(665, 16)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$progressBar.Style = "Continuous"
$form.Controls.Add($progressBar)

# Zone de logs
$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Location = New-Object System.Drawing.Point(25, 295)
$logBox.Size = New-Object System.Drawing.Size(665, 270)
$logBox.BackColor = [System.Drawing.Color]::FromArgb(59, 59, 59)
$logBox.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 220)
$logBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$logBox.ReadOnly = $true
$logBox.BorderStyle = "FixedSingle"
$form.Controls.Add($logBox)

# ---------------------------------------------
# FONCTIONS UTILITAIRES
# ---------------------------------------------
function Write-Log {
    param([string]$message, [string]$color = "white")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logBox.SelectionColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
    $logBox.AppendText("[$timestamp] ")
    switch ($color) {
        "green"  { $logBox.SelectionColor = [System.Drawing.Color]::FromArgb(0, 255, 100) }
        "red"    { $logBox.SelectionColor = [System.Drawing.Color]::FromArgb(255, 80, 80) }
        "yellow" { $logBox.SelectionColor = [System.Drawing.Color]::FromArgb(255, 200, 80) }
        "cyan"   { $logBox.SelectionColor = [System.Drawing.Color]::FromArgb(80, 200, 255) }
        default  { $logBox.SelectionColor = [System.Drawing.Color]::White }
    }
    $logBox.AppendText("$message`n")
    $logBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Set-Progress {
    param([int]$value)
    $progressBar.Value = [Math]::Min($value, 100)
    [System.Windows.Forms.Application]::DoEvents()
}

function Set-RegistryValue {
    param([string]$Path, [string]$Name, $Value, [string]$Type = "DWord")
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
        return $true
    } catch {
        Write-Log "  [ERR] Registre [$Name] : $($_.Exception.Message)" "red"
        return $false
    }
}

function Remove-AppxFull {
    param([string]$name)
    try {
        Get-AppxPackage -AllUsers $name -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object DisplayName -like "*$name*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        Write-Log "  [OK] $name supprime" "green"
    } catch {
        Write-Log "  [--] $name : deja absent ou non supprimable" "yellow"
    }
}

# ---------------------------------------------
# FONCTIONS DE NETTOYAGE
# ---------------------------------------------

function New-RestorePoint {
    Write-Log "=== Creation d'un point de restauration ===" "cyan"
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Avant Black-Lab Windows CleanUp v2.0" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Log "  [OK] Point de restauration cree" "green"
    } catch {
        Write-Log "  [!!] Impossible de creer le point : $($_.Exception.Message)" "yellow"
        Write-Log "       (Windows limite a 1 point toutes les 24h)" "yellow"
    }
}

function Remove-XboxComponents {
    Write-Log "=== Desactivation Xbox et Game Bar ===" "cyan"

    Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0
    Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "HistoricalCaptureEnabled" 0
    Write-Log "  [OK] GameDVR desactive" "green"

    Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameBar" "ShowStartupPanel" 0
    Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameBar" "AllowAutoGameMode" 0
    Write-Log "  [OK] Game Bar desactivee" "green"

    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0
    Write-Log "  [OK] GameDVR bloque via GPO" "green"

    $packages = @(
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxGameOverlay",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.GamingApp"
    )
    foreach ($pkg in $packages) { Remove-AppxFull $pkg }

    $services = @("XboxGipSvc", "XboxNetApiSvc", "XblAuthManager", "XblGameSave")
    foreach ($svc in $services) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Log "  [OK] Service $svc desactive" "green"
    }

    Write-Log "=== Xbox desactive ===" "cyan"
}

function Remove-Bloatware {
    Write-Log "=== Suppression des applications inutiles ===" "cyan"

    $bloatware = @(
        "Clipchamp.Clipchamp",
        "Microsoft.549981C3F5F10",
        "Microsoft.BingNews",
        "Microsoft.BingWeather",
        "Microsoft.GetHelp",
        "Microsoft.Getstarted",
        "Microsoft.Messaging",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MixedReality.Portal",
        "Microsoft.Office.OneNote",
        "Microsoft.OutlookForWindows",
        "Microsoft.People",
        "Microsoft.PowerAutomateDesktop",
        "Microsoft.Todos",
        "Microsoft.Windows.DevHome",
        "Microsoft.WindowsAlarms",
        "Microsoft.WindowsCamera",
        "Microsoft.WindowsCommunicationsApps",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsMaps",
        "Microsoft.WindowsSoundRecorder",
        "Microsoft.YourPhone",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo",
        "MicrosoftTeams",
        "MSTeams",
        "Microsoft.Copilot",
        "Microsoft.Windows.Ai.Copilot.Provider"
    )

    foreach ($app in $bloatware) { Remove-AppxFull $app }

    Write-Log "=== Applications inutiles supprimees ===" "cyan"
}

function Remove-Telemetry {
    Write-Log "=== Desactivation de la telemetrie ===" "cyan"

    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
    Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "LimitDiagnosticLogCollection" 1
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "DisableOneSettingsDownloads" 1
    Write-Log "  [OK] Telemetrie desactivee via registre" "green"

    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" "Disabled" 1
    Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" "Disabled" 1
    Write-Log "  [OK] Rapport d'erreurs desactive" "green"

    $services = @("DiagTrack", "WAPushService", "dmwappushservice", "diagnosticshub.standardcollector.service")
    foreach ($svc in $services) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Log "  [OK] Service $svc desactive" "green"
    }

    $diagPath = "$env:ProgramData\Microsoft\Diagnosis\ETLLogs\AutoLogger"
    if (Test-Path $diagPath) {
        Remove-Item "$diagPath\*" -Force -ErrorAction SilentlyContinue
        Write-Log "  [OK] Logs de telemetrie vides" "green"
    }

    Write-Log "=== Telemetrie desactivee ===" "cyan"
}

function Remove-OneDrive {
    Write-Log "=== Desinstallation de OneDrive ===" "cyan"

    Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800

    $paths = @(
        "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe",
        "$env:SYSTEMROOT\System32\OneDriveSetup.exe",
        "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDriveSetup.exe",
        "$env:LOCALAPPDATA\Microsoft\OneDrive\Update\OneDriveSetup.exe"
    )
    $found = $false
    foreach ($p in $paths) {
        if (Test-Path $p) {
            Start-Process -FilePath $p -ArgumentList "/uninstall" -Wait -NoNewWindow
            Write-Log "  [OK] OneDrive desinstalle via $p" "green"
            $found = $true
            break
        }
    }
    if (-not $found) {
        Write-Log "  [--] OneDrive Setup introuvable (peut-etre deja absent)" "yellow"
    }

    $leftovers = @(
        "$env:USERPROFILE\OneDrive",
        "$env:LOCALAPPDATA\Microsoft\OneDrive",
        "$env:PROGRAMDATA\Microsoft OneDrive",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"
    )
    foreach ($path in $leftovers) {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Log "  [OK] Restes OneDrive supprimes" "green"

    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue
    Write-Log "  [OK] Demarrage automatique OneDrive supprime" "green"

    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" 1
    Write-Log "  [OK] Reinstallation OneDrive bloquee" "green"

    Write-Log "=== OneDrive supprime ===" "cyan"
}

function Disable-Widgets {
    Write-Log "=== Desactivation des Widgets ===" "cyan"

    Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" 0
    Write-Log "  [OK] Bouton Widgets masque" "green"

    Remove-AppxFull "MicrosoftWindows.Client.WebExperience"

    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0
    Write-Log "  [OK] Widgets desactives via GPO" "green"

    Write-Log "=== Widgets desactives ===" "cyan"
}

function Disable-WebSearch {
    Write-Log "=== Desactivation de la recherche web ===" "cyan"

    Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
    Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" 0
    Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "AllowSearchToUseLocation" 0
    Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 1
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" 1
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "ConnectedSearchUseWeb" 0
    Write-Log "  [OK] Recherche web desactivee" "green"

    Write-Log "=== Recherche web desactivee ===" "cyan"
}

function Disable-Ads {
    Write-Log "=== Desactivation des publicites et suggestions ===" "cyan"

    $cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-RegistryValue $cdmPath "ContentDeliveryAllowed" 0
    Set-RegistryValue $cdmPath "OemPreInstalledAppsEnabled" 0
    Set-RegistryValue $cdmPath "PreInstalledAppsEnabled" 0
    Set-RegistryValue $cdmPath "PreInstalledAppsEverEnabled" 0
    Set-RegistryValue $cdmPath "SilentInstalledAppsEnabled" 0
    Set-RegistryValue $cdmPath "SubscribedContent-310093Enabled" 0
    Set-RegistryValue $cdmPath "SubscribedContent-314559Enabled" 0
    Set-RegistryValue $cdmPath "SubscribedContent-338387Enabled" 0
    Set-RegistryValue $cdmPath "SubscribedContent-338388Enabled" 0
    Set-RegistryValue $cdmPath "SubscribedContent-338389Enabled" 0
    Set-RegistryValue $cdmPath "SubscribedContent-338393Enabled" 0
    Set-RegistryValue $cdmPath "SubscribedContent-353694Enabled" 0
    Set-RegistryValue $cdmPath "SubscribedContent-353696Enabled" 0
    Set-RegistryValue $cdmPath "SubscribedContent-353698Enabled" 0
    Set-RegistryValue $cdmPath "ShowSyncProviderNotifications" 0
    Set-RegistryValue $cdmPath "SystemPaneSuggestionsEnabled" 0
    Write-Log "  [OK] Suggestions et pubs menu Demarrer desactivees" "green"

    Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
    Write-Log "  [OK] ID publicitaire desactive" "green"

    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" "NoLockScreenCamera" 1
    Write-Log "  [OK] Pub ecran de verrouillage desactivee" "green"

    Write-Log "=== Publicites desactivees ===" "cyan"
}

function Disable-Copilot {
    Write-Log "=== Desactivation de Copilot ===" "cyan"

    Set-RegistryValue "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
    Write-Log "  [OK] Copilot desactive via GPO" "green"

    Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCopilotButton" 0
    Write-Log "  [OK] Bouton Copilot masque" "green"

    Remove-AppxFull "Microsoft.Windows.Ai.Copilot.Provider"
    Remove-AppxFull "Microsoft.Copilot"
    Remove-AppxFull "MicrosoftWindows.Client.Copilot"

    Write-Log "=== Copilot desactive ===" "cyan"
}

function Disable-Recall {
    Write-Log "=== Desactivation de Recall (Win11 24H2+) ===" "cyan"
    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName "Recall" -ErrorAction SilentlyContinue
        if ($feature -and $feature.State -eq "Enabled") {
            Disable-WindowsOptionalFeature -Online -FeatureName "Recall" -NoRestart -ErrorAction Stop | Out-Null
            Write-Log "  [OK] Recall desactive" "green"
        } else {
            Write-Log "  [--] Recall absent ou deja desactive" "yellow"
        }
    } catch {
        Write-Log "  [--] Recall : $($_.Exception.Message)" "yellow"
    }

    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
    Write-Log "  [OK] Recall bloque via registre" "green"

    Write-Log "=== Recall desactive ===" "cyan"
}

function Clear-TempFiles {
    Write-Log "=== Nettoyage des fichiers temporaires ===" "cyan"

    $tempPaths = @(
        $env:TEMP,
        "$env:SYSTEMROOT\Temp",
        "$env:SYSTEMROOT\Prefetch",
        "$env:LOCALAPPDATA\Temp"
    )

    $totalFreed = 0
    foreach ($path in $tempPaths) {
        if (Test-Path $path) {
            $before = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
            Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
            $after = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
            $freed = [Math]::Max(0, $before - $after)
            $totalFreed += $freed
            Write-Log "  [OK] $path nettoye" "green"
        }
    }

    $freedMB = [Math]::Round($totalFreed / 1MB, 1)
    Write-Log "  >> Espace libere : ~$freedMB MB" "yellow"

    Write-Log "=== Fichiers temporaires nettoyes ===" "cyan"
}

# ---------------------------------------------
# NETTOYAGE COMPLET
# ---------------------------------------------
function FullClean {
    $steps = @(
        @{ Name="Point de restauration";  Fn={ New-RestorePoint } },
        @{ Name="Xbox et Game Bar";       Fn={ Remove-XboxComponents } },
        @{ Name="Bloatware";              Fn={ Remove-Bloatware } },
        @{ Name="Telemetrie";             Fn={ Remove-Telemetry } },
        @{ Name="OneDrive";               Fn={ Remove-OneDrive } },
        @{ Name="Widgets";                Fn={ Disable-Widgets } },
        @{ Name="Recherche Web";          Fn={ Disable-WebSearch } },
        @{ Name="Publicites";             Fn={ Disable-Ads } },
        @{ Name="Copilot";                Fn={ Disable-Copilot } },
        @{ Name="Recall";                 Fn={ Disable-Recall } },
        @{ Name="Fichiers temporaires";   Fn={ Clear-TempFiles } }
    )

    Write-Log "========== DEMARRAGE DU NETTOYAGE COMPLET ==========" "cyan"
    Set-Progress 0

    for ($i = 0; $i -lt $steps.Count; $i++) {
        Write-Log "--- Etape $($i+1)/$($steps.Count) : $($steps[$i].Name) ---" "yellow"
        & $steps[$i].Fn
        Set-Progress ([int](($i + 1) / $steps.Count * 100))
    }

    Write-Log "========== NETTOYAGE COMPLET TERMINE ==========" "cyan"
    Write-Log "Un redemarrage est recommande pour appliquer tous les changements." "yellow"

    [System.Windows.Forms.MessageBox]::Show(
        "Nettoyage termine avec succes !`n`nUn redemarrage est recommande.",
        "Black-Lab Debloater v2.0",
        "OK",
        "Information"
    ) | Out-Null
}

# ---------------------------------------------
# HELPER CREATION BOUTONS
# ---------------------------------------------

# Un Panel peint manuellement = pas de fond rectangulaire force par WinForms
function New-StyledButton {
    param([string]$text, [int]$x, [int]$y, [int]$w, [int]$h, [scriptblock]$onClick, [System.Drawing.Color]$bg)

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Size      = New-Object System.Drawing.Size($w, $h)
    $panel.Location  = New-Object System.Drawing.Point($x, $y)
    $panel.BackColor = [System.Drawing.Color]::Transparent
    $panel.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $panel.Tag       = [PSCustomObject]@{ Label = $text; Bg = $bg; Hover = $false; Action = $onClick }

    $panel.Add_Paint({
        param($s, $e)
        $g = $e.Graphics
        $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

        $pw = $s.Width; $ph = $s.Height; $r = 10; $d = $r * 2
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddArc(0,        0,        $d, $d, 180, 90)
        $path.AddArc($pw - $d, 0,        $d, $d, 270, 90)
        $path.AddArc($pw - $d, $ph - $d, $d, $d,   0, 90)
        $path.AddArc(0,        $ph - $d, $d, $d,  90, 90)
        $path.CloseFigure()

        # Fond de base
        $fillColor = $s.Tag.Bg
        if ($s.Tag.Hover) {
            # Eclaircit un peu au survol
            $fc = $fillColor
            $fillColor = [System.Drawing.Color]::FromArgb(
                [Math]::Min(255, $fc.R + 30),
                [Math]::Min(255, $fc.G + 30),
                [Math]::Min(255, $fc.B + 30)
            )
        }
        $brush = New-Object System.Drawing.SolidBrush($fillColor)
        $g.FillPath($brush, $path)
        $brush.Dispose()
        $path.Dispose()

        # Texte centre
        $sf = New-Object System.Drawing.StringFormat
        $sf.Alignment     = [System.Drawing.StringAlignment]::Center
        $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
        $rect  = New-Object System.Drawing.RectangleF(0, 0, $pw, $ph)
        $font  = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $tBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString($s.Tag.Label, $font, $tBrush, $rect, $sf)
        $tBrush.Dispose(); $font.Dispose(); $sf.Dispose()
    })

    $panel.Add_MouseEnter({ $this.Tag.Hover = $true;  $this.Invalidate() })
    $panel.Add_MouseLeave({ $this.Tag.Hover = $false; $this.Invalidate() })
    $panel.Add_MouseClick({ param($s,$e) if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) { & $s.Tag.Action } })

    return $panel
}

$defaultBg = [System.Drawing.Color]::FromArgb(55, 55, 65)
$dangerBg  = [System.Drawing.Color]::FromArgb(180, 0, 0)
$successBg = [System.Drawing.Color]::FromArgb(0, 170, 0)
$rebootBg  = [System.Drawing.Color]::FromArgb(255, 22, 84)

$btnW = 210
$col1 = 25; $col2 = 250; $col3 = 475

$form.Controls.Add((New-StyledButton "[ Xbox / Game Bar ]"    $col1 105 $btnW 45 { Remove-XboxComponents } $defaultBg))
$form.Controls.Add((New-StyledButton "[ Bloatware ]"          $col2 105 $btnW 45 { Remove-Bloatware }      $defaultBg))
$form.Controls.Add((New-StyledButton "[ Telemetrie ]"         $col3 105 $btnW 45 { Remove-Telemetry }      $defaultBg))
$form.Controls.Add((New-StyledButton "[ OneDrive ]"           $col1 160 $btnW 45 { Remove-OneDrive }       $dangerBg))
$form.Controls.Add((New-StyledButton "[ Widgets ]"            $col2 160 $btnW 45 { Disable-Widgets }       $defaultBg))
$form.Controls.Add((New-StyledButton "[ Recherche Web ]"      $col3 160 $btnW 45 { Disable-WebSearch }     $defaultBg))
$form.Controls.Add((New-StyledButton "[ Pubs / Suggestions ]" $col1 215 $btnW 45 { Disable-Ads }           $defaultBg))
$form.Controls.Add((New-StyledButton "[ Copilot ]"            $col2 215 $btnW 45 { Disable-Copilot }       $defaultBg))
$form.Controls.Add((New-StyledButton "[ Recall (24H2+) ]"     $col3 215 $btnW 45 { Disable-Recall }        $dangerBg))

$form.Controls.Add((New-StyledButton ">> NETTOYAGE COMPLET (Tout en un)" 25  575 330 50 { FullClean } $successBg))

$btnReboot = New-StyledButton ">> Redemarrer maintenant" 370 575 320 50 {
    $result = [System.Windows.Forms.MessageBox]::Show("Redemarrer l'ordinateur maintenant ?", "Black-Lab Debloater", "YesNo", "Question")
    if ($result -eq "Yes") { Restart-Computer }
} $rebootBg
$form.Controls.Add($btnReboot)

$footer = New-Object System.Windows.Forms.Label
$footer.Text = "D-Goth  |  Black-Lab.fr  |  v2.0"
$footer.Font = New-Object System.Drawing.Font("Consolas", 8)
$footer.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 120)
$footer.Size = New-Object System.Drawing.Size(670, 20)
$footer.Location = New-Object System.Drawing.Point(25, 650)
$footer.TextAlign = "MiddleCenter"
$form.Controls.Add($footer)

# ---------------------------------------------
# LANCEMENT
# ---------------------------------------------
Write-Log "Bienvenue dans Black-Lab Windows CleanUp v2.0" "cyan"
Write-Log "Selectionnez une option ou lancez le nettoyage complet." "yellow"
Write-Log "[ATTENTION] OneDrive et Recall (rouge) sont des actions irreversibles sans restauration." "red"

$form.ShowDialog() | Out-Null