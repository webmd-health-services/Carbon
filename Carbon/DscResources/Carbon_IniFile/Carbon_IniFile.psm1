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

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([Collections.Hashtable])]
	param
	(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the file to update.
        $Path,

        [string]
        # The section of the INI file where the setting can be found.
        $Section,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the INI setting.
        $Name,

        [string]
        # The value of the INI setting.        
        $Value,

        [Switch]
        # The INI file being modified is case-sensitive.
        $CaseSensitive,

        [Switch]
        # If `$true`, creates the INI file if it doesn't exist.
        $Force,

        [ValidateSet("Present","Absent")]
        [string]
        # Create or delete the INI setting?
        $Ensure = 'Present'
	)
    
    Set-StrictMode -Version 'Latest'

    $ini = @{ }
    if( (Test-Path -Path $Path -PathType Leaf) )
    {
        $ini = Split-CIni -Path $Path -AsHashtable -CaseSensitive:$CaseSensitive
    }
    else
    {
        if( -not $Force )
        {
            Write-Error ('INI file ''{0}'' not found. Set the `Force` property to `true` to create this INI file when it doesn''t exist.' -f $Path)
            return
        }
    }
    
    $key = $Name
    if( $Section )
    {
        $key = '{0}.{1}' -f $Section,$Name
    }
    
    $currentValue = $null
    $Ensure = 'Absent'
    if( $ini.ContainsKey( $key ) )
    {
        $currentValue = $ini[$key].Value
        $Ensure = 'Present';
    }
    
    @{
        Path = $Path;
        Section = $Section;
        Name = $Name;
        Value = $currentValue;
        CaseSensitive = [bool]$CaseSensitive;
        Force = [bool]$Force
        Ensure = $Ensure;
    }
}

function Set-TargetResource
{
    <#
    .SYNOPSIS
    DSC resource for managing settings in INI files.

    .DESCRIPTION
    The `Carbon_IniFile` resource sets or removes settings from INI files.

    `Carbon_IniFile` is new in Carbon 2.0.

    .LINK
    Remove-CIniEntry

    .LINK
    Set-CIniEntry

    .LINK
    Split-CIni

    .EXAMPLE
    >
    Demonstrates how to create/set a setting in sectionless INI file.

        Carbon_IniFile SetNpmPrefix
        {
            Path = 'C:\Program Files\nodejs\node_modules\npm\npmrc'
            Name = 'prefix';
            Value = 'C:\node-global-modules';
            CaseSensitive = $true;
        }

    In this case, we're setting the `prefix` NPM setting to `C:\node-global-modules` in the `C:\Program Files\nodejs\node_modules\npm\npmrc` file. It is expected this file exists and you'll get an error if it doesn't. NPM configuration files are case-sensitive, so the `CaseSensitive` property is set to `$true`.

    This line will be added to the INI file:

        prefix = C:\node-global-modules

    .EXAMPLE
    >
    Demonstrates how to create/set a setting in an INI file with sections.

        Carbon_IniFile SetBuildUserMercurialUsername
        {
            Path = 'C:\Users\BuildUser\mercurial.ini'
            Section = 'ui';
            Name = 'username';
            Force = $true;
            Value = 'Build User <builduser@example.com>';
        }

    In this case, we're setting the 'username' setting in the 'ui' section of the `C:\Users\BuildUser\mercurial.ini` file to `Build User <builduser@example.com>`. Since the `$Force` property is `$true`, if the file doesn't exist, it will be created. These lines will be added to the ini file:

        [ui]
        username = Build User <builduser@example.com>

    .EXAMPLE
    >
    Demonstrates how to remove a setting from a case-sensitive INI file.

        Carbon_IniFile RemoveNpmPrefix
        {
            Path = 'C:\Program Files\nodejs\node_modules\npm\npmrc'
            Name = 'prefix';
            CaseSensitive = $true;
            Ensure = 'Absent';
        }

    .EXAMPLE
    >
    Demonstrates how to remove a setting from an INI file that organizes settings into sections.

        Carbon_IniFile RemoveBuildUserMercurialUsername
        {
            Path = 'C:\Users\BuildUser\mercurial.ini'
            Section = 'ui';
            Name = 'username';
            Ensure = 'Absent';
        }
    #>
	[CmdletBinding()]
	param
	(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the file to update.
        $Path,

        [string]
        # The section of the INI file where the setting can be found.
        $Section,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the INI setting.
        $Name,

        [string]
        # The value of the INI setting.        
        $Value,

        [Switch]
        # The INI file being modified is case-sensitive.
        $CaseSensitive,

        [Switch]
        # If `$true`, creates the INI file if it doesn't exist.
        $Force,

        [ValidateSet("Present","Absent")]
        [string]
        # Create or delete the INI setting?
        $Ensure = 'Present'
	)
    
    Set-StrictMode -Version 'Latest'

    $resource = Get-TargetResource -Path $Path -Section $Section -Name $Name -Force:$Force -CaseSensitive:$CaseSensitive
    if( -not $resource )
    {
        return
    }

    if( -not (Test-Path -Path $Path -PathType Leaf) -and $Force )
    {
        New-Item -Path $Path -ItemType 'File' -Force | Out-Null
    }

    $fullName = $Name
    if( $Section )
    {
        $fullName = '{0}.{1}' -f $Section,$Name
    }

    if( $resource.Ensure -eq 'Present' -and $Ensure -eq 'Absent' )
    {
        Write-Verbose ('{0}: {1}: removing' -f $Path,$fullName)
        Remove-CIniEntry -Path $Path -Section $Section -Name $Name -CaseSensitive:$CaseSensitive
        return
    }

    if( $Ensure -eq 'Present' )
    {
        Write-Verbose ('{0}: {1}: setting' -f $Path,$fullName)
        Set-CIniEntry -Path $Path -Section $Section -Name $Name -Value $Value -CaseSensitive:$CaseSensitive
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
        # The path to the file to update.
        $Path,

        [string]
        # The section of the INI file where the setting can be found.
        $Section,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the INI setting.
        $Name,

        [string]
        # The value of the INI setting.        
        $Value,

        [Switch]
        # The INI file being modified is case-sensitive.
        $CaseSensitive,

        [Switch]
        # If `$true`, creates the INI file if it doesn't exist.
        $Force,

        [ValidateSet("Present","Absent")]
        [string]
        # Create or delete the INI setting?
        $Ensure = 'Present'
	)
    
    Set-StrictMode -Version 'Latest'

    $resource = Get-TargetResource -Path $Path -Section $Section -Name $Name -Force:$Force
    if( -not $resource )
    {
        return $false
    }

    $fullName = $Name
    if( $Section )
    {
        $fullName = '{0}.{1}' -f $Section,$Name
    }

    if( $Ensure -eq 'Present' )
    {
        $result = ($resource.Value -eq $Value)
        if( $CaseSensitive )
        {
            $result = ($resource.Value -ceq $Value)
        }

        if( $result )
        {
            Write-Verbose ('{0}: {1}: current value unchanged' -f $Path,$fullName)
        }
        else
        {
            Write-Verbose ('{0}: {1}: current value differs' -f $Path,$fullName)
        }
    }
    else
    {
        $result = ($resource.Ensure -eq 'Absent')
        if( $result )
        {
            Write-Verbose ('{0}: {1}: not found' -f $Path,$fullName) 
        }
        else
        {
            Write-Verbose ('{0}: {1}: found' -f $Path,$fullName)
        }
    }
    return $result
}

Export-ModuleMember -Function '*-TargetResource'

