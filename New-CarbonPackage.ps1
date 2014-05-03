[CmdletBinding()]
param(
)

Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\Import-Carbon.ps1' -Resolve)

$tempDir = New-TempDir
$libDir = Join-Path -Path $tempDir -ChildPath 'lib'
$contentDir = Join-Path -Path $tempDir -ChildPath 'content'
$toolsDir = Join-Path -Path $tempDir -ChildPath 'tools'

foreach( $contentSource in @( 'Carbon', 'Website', 'Examples' ) )
{
    Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath $contentSource)  `
              -Destination (Join-Path -Path $contentDir -ChildPath $contentSource) `
              -Recurse
}

foreach( $file in @( '*.txt', 'Carbon.nuspec' ) )
{
    Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath $file) `
              -Destination $tempDir
}

Push-Location $tempDir
try
{
    $nugetPath = Join-Path -Path $PSScriptRoot -ChildPath 'Tools\NuGet-2.8\NuGet.exe' -Resolve
    & $nugetPath pack '.\Carbon.nuspec' -BasePath '.'

    & $nugetPath push (Join-Path -Path $tempDir -ChildPath 'Carbon*.nupkg')
    #$outDir = New-TempDir
    #& $nugetPath install 'Carbon' -Source $tempDir -OutputDirectory $outDir


}
finally
{
    Pop-Location
    Remove-Item -Recurse $tempDir
    #Remove-Item -Recurse $outDir
}