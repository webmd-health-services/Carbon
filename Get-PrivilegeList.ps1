<#
#>
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
[CmdletBinding()]
param(
)

@( 'http://msdn.microsoft.com/en-us/library/windows/desktop/bb530716.aspx', 'http://msdn.microsoft.com/en-us/library/windows/desktop/bb545671.aspx' ) |
    ForEach-Object { Invoke-WebRequest -Uri $_ } |
    Select-Object -ExpandProperty 'RawContent' |
    Select-String -AllMatches 'TEXT\("([^"]+)"\)' |
    Select-Object -ExpandProperty 'Matches' |
    Select-Object -ExpandProperty 'Groups' |
    Select-Object -ExpandProperty 'Value' |
    Where-Object { $_ -notlike 'TEXT*' } |
    Select-Object -Unique |
    Sort-Object | 
    ForEach-Object { ' * {0}' -f $_ }
