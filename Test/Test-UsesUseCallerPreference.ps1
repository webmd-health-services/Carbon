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

function Test-FunctionsShouldUseUseCallerPreference
{
    $files = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\Functions\*.ps1') -File |
                Where-Object { $_.BaseName -ne 'Use-CallerPreference' } |
                Where-Object { -not ($_ | Select-String -Pattern 'Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState' -SimpleMatch) } | 
                Select-Object -ExpandProperty 'Name' |
                Sort-Object

    if( $files )
    {
        Fail ('The following scripts don''t don''t use `Use-CallerPreference`:{0} * {1}' -f ([Environment]::NewLine),($files -join ('{0} * ' -f ([Environment]::NewLine))))
    }
}

