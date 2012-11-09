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

function Get-RegistryKeyValue
{
    <#
    .SYNOPSIS
    Gets the value from a registry key.
    
    .DESCRIPTION
    PowerShell's `Get-ItemProperty` cmdlet is a pain to use.  It doesn't actually return an object representing a registry key's value, but some other weird object that requires painful gyrations to get values from. This function returns just the value of a key.
    
    .EXAMPLE
    Get-RegistryKeyValue -Path 'hklm:\Software\Carbon\Test' -Name 'Title'
    
    Returns the value of the 'hklm:\Software\Carbon\Test' key's `Title` value.  
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key where the value should be set.  Will be created if it doesn't exist.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the value being set.
        $Name
    )
    
    if( -not (Test-RegistryKeyValue -Path $Path -Name $Name) )
    {
        return $null
    }
    
    $itemProperties = Get-ItemProperty -Path $Path -Name *
    return $itemProperties.$Name
}

function Install-RegistryKey
{
    <#
    .SYNOPSIS
    Creates a registry key.  If it already exists, does nothing.
    
    .DESCRIPTION
    Given the path to a registry key, creates the key and all its parents.  If the key already exists, nothing happens.
    
    .EXAMPLE
    Install-RegistryKey -Path 'hklm:\Software\Carbon\Test'
    
    Creates the `hklm:\Software\Carbon\Temp` registry key if it doesn't already exist.
    #>
    [CmdletBinding(SupportsShouldPRocess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key to create.
        $Path
    )
    
    if( -not (Test-Path -Path $Path -PathType Container) )
    {
        Write-Host "Creating registry key '$Path'."
        $null = New-Item -Path $Path -ItemType RegistryKey -Force
    }
}

function Remove-RegistryKeyValue
{
    <#
    .SYNOPSIS
    Removes a value from a registry key, if it exists.
    
    .DESCRIPTION
    If the given key doesn't exist, nothing happens.
    
    .EXAMPLE
    Remove-RegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'InstallPath'
    
    Removes the `InstallPath` value from the `hklm:\Software\Carbon\Test` registry key.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key where the value should be removed.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the value to remove.
        $Name
    )
    
    if( (Test-RegistryKeyValue -Path $Path -Name $Name) )
    {
        if( $pscmdlet.ShouldProcess( ('Item: {0} Property: {1}' -f $Path,$Name), 'Remove Property' ) )
        {
            Remove-ItemProperty -Path $Path -Name $Name
        }
    }
}

function Set-RegistryKeyValue
{
    <#
    .SYNOPSIS
    Sets a value in a registry key.
    
    .DESCRIPTION
    If the key doesn't exist, it is created.  If the value doesn't exist, it is created.
    
    .LINK
    Get-RegistryKeyValue
    
    .LINK
    Test-RegistryKeyValue
    
    .EXAMPLE
    Set-RegistryKeyValue -Path 'hklm:\Software\Carbon\Test -Name Status -String foobar 
    
    Creates the `Status` string value under the `hklm:\Software\Carbon\Test` key and sets its value to `foobar`.
    
    .EXAMPLE
    Set-RegistryKeyValue -Path 'hklm:\Software\Carbon\Test -Name ComputerName -String '%ComputerName%' -Expand
    
    Creates an expandable string.  When retrieving this value, environment variables will be expanded.
    
    .EXAMPLE
    Set-RegistryKeyValue -Path 'hklm:\Software\Carbon\Test -Name Movies -String ('Signs','Star Wars','Raiders of the Lost Ark')
    
    Sets a multi-string (i.e. array) value.
    
    .EXAMPLE
    Set-RegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'SomeBytes' -Binary ([byte[]]@( 1, 2, 3, 4)) 
    
    Sets a binary value (i.e. `REG_BINARY`).
    
    .EXAMPLE
    Set-RegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'AnInt' -DWord 48043
    
    Sets a binary value (i.e. `REG_DWORD`).
    
    .EXAMPLE
    Set-RegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'AnInt64' -QWord 9223372036854775807
    
    Sets a binary value (i.e. `REG_QWORD`).
    
    .EXAMPLE
    Set-RegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'UsedToBeAStringNowShouldBeDWord' -DWord 1 -Force
    
    Uses the `Force` parameter to delete the existing `UsedToBeAStringNowShouldBeDWord` before re-creating it.  This flag is useful if you need to change the type of a registry value.
    #>
    [CmdletBinding(SupportsShouldPRocess=$true,DefaultParameterSetName='String')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key where the value should be set.  Will be created if it doesn't exist.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the value being set.
        $Name,
        
        [Parameter(Mandatory=$true,ParameterSetName='String')]
        [string]
        # The value's data.  Creates a value for holding string data (i.e. `REG_SZ`).
        $String,
        
        [Parameter(ParameterSetName='String')]
        [Switch]
        # The string should be expanded when retrieved.  Creates a value for holding expanded string data (i.e. `REG_EXPAND_SZ`).
        $Expand,
        
        [Parameter(Mandatory=$true,ParameterSetName='Binary')]
        [byte[]]
        # The value's data.  Creates a value for holding binary data (i.e. `REG_BINARY`).
        $Binary,
        
        [Parameter(Mandatory=$true,ParameterSetName='DWord')]
        [int]
        # The value's data.  Creates a value for holding a 32-bit integer (i.e. `REG_DWORD`).
        $DWord,
        
        [Parameter(Mandatory=$true,ParameterSetName='QWord')]
        [long]
        # The value's data.  Creates a value for holding a 64-bit integer (i.e. `REG_QWORD`).
        $QWord,
        
        [Parameter(Mandatory=$true,ParameterSetName='MultiString')]
        [string[]]
        # The value's data.  Creates a value for holding an array of strings (i.e. `REG_MULTI_SZ`).
        $Strings,
        
        [Switch]
        # Removes and re-creates the value.  Useful for changing a value's type.
        $Force,
        
        [Switch]
        # If set, won't write any information about what values are being set.
        $Quiet
    )
    
    $value = $null
    $type = $pscmdlet.ParameterSetName
    switch ( $pscmdlet.ParameterSetName )
    {
        'String' 
        { 
            $value = $String 
            if( $Expand )
            {
                $type = 'ExpandString'
            }
        }
        'Binary' { $value = $Binary }
        'DWord' { $value = $DWord }
        'QWord' { $value = $QWord }
        'MultiString' { $value = $Strings }
    }
    
    if( -not $PSBoundParameters.ContainsKey( 'WhatIf' ) -and -not $Quiet )
    {
        Write-Host "Setting registry value '$Path@$Name'."
    }
    
    Install-RegistryKey -Path $Path
    
    if( $Force )
    {
        Remove-RegistryKeyValue -Path $Path -Name $Name 
    }
    
    if( Test-RegistryKeyValue -Path $Path -Name $Name )
    {
        Set-ItemProperty -Path $Path -Name $Name -Value $value
    }
    else
    {
        $null = New-ItemProperty -Path $Path -Name $Name -Value $value -PropertyType $type
    }
    
    
}

function Test-RegistryKeyValue
{
    <#
    .SYNOPSIS
    Tests if a registry value exists.
    
    .DESCRIPTION
    The usual ways for checking if a registry value exists don't handle when a value simply has an empty or null value.  This function actually checks if a key has a value with a given name.
    
    .EXAMPLE
    Test-RegistryKeyValue -Path 'hklm:\Software\Carbon\Test' -Name 'Title'
    
    Returns `True` if `hklm:\Software\Carbon\Test` contains a value named 'Title'.  `False` otherwise.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key where the value should be set.  Will be created if it doesn't exist.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the value being set.
        $Name
    )
    
    if( -not (Test-Path -Path $Path -PathType Container) )
    {
        return $false
    }
    
    $properties = Get-ItemProperty -Path $Path 
    if( -not $properties )
    {
        return $false
    }
    
    $member = Get-Member -InputObject $properties -Name $Name
    if( $member )
    {
        return $true
    }
    else
    {
        return $false
    }
    
}