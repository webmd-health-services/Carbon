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

function Start-Test
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
}

function Stop-Test
{
}

function Test-ShouldGetAllGroups
{
    $groups = Get-Group
    try
    {
        Assert-NotNull $groups
        Assert-GreaterThan $groups.Length 0
        $groups | ForEach-Object { Assert-Is $_ ([DirectoryServices.AccountManagement.GroupPrincipal]) }
    }
    finally
    {
        $groups | ForEach-Object { $_.Dispose() }
    }
}

function Test-ShouldGetOneGroup
{
    Get-Group |
        ForEach-Object { 
            $expectedGroup = $_
            try
            {
                $group = Get-Group -Name $expectedGroup.Name
                try
                {
                    Assert-Equal $expectedGroup.Sid $group.Sid
                }
                finally
                {
                    if( $group )
                    {
                        $group.Dispose()
                    }
                }
            }
            finally
            {
                $expectedGroup.Dispose()
            }
        }
}

function Test-ShouldErrorIfGroupNotFound
{
    $Error.Clear()
    $group = Get-Group -Name 'fjksdjfkldj' -ErrorAction SilentlyContinue
    Assert-Null $group
    Assert-Equal 1 $Error.Count
    Assert-Like $Error[0].Exception.Message '*not found*'
}
