
$Port = 9878
$SiteName = 'TestVirtualDirectory'
$VDirName = 'VDir'
$WebConfig = Join-Path $TestDir web.config

function SetUp
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve)

    Remove-IisWebsite -Name $SiteName
    Install-IisWebsite -Name $SiteName -Path $TestDir -Bindings "http://*:$Port"
    if( Test-Path $WebConfig )
    {
        Remove-Item $WebConfig
    }
}

function TearDown
{
    Remove-IisWebsite -Name $SiteName
    Remove-Module Carbon
}

function Invoke-NewVirtualDirectory($Path = $TestDir)
{
    Install-IisVirtualDirectory -SiteName $SiteName -Name $VDirName -Path $Path
    Assert-LastProcessSucceeded 'Failed to create virtual directory.'
}

function Test-ShouldCreateVirtualDirectory
{
    Invoke-NewVirtualDirectory
    Assert-VirtualDirectoryRunning
}

function Test-ShouldDeleteExistingVirtualDirectory
{
    Invoke-NewVirtualDirectory -Path $env:SystemRoot
    Invoke-NewVirtualDirectory
    Assert-VirtualDirectoryRunning
}

function Test-ShouldTurnOnDirectoryBrowsing
{
    Invoke-NewVirtualDirectory
    Set-IisDirectoryBrowsing -SiteName $SiteName -Directory $VDirName
    Assert-LastProcessSucceeded 'Failed to enable directory browsing.'
    Assert-FileDoesNotExist $WebConfig 'Changes not committed to apphost config level.'
    $output = Read-Url "http://localhost:$Port/$VDirName"
    Assert-ContainsLike $output 'NewWebsite.html' "Didn't get directory list."
}

function Assert-VirtualDirectoryRunning($vdir)
{
    $html = Read-Url "http://localhost:$Port/$vdir/NewWebsite.html"
    Assert-Like $html 'NewWebsite Test Page' 'Unable to download from new virtual directory.'   
}

function Read-Url($Url)
{
    $browser = New-Object Net.WebClient
    $numTries = 0
    $maxTries = 5
    do
    {
        try
        {
            return $browser.downloadString( $Url )
        }
        catch
        {
            Write-Verbose "Error downloading '$Url': $_"
            $numTries++
            Start-Sleep -Milliseconds 100
        }
    }
    while( $numTries -lt $maxTries )
}