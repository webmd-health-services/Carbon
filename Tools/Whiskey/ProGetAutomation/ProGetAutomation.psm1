
Add-Type -AssemblyName 'System.Net.Http'
Add-Type -AssemblyName 'System.Web'
Add-Type -AssemblyName 'System.IO.Compression.FileSystem'

Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Functions') -Filter '*.ps1' |
    ForEach-Object { . $_.FullName }
