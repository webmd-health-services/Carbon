

function SetUp()
{
    Import-Module (Join-Path $TestDir ..\Carbon -Resolve)
}

function TearDown()
{
    Remove-Module Carbon
}

function Test-ProcessesHaveParentProcessID
{
    Get-Process | % {
        Assert-IsNotNull $_.ParentProcessID "Process $($_.Name) does not have a parent."
    }
}