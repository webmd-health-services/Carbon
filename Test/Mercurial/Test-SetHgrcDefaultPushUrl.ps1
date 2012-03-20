
$RepoDir = $null
$hgrc = $null

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force

    $RepoDir = Join-Path $env:TEMP ([IO.Path]::GetRandomFileName())
    $hgDir = JOin-Path $RepoDir .hg
    $hgrcPath = Join-Path $hgDir hgrc
    New-Item $RepoDir -ItemType Directory
    New-Item $hgDir -ItemType Directory
}

function TearDown
{
    Remove-Item $RepoDir -Recurse
    Remove-Module Carbon
}

function Invoke-SetHgrcDefaultPushUrl
{
    [CmdletBinding()]
    param(
        $RepoPath = $RepoDir, 
        $Url
    )
    
    Set-HgrcDefaultPushUrl -RepoPath $RepoPath -DefaultPushUrl $Url
}

function Test-AddsDefaultPushToHgrc
{
    Out-File $hgrcPath -Encoding ASCII -InputObject ""
    
    Invoke-SetHgrcDefaultPushUrl -Url 'AddsDefaultPushToHgrc'

    Assert-DefaultPushUrl 'AddsDefaultPushToHgrc'
}

function Test-UpdatesDefaultPushUrl
{
    Out-File $hgrcPath -Encoding ASCII -InputObject "default-push = BAdUrl"
    
    Invoke-SetHgrcDefaultPushUrl -Url 'Assert-DefaultPushUrl '
    
    Assert-DefaultPushUrl 'Assert-DefaultPushUrl '
}

function Test-ShouldFailIfNotARepo
{
    $error.Clear()
    $result = Set-HgrcDefaultPushUrl -RepoPath $env:WINDIR -DefaultPushUrl 'DoesNoMatter' -ErrorAction SilentlyContinue
    Assert-False $result 'succeeded to set .hg\hgrc in non-repo'
    Assert-Equal 1 $error.Count 'error wasn''t thrown'
    Assert-Like $error[0] "isn't a Mercurial repository" "expected error wasn't thrown"
}

function Test-UpdateDfaultPushUrlInTypicalHgrc
{
    Out-File $hgrcPath -Encoding ASCII -InputObject "[paths]`ndefault = \\pdxhg\Repositories\DoesNotMatter"
    
    Invoke-SetHgrcDefaultPushUrl -Url 'UpdatesDefaultPushUrl'
    
    Assert-DefaultPushUrl 'UpdatesDefaultPushUrl'
}

function Test-ShouldSupportWhatIf
{
    Out-File $hgrcPath -Encoding ASCII -INputObject "[paths]`ndefault-push = DoesNotMatter"
    
    Set-HgrcDefaultPushUrl -RepoPath $RepoDir -DefaultPushUrl 'ANewUrl' -WhatIf
    
    Assert-DefaultPushUrl 'DoesNotMatter'
}

function Assert-DefaultPushUrl
{
    param(
        $ExpectedDefaultPushUrl
    )
    
    $hgrc = Split-Ini -Path $hgrcPath
    Assert-Equal $ExpectedDefaultPushUrl ($hgrc['paths.default-push'].Value) 'Default-push URL not set.'
}