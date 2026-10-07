<#
  wezhere installer: Explorer context menu "Open WezTerm here" (admin, no UAC popup)
  + "Open WezTerm here (user)". Self-elevates once to register the scheduled task.
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
    Write-Host 'wezhere removed'
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
Write-Host "wezhere installed -> $exe"
