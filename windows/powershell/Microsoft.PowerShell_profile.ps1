# Initialize Starship prompt
Invoke-Expression (&starship init powershell)

# Initialize zoxide (smarter cd)
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# Quick navigation aliases
function dots { Set-Location "D:\works\personal_projects\dotfiles" }
function proj { Set-Location "D:\works\personal_projects" }
function realm { Set-Location "D:\works\personal_projects\c\Realm" }
