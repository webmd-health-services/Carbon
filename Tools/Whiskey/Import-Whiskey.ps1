
$VerbosePreference = 'SilentlyContinue'

if( (Get-Module -Name 'Whiskey') )
{
    Remove-Module -Name 'Whiskey' -Force
}

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Whiskey.psd1' -Resolve)
