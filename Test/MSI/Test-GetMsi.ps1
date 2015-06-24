
& (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)

function Test-ShouldGetMsi
{
    $msi = Get-Msi -Path (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonNoOpMsi.msi' -Resolve)
}

function Test-ShouldAcceptPipelineInput
{
    $msi = Get-ChildItem -Path $PSScriptRoot -Filter *.msi | Get-Msi
    Assert-CarbonMsi $msi
}

function Test-ShouldAcceptArrayOfStrings
{
    $path = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonNoOpMsi.msi'

    $msi = Get-Msi -Path @( $path, $path )
    Assert-Is $msi ([object[]])
    foreach( $item in $msi )
    {
        Assert-CarbonMsi $item
    }
}

function Test-ShouldAcceptArrayOfFileInfo
{
    $path = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonNoOpMsi.msi'

    $item = Get-Item -Path $path
    $msi = Get-Msi -Path @( $item, $item )

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
    Assert-Equal 'Carbon NoOp' $msi.ProductName
    Assert-Equal ([Guid]'{E1724ABC-A8D6-4D88-BBED-2E077C9AE6D2}') $msi.ProductCode
    Assert-Equal 1033 $msi.ProductLanguage
    Assert-Equal '1.0.0' $msi.ProductVersion
    Assert-NotNull $msi.Properties
    Assert-Equal 32 $msi.Properties.Count
}