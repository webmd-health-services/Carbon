<#
.SYNOPSIS
Bootstraps a server so it can run Carbon's tests.
#>
[CmdletBinding()]
param(
)

Invoke-Expression -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))"

choco install tortoisehg -y

mkdir C:\Projects
$carbonDir = 'C:\Projects\Carbon'

Set-Alias -Name 'hg' -Value 'C:\Program Files\TortoiseHg\hg.exe'
hg clone 'https://bitbucket.org/splatteredbits/carbon' $carbonDir

& 'C:\Projects\Carbon\Initialize-Server.ps1'
