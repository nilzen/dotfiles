# Prerequisites
# -------------
#
# "-PredictionViewStyle ListView" requires PSReadLine >= 2.2.0 install module using:
# Install-Module -Name PSReadLine -AllowPrerelease
#
# Create a symbolic link to this PowerShell profile script,
# find the path to the profile script in PowerShell using:
#
# echo $PROFILE
#
# and create a symbolic link to this profile script using (CMD as administrator):
#
# mklink C:\path\to\Microsoft.PowerShell_profile.ps1 C:\git\dotfiles\Microsoft.PowerShell_profile.ps1

oh-my-posh --init --shell pwsh --config C:\DeveloperArea\dotfiles\.ohmyposh.json | Invoke-Expression

Import-Module -Name Terminal-Icons

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
