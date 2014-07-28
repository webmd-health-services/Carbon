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

function Install-PerformanceCounter
{
    <#
    .SYNOPSIS
    Installs a performance counter.

    .DESCRIPTION
    Creates a new performance counter with a specific name, description, and type under a given category.  The counter's category is re-created: its current counters are retrieved, the category is removed, a the category is re-created.  Unfortunately, we haven't been able to find any .NET APIs that allow us to delete and create an existing counter.
    
    If you're creating a performance counter that relies on an accompanying base counter, use the `BaseName`, `BaseDescription`, and `BaseType` parameters to properly add the base counter.
    
    .LINK
    http://msdn.microsoft.com/en-us/library/system.diagnostics.performancecountertype.aspx

    .EXAMPLE
    Install-PerformanceCounter -CategoryName ToyotaCamry -Name MilesPerGallon -Description 'The miles per gallon fuel efficiency.' -Type NumberOfItems32

    Creates a new miles per gallon performance counter for the ToyotaCamry category.
    
    .EXAMPLE
    Install-PerformanceCounter -CategoryName "Dispatcher" -Name "Average Dispatch time" -Type AverageTimer32 -BaseName "Average Dispatch Base" -BaseType AverageBase -Force
    
    Creates a counter to collect average timings, with a base counter.  Some counters require base counters, which have to be added a specific way to work properly.
    #>
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='SimpleCounter')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The category's name where the counter will be created.
        $CategoryName,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The performance counter's name.
        $Name,
        
        [string]
        # The performance counter's description (i.e. help message).
        $Description,
        
        [Parameter(Mandatory=$true)]
        [Diagnostics.PerformanceCounterType]
        # The performance counter's type (from the Diagnostics.PerformanceCounterType enumeration).
        $Type,
        
        [Parameter(Mandatory=$true,ParameterSetName='WithBaseCounter')]
        [string]
        # The base performance counter's name.
        $BaseName,
        
        [Parameter(ParameterSetName='WithBaseCounter')]
        [string]
        # The base performance counter's description (i.e. help message).
        $BaseDescription,
        
        [Parameter(Mandatory=$true,ParameterSetName='WithBaseCounter')]
        [Diagnostics.PerformanceCounterType]
        # The base performance counter's type (from the Diagnostics.PerformanceCounterType enumeration).
        $BaseType,
        
        [Switch]
        # Re-create the performance counter even if it already exists.
        $Force
    )
    
    Set-StrictMode -Version Latest
    
    $currentCounters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    
    $counter = $currentCounters | 
                    Where-Object { 
                        $_.CounterName -eq $Name -and `
                        $_.CounterHelp -eq $Description -and `
                        $_.CounterType -eq $Type
                    }
            
    if( $counter -and -not $Force)
    {
        return
    }
    
    if( $PSCmdlet.ParameterSetName -eq 'WithBaseCounter' )
    {
        $baseCounter = $currentCounters | 
                        Where-Object { 
                            $_.CounterName -eq $BaseName -and `
                            $_.CounterHelp -eq $BaseDescription -and `
                            $_.CounterType -eq $BaseType
                        }
                        
        if( $baseCounter -and -not $Force)
        {
            return
        }
    }
    else
    {
        $BaseName = $null
    }
        
    $counters = New-Object Diagnostics.CounterCreationDataCollection 
    $currentCounters  | 
        Where-Object { $_.CounterName -ne $Name -and $_.CounterName -ne $BaseName } |
        ForEach-Object {
            $creationData = New-Object Diagnostics.CounterCreationData $_.CounterName,$_.CounterHelp,$_.CounterType
            [void] $counters.Add( $creationData )
        }
    
    $newCounterData = New-Object Diagnostics.CounterCreationData $Name,$Description,$Type
    [void] $counters.Add( $newCounterData )
    
    $baseMsg = ''
    if( $PSCmdlet.ParameterSetName -eq 'WithBaseCounter' )
    {
        $newBaseCounterData = New-Object Diagnostics.CounterCreationData $BaseName,$BaseDescription,$BaseType
        [void] $counters.Add( $newBaseCounterData )
        $baseMsg = ' with base counter ''{0}'' ({1})' -f $BaseName,$BaseType
    }
    
    $msg = "Installing '{0}' performance counter '{1}' ({2}){3}." -f $CategoryName,$Name,$Type,$baseMsg
    
    if( $pscmdlet.ShouldProcess( $CategoryName, "install performance counter '$Name'" ) )
    {
        Uninstall-PerformanceCounterCategory -CategoryName $CategoryName

        [void] [Diagnostics.PerformanceCounterCategory]::Create( $CategoryName, '', $counters )
    }
}
