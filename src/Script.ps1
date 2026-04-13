# Quick CLI Manager (Aesthetic Polished Version)
# Centered titles and aligned config details.

# OS check for encoding
if ($IsWindows) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null
}

# Correct paths: config.json is in parent (root), UI.json is same folder (src)
$parentDir = Split-Path $PSScriptRoot -Parent
$configPath = Join-Path $parentDir "config.json"
$uiPath = Join-Path $PSScriptRoot "UI.json"

function Load-Config {
    if (Test-Path $configPath) { return Get-Content $configPath | ConvertFrom-Json }
    return $null
}

function Save-Config($config) {
    $config | ConvertTo-Json -Depth 10 | Out-File $configPath -Encoding utf8
}

function Load-UI {
    if (Test-Path $uiPath) {
        $raw = Get-Content $uiPath -Raw -Encoding UTF8
        return $raw | ConvertFrom-Json
    }
    return @{ mainTitle = "Quick CLI" }
}

$UI = Load-UI

# --- TUI Engine ---

function Invoke-Menu {
    param(
        [string]$Title,
        [string[]]$Options,
        [string]$HeaderInfo = ""
    )

    $currentIndex = 0
    $count = $Options.Count
    $totalWidth = 42

    while ($true) {
        Clear-Host
        
        $buffer = New-Object System.Text.StringBuilder
        [void]$buffer.AppendLine("==========================================")
        
        # 1. 标题居中逻辑 (考虑中文字符可能占双位)
        $displayLength = 0
        foreach ($char in $Title.ToCharArray()) {
            if ([int]$char -gt 255) { $displayLength += 2 } else { $displayLength += 1 }
        }
        $padCount = [math]::Max(0, [int](($totalWidth - $displayLength) / 2))
        $centeredTitle = (" " * $padCount) + $Title
        [void]$buffer.AppendLine($centeredTitle.PadRight($totalWidth))
        
        [void]$buffer.AppendLine("==========================================")
        
        if ($HeaderInfo) {
            $lines = $HeaderInfo.Split("`n")
            foreach ($line in $lines) { [void]$buffer.AppendLine($line.PadRight($totalWidth)) }
            [void]$buffer.AppendLine("-" * $totalWidth)
        }

        for ($i = 0; $i -lt $count; $i++) {
            $prefix = if ($i -eq $currentIndex) { "> " } else { "  " }
            $text = "{0}{1}. {2}" -f $prefix, ($i + 1), $Options[$i]
            [void]$buffer.AppendLine($text.PadRight($totalWidth))
        }

        [void]$buffer.AppendLine("")
        [void]$buffer.AppendLine($UI.navHint)

        Write-Host $buffer.ToString() -NoNewline

        if (-not $Host.UI.RawUI.KeyAvailable) { Start-Sleep -Milliseconds 10 }
        $keyInfo = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($keyInfo.VirtualKeyCode) {
            38 { $currentIndex = ($currentIndex - 1 + $count) % $count } # Up
            40 { $currentIndex = ($currentIndex + 1) % $count }         # Down
            9 { $currentIndex = ($currentIndex + 1) % $count }         # Tab
            13 { return $currentIndex }                                 # Enter
            27 { return "ESC" }                                         # Escape
            default {
                if ($keyInfo.Character -ge '1' -and $keyInfo.Character -le [char]($count + 48)) {
                    return ([int]$keyInfo.Character - 49)
                }
            }
        }
    }
}

# --- Input Engine ---

function Read-StringWithCancel {
    param([string]$Prompt, [switch]$IsPassword)
    Write-Host "`n$Prompt" -NoNewline
    $inputStr = ""
    while ($true) {
        if (-not $Host.UI.RawUI.KeyAvailable) { Start-Sleep -Milliseconds 10 }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($key.VirtualKeyCode -eq 27) { Write-Host "`n$($UI.cancelledMsg)" -ForegroundColor Gray; return $null }
        if ($key.VirtualKeyCode -eq 13) { Write-Host ""; return $inputStr }
        if ($key.VirtualKeyCode -eq 8) {
            if ($inputStr.Length -gt 0) {
                $inputStr = $inputStr.Substring(0, $inputStr.Length - 1)
                $pos = $Host.UI.RawUI.CursorPosition
                if ($pos.X -gt 0) {
                    $pos.X -= 1; $Host.UI.RawUI.CursorPosition = $pos
                    Write-Host " " -NoNewline; $Host.UI.RawUI.CursorPosition = $pos
                }
            } continue
        }
        if ($key.Character -ne "`0" -and $key.VirtualKeyCode -ne 9) {
            $inputStr += $key.Character
            if ($IsPassword) { Write-Host "*" -NoNewline } else { Write-Host $key.Character -NoNewline }
        }
    }
}

# --- Pages ---

function Manage-Providers {
    do {
        $config = Load-Config
        $list = @()
        foreach ($p in $config.providers) { $list += "$($p.name) (" + $p.baseUrl + ")" }
        $list += $UI.addProvider
        $list += $UI.delProvider
        $list += $UI.backLabel

        $choice = Invoke-Menu $UI.manageProvidersTitle $list
        if ($choice -eq "ESC" -or $choice -eq ($list.Count - 1)) { return }

        if ($choice -eq ($list.Count - 3)) {
            $name = Read-StringWithCancel "Name: "
            if ($null -ne $name) {
                $url = Read-StringWithCancel "Base URL: "
                if ($null -ne $url) {
                    $key = Read-StringWithCancel "API Key: " -IsPassword
                    if ($null -ne $key) {
                        $config.providers += @{ name = $name; baseUrl = $url; apiKey = $key; models = @(); disableBetas = $true; useAuthToken = $true }
                        Save-Config $config
                    }
                }
            }
        }
        elseif ($choice -eq ($list.Count - 2)) {
            $idxStr = Read-StringWithCancel "Delete Index (1-$($config.providers.Count)): "
            if ($idxStr -match "^\d+$") {
                $idx = [int]$idxStr - 1
                if ($idx -ge 0 -and $idx -lt $config.providers.Count) {
                    $config.providers = $config.providers | Where-Object { $_.name -ne $config.providers[$idx].name }
                    Save-Config $config
                }
            }
        }
    } until ($false)
}

function Manage-Models {
    $config = Load-Config
    $list = @()
    foreach ($p in $config.providers) { $list += $p.name }
    $list += $UI.backLabel

    $pIdx = Invoke-Menu $UI.manageModelsTitle $list
    if ($pIdx -eq "ESC" -or $pIdx -eq ($list.Count - 1)) { return }

    do {
        $config = Load-Config
        $p = $config.providers[$pIdx]
        $mList = @()
        foreach ($m in $p.models) { $mList += "$($m.name) ($($m.id))" }
        $mList += $UI.addModel
        $mList += $UI.delModel
        $mList += $UI.backLabel

        $choice = Invoke-Menu "$($UI.manageModelsTitle) ($($p.name))" $mList
        if ($choice -eq "ESC" -or $choice -eq ($mList.Count - 1)) { return }

        if ($choice -eq ($mList.Count - 3)) {
            $name = Read-StringWithCancel "Name: "
            if ($null -ne $name) {
                $id = Read-StringWithCancel "ID: "
                if ($null -ne $id) {
                    $p.models += @{ name = $name; id = $id }
                    Save-Config $config
                }
            }
        }
        elseif ($choice -eq ($mList.Count - 2)) {
            $idxStr = Read-StringWithCancel "Index: "
            if ($idxStr -match "^\d+$") {
                $idx = [int]$idxStr - 1
                if ($idx -ge 0 -and $idx -lt $p.models.Count) {
                    $p.models = $p.models | Where-Object { $_.id -ne $p.models[$idx].id }
                    Save-Config $config
                }
            }
        }
    } until ($false)
}

# --- Main ---

do {
    $config = Load-Config
    if ($config.providers.Count -eq 0) {
        $config.providers += @{ name = "Default"; baseUrl = "https://api.openai.com/v1"; apiKey = ""; models = @(); disableBetas = $true; useAuthToken = $false }
        Save-Config $config
    }
    
    $choice = Invoke-Menu $UI.mainTitle $UI.menuItems

    if ($choice -eq "ESC" -or $choice -eq 3) { break }

    switch ($choice) {
        0 { # Start CLI Flow
            $tIdx = Invoke-Menu $UI.engineTitle @("Claude Code", "Codex CLI", $UI.backLabel)
            if ($tIdx -eq "ESC" -or $tIdx -eq 2) { continue }
            $tName = if ($tIdx -eq 0) { "Claude Code" } else { "Codex CLI" }

            do {
                $config = Load-Config
                $pIdx = [math]::Min($config.current.providerIndex, $config.providers.Count - 1)
                $currP = $config.providers[$pIdx]
                $mIdx = [math]::Min($config.current.modelIndex, [math]::Max(0, $currP.models.Count - 1))
                $currM = if ($currP.models.Count -gt 0) { $currP.models[$mIdx] } else { @{ name = $UI.notConfigured; id = "none" } }
                
                # 配置详情去空格对齐
                $header = "$($UI.configHeader)`n$($UI.providerLabel): $($currP.name)`n$($UI.modelLabel): $($currM.name)"
                $subChoice = Invoke-Menu "$($UI.launchTitle) - $tName" $UI.launchOptions $header
                
                if ($subChoice -eq "ESC" -or $subChoice -eq 3) { break }

                switch ($subChoice) {
                    0 { # Run
                        if ($currM.id -eq "none") { Write-Host "`n$($UI.errorMsg)" -ForegroundColor Red; Read-Host; continue }
                        Write-Host "`n$($UI.launchingMsg) $tName..." -ForegroundColor Yellow
                        if ($tName -like "*Claude*") {
                            $env:ANTHROPIC_BASE_URL = $currP.baseUrl; $env:ANTHROPIC_MODEL = $currM.id
                            if ($currP.useAuthToken) { $env:ANTHROPIC_API_KEY = ""; $env:ANTHROPIC_AUTH_TOKEN = $currP.apiKey } else { $env:ANTHROPIC_API_KEY = $currP.apiKey; $env:ANTHROPIC_AUTH_TOKEN = "" }
                            $env:CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = if ($currP.disableBetas) { "true" } else { "false" }
                            claude
                        }
                        else {
                            $codexTmpHome = Join-Path $HOME ".codex_custom_api"
                            if (-not (Test-Path $codexTmpHome)) { New-Item -ItemType Directory -Path $codexTmpHome -Force | Out-Null }
                            $env:CODEX_HOME = $codexTmpHome; $env:OPENAI_API_KEY = $currP.apiKey
                            $bx = if ($currP.baseUrl -notmatch "/v1$") { "$($currP.baseUrl)/v1" } else { $currP.baseUrl }
                            codex --config openai_base_url="$bx" -m $currM.id
                        }
                        Write-Host "`n$($UI.exitMsg)"
                        Read-Host
                    }
                    1 { # Switch Provider
                        $pList = @()
                        foreach ($p in $config.providers) { $pList += $p.name }
                        $pIdxS = Invoke-Menu $UI.providerLabel ($pList + $UI.backLabel)
                        if ($pIdxS -ne "ESC" -and $pIdxS -lt $pList.Count) {
                            $config.current.providerIndex = $pIdxS
                            $config.current.modelIndex = 0
                            Save-Config $config
                        }
                    }
                    2 { # Switch Model
                        $mList = @()
                        foreach ($m in $currP.models) { $mList += $m.name }
                        $mIdxS = Invoke-Menu "$($UI.modelLabel) ($($currP.name))" ($mList + $UI.backLabel)
                        if ($mIdxS -ne "ESC" -and $mIdxS -lt $mList.Count) {
                            $config.current.modelIndex = $mIdxS
                            Save-Config $config
                        }
                    }
                }
            } until ($false)
        }
        1 { Manage-Providers }
        2 { Manage-Models }
    }
} until ($false)
