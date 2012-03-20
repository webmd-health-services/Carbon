
function Get-PerformanceCounters
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The category's name whose performance counters will be returned.
        $CategoryName
    )
    
    if( (Test-PerformanceCounterCategory -CategoryName $CategoryName) )
    {
        $category = New-Object Diagnostics.PerformanceCounterCategory $CategoryName
        return ,@($category.GetCounters(""))
    }
    else
    {
        return ,@()
    }
}

function Install-PerformanceCounter
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The category's name where the counter will be created.
        $CategoryName,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The performance counter's name.
        $Name,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The performance counter's description (i.e. help message).
        $Description,
        
        [Parameter(Mandatory=$true)]
        [Diagnostics.PerformanceCounterType]
        # The performance counter's type (from the Diagnostics.PerformanceCounterType enumeration).
        $Type
    )
    
    $currentCounters = Get-PerformanceCounters -CategoryName $CategoryName
    
    $counters = New-Object Diagnostics.CounterCreationDataCollection 
    foreach( $counter in $currentCounters )
    {
        if( $counter.CounterName -eq $Name )
        {
            continue
        }
        $creationData = New-Object Diagnostics.CounterCreationData $counter.CounterName,$counter.CounterHelp,$counter.CounterType
        [void] $counters.Add( $creationData )
    }
    
    $newCounterData = New-Object Diagnostics.CounterCreationData $Name,$Description,$Type
    [void] $counters.Add( $newCounterData )
    
    if( $pscmdlet.ShouldProcess( $CategoryName, "install performance counter '$Name'" ) )
    {
        Uninstall-PerformanceCounterCategory -CategoryName $CategoryName
        Write-Host "Installing performance counter '$Name' in category '$CategoryName'."
        [void] [Diagnostics.PerformanceCounterCategory]::Create( $CategoryName, '', $counters )
    }
}

function Uninstall-PerformanceCounterCategory
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The performance counter's category name.
        $CategoryName
    )
    
    if( (Test-PerformanceCounterCategory -CategoryName $CategoryName) )
    {
        if( $pscmdlet.ShouldProcess( $CategoryName, 'uninstall performance counter category' ) )
        {
            [Diagnostics.PerformanceCounterCategory]::Delete( $CategoryName )
        }
    }
}

function Test-PerformanceCounter
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The category's name whose performance counters will be returned.
        $CategoryName,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The performance counter's name.
        $Name
    )
    
    if( (Test-PerformanceCounterCategory -CategoryName $CategoryName) )
    {
        return [Diagnostics.PerformanceCounterCategory]::CounterExists( $Name, $CategoryName )
    }
    
    return $false
}

function Test-PerformanceCounterCategory
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The category's name whose performance counters will be returned.
        $CategoryName
    )
    
    return [Diagnostics.PerformanceCounterCategory]::Exists( $CategoryName )
}


