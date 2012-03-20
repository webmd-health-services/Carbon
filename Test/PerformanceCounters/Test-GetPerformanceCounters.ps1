
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
}

function Test-ShouldGetPerformanceCounters
{
    $categories = [Diagnostics.PerformanceCounterCategory]::GetCategories() 
    foreach( $category in $categories )
    {
        $countersExpected = $category.GetCounters("")
        $countersActual = Get-PerformanceCounters -CategoryName $category.CategoryName
        Assert-Equal $countersExpected.Length $countersActual.Length
    }
    
}

function Test-ShouldGetNoPerformanceCountersForNonExistentCategory
{
    $counters = Get-PerformanceCounters -CategoryName 'IDoNotExist'
    Assert-Equal 0 $counters.Length
}
