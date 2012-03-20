
$originalHostsFile = ''

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
    $originalHostsfile = Get-Content (Get-PathToHostsFile)
}

function TearDown
{
    Set-Content -Path (Get-PathToHostsFile) -Value $originalHostsFile
}

function Test-ShouldRemoveCustomHostsEntry
{
    $commentLine = '# Below are all my custom host entries.'
    $commentLine >> (Get-PathToHostsFile)
    $customEntry = "10.1.1.1     example.com"
    $customEntry >> (Get-PathToHostsFile)
    Reset-HostsFile
    $hostsFile = Get-Content -Path (Get-PathToHostsFile)
    Assert-DoesNotContain $hostsFile $commentLine
    Assert-DoesNotContain $hostsFile $customEntry
    Assert-Contains $hostsFile '127.0.0.1       localhost'
}

function Test-ShouldSupportShouldProcess
{
    $customEntry = '1.2.3.4       example.com'
    $customEntry >> (Get-PathToHostsFile)
    Reset-HostsFile -WhatIf
    Assert-Contains (Get-Content -Path (Get-PathToHostsFile)) $customEntry
}

function Test-ShouldResetCustomHostsFile
{
    $hostsFilePath = (Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName()) )
    Set-Content -Path $hostsFilePath -Value "# Line 1`n# Line 2`n1.2.3.4`texample.com"
    try
    {
        Reset-HostsFile -Path $hostsFilePath
        $hostsFile = Get-Content -Path $hostsFilePath
        Assert-DoesNotContain $hostsFile '1.2.3.4`texample.com'
        Assert-Contains $hostsFile '# Line 1' 
        Assert-Contains $hostsFile '# Line 2' 
    }
    finally
    {
        Remove-Item $hostsFilePath
    }
}