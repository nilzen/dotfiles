oh-my-posh --init --shell pwsh --config C:\Repos\dotfiles\.ohmyposh.json | Invoke-Expression

Import-Module -Name Terminal-Icons

# -PredictionViewStyle ListView Requires PSReadLine >= 2.2.0
# Install-Module -Name PSReadLine -AllowPrerelease
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
