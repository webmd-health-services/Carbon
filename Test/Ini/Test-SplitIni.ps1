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

$iniPath = $null

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    $iniPath = [IO.Path]::GetRandomFileName()
    $iniContent = @"
[section1]
option1=value1
option2 = value2

[section2]

[section3]
option3=v
   a
   l
   u
   e
   3
[section4]
# Comment
option4=value4 # No comments accepted
;another comment

option5=value5

[section1]
option6 = option 6 and other values =
option2 = value7

[section5]
option1=value8
"@
    
    $iniContent > $iniPath
}

function Stop-Test
{
    Remove-Item $iniPath
}

function Test-ShouldReadIniAsHashtable
{
    $ini = Split-Ini -Path $iniPath -AsHashtable
    Assert-NotNull $ini
    Assert-IniContains -Ini $ini -Section 'section1' -Name 'option1' -Value 'value1' -LineNumber 2
    Assert-IniContains -Ini $ini -Section 'section1' -Name 'option2' -Value 'value7' -LineNumber 23
    Assert-IniContains -Ini $ini -Section 'section3' -Name 'option3' -Value "v`na`nl`nu`ne`n3" -LineNumber 8
    Assert-IniContains -Ini $ini -Section 'section4' -Name 'option4' -Value 'value4 # No comments accepted' -LineNumber 16
    Assert-IniContains -Ini $ini -Section 'section4' -Name 'option5' -Value 'value5' -LineNumber 19
    Assert-IniContains -Ini $ini -Section 'section1' -Name 'option6' -Value 'option 6 and other values =' -LineNumber 22
    Assert-IniContains -Ini $ini -Section 'section5' -Name 'option1' -Value 'value8' -LineNumber 26
}

function Test-ShouldFailIfInvalidPath
{
    $error.Clear()
    $ini = Split-Ini -Path "C:\$([Guid]::NewGuid())" -ErrorAction SilentlyContinue
    Assert-Null $ini
    Assert-Equal 1 $error.Count
}

function Test-ShouldReturnObjectForEachValue
{
    $ini = Split-Ini -Path $iniPath
    Assert-Equal 'System.Object[]' $ini.GetType()
    Assert-Equal 8 $ini.Length
    Assert-Equal 'section1.option1' $ini[0].FullName
    Assert-Equal 'section1.option2' $ini[1].FullName
    Assert-Equal 'section3.option3' $ini[2].FullName
    Assert-Equal 'section4.option4' $ini[3].FullName
    Assert-Equal 'section4.option5' $ini[4].FullName
    Assert-Equal 'section1.option6' $ini[5].FullName
    Assert-Equal 'section1.option2' $ini[6].FullName
    Assert-Equal 'section5.option1' $ini[7].FullName
}

function Test-ShouldSplitIniWithoutSections
{
    @"
name=value
name2=value2

# Comment
name3 = value3
"@ > $iniPath

    $ini = Split-Ini -Path $iniPath -AsHashtable
    Assert-NotNull $ini
    Assert-IniContains -Ini $ini -Name 'name' -Value 'value' -LineNumber 1
    Assert-IniContains -Ini $ini -Name 'name2' -Value 'value2' -LineNumber 2
    Assert-IniContains -Ini $ini -Name 'name3' -Value 'value3' -LineNumber 5
}

function Test-ShouldSplitIniWithAndWithoutSections
{
    @"
name=value
name2=value2

[section]
# Comment
name3 = value3
"@ > $iniPath

    $ini = Split-Ini -Path $iniPath -AsHashtable
    Assert-NotNull $ini
    Assert-IniContains -Ini $ini -Name 'name' -Value 'value' -LineNumber 1
    Assert-IniContains -Ini $ini -Name 'name2' -Value 'value2' -LineNumber 2
    Assert-IniContains -Ini $ini -Name 'name3' -Value 'value3' -Section 'section' -LineNumber 6
}

function Test-ShouldSupportCaseSensitiveIniFiles
{
    @"
name = a
NAME = b

[section]
name1 = c
NAME1 = d

[SECTION]
name1 = e
NAME1 = f
"@ | Set-Content -Path $iniPath

    $ini = Split-Ini -Path $iniPath -AsHashtable -CaseSensitive
    Assert-NotNull $ini
    Assert-Equal 6 $ini.Count
    Assert-True $ini.ContainsKey('name')
    Assert-Equal 'a'  $ini['name'].Value
    Assert-True $ini.ContainsKey('NAME')
    Assert-Equal 'b'  $ini['NAME'].Value
    Assert-True $ini.ContainsKey('section.name1')
    Assert-Equal 'c'  $ini['section.name1'].Value
    Assert-True $ini.ContainsKey('section.NAME1')
    Assert-Equal 'd'  $ini['section.NAME1'].Value
    Assert-True $ini.ContainsKey('SECTION.name1')
    Assert-Equal 'e'  $ini['SECTION.name1'].Value
    Assert-True $ini.ContainsKey('SECTION.NAME1')
    Assert-Equal 'f'  $ini['SECTION.NAME1'].Value

    $ini = Split-Ini -Path $iniPath
    Assert-NotNull $ini
    Assert-Equal 6 $ini.Count
}

function Assert-IniContains
{
    param(
        [Collections.Hashtable]
        $Ini,
        [string]
        $Section,
        [string]
        $Name,
        [string]
        $Value,
        [int]
        $LineNumber
    )
    
    $key = "$Name"
    if( $Section )
    {
        $key = "$Section.$Name"
    }
    Assert-True $Ini.ContainsKey( $key ) "Missing key '$key'"
    Assert-Equal $key $Ini[$key].FullName
    Assert-Equal $Section $Ini[$key].Section
    Assert-Equal $Name $Ini[$key].Name
    Assert-Equal $Value $Ini[$key].Value
    Assert-Equal $LineNumber $Ini[$key].LineNumber
}

