<#
.SYNOPSIS
Example script showing how to setup a simple web server.

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
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

& (Join-Path $PSSCriptRoot ..\Import-Carbon.ps1 -Resolve)

$deploymentWritersGroupName = 'DeploymentWriters'
$deploymnetReadersGroupName = 'DeploymentReaders'
$ccnetServiceUser = 'example.com\CCServiceUser'

Install-Group -Name $deploymentWritersGroupName `
              -Description 'Users allowed to write to the deployment share.' `
              -Members $ccnetServiceUser
Install-Group -Name $deploymnetReadersGroupName `
              -Description 'Users allowed to read the deployment share.' `
              -Members 'Everyone'

$websitePath = '\Path\to\website\directory'
Grant-Permission -Path $websitePath -Permission FullControl `
                 -Identity $deploymentWritersGroupName
Grant-Permission -Path $websitePath -Permission Read `
                 -Identity $deploymnetReadersGroupName

$deployShareName = 'Deploy'
Install-Share -Name $deployShareName `
              -Path $websitePath `
              -Description 'Share used by build server to deploy website changes.' `
              -FullAccess $deploymentWritersGroupName `
              -ReadAccess $deploymnetReadersGroupName


$sslCertPath = 'Path\to\SSL\certificate.cer'
$cert = Install-Certificate -Path $sslCertPath -StoreLocation LocalMachine -StoreName My
Set-SslCertificateBinding -ApplicationID ([Guid]::NewGuid()) -Thumbprint $cert.Thumbprint

$appPoolName = 'ExampleAppPool'
Install-IisAppPool -Name $appPoolName -ServiceAccount NetworkService
Install-IisWebsite -Path $websitePath -Name 'example1.get-carbon.org' `
                   -Bindings ('http/*:80','https/*:443') -AppPoolName $appPoolName

Set-DotNetConnectionString -Name 'example1DB' `
                           -Value 'Data Source=db.example1.get-carbon.org; Initial Catalog=example1DB; Integrated Security=SSPI;' `
                           -Framework64 `
                           -Clr4
