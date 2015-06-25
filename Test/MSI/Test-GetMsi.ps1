
& (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)

function Test-ShouldGetMsi
{
    $msi = Get-Msi -Path (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestInstaller.msi' -Resolve)
}

function Test-ShouldAcceptPipelineInput
{
    $msi = Get-ChildItem -Path $PSScriptRoot -Filter *.msi | Get-Msi
    Assert-NotNull $msi
    $msi | ForEach-Object {  Assert-CarbonMsi $_ }
}

function Test-ShouldAcceptArrayOfStrings
{
    $path = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestInstaller.msi'

    $msi = Get-Msi -Path @( $path, $path )
    Assert-Is $msi ([object[]])
    foreach( $item in $msi )
    {
        Assert-CarbonMsi $item
    }
}

function Test-ShouldAcceptArrayOfFileInfo
{
    $path = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestInstaller.msi'

    $item = Get-Item -Path $path
    $msi = Get-Msi -Path @( $item, $item )

    Assert-Is $msi ([object[]])
    foreach( $item in $msi )
    {
        Assert-CarbonMsi $item
    }
}

function Test-ShouldSupportWildcards
{
    $msi = Get-Msi -Path (Join-Path -Path $PSScriptRoot -ChildPath '*.msi')
    Assert-Is $msi ([object[]])
    foreach( $item in $msi )
    {
        Assert-CarbonMsi $item
    }
}

function Assert-CarbonMsi
{
    param(
        $msi
    )

    Assert-NotNull $msi
    Assert-Is $msi ([Carbon.Msi.MsiInfo])
    Assert-Equal 'Carbon' $msi.Manufacturer
    Assert-Like $msi.ProductName 'Carbon *' 
    Assert-NotNull $msi.ProductCode
    Assert-NotEqual $msi.ProductCode ([Guid]::Empty)
    Assert-Equal 1033 $msi.ProductLanguage
    Assert-Equal '1.0.0' $msi.ProductVersion
    Assert-NotNull $msi.Properties
    Assert-GreaterThan $msi.Properties.Count 5
}