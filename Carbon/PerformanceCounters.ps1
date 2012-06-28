# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Get-PerformanceCounters
{
    <#
    .SYNOPSIS
    Gets the performance counters for a category.

    .DESCRIPTION
    Returns [PerformanceCounterCategory]() objects for the given category name.  If not counters exist for the category exits, an empty array is returned.

    .OUTPUTS
    System.Diagnostics.PerformanceCounterCategory.

    .EXAMPLE
    Get-PerformanceCounters -CategoryName Processor

    Gets all the `Processor` performance counters.
    #>
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
    <#
    .SYNOPSIS
    Installs a performance counter.

    .DESCRIPTION
    Creates a new performance counter with a specific name, description, and type under a given category.  The counter's category is re-created: its current counters are retrieved, the category is removed, a the category is re-created.  Unfortunately, we haven't been able to find any .NET APIs that allow us to delete and create an existing counter.

    .EXAMPLE
    Install-PerformanceCounter -CategoryName ToyotaCamry -Name MilesPerGallon -Description 'The miles per gallon fuel efficiency.' -Type NumberOfItems32

    Creates a new miles per gallon performance counter for the ToyotaCamry category.
    #>
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
