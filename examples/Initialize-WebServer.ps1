<#
.SYNOPSIS
Example script showing how to setup a simple web server.

#>
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

Install-Group -Name $deploymentWritersGroupName -Description 'Users allowed to write to the deployment share.' -Members $ccnetServiceUser
Install-Group -Name $deploymnetReadersGroupName -Description 'Users allowed to read the deployment share.' -Members 'Everyone'

$websitePath = '\Path\to\website\directory'
Grant-Permissions -Path $websitePath -Permissions FullControl -Identity $deploymentWritersGroupName
Grant-Permissions -Path $websitePath -Permissions Read -Identity $deploymnetReadersGroupName

$deployShareName = 'Deploy'
Install-Share -Name $deployShareName `
              -Path $websitePath `
              -Description 'Share used by build server to deploy website changes.' `
              -Permissions "$deploymentWritersGroupName,FULL","$deploymentReadersGroupName,READ"


$sslCertPath = 'Path\to\SSL\certificate.cer'
$cert = Install-Certificate -Path $sslCertPath -StoreLocation LocalMachine -StoreName My
Set-SslCertificateBinding -IPPort '0.0.0.0:80' -ApplicationID ([Guid]::NewGuid()) -Thumbprint $cert.Thumbprint

$appPoolName = 'ExampleAppPool'
Install-IisAppPool -Name $appPoolName -ServiceAccount NetworkService
Install-IisWebsite -Path $websitePath -Name 'example1.get-carbon.org' -Bindings ('http/*:80','https/*:443') -AppPoolName $appPoolName

Set-DotNetConnectionString -Name 'example1DB' `
                           -Value 'Data Source=db.example1.get-carbon.org; Initial Catalog=example1DB; Integrated Security=SSPI;' `
                           -Framework64 `
                           -Clr4
