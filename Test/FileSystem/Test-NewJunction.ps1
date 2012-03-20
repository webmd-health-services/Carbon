
Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force

$JunctionPath = $null

function SetUp
{
    $Script:JunctionPath = Join-Path $env:Temp ([IO.Path]::GetRandomFileName())
}

function TearDown
{
    fsutil reparsepoint delete $Script:JunctionPath
}

function Invoke-NewJunction($link, $target)
{
    return New-Junction $link $target
}

function Test-ShouldCreateJunction
{
    $result = Invoke-NewJunction $JunctionPath $TestDir
    Assert-NotNull $result 'Did not get a result from New-Junction'
    Assert-DirectoryExists $JunctionPath
    Assert-Like $result.Attributes ReparsePoint 'Junction not created as a junction.'
}

function Test-ShouldNotCreateJunctionIfLinkIsDirectory
{
    $error.Clear()
    $result = Invoke-NewJunction $TestDir $env:Temp 2> $null
    Assert-Equal 1 @($error).Length "Didn't write an error if a junction already exists."
    Assert-Null $result "Returned a non-null object when failing to create a junction."
}

function Test-ShouldNotCreateJunctionIfJunctionAlreadyExists
{
    $error.Clear()
    Invoke-NewJunction $JunctionPath $TestDir
    Assert-Equal 0 @($error).Length "Got an error creating a junction."
    
    $result = Invoke-NewJunction $JunctionPath $env:Temp 2> $null
    Assert-Equal 1 @($error).Length "Didn't get an error failing to create a junction."
    Assert-Null $result 'Returned a non-null object when creating a junction that already exists.'
}