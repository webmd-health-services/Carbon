# Copyright 2012 Aaron Jensen
# 
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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonDscResource.ps1' -Resolve)

$npmrcPath = $null

function Get-NpmrcPath
{
    param(
    )

    if( -not $npmrcPath )
    {
        $npmCmd = Get-Command -Name 'npm.cmd' -ErrorAction Ignore
        if( -not $npmCmd )
        {
            $npmCmd = Get-Command -Name (Join-Path -Path $env:ProgramFiles -ChildPath 'nodejs\npm.cmd') -ErrorAction Ignore
            if( -not $npmCmd )
            {
                Write-Error ('npm.cmd not found. Is Node.js installed? If not, make sure you install Node.js before this resource.')
                return
            }
        }

        $nodeJsRoot = Split-Path -Parent -Path $npmCmd.Path
        $script:npmrcPath = Join-Path -Path $nodeJsRoot -ChildPath 'node_modules\npm\npmrc'
        if( -not (Test-Path -Path $npmrcPath -PathType Leaf) )
        {
            Write-Error ('Built-in npmrc ''{0}'' not found. Is Node.js installed? If not, make sure you install Node.js before this resource.' -f $npmrcPath)
            return
        }
    }

    return $npmrcPath
}

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([Collections.Hashtable])]
	param
	(
		[Parameter(Mandatory=$true)]
		[string]
        # The name of the NPM config value.
		$Name,

		[string]
        # the value of the NPM config value.        
		$Value,

		[ValidateSet("Present","Absent")]
		[string]
        # Create or delete the NPM config value?
		$Ensure = 'Present'
	)
    
    Set-StrictMode -Version 'Latest'

    $npmrcPath = Get-NpmrcPath
    if( -not $npmrcPath )
    {
        return
    }

    $ini = Split-Ini -Path $npmrcPath -AsHashtable -CaseSensitive
    
    $currentValue = $null
    $Ensure = 'Absent'
    if( $ini.ContainsKey( $Name ) )
    {
        $currentValue = $ini[$Name].Value
        $Ensure = 'Present';
    }

    @{
        Name = $Name;
        Value = $currentValue;
        Ensure = $Ensure;
    }
}

function Set-TargetResource
{
    <#
    .SYNOPSIS
    DSC resource for configuring Node Package Manager (NPM) settings.

    .DESCRIPTION
    The `Carbon_NpmConfig` resource sets NPM configuration settings in the global NPM config file, which is usually found at `C:\Program Files\nodejs\node_modules\npm\npmrc`. All settings added/removed using this resource will be used for all users on the computer, unless a user overrides the setting.

    .LINK
    Remove-IniEntry

    .LINK
    Set-IniEntry

    .LINK
    Split-Ini

    .EXAMPLE
    >
    Demonstrates how to create/set an NPM config value.

        Carbon_NpmConfig SetNpmPrefix
        {
            Name = 'prefix';
            Value = 'C:\node-global-modules';
            Ensure = 'Present';
        }

    In this case, we're setting the directory all users will use to store node modules.

    .EXAMPLE
    >
    Demonstrates how to remove an NPM config value.

        Carbon_NpmConfig SetNpmPrefix
        {
            Name = 'prefix';
            Ensure = 'Absent';
        }
    #>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		[string]
        # The name of the NPM config value.
		$Name,

		[string]
        # The value of the NPM config value. Required when `Ensure` is set to `Present`.
		$Value,

		[ValidateSet("Present","Absent")]
		[string]
        # Create or delete the NPM config value?
		$Ensure = 'Present'
	)
    
    Set-StrictMode -Version 'Latest'

    $npmrcPath = Get-NpmrcPath
    if( -not $npmrcPath )
    {
        return
    }

    $resource = Get-TargetResource -Name $Name
    if( $resource.Ensure -eq 'Present' -and $Ensure -eq 'Absent' )
    {
        Write-Verbose ('Removing {0}' -f $Name)
        Remove-IniEntry -Path $npmrcPath -Name $Name -CaseSensitive
        return
    }

    if( $Ensure -eq 'Present' )
    {
        Write-Verbose ('Setting {0}' -f $Name)
        Set-IniEntry -Path $npmrcPath -Name $Name -Value $Value -CaseSensitive
    }
}

function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([bool])]
	param
	(
		[Parameter(Mandatory=$true)]
		[string]
        # The name of the NPM config value.
		$Name,

		[string]
        # The value of the NPM config value.        
		$Value,

		[ValidateSet("Present","Absent")]
		[string]
        # Create or delete the NPM config value?
		$Ensure = 'Present'
	)
    
    Set-StrictMode -Version 'Latest'

    $resource = Get-TargetResource -Name $Name
    if( -not $resource )
    {
        return $false
    }

    if( $Ensure -eq 'Present' )
    {
        $result = ($resource.Value -ceq $Value)
        if( $result )
        {
            Write-Verbose ('{0}: current value unchanged' -f $Name)
        }
        else
        {
            Write-Verbose ('{0}: current value differs' -f $Name)
        }
    }
    else
    {
        $result = ($resource.Ensure -eq 'Absent')
        if( $result )
        {
            Write-Verbose ('{0}: not found' -f $Name) 
        }
        else
        {
            Write-Verbose ('{0}: found' -f $Name)
        }
    }
    return $result
}

Export-ModuleMember -Function '*-TargetResource'
