<#
.SYNOPSIS
Publishes Carbon to the PowerShell gallery.
#>
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
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    # The path to the module.
    $Path,

    [Parameter(Mandatory=$true)]
    [string]
    # The API key for the PowerShell Gallery.
    $ApiKey,

    [Parameter(Mandatory=$true)]
    [string]
    # The URL to the module's license.
    $LicenseUri
)

Set-StrictMode -Version 'Latest'

Publish-Module -Path $Path `
               -Repository 'PSGallery' `
               -NuGetApiKey $ApiKey `
               -LicenseUri $LicenseUri
