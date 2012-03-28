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
