
$importCarbonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\Import-Carbon.ps1' -Resolve

function Start-Test
{
    if( (Get-Module 'Carbon') )
    {
        Remove-Module 'Carbon'
    }
}

function Test-ShouldImport
{
    & $importCarbonPath
    Assert-NotNull (Get-Command -Module 'Carbon')
}

function Test-ShouldImportWithPrefix
{
    & $importCarbonPath -Prefix 'C'
    $carbonCmds = Get-Command -Module 'Carbon'
    Assert-NotNull $carbonCmds
    foreach( $cmd in $carbonCmds )
    {
        Assert-Match $cmd.Name '^.+-C.+$'
    }
}