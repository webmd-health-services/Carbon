
$originalHostsFile = ''

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
    $originalHostsfile = Get-Content (Get-PathToHostsFile)
}

function TearDown
{
    Set-Content -Path (Get-PathToHostsFile) -Value $originalHostsFile
    Remove-Module Carbon
}

function Test-ShouldUpdateExistingHostsEntry
{
    $hostsEntry = '1.2.3.4  example.com'
    $hostsEntry | Out-HostsFile
    
    Assert-HostsFileContains -Line $hostsEntry
    
    Set-HostsEntry -IPAddress '5.6.7.8' -HostName 'example.com' -Description 'Customizing example.com'
    
    Assert-HostsFileContains -Line "5.6.7.8         example.com`t# Customizing example.com"  
}

function Test-ShouldAddNewHostsEntry
{
    $ip = '255.255.255.255'
    $hostname = 'shouldaddnewhostsentry.example.com'
    $description = 'testing if new hosts entries get added'
    
    Set-HostsEntry -IPAddress $ip -Hostname $hostname -Description $description
    
    Assert-HostsFileContains -Line "$ip $hostname`t# $description"
}

function Test-ShouldRemoveComment
{
    $ip = '1.1.1.1'
    $hostname = 'shouldremovecomment.example.com'
    
    "$ip $hostname  # this comment should get removed" | Out-HostsFile
    
    Set-HostsEntry -IPAddress $ip -HostName $hostname
   
    Assert-HostsFileContains -Line "$ip         $hostname"
}

function Test-ShouldCommentOutDuplicates
{
    $ip = '3.3.3.3'
    $hostname = 'shouldcommentoutduplicates.example.com'
    
    $line = "$ip $hostname"
    ($line,$line) | Out-HostsFile
    
    Set-HostsEntry -IPAddress $ip -HostName $hostname
    
    Assert-HostsFileContains -Line "$ip         $hostname"
    Assert-HostsFileContains -Line "#$ip $hostname"
}

function Test-ShouldSupportWhatIf
{
    Reset-HostsFile
    
    Set-HostsEntry -IPAddress '127.0.0.1' -Hostname 'example.com' -WhatIf
    
    Assert-HostsFileContains '127.0.0.1       localhost'
}

function Test-ShouldSetEntryInEmptyHostsFile
{
    Remove-Item (Get-PathToHostsFile)
    New-Item -Path (Get-PathToHostsFile) -ItemType File
    
    Set-HostsEntry -IPAddress '127.0.0.1' -Hostname 'example.com'
    
    Assert-HostsFileContains '127.0.0.1       example.com'
}

function Assert-HostsFileContains($Line)
{
    $hostsFile = Get-Content (Get-PathToHostsFile)
    Assert-Contains $hostsFile $Line "Hosts file"
}

filter Out-HostsFile
{
    process
    {
        $_ | Out-File (Get-PathToHostsFile) -Append -Encoding ASCII
    }
}