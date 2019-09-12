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

#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Get-ProgramInstallInfo.when getting all programs' {
    $programs = Get-ProgramInstallInfo
    It 'should get all installed programs' {
        $programs | Should -Not -BeNullOrEmpty
    }

    It ('should get information about each program') {
        foreach( $program in $programs )
        {
            Write-Verbose -Message $program.DisplayName
            $program | Should Not BeNullOrEmpty
            [Microsoft.Win32.RegistryKey]$key = $program.Key
            $valueNames = $key.GetValueNames()
            foreach( $property in (Get-Member -InputObject $program -MemberType Property) )
            {
                $propertyName = $property.Name
                Write-Verbose -Message ('  {0}' -f $propertyName)
                if( $propertyName -eq 'Version' )
                {
                    Write-Verbose 'BREAK'
                }
    
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
                        try
                        {
                            $propertyValue = $sid.Translate([Security.Principal.NTAccount]).Value
                        }
                        catch
                        {
                            $propertyValue = $sid.ToString()
                        }
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
                        [DateTime]$dateTime = [DateTime]::MinValue
    
                        if( -not ([DateTime]::TryParse($keyValue,[ref]$dateTime)) )
                        {
                            [DateTime]::TryParseExact( $keyValue, 'yyyyMMdd', [Globalization.CultureInfo]::CurrentCulture, [Globalization.DateTimeStyles]::None, [ref]$dateTime)
                        }
                        $keyValue = $dateTime
                    }
                    elseif( $typeName -eq 'Int32' )
                    {
                        $intValue = 0
                        $keyValue = [Int32]::TryParse($keyValue, [ref] $intValue)
                        $keyValue = $intValue
                    }
                    elseif( $typeName -eq 'Version' )
                    {
                        [int]$intValue = 0
                        if( $keyValue -isnot [int32] -and [int]::TryParse($keyValue,[ref]$intValue) )
                        {
                            $keyValue = $intValue
                        }

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
                    $propertyValue | Should BeNullOrEmpty
                }
                else
                {
                    $propertyValue | Should Be $keyValue
                }
            }
        }
    }
}

Describe 'Get-ProgramInstallInfo.when getting a program by name' {
    $p = Get-ProgramInstallInfo | Select-Object -First 1
    $p2 = Get-ProgramInstallInfo $p.DisplayName
    It 'should get just that program' {
        $p2 | Should Not BeNullOrEmpty
        $p2 | Should Be $p
    }
}   

Describe 'Get-ProgramInstallInfo.when getting programs by wildcard' {

    $p = Get-ProgramInstallInfo | Select-Object -First 1

    $wildcard = $p.DisplayName.Substring(0,$p.DisplayName.Length - 1)
    $wildcard = '{0}*' -f $wildcard
    $p2 = Get-ProgramInstallInfo $wildcard

    It 'should find the program' {
        $p2 | Should Not BeNullOrEmpty
        $p2 | Should Be $p
    }
}

Describe 'Get-ProgramInstallInfo.when there are invalid integer versions' {
    
    $program = Get-ProgramInstallInfo | Select-Object -First 1

    $regKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\CarbonGetProgramInstallInfo'
    Install-RegistryKey -Path $regKeyPath
    try
    {
        $name = 'Carbon+Get-ProgramInstallInfo'
        Set-RegistryKeyValue -Path $regKeyPath -Name 'DisplayName' -String $name
        Set-RegistryKeyValue -Path $regKeyPath -Name 'Version' -DWord 0xff000000

        $program = Get-ProgramInstallInfo -Name $name
        
        It 'should ignore the invalid version' {
            $program.Version | Should BeNullOrEmpty
        }
    }
    finally
    {
        Remove-Item -Path $regKeyPath -Recurse
    }
    

}
