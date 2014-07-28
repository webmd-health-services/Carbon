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
        Write-Verbose "Setting registry value '$Path@$Name'."
    }
    
    $commonParams = @{
                        ErrorAction = $ErrorActionPreference;
                        Verbose = $VerbosePreference;
                        WhatIf = $WhatIfPreference;
                    }
    
    Install-RegistryKey -Path $Path @commonParams
    
    if( $Force )
    {
        Remove-RegistryKeyValue -Path $Path -Name $Name @commonParams
    }

    if( Test-RegistryKeyValue -Path $Path -Name $Name )
    {
        Set-ItemProperty -Path $Path -Name $Name -Value $value @commonParams
    }
    else
    {
        $null = New-ItemProperty -Path $Path -Name $Name -Value $value -PropertyType $type @commonParams
    }
}
