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

function Get-BBServerFile
{
    <#
    .SYNOPSIS
    Gets a list of files from a repository.

    .DESCRIPTION
    The `Get-BBServerFile` function returns a list of all files in a Bitbucket Server repository.
    
    If you pass a path, the file search will begin at the specified directory relative to the root of the repository. By default, the file search will begin at the root. All file searches are performed recursively and all matching files from all sub-directories will be returned.  

    If you pass a name, the search will only return that match the criteria. Wildcards are allowed to search for files. Wildcard matching is *not* supported by the Bitbucket Server API, so all files must be retrieved and searched.

    .EXAMPLE
    Get-BBServerFile -Connection $conn -ProjectKey 'TestProject' -RepoName 'TestRepo'

    Demonstrates how to get a list of all the files `TestRepo` repository.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,

        [Parameter(Mandatory=$true)]
        [string]
        # The key/ID that identifies the project where the repository resides. This is *not* the project name.
        $ProjectKey,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of a specific repository.
        $RepoName,

        [string]
        # The name of the file to search for.
        $FileName,

        [string]
        # The file path to begin searching for files, relative to the repository's root. All sub-directories will be searched recursively.
        $FilePath

    )
    
    Set-StrictMode -Version 'Latest'
    
    $resourcePath = ('projects/{0}/repos/{1}/files/{2}' -f $ProjectKey, $RepoName, $FilePath)
    $nextPageStart = 0
    $isLastPage = $false
    $fileList = $null
    
    while( $isLastPage -eq $false )
    {
        $getFiles = Invoke-BBServerRestMethod -Connection $Connection -Method 'GET' -ApiName 'api' -ResourcePath ('{0}?limit={1}&start={2}' -f $resourcePath, [int16]::MaxValue, $nextPageStart)
        if( $getFiles )
        {
            $nextPageStart = $getFiles.nextPageStart
            $isLastPage = $getFiles.isLastPage
            $fileList += $getFiles.values
        }
        else
        {
            $isLastPage = $true
        }
    }
    
    if( $FileName )
    {
        $fileList = $fileList | Where-Object { $_.Substring($_.LastIndexOf('/') + 1) -like $FileName }
    }
    
    return $fileList
}
