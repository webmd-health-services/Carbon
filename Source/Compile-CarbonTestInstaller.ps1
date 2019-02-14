<#
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]
    $Configuration
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 'Latest'
#Requires -Version 5.1

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\VSSetup' -Resolve)

$instances = Get-VSSetupInstance 
$instances | Format-List | Out-String | Write-Verbose
$instance = $instances | 
                Where-Object { $_.DisplayName -notlike '* Test Agent *' } |
                Sort-Object -Descending -Property InstallationVersion | 
                Select-Object -First 1

$idePath = Join-Path -Path $instance.InstallationPath -ChildPath 'Common7\IDE' -Resolve
Write-Verbose -Message ('Using {0} {1} found at "{2}".' -f $instance.DisplayName,$instance.InstallationVersion,$idePath)
$installerSlnPath = Join-Path -Path $PSScriptRoot -ChildPath 'Carbon.Installer.sln' -Resolve

$env:PATH = '{0}{1}{2}' -f $env:PATH,[IO.Path]::PathSeparator,$idePath

Write-Verbose ('devenv "{0}" /build "{1}"' -f $installerSlnPath,$Configuration)
devenv $installerSlnPath /build $Configuration
if( $LASTEXITCODE )
{
    Write-Error -Message ('Failed to build Carbon test installers. Check the output above for details. If the build failed because of this error: "ERROR: An error occurred while validating. HRESULT = ''8000000A''", open a command prompt, move into the "{0}" directory, and run ".\Common7\IDE\CommonExtensions\Microsoft\VSI\DisableOutOfProcBuild\DisableOutOfProcBuild.exe".' -f $instance.InstallationPath)
}