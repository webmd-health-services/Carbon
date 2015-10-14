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

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Test-ShouldGetInstalledPrograms
{
    foreach( $program in (Get-ProgramInstallInfo) )
    {
        Assert-NotNull $program
        [Microsoft.Win32.RegistryKey]$key = $program.Key
        $valueNames = $key.GetValueNames()
        foreach( $property in (Get-Member -InputObject $program -MemberType Property) )
        {
            $propertyName = $property.Name

            if( $propertyName -eq 'Key' )
            {
                continue
            }

            $keyValue = $key.GetValue( $propertyName )
            $propertyValue = $program.$propertyName

            if( $propertyName -eq 'ProductCode' )
            {
                $propertyValue = Split-Path -Leaf -Path $key.Name
                [Guid]$guid = [Guid]::Empty
                [Guid]::TryParse( $propertyValue, [ref]$guid )
                $propertyValue = $guid
                $keyValue = $guid
            }
            elseif( $propertyName -eq 'User' )
            {
                if( $key.Name -match 'HKEY_USERS\\([^\\]+)\\' )
                {
                    $sddl = $Matches[1]
                    $sid = New-Object 'Security.Principal.SecurityIdentifier' $sddl
                    $propertyValue = $sid.Translate([Security.Principal.NTAccount]).Value
                    $keyValue = $propertyValue
                }
            }

            $typeName = $program.GetType().GetProperty($propertyName).PropertyType.Name
            if( $keyValue -eq $null )
            {
                if( $typeName -eq 'Int32' )
                {
                    $keyValue = 0
                }
                elseif( $typeName -eq 'Version' )
                {
                    $keyValue = $null
                }
                elseif( $typeName -eq 'DateTime' )
                {
                    $keyValue = [DateTime]::MinValue
                }
                elseif( $typeName -eq 'Boolean' )
                {
                    $keyValue = $false
                }
                elseif( $typeName -eq 'Guid' )
                {
                    $keyValue = [Guid]::Empty
                }
                else
                {
                    $keyValue = ''
                }
            }
            else
            {
                if( $typeName -eq 'DateTime' )
                {
                    if( $keyValue -match '^(\d{4})(\d{2})(\d{2})$' )
                    {
                        $keyValue = Get-Date -Year $Matches[1] -Month $Matches[2] -Day $Matches[3] -Hour 0 -Minute 0 -Second 0 -Millisecond 0
                    }
                    else
                    {
                        $keyValue = [DateTime]$keyValue
                    }
                }
                elseif( $typeName -eq 'Int32' )
                {
                    $intValue = 0
                    $keyValue = [Int32]::TryParse($keyValue, [ref] $intValue)
                    $keyValue = $intValue
                }
                elseif( $typeName -eq 'Version' )
                {
                    if( $keyValue -is [int32] )
                    {
                        $major = $keyValue -shr 24   # First 8 bits
                        $minor = ($keyValue -band 0x00ff0000) -shr 16  # bits 9 - 16
                        $build = $keyValue -band 0x0000ffff   # last 8 bits
                        $keyValue = New-Object 'Version' $major,$minor,$build
                    }
                    else
                    {
                        [Version]$version = $null
                        if( [Version]::TryParse($keyValue, [ref]$version) )
                        {
                            $keyValue = $version
                        }
                    }
                }
            }

            if( $keyValue -eq $null )
            {
                Assert-Null $propertyValue
            }
            else
            {
                Assert-Equal $keyValue $propertyValue ('{0}: {1}' -f $program.Key.Name,$propertyName)
            }
        }
    }
}

function Test-ShouldGetSpecificProgram
{
    $p = Get-ProgramInstallInfo | Select-Object -First 1
    $p2 = Get-ProgramInstallInfo $p.DisplayName
    Assert-NotNull $p2
    Assert-Equal $p $p2
}

function Test-ShouldSupportWildcardName
{
    $p = Get-ProgramInstallInfo | Select-Object -First 1
    $wildcard = $p.DisplayName.Substring(0,$p.DisplayName.Length - 1)
    $wildcard = '{0}*' -f $wildcard
    $p2 = Get-ProgramInstallInfo $wildcard
    Assert-NotNull $p2
    Assert-Equal $p $p2
}

