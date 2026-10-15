<#
  wezhere installer: Explorer context menu "Open WezTerm here" (admin, no UAC popup)
  + "Open WezTerm here (user)". Self-elevates once to register the scheduled task.
  Also retargets an existing WezTerm taskbar pin to launch elevated in ~.
  On Win11 the entries live under "Show more options" (or Shift+right-click).

  .\install.ps1            build must exist (sh build.sh), installs
  .\install.ps1 -Uninstall removes task, menu entries and the installed exe
#>
param([switch]$Uninstall)

$ErrorActionPreference = 'Stop'
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    if ($Uninstall) { $a += '-Uninstall' }
    $p = Start-Process powershell.exe -Verb RunAs -ArgumentList $a -Wait -PassThru
    exit $p.ExitCode
}

$dir  = Join-Path $env:LOCALAPPDATA 'Programs\wezhere'
$exe  = Join-Path $dir 'wezhere.exe'
$keys = 'Directory\Background\shell', 'Directory\shell', 'Drive\shell' | ForEach-Object { "HKCU:\Software\Classes\$_" }

foreach ($k in $keys) {
    Remove-Item "$k\wezhere", "$k\wezhere-user" -Recurse -ErrorAction SilentlyContinue
}
Unregister-ScheduledTask -TaskName wezhere -Confirm:$false -ErrorAction SilentlyContinue

if ($Uninstall) {
    Remove-Item $dir -Recurse -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\WezTerm.lnk') -ErrorAction SilentlyContinue
    Write-Host 'wezhere removed (scoop update wezterm-nightly to restore its shortcut)'
    exit 0
}

New-Item -ItemType Directory $dir -Force | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'build\wezhere.exe') $exe -Force

# Priority 4 = normal. Task default is 7 (below normal) and every shell you open would inherit it.
$user = "$env:USERDOMAIN\$env:USERNAME"
$xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo><Description>wezhere: elevated "Open WezTerm here" from Explorer, no UAC popup. ~/dotfiles/windows/wezhere</Description></RegistrationInfo>
  <Principals>
    <Principal id="Author">
      <UserId>$user</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>Parallel</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>false</AllowHardTerminate>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>4</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>$exe</Command>
      <Arguments>--launch `$(Arg0)</Arguments>
    </Exec>
  </Actions>
</Task>
"@
Register-ScheduledTask -TaskName wezhere -Xml $xml | Out-Null

$icon = Join-Path $env:USERPROFILE 'scoop\apps\wezterm-nightly\current\wezterm-gui.exe'
foreach ($k in $keys) {
    foreach ($e in @(@{ Id = 'wezhere'; Label = 'Open WezTerm here'; Args = '"%V"' },
                     @{ Id = 'wezhere-user'; Label = 'Open WezTerm here (user)'; Args = '--user "%V"' })) {
        $key = "$k\$($e.Id)"
        New-Item "$key\command" -Force | Out-Null
        Set-ItemProperty $key '(default)' $e.Label
        Set-ItemProperty $key 'Icon' "`"$icon`""
        Set-ItemProperty "$key\command" '(default)' "`"$exe`" $($e.Args)"
    }
}
# Taskbar pin: Windows has no API to pin things, so only retarget a pin that already exists.
# Edited in place (not recreated) because the .lnk carries wezterm's AppUserModelID
# (org.wezfurlong.wezterm); lose that and the elevated window gets its own taskbar icon
# instead of lighting up the pin. Icon goes through scoop's `current` so updates don't orphan it.
$pin = Get-ChildItem (Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar') -Filter 'WezTerm*.lnk' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($pin) {
    $s = (New-Object -ComObject WScript.Shell).CreateShortcut($pin.FullName)
    $s.TargetPath = $exe
    $s.Arguments = "`"$env:USERPROFILE`""
    $s.WorkingDirectory = $env:USERPROFILE
    $s.IconLocation = "$icon,0"
    $s.Save()
    Write-Host "taskbar pin -> wezhere (elevated)"
} else {
    Write-Host "no WezTerm taskbar pin found; pin it from a running window and rerun to make it elevated"
}

# Start menu: our own WezTerm.lnk at the Programs root, because scoop rewrites its
# Scoop Apps\WezTerm.lnk on every nightly update. Scoop's one gets retargeted too, until it doesn't.
$programs = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
foreach ($lnk in (Join-Path $programs 'WezTerm.lnk'), (Join-Path $programs 'Scoop Apps\WezTerm.lnk')) {
    if ($lnk -like '*Scoop Apps*' -and -not (Test-Path $lnk)) { continue }
    $s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
    $s.TargetPath = $exe
    $s.Arguments = "`"$env:USERPROFILE`""
    $s.WorkingDirectory = $env:USERPROFILE
    $s.IconLocation = "$icon,0"
    $s.Save()
    Write-Host "start menu -> $lnk"
}

Write-Host "wezhere installed -> $exe"
