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

function Test-ShouldGetHandles()
{
    $tempFile = '{0}-{1}' -f (Split-Path -Leaf -Path $PSCommandPath),([IO.Path]::GetRandomFileName())
    $tempFile = Join-Path -Path $env:TEMP -ChildPath $tempFile
    $file = [IO.File]::OpenWrite($tempFile)
    try
    {
        $handles = Find-OpenFile 
        Assert-NotNull $handles
        Assert-GreaterThan $handles.Count 1

        $handleInfo = $handles | Where-Object { $_.Path -eq $tempFile }
        Assert-NotNull $handleInfo
        Assert-Equal $PID $handleInfo.ProcessID
    }
    finally
    {
        $file.Close()
        Remove-Item -Path $tempFile
    }
}