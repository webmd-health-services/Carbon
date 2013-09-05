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
    & (Join-Path -Path $TestDir -ChildPath ..\..\Carbon\Import-Carbon.ps1 -Resolve)
}

function TearDown
{
}

function Test-ShouldTestUncPath
{
    Assert-True (Test-UncPath -Path '\\computer\share')
}

function Test-ShouldTestRelativePath
{
    Assert-False (Test-UncPath -Path '..\..\foo\bar')
}

function Test-ShouldTestNtfsPath
{
    Assert-False (Test-UncPath -Path 'C:\foo\bar\biz\baz\buz')
}
