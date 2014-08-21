# Copyright 2013 Aaron Jensen
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

Add-Type -Path (Join-Path $PSSCriptRoot bin\MarkdownSharp.dll)
$markdown = New-Object MarkdownSharp.Markdown
$markdown.AutoHyperlink = $true

$loadedTypes = @{ }
[AppDomain]::CurrentDomain.GetAssemblies() | 
    ForEach-Object { $_.GetTypes() } | 
    ForEach-Object { 
        if( $loadedTypes.ContainsKey( $_.Name ) )
        {
            Write-Verbose ("Found multiple <{0}> types." -f $_.Name)
        }
        else
        {
            $loadedTypes[$_.Name] = $_.FullName
        }
    }

$filesToSkip = @{
                    'Import-Silk' = $true;
                }

Get-Item (Join-Path $PSScriptRoot *-*.ps1) | 
    Where-Object { -not $filesToSkip.ContainsKey( $_.BaseName ) } |
    ForEach-Object {
        Write-Debug ("Importing sub-module {0}." -f $_.FullName)
        . $_.FullName
    }
