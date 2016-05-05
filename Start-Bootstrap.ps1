<#
.SYNOPSIS
Bootstraps a server so it can run Carbon's tests.
#>
[CmdletBinding()]
param(
)

Invoke-Expression -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))"

choco install tortoisehg -y

$projectsDir = 'C:\Projects'
if( -not (Test-Path -Path $projectsDir) )
{
    mkdir C:\Projects
}

$carbonDir = Join-Path -Path $projectsDir -ChildPath 'Carbon'

Set-Alias -Name 'hg' -Value 'C:\Program Files\TortoiseHg\hg.exe'
if( -not (Test-Path -Path $carbonDir -PathType Container) )
{
    hg clone 'https://bitbucket.org/splatteredbits/carbon' $carbonDir
}

Push-Location -Path $carbonDir
try
{
    hg pull
    hg update

    & 'C:\Projects\Carbon\Initialize-Server.ps1'
}
finally
{
    Pop-Location
}