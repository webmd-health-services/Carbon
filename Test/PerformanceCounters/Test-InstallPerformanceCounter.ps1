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

$CategoryName = 'Carbon-PerformanceCounters'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Stop-Test
{
    Uninstall-PerformanceCounterCategory -CategoryName $CategoryName
    Assert-False (Test-PerformanceCounterCategory -CategoryName $CategoryName) 'Performance counter category not uninstalled.'
}

function Test-ShouldInstallNewPerformanceCounterWithNewCategory
{
    $name = 'Test Counter'
    $description = 'Counter used to test that Carbon installation function works.'
    $type = 'NumberOfItems32'
    
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $description -Type $type
    Assert-True (Test-PerformanceCounterCategory -CategoryName $CategoryName) 'Category not auto-created.'
    Assert-True (Test-PerformanceCounter -CategoryName $CategoryName -Name $name)
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Equal 1 $counters.Length
    Assert-Counter $counters[0] $name $description $type
}

function Test-ShouldInstallCounterWithNoDescription
{
    $name = 'Test Counter'
    $type = 'NumberOfItems32'
    
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Type $type
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Counter $counters[0] $name $null $type
}

function Test-ShouldPreserveExistingCountersWhenInstallingNewCounter
{
    $name = 'Test Counter'
    $description = 'Counter used to test that Carbon installation function works.'
    $type = 'NumberOfItems32'
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $description -Type $type
    
    $name2 = 'Test Counter 2'
    $description2 = 'Second counter used to test that Carbon installation function works.'
    $type2 = 'NumberOfItems64'
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name2 -Description $description2 -Type $type2
    
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Equal 2 $counters.Length
    Assert-Counter $counters[0] $name $description $type
    Assert-Counter $counters[1] $name2 $description2 $type2   
}

function Test-ShouldSupportWhatIf
{
    $name = 'Test Counter'
    $description = 'Counter used to test that Carbon installation function works.'
    $type = 'NumberOfItems32'
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $description -Type $type -WhatIf
    Assert-False (Test-PerformanceCounterCategory -Categoryname $CategoryName)
    Assert-False (Test-PerformanceCounter -CategoryName $CategoryName -Name $name)    
}

function Test-ShouldReinstallExistingPerformanceCounter
{
    $name = 'Test Counter'
    $description = 'Counter used to test that Carbon installation function works.'
    $type = 'NumberOfItems32'
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $description -Type $type
    
    $newDescription = '[New] ' + $description
    $newType = 'NumberOfItems64'
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $newDescription -Type $newType
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Counter $counters[0] $name $newDescription $newType
}

function Test-ShouldNotInstallIfCounterHasNotChanged
{
    $name = 'Test Counter'
    $description = 'Counter used to test that Carbon installation function works.'
    $type = 'NumberOfItems32'
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $description -Type $type
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Counter $counters[0] $name $description $type
    
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $description -Type $type
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Counter $counters[0] $name $description $type
    
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $description -Type $type -Force
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Counter $counters[0] $name $description $type
}

function Test-ShouldCreateBaseCounter
{
    $name = 'Test Counter'
    $description = 'Counter used to test that Carbon installation function works.'
    $type = 'AverageTimer32'
    
    $baseName = 'Test Base Counter'
    $baseDescription = 'Base counter used by Carbon Test Counter'
    $baseType = 'AverageBase'
    
    Install-PerformanceCounter -Category $CategoryName -Name $name -Description $description -Type $type `
                               -BaseName $baseName -BaseDescription $baseDescription -BaseType $baseType
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Counter $counters[0] $name $description $type
    Assert-Counter $counters[1] $baseName $baseDescription $baseType
}

function Test-ShouldRecreateBaseCounter
{
    $name = 'Test Counter'
    $description = 'Counter used to test that Carbon installation function works.'
    $type = 'AverageTimer32'
    
    $baseName = 'Test Base Counter'
    $baseDescription = 'Base counter used by Carbon Test Counter'
    $baseType = 'AverageBase'
    
    Install-PerformanceCounter -Category $CategoryName -Name $name -Description $description -Type $type `
                               -BaseName $baseName -BaseDescription $baseDescription -BaseType $baseType
    Install-PerformanceCounter -Category $CategoryName -Name 'Third Counter' -Type NumberOfItems32
    
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Counter $counters[0] $name $description $type
    Assert-Counter $counters[1] $baseName $baseDescription $baseType
    Assert-Counter $counters[2] 'Third Counter' $null NumberOfItems32
    
    Install-PerformanceCounter -Category $CategoryName -Name $name -Description $description -Type $type `
                               -BaseName $baseName -BaseDescription $baseDescription -BaseType $baseType `
                               -Force
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Counter $counters[0] 'Third Counter' $null NumberOfItems32
    Assert-Counter $counters[1] $name $description $type
    Assert-Counter $counters[2] $baseName $baseDescription $baseType
    
}

function Assert-Counter($Counter, $Name, $Description, $Type)
{
    Assert-Equal $Name $Counter.CounterName 'counter name'
    if( $Description -eq $null )
    {
        Assert-Equal $Name $Counter.CounterHelp 'counter help'
    }
    else
    {
        Assert-Equal $Description $Counter.CounterHelp 'counter help'
    }
    Assert-Equal $Type $Counter.CounterType 'counter type'

}

