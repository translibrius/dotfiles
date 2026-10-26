# Initialize Starship prompt
Invoke-Expression (&starship init powershell)

# Initialize zoxide (smarter cd)
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# Quick navigation aliases
function dots { Set-Location "D:\works\personal_projects\dotfiles" }
function proj { Set-Location "D:\works\personal_projects" }
function realm { Set-Location "D:\works\personal_projects\c\Realm" }

# ---- Secrets ---------------------------------------------------------------
# ~/.secrets is bash syntax (export KEY=value), shared with .bashrc/.zshrc.
# Parsed, not sourced. Quotes around the value are optional.
$secretsFile = Join-Path $env:USERPROFILE ".secrets"
if (Test-Path $secretsFile) {
    foreach ($line in Get-Content $secretsFile) {
        if ($line -match '^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
            $v = $Matches[2].Trim()
            if ($v.Length -ge 2 -and (($v[0] -eq '"' -and $v[-1] -eq '"') -or ($v[0] -eq "'" -and $v[-1] -eq "'"))) {
                $v = $v.Substring(1, $v.Length - 2)
            }
            Set-Item -Path "Env:$($Matches[1])" -Value $v
        }
    }
}

# ---- glm: Claude Code pointed at Z.AI's GLM Coding Plan ---------------------
# Twin of .local/bin/glm (bash). Keep the env table in sync with it.
# Env is set only for the child process and restored after, so plain `claude`
# in the same shell stays on Anthropic.
function glm {
    if (-not $env:ZAI_API_KEY) {
        Write-Error "glm: ZAI_API_KEY not set. Put 'export ZAI_API_KEY=...' in ~/.secrets"
        return
    }
    $vars = [ordered]@{
        ANTHROPIC_API_KEY                        = $null
        ANTHROPIC_AUTH_TOKEN                     = $env:ZAI_API_KEY
        ANTHROPIC_BASE_URL                       = "https://api.z.ai/api/anthropic"
        ANTHROPIC_DEFAULT_OPUS_MODEL             = "glm-5.3[1m]"
        ANTHROPIC_DEFAULT_SONNET_MODEL           = "glm-5.3[1m]"
        ANTHROPIC_DEFAULT_HAIKU_MODEL            = "glm-5.3-flash[1m]"
        CLAUDE_CODE_AUTO_COMPACT_WINDOW          = "1000000"
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
        API_TIMEOUT_MS                           = "3000000"
    }
    $saved = @{}
    foreach ($k in $vars.Keys) {
        $saved[$k] = [Environment]::GetEnvironmentVariable($k)
        [Environment]::SetEnvironmentVariable($k, $vars[$k])
    }
    $model = if ($env:GLM_MODEL) { $env:GLM_MODEL } else { "glm-5.3[1m]" }
    try     { & claude --model $model @args }
    finally { foreach ($k in $vars.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k]) } }
}
