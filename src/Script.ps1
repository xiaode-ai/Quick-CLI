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

function Get-AppConfig {
    if (Test-Path $configPath) { return Get-Content $configPath | ConvertFrom-Json }
    return $null
}

function Save-Config($config) {
    $config | ConvertTo-Json -Depth 10 | Out-File $configPath -Encoding utf8
}

function Get-AppUI {
    $config = Get-AppConfig
    $lang = "en-us" # Default
    if ($config -and $config.current -and $config.current.language) { $lang = $config.current.language }
    
    $i18nDir = Join-Path $parentDir "i18n"
    $uiFile = Join-Path $i18nDir "$lang.json"
    
    if (Test-Path $uiFile) {
        $raw = Get-Content $uiFile -Raw -Encoding UTF8
        return $raw | ConvertFrom-Json
    }
    # Fallback to any available UI file if zh-cn is also missing
    return @{ mainTitle = "Quick CLI"; menuItems = @("Start CLI", "Exit") }
}

$UI = Get-AppUI

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
        
        # 1. 鏍囬灞呬腑閫昏緫 (鑰冭檻涓枃瀛楃鍙兘鍗犲弻浣?
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

function Show-ProviderMenu {
    param($Title)
    while ($true) {
        $config = Get-AppConfig
        $list = @()
        foreach ($p in $config.providers) {
            $list += "$($p.name) (" + $p.baseUrl + ")"
        }
        $list += $UI.addProvider
        $list += $UI.delProvider

        $choice = Invoke-Menu $Title $list
        if ($choice -eq "ESC") { return }

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
    }
}

function Show-ModelMenu {
    param($Title)
    while ($true) {
        $config = Get-AppConfig
        if ($null -eq $config.providers -or $config.providers.Count -eq 0) {
            Write-Host "`n$($UI.errorMsg)" -ForegroundColor Red
            Read-Host
            return
        }

        $allModels = @()
        for ($pIdx = 0; $pIdx -lt $config.providers.Count; $pIdx++) {
            $p = $config.providers[$pIdx]
            if ($null -ne $p.models) {
                $mCount = @($p.models).Count
                for ($mIdx = 0; $mIdx -lt $mCount; $mIdx++) {
                    $m = $p.models[$mIdx]
                    $obj = [PSCustomObject]@{ 
                        pIdx = $pIdx
                        mIdx = $mIdx
                        displayText = "$($p.name) > $($m.name)"
                    }
                    $allModels += $obj
                }
            }
        }

        $list = @()
        foreach ($item in $allModels) { $list += $item.displayText }
        $list += $UI.addModel
        $list += $UI.delModel

        $choice = Invoke-Menu $Title $list
        if ($choice -eq "ESC") { return }

        if ($choice -eq ($list.Count - 3)) { # Add Model
            $pNames = @()
            foreach ($p in $config.providers) { $pNames += $p.name }
            $pChoice = Invoke-Menu $UI.selectProviderPrompt $pNames
            if ($pChoice -eq "ESC") { continue }
            
            $name = Read-StringWithCancel $UI.modelNamePrompt
            if ($null -ne $name) {
                $id = Read-StringWithCancel $UI.modelIdPrompt
                if ($null -ne $id) {
                    # 确保 models 是数组
                    if ($null -eq $config.providers[$pChoice].models) { $config.providers[$pChoice].models = @() }
                    $config.providers[$pChoice].models += @{ name = $name; id = $id }
                    Save-Config $config
                }
            }
        }
        elseif ($choice -eq ($list.Count - 2)) { # Delete Model
            if ($allModels.Count -eq 0) { continue }
            $totalCount = $allModels.Count
            $idxStr = Read-StringWithCancel "$($UI.deleteModelIndexPrompt) (1-$totalCount): "
            if ($idxStr -match "^\d+$") {
                $idx = [int]$idxStr - 1
                if ($idx -ge 0 -and $idx -lt $totalCount) {
                    $target = $allModels[$idx]
                    $pIdx = $target.pIdx
                    $mIdx = $target.mIdx
                    
                    $oldModels = $config.providers[$pIdx].models
                    $newModels = @()
                    for ($i = 0; $i -lt $oldModels.Count; $i++) {
                        if ($i -ne $mIdx) { $newModels += $oldModels[$i] }
                    }
                    $config.providers[$pIdx].models = $newModels
                    Save-Config $config
                }
            }
        }
    }
}

# --- Main ---

while ($true) {
    $UI = Get-AppUI # Reload UI each loop to support language switching
    $config = Get-AppConfig
    if ($config.providers.Count -eq 0) {
        $config.providers += @{ name = "Default"; baseUrl = "https://api.openai.com/v1"; apiKey = ""; models = @(); disableBetas = true; useAuthToken = false }
        if (-not $config.current.language) { $config.current.language = "en-us" }
        Save-Config $config
    }
    
    $choice = Invoke-Menu $UI.mainTitle $UI.menuItems

    if ($choice -eq "ESC") { break }
    $selText = $UI.menuItems[$choice]

    switch ($choice) {
        0 { # Start CLI Flow
            $tIdx = Invoke-Menu $selText $config.tools
            if ($tIdx -eq "ESC") { continue }
            $tName = $config.tools[$tIdx]

            while ($true) {
                $config = Get-AppConfig
                if (-not $config.current.PSObject.Properties.Item('toolSettings')) {
                    $config.current | Add-Member -NotePropertyName toolSettings -NotePropertyValue ([PSCustomObject]@{})
                }
                $ts = $config.current.toolSettings."$tName"
                
                $pIdx = if ($null -eq $ts) { -1 } else { $ts.providerIndex }
                $mIdx = if ($null -eq $ts) { 0 } else { $ts.modelIndex }

                $currP = $null
                $currM = $null

                if ($pIdx -eq -1) {
                    $currP = @{ name = $UI.officialProvider; isOfficial = $true; models = @() }
                    $currM = @{ name = $UI.defaultModel; id = "" }
                } else {
                    $safePIdx = [math]::Min($pIdx, $config.providers.Count - 1)
                    $currP = $config.providers[$safePIdx]
                    $safeMIdx = [math]::Min($mIdx, [math]::Max(0, $currP.models.Count - 1))
                    $currM = if ($currP.models.Count -gt 0) { $currP.models[$safeMIdx] } else { @{ name = $UI.notConfigured; id = "none" } }
                }
                
                $header = "$($UI.configHeader)`n$($UI.providerLabel): $($currP.name)`n$($UI.modelLabel): $($currM.name)"
                $subChoice = Invoke-Menu $tName $UI.launchOptions $header
                
                if ($subChoice -eq "ESC") { break }
                $optText = $UI.launchOptions[$subChoice]

                switch ($subChoice) {
                    0 { # Run
                        if ($currM.id -eq "none") { Write-Host "`n$($UI.errorMsg)" -ForegroundColor Red; Read-Host; continue }
                        Write-Host "`n$($UI.launchingMsg) $tName..." -ForegroundColor Yellow
                        if ($tName -like "*Claude*") {
                            if ($currP.isOfficial) {
                                $env:ANTHROPIC_BASE_URL = ""; $env:ANTHROPIC_API_KEY = ""; $env:ANTHROPIC_MODEL = ""
                            } else {
                                # Claude Code 使用 OpenRouter 时不能带 /v1，自动剥离后缀
                                $cleanUrl = $currP.baseUrl -replace "/v1/?$", ""
                                $env:ANTHROPIC_BASE_URL = $cleanUrl; $env:ANTHROPIC_MODEL = $currM.id
                                if ($currP.useAuthToken) { $env:ANTHROPIC_API_KEY = ""; $env:ANTHROPIC_AUTH_TOKEN = $currP.apiKey } else { $env:ANTHROPIC_API_KEY = $currP.apiKey; $env:ANTHROPIC_AUTH_TOKEN = "" }
                            }
                            $env:CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = if ($currP.disableBetas) { "true" } else { "false" }
                            
                            Write-Host "`n$($UI.exitHintClaude)" -ForegroundColor Gray
                            claude
                        }
                        elseif ($tName -like "*Gemini*") {
                            if ($currP.isOfficial) {
                                $env:GEMINI_API_KEY = ""; $env:GOOGLE_API_KEY = ""; $env:GEMINI_MODEL = ""; $env:GOOGLE_GEMINI_BASE_URL = ""
                                $env:GOOGLE_VERTEX_BASE_URL = ""; $env:CODE_ASSIST_ENDPOINT = ""; $env:GENERATIVE_AI_ENDPOINT = ""
                                $env:GOOGLE_CLOUD_PROJECT = ""; $env:GOOGLE_CLOUD_PROJECT_ID = ""; $env:GEMINI_CLI_FORCE_AUTH_METHOD = ""
                            } else {
                                # 注入 Gemini 官方及常见第三方工具所需的环境变量
                                $env:GEMINI_API_KEY = $currP.apiKey
                                $env:GOOGLE_API_KEY = $currP.apiKey
                                $env:GEMINI_MODEL = $currM.id
                                
                                # 0-修改代理方案 (GCR): 自动重定向 API 请求到用户配置的 Base URL (如 OpenRouter)
                                # 剥离最后的 /v1 或其他后缀，以符合各版本工具的 Base URL 规范
                                $cleanUrl = $currP.baseUrl -replace "/v1/?$", ""
                                $env:GOOGLE_GEMINI_BASE_URL = $cleanUrl
                                $env:GOOGLE_VERTEX_BASE_URL = $cleanUrl
                                $env:CODE_ASSIST_ENDPOINT = $cleanUrl
                                # 额外增加通用端点环境变量以增强兼容性
                                $env:GENERATIVE_AI_ENDPOINT = $cleanUrl

                                # 强制跳过身份验证提示及项目 ID 检查 (GCR 优化仅限非官方渠道)
                                $env:GOOGLE_CLOUD_PROJECT = "quick-cli-dummy"
                                $env:GOOGLE_CLOUD_PROJECT_ID = "quick-cli-dummy"
                                $env:GEMINI_CLI_FORCE_AUTH_METHOD = "api-key"
                                $env:GOOGLE_GENAI_USE_VERTEXAI = "false"
                            }
                            
                            Write-Host "`n$($UI.exitHintClaude)" -ForegroundColor Gray
                            gemini
                        }
                        else {
                            if ($currP.isOfficial) {
                                codex
                            } else {
                                $codexTmpHome = Join-Path $HOME ".codex_custom_api"
                                if (-not (Test-Path $codexTmpHome)) { New-Item -ItemType Directory -Path $codexTmpHome -Force | Out-Null }
                                $env:CODEX_HOME = $codexTmpHome; $env:OPENAI_API_KEY = $currP.apiKey
                                $bx = if ($currP.baseUrl -notmatch "/v1$") { "$($currP.baseUrl)/v1" } else { $currP.baseUrl }
                                codex --config openai_base_url="$bx" -m $currM.id
                            }
                        }
                    }
                    1 { # Switch Provider
                        $pList = @()
                        $offName = $UI.officialProvider
                        if ($pIdx -eq -1) { $offName += $UI.currentTag }
                        $pList += $offName

                        for ($i = 0; $i -lt $config.providers.Count; $i++) {
                            $p = $config.providers[$i]
                            $name = $p.name
                            if ($i -eq $pIdx) { $name += $UI.currentTag }
                            $pList += $name
                        }
                        $pIdxS = Invoke-Menu $optText $pList
                        if ($pIdxS -eq "ESC") { continue }
                        
                        $newPIdx = if ($pIdxS -eq 0) { -1 } else { $pIdxS - 1 }
                        
                        if (-not $config.current.PSObject.Properties.Item('toolSettings')) {
                            $config.current | Add-Member -NotePropertyName toolSettings -NotePropertyValue ([PSCustomObject]@{})
                        }
                        
                        if (-not $config.current.toolSettings.PSObject.Properties.Item($tName)) {
                            $config.current.toolSettings | Add-Member -NotePropertyName $tName -NotePropertyValue ([PSCustomObject]@{ providerIndex = $newPIdx; modelIndex = 0 })
                        } else {
                            $config.current.toolSettings."$tName".providerIndex = $newPIdx
                            $config.current.toolSettings."$tName".modelIndex = 0
                        }
                        Save-Config $config
                    }
                    2 { # Switch Model
                        if ($currP.isOfficial) {
                            # 官方提供商仅支持默认模型
                            Invoke-Menu $optText @($UI.defaultModel + $UI.currentTag)
                            continue
                        }
                        $mList = @()
                        for ($i = 0; $i -lt $currP.models.Count; $i++) {
                            $m = $currP.models[$i]
                            $name = $m.name
                            if ($i -eq $mIdx) { $name += $UI.currentTag }
                            $mList += $name
                        }
                        $mIdxS = Invoke-Menu $optText $mList
                        if ($mIdxS -ne "ESC") {
                            if (-not $config.current.PSObject.Properties.Item('toolSettings')) {
                                $config.current | Add-Member -NotePropertyName toolSettings -NotePropertyValue ([PSCustomObject]@{})
                            }
                            if (-not $config.current.toolSettings.PSObject.Properties.Item($tName)) {
                                $config.current.toolSettings | Add-Member -NotePropertyName $tName -NotePropertyValue ([PSCustomObject]@{ providerIndex = -1 })
                            }
                            $config.current.toolSettings."$tName".modelIndex = $mIdxS
                            Save-Config $config
                        }
                    }
                }
            }
        }
        1 { Show-ProviderMenu $selText }
        2 { Show-ModelMenu $selText }
        3 { # Language Selection
            $langs = @("en-us", "zh-cn")
            $lIdx = Invoke-Menu $UI.selectLanguagePrompt $UI.langList
            if ($lIdx -ne "ESC") {
                $config.current.language = $langs[$lIdx]
                Save-Config $config
            }
        }
    }
}

