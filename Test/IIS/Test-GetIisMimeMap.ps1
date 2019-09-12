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

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldGetAllMimeTypes
{
    $mimeMap = Get-IisMimeMap
    Assert-NotNull $mimeMap
    Assert-True ($mimeMap.Length -gt 0)
    
    $mimeMap | ForEach-Object {
        Assert-True ($_.FileExtension -like '.*') ('invalid file extension ''{0}''' -f $_.FileExtension)
        Assert-True ($_.MimeType -like '*/*') 'invalid mime type'
    }
}

function Test-ShouldGetWildcardFileExtension
{
    $mimeMap = Get-IisMimeMap -FileExtension '.htm*'
    Assert-NotNull $mimeMap
    Assert-Equal 2 $mimeMap.Length
    Assert-Equal '.htm' $mimeMap[0].FileExtension
    Assert-Equal 'text/html' $mimeMap[0].MimeType
    Assert-Equal '.html' $mimeMap[1].FileExtension
    Assert-Equal 'text/html' $mimeMap[1].MimeType
}


function Test-ShouldGetWildcardMimeType
{
    $mimeMap = Get-IisMimeMap -MimeType 'text/*'
    Assert-NotNull $mimeMap
    Assert-True ($mimeMap.Length -gt 1)
    $mimeMap | ForEach-Object {
        Assert-True ($_.MimeType -like 'text/*')
    }
}

