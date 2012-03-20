
$siteName = 'DefaultDocument'
$sitePort = 4387
$webConfigPath = Join-Path $TestDir web.config

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
    Remove-IisWebsite $siteName
    Install-IisWebsite -Name $siteName -Path $TestDir -Bindings "http://*:$sitePort"
    if( Test-Path $webConfigPath -PathType Leaf )
    {
        Remove-Item $webConfigPath
    }
}

function TearDown
{
    Remove-IisWebsite $siteName
    Remove-Module Carbon
}

function Test-ShouldAddDefaultDocument
{
    Add-IISDefaultDocument -Site $SiteName -FileName 'NewWebsite.html'
    Assert-DefaultDocumentReturned
    Assert-FileDoesNotExist $webConfigPath "Settings were made in site web.config, not apphost.config."
}

function Test-ShouldAddDefaultDocumentTwice
{
    Add-IISDefaultDocument -Site $SiteName -FileName 'NewWebsite.html'
    Add-IISDefaultDocument -Site $SiteName -FileName 'NewWebsite.html'
    Assert-DefaultDocumentReturned
}

function Assert-DefaultDocumentReturned()
{
    $html = ''
    $maxTries = 10
    $tryNum = 0
    $defaultDocumentReturned = $false
    do
    {
        try
        {    
            $browser = New-Object Net.WebClient
            $html = $browser.downloadString( "http://localhost:$sitePort/" )
            Assert-Like $html 'NewWebsite Test Page' 'Unable to download from new website.'   
            $defaultDocumentReturned = $true
        }
        catch
        {
            Start-Sleep -Milliseconds 100
        }
        $tryNum += 1
    }
    while( $tryNum -lt $maxTries -and -not $defaultDocumentReturned )
    
    Assert-True $defaultDocumentReturned "Default document never returned."
}