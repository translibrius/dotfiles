<#
.SYNOPSIS
    Windows dotfile linker — like GNU Stow but for Windows.
    Creates symbolic links from this repo to their system locations.

.DESCRIPTION
    Run as Administrator (symlinks need elevated privileges unless Developer Mode is on).
    Use -DryRun to preview without making changes.
    Use -Force to overwrite existing files (backs up to .bak first).

.EXAMPLE
    .\link.ps1
    .\link.ps1 -DryRun
    .\link.ps1 -Force
#>

param(
    [switch]$DryRun,
    [switch]$Force,
    [switch]$Unlink
)

$dotfiles = $PSScriptRoot

# Mapping: repo path (relative to dotfiles) -> system target path
# Cross-platform configs use .config/ in repo, mapped to Windows locations
$links = @(
    # Alacritty: shared base config to ~/.config, Windows overrides to %APPDATA%
    @{ Src = ".config\alacritty\alacritty.toml";  Dst = "$env:USERPROFILE\.config\alacritty\alacritty.toml" }
    @{ Src = "windows\alacritty\alacritty.toml";  Dst = "$env:APPDATA\alacritty\alacritty.toml" }

    # Starship: uses ~/.config/starship.toml on all platforms
    @{ Src = ".config\starship.toml";              Dst = "$env:USERPROFILE\.config\starship.toml" }

    # Git Bash
    @{ Src = ".bashrc";                            Dst = "$env:USERPROFILE\.bashrc" }

    # PowerShell 5.1 (Windows PowerShell)
    @{ Src = "windows\powershell\Microsoft.PowerShell_profile.ps1"
       Dst = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" }

    # PowerShell 7+ (if installed)
    @{ Src = "windows\powershell\Microsoft.PowerShell_profile.ps1"
       Dst = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" }

    # Clink (Starship in CMD)
    @{ Src = "windows\clink\starship.lua";         Dst = "$env:LOCALAPPDATA\clink\starship.lua" }

    # Claude Code global settings + instructions
    @{ Src = ".claude\settings.json";              Dst = "$env:USERPROFILE\.claude\settings.json" }
    @{ Src = ".claude\CLAUDE.md";                  Dst = "$env:USERPROFILE\.claude\CLAUDE.md" }

    # Claude Code global skills
    @{ Src = ".claude\skills";                     Dst = "$env:USERPROFILE\.claude\skills" }
)

function Link-Dotfile {
    param($Src, $Dst)

    $srcFull = Join-Path $dotfiles $Src

    if (-not (Test-Path $srcFull)) {
        Write-Host "  SKIP  $Src (not found in repo)" -ForegroundColor DarkGray
        return
    }

    if ($Unlink) {
        if ((Test-Path $Dst) -and ((Get-Item $Dst).LinkType -eq "SymbolicLink")) {
            if ($DryRun) {
                Write-Host "  WOULD UNLINK  $Dst" -ForegroundColor Yellow
            } else {
                Remove-Item $Dst
                Write-Host "  UNLINKED  $Dst" -ForegroundColor Red
            }
        } else {
            Write-Host "  SKIP  $Dst (not a symlink)" -ForegroundColor DarkGray
        }
        return
    }

    # Already linked correctly
    if ((Test-Path $Dst) -and ((Get-Item $Dst).LinkType -eq "SymbolicLink")) {
        $target = (Get-Item $Dst).Target
        if ($target -eq $srcFull) {
            Write-Host "  OK    $Dst -> $Src" -ForegroundColor Green
            return
        }
    }

    # Existing file that isn't our symlink
    if (Test-Path $Dst) {
        if (-not $Force) {
            Write-Host "  EXISTS  $Dst (use -Force to overwrite)" -ForegroundColor Yellow
            return
        }
        $backup = "$Dst.bak"
        if ($DryRun) {
            Write-Host "  WOULD BACKUP  $Dst -> $backup" -ForegroundColor Yellow
        } else {
            Move-Item $Dst $backup -Force
            Write-Host "  BACKUP  $Dst -> $backup" -ForegroundColor Yellow
        }
    }

    # Create parent directory
    $parent = Split-Path $Dst -Parent
    if (-not (Test-Path $parent)) {
        if ($DryRun) {
            Write-Host "  WOULD MKDIR  $parent" -ForegroundColor Cyan
        } else {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
    }

    # Create symlink
    if ($DryRun) {
        Write-Host "  WOULD LINK  $Dst -> $Src" -ForegroundColor Cyan
    } else {
        New-Item -ItemType SymbolicLink -Path $Dst -Target $srcFull -Force | Out-Null
        Write-Host "  LINKED  $Dst -> $Src" -ForegroundColor Green
    }
}

# Check if we can create symlinks (Developer Mode or Admin)
$canSymlink = $true
try {
    $testLink = Join-Path $env:TEMP "dotfiles_symlink_test"
    $testTarget = Join-Path $dotfiles "link.ps1"
    New-Item -ItemType SymbolicLink -Path $testLink -Target $testTarget -Force -ErrorAction Stop | Out-Null
    Remove-Item $testLink -Force
} catch {
    $canSymlink = $false
    Write-Host "`n  ERROR: Cannot create symlinks." -ForegroundColor Red
    Write-Host "  Enable Developer Mode (Settings > Developer) or run as Administrator.`n" -ForegroundColor Yellow
    exit 1
}

$action = if ($Unlink) { "Unlinking" } elseif ($DryRun) { "Dry run" } else { "Linking" }
Write-Host "`n  $action dotfiles...`n" -ForegroundColor Magenta

foreach ($link in $links) {
    Link-Dotfile -Src $link.Src -Dst $link.Dst
}

Write-Host ""
