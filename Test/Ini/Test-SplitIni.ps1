
$iniPath = $null

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
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

function TearDown
{
    Remove-Item $iniPath
    Remove-Module Carbon
}

function Test-ShouldReadIni
{
    $ini = Split-Ini -Path $iniPath
    Assert-NotNull $ini
    Assert-IniContains -Ini $ini -Section 'section1' -Name 'option1' -Value 'value1' -LineNumber 1
    Assert-IniContains -Ini $ini -Section 'section1' -Name 'option2' -Value 'value7' -LineNumber 22
    Assert-IniContains -Ini $ini -Section 'section3' -Name 'option3' -Value "v`na`nl`nu`ne`n3" -LineNumber 7
    Assert-IniContains -Ini $ini -Section 'section4' -Name 'option4' -Value 'value4 # No comments accepted' -LineNumber 15
    Assert-IniContains -Ini $ini -Section 'section4' -Name 'option5' -Value 'value5' -LineNumber 18
    Assert-IniContains -Ini $ini -Section 'section1' -Name 'option6' -Value 'option 6 and other values =' -LineNumber 21
    Assert-IniContains -Ini $ini -Section 'section5' -Name 'option1' -Value 'value8' -LineNumber 25
}

function Test-ShouldFailIfInvalidPath
{
    $error.Clear()
    $ini = Split-Ini -Path "C:\$([Guid]::NewGuid())" -ErrorAction SilentlyContinue
    Assert-Null $ini
    Assert-Equal 1 $error.Count
}

function Test-ShouldPassThruItems
{
    $ini = Split-Ini -Path $iniPath -PassThru
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

    $ini = Split-Ini -Path $iniPath
    Assert-NotNull $ini
    Assert-IniContains -Ini $ini -Name 'name' -Value 'value' -LineNumber 0
    Assert-IniContains -Ini $ini -Name 'name2' -Value 'value2' -LineNumber 1
    Assert-IniContains -Ini $ini -Name 'name3' -Value 'value3' -LineNumber 4
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

    $ini = Split-Ini -Path $iniPath
    Assert-NotNull $ini
    Assert-IniContains -Ini $ini -Name 'name' -Value 'value' -LineNumber 0
    Assert-IniContains -Ini $ini -Name 'name2' -Value 'value2' -LineNumber 1
    Assert-IniContains -Ini $ini -Name 'name3' -Value 'value3' -Section 'section' -LineNumber 5
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