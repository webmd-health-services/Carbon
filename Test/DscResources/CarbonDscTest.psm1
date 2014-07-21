
$CarbonDscOutputRoot = $null

function Start-CarbonDscTestFixture
{

    $tempDir = [IO.Path]::GetRandomFileName()
    $tempDir = 'CarbonDscTest-{0}-{1}' -f $Name,$tempDir
    $script:CarbonDscOutputRoot = Join-Path -Path $env:TEMP -ChildPath $tempDir

    New-Item -Path $CarbonDscOutputRoot -ItemType 'directory'

    Clear-DscLocalResourceCache
}

function Stop-CarbonDscTestFixture
{

    if( (Test-Path -Path $CarbonDscOutputRoot -PathType Container) )
    {
        Remove-Item -Path $CarbonDscOutputRoot -Recurse
    }
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

    Start-DscConfiguration -Wait -ComputerName 'localhost' -Verbose:$VerbosePreference
}

function Assert-DscResourcePresent
{
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $Resource
    )

    Set-StrictMode -Version 'Latest'

    Assert-Equal 'Present' $Resource.Ensure
}

function Assert-DscResourceAbsent
{
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $Resource
    )

    Set-StrictMode -Version 'Latest'

    Assert-Equal 'Absent' $Resource.Ensure
}


Export-ModuleMember -Function '*-*' -Variable 'CarbonDscOutputRoot'