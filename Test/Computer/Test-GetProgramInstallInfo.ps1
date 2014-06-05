
function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
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
            $typeName = $program.GetType().GetProperty($propertyName).PropertyType.Name
            if( $keyValue -eq $null )
            {
                if( $typeName -eq 'Int32' )
                {
                    $keyValue = 0
                }
                elseif( $typeName -eq 'DateTime' )
                {
                    $keyValue = [DateTime]::MinValue
                }
                elseif( $typeName -eq 'Boolean' )
                {
                    $keyValue = $false
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
                        $keyValue = Get-date -Year $Matches[1] -Month $Matches[2] -Day $Matches[3] -Hour 0 -Minute 0 -Second 0 -Millisecond 0
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
            }
            Assert-Equal $keyValue $propertyValue ('{0}: {1}' -f $program.Key.Name,$propertyName)
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