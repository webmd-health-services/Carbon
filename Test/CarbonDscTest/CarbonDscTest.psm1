# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

$CarbonDscOutputRoot = $null
$currentDscResource = $null
# $script:carbonModulePath = $null

function Start-CarbonDscTestFixture
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string] $DscResourceName
    )

    Set-StrictMode -Version 'Latest'

    # $modulePath = Join-Path -Path ([Environment]::GetFolderPath('ProgramFiles')) -ChildPath 'PowerShell\Modules'
    # $script:carbonModulePath = Join-Path -Path $modulePath -ChildPath 'Carbon'
    # $carbonTargetPath = Join-path -Path $PSScriptRoot -ChildPath '..\..\Carbon' -Resolve
    # if ((Test-Path -Path $script:carbonModulePath))
    # {
    #     if (-not ((Get-Item -Path $script:carbonModulePath).Target))
    #     {
    #         $msg = "Carbon is already installed globally on this machine at ""$($script:carbonModulePath)"". Please " +
    #                'uninstall the global version of Carbon and re-run this test.'
    #         Write-Error -Message $msg -ErrorAction Stop
    #         return
    #     }

    #     Remove-Item -Path $script:carbonModulePath
    # }

    # New-Item -Path $script:carbonModulePath -ItemType Junction -Value $carbonTargetPath

    $script:currentDscResource = $DscResourceName
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath ('..\..\Carbon\DscResources\Carbon_{0}' -f $DscResourceName) -Resolve) -Force -Global

    if( $PSVersionTable.PSEdition -eq 'Core' )
    {
        if( Get-Module -Name 'PSDesiredStateConfiguration' | Where-Object Version -lt ([Version]'2.0.0') )
        {
            Remove-Module -Name 'PSDesiredStateConfiguration'
        }

        if( -not (Get-Module -Name 'PSDesiredStateConfiguration' | Where-Object Version -ge ([Version]'2.0.0')) )
        {
            if( -not (Get-Module -Name 'PSDesiredStateConfiguration' -ListAvailable | Where-Object Version -ge ([Version]'2.0.0')) )
            {
                Find-Module -Name 'PSDesiredStateConfiguration' -MinimumVersion '2.0' -MaximumVersion '2.99' |
                    Select-Object -First 1 |
                    Install-Module -Force
            }
            Import-Module -Name 'PSDesiredStateConfiguration' -Global
        }
    }
    Enable-PSRemoting -SkipNetworkProfileCheck -Force

    $tempDir = [IO.Path]::GetRandomFileName()
    $tempDir = 'CarbonDscTest-{0}-{1}' -f $DscResourceName,$tempDir
    $script:CarbonDscOutputRoot = Join-Path -Path $env:TEMP -ChildPath $tempDir

    New-Item -Path $script:CarbonDscOutputRoot -ItemType 'directory'

    Clear-CDscLocalResourceCache
}

function Stop-CarbonDscTestFixture
{
    if( (Test-Path -Path $script:CarbonDscOutputRoot -PathType Container) )
    {
        Remove-Item -Path $script:CarbonDscOutputRoot -Recurse
    }

    # if ((Get-Item -Path $script:carbonModulePath).Target)
    # {
    #     Remove-Item -Path $script:carbonModulePath
    # }
}

function Invoke-CarbonTestDscConfiguration
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    Set-StrictMode -Off

    & $Name -OutputPath $tempDir

    Start-DscConfiguration -Wait -ComputerName 'localhost'
}

function Assert-DscResourcePresent
{
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $Resource
    )

    Set-StrictMode -Version 'Latest'

    if( (Get-Command -Name 'Assert-Equal' -ErrorAction Ignore) )
    {
        Assert-Equal 'Present' $Resource.Ensure
    }
    else
    {
        $Resource.Ensure | Should -Be 'Present'
    }
}

function Assert-DscResourceAbsent
{
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $Resource
    )

    Set-StrictMode -Version 'Latest'

    if( (Get-Command -Name 'Assert-Equal' -ErrorAction Ignore) )
    {
        Assert-Equal 'Absent' $Resource.Ensure
    }
    else
    {
        $Resource.Ensure | Should -Be 'Absent'
    }
}

Export-ModuleMember -Function '*-*' -Variable 'CarbonDscOutputRoot'
