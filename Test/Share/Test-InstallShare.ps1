
$ShareName = 'New Share Test'
$SharePath = $TestDir

function SetUp
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve)

    Remove-Share
}

function TearDown
{
    Remove-Share
    
    Remove-Module Carbon
}

function Remove-Share
{
    $share = Get-Share
    if( $share -ne $null )
    {
        $share.Delete()
    }
}

function Invoke-NewShare($Permissions = @(), $Remarks = '')
{
    Install-Share -Name $ShareName -Path $TestDir -Permissions $Permissions -Description $Remarks
    Assert-ShareCreated
}

function Get-Share
{
    return Get-WmiObject Win32_Share -Filter "Name='$ShareName'"
}


function Test-ShouldCreateShare
{
    Invoke-NewShare
}

function Test-ShouldGrantPermissions
{
    Invoke-NewShare -Permissions 'ADMINISTRATORs,FULL'
    $details = net share """$ShareName"""
    Assert-ContainsLike $details "BUILTIN\Administrators, FULL" 'Permissions not set on share.'
}

function Test-ShouldDeleteThenRecreateShare
{
    Invoke-NewShare -Permissions 'Administrators,FULL'
    
    Invoke-NewShare
    $details = net share """$ShareName"""
    Assert-ContainsNotLike $details "Administrators, FULL" "Share not deleted and re-created."
}

function Test-ShouldSetRemarks
{
    $expectedRemarks = 'Hello, workd.'
    Invoke-NewShare -Remarks $expectedRemarks
    
    $details = Get-Share
    Assert-Equal $expectedRemarks $details.Description 'Share description not set.'
}

function Test-ShouldHandlePathWithTrailingSlash
{
    Install-Share $ShareName -Path "$TestDir\"
    
    Assert-ShareCreated
}

function Assert-ShareCreated
{
    $share = Get-Share
    Assert-NotNull $share "Share not created."
}