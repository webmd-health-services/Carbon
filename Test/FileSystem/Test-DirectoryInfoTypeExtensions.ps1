
$junctionName = $null
$junctionPath = $null

function Setup
{
    Import-Module (Join-path $TestDir ..\..\Carbon -Resolve)
    $junctionName = [IO.Path]::GetRandomFilename()    
    $junctionPath = Join-Path $env:Temp $junctionName
    New-Junction -Link $junctionPath -Target $TestDir
}

function TearDown
{
    Remove-Junction -Path $junctionPath
    Remove-Module Carbon
}

function Test-ShouldAddIsJunctionProperty
{
    $dirInfo = Get-Item $junctionPath
    Assert-True $dirInfo.IsJunction
    
    $dirInfo = Get-Item $TestDir
    Assert-False $dirInfo.IsJunction
}

function Test-ShouldAddTargetPathProperty
{
    $dirInfo = Get-Item $junctionPath
    Assert-Equal $TestDir $dirInfo.TargetPath
    
    $dirInfo = Get-Item $Testdir
    Assert-Null $dirInfo.TargetPath
    
}