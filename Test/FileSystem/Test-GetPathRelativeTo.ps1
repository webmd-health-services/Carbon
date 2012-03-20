
function SetUp()
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve)
}

function TearDown()
{
    Remove-Module Carbon
}

function Test-GetPathRelativeToWithExplicitPath
{
    $fileDir = New-TempDir
    $to = Join-Path $fileDir 'myfile.txt'
    
    $from = [System.IO.Path]::GetTempPath()
    
    $relativePath = Get-PathRelativeTo $from -To $to
    Assert-Equal ".\$([System.IO.Path]::GetFileName($fileDir))\myfile.txt" $relativePath 
}

function Test-GetPathRelativeToFromPipeline
{
    $to = [System.IO.Path]::GetFullPath( (Join-Path $TestDir '..\..\FileSystem.ps1') )
    
    $relativePath = Get-Item $to | Get-PathRelativeTo $TestDir
    Assert-Equal '..\..\FileSystem.ps1' $relativePath
}

function Test-GetsPathFromFilePath
{
    $to = [System.IO.Path]::GetFullPath( (Join-Path $TestDir '..\..\FileSystem.ps1') )
    
    $relativePath = Get-Item $to | Get-PathRelativeTo $TestScript 'File'
    Assert-Equal '..\..\FileSystem.ps1' $relativePath
}

function Test-GetsRelativePathForMultiplePaths
{

    Get-ChildItem $env:WinDir | Get-PathRelativeTo -From (Join-Path $env:WinDir 'System32') 
}

function Test-GetsRelativePathFromFile
{
    $relativePath = Get-PathRelativeTo 'C:\Foo\Foo\Foo.txt' 'File' -To 'C:\Bar\Bar\Bar'
    Assert-Equal '..\..\Bar\Bar\Bar' $relativePath
}

function Test-ShouldReturnString
{
    $relativePath = Get-PathRelativeTo 'C:\A\B\C' -To 'C:\A\B\D\f.txt'
    Assert-Is $relativePath string
    Assert-Equal '..\D\F.txt' $relativePath
}
