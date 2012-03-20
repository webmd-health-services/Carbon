
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldGetCanonicalCaseForDirectory
{
    $currentDir = (Resolve-Path '.').Path
    $canonicalCase = Get-PathCanonicalCase ($currentDir.ToUpper())
    Assert-True ($currentDir -ceq $canonicalCase)
}

function Test-ShouldGetCanonicalCaseForFile
{
    $currentFile = Join-Path $TestDir 'Test-GetPathCanonicalCase.ps1' -Resolve
    $canonicalCase = Get-PathCanonicalCase -Path ($currentFile.ToUpper())
    Assert-True ($currentFile -ceq $canonicalCase)
}

function Test-ShouldNotGetCaseForFileThatDoesNotExist
{
    $error.Clear()
    $result = Get-PathCanonicalCase 'C:\I\Do\Not\Exist' -ErrorAction SilentlyContinue
    Assert-False $result
    Assert-Equal 1 $error.Count
}