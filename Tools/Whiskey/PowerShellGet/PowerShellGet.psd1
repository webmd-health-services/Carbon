@{
RootModule = 'PSModule.psm1'
ModuleVersion = '1.6.0'
GUID = '1d73a601-4a6c-43c5-ba3f-619b18bbb404'
Author = 'Microsoft Corporation'
CompanyName = 'Microsoft Corporation'
Copyright = '(c) Microsoft Corporation. All rights reserved.'
Description = 'PowerShell module with commands for discovering, installing, updating and publishing the PowerShell artifacts like Modules, DSC Resources, Role Capabilities and Scripts.'
PowerShellVersion = '3.0'
FormatsToProcess = 'PSGet.Format.ps1xml'
FunctionsToExport = @('Install-Module',
                      'Find-Module',
                      'Save-Module',
                      'Update-Module',
                      'Publish-Module',
                      'Get-InstalledModule',
                      'Uninstall-Module',
                      'Find-Command',
                      'Find-DscResource',
                      'Find-RoleCapability',
                      'Install-Script',
                      'Find-Script',
                      'Save-Script',
                      'Update-Script',
                      'Publish-Script',
                      'Get-InstalledScript',
                      'Uninstall-Script',
                      'Test-ScriptFileInfo',
                      'New-ScriptFileInfo',
                      'Update-ScriptFileInfo',
                      'Get-PSRepository',
                      'Set-PSRepository',
                      'Register-PSRepository',
                      'Unregister-PSRepository',
                      'Update-ModuleManifest')
VariablesToExport = "*"
AliasesToExport = @('inmo',
                    'fimo',
                    'upmo',
                    'pumo')
FileList = @('PSModule.psm1',
             'PSGet.Format.ps1xml',
             'PSGet.Resource.psd1')
RequiredModules = @(@{ModuleName='PackageManagement';ModuleVersion='1.1.7.0'})
PrivateData = @{
                "PackageManagementProviders" = 'PSModule.psm1'
                 "SupportedPowerShellGetFormatVersions" = @('1.x','2.x')
    PSData = @{
        Tags = @('Packagemanagement',
                 'Provider',
                 'PSEdition_Desktop',
                 'PSEdition_Core',
                 'Linux',
                 'Mac')
        ProjectUri = 'https://go.microsoft.com/fwlink/?LinkId=828955'
        LicenseUri = 'https://go.microsoft.com/fwlink/?LinkId=829061'
        ReleaseNotes = @'
## 1.6.0
        
New features
* Prerelease Version Support (#185)
  - Implemented prerelease versions functionality in PowerShellGet cmdlets.
  - Enables publishing, discovering, and installing the prerelease versions of modules and scripts from the PowerShell Gallery.
  - [Documentation](https://docs.microsoft.com/en-us/powershell/gallery/psget/module/PrereleaseModule)

* Enabled publish cmdlets on PWSH and Nano Server (#196)
  - Dotnet command version 2.0.0 or newer should be installed by the user prior to using the publish cmdlets on PWSH and Windows Nano Server.
  - Users can install the dotnet command by following the instructions specified at https://aka.ms/dotnet-install-script.
  - On Windows, users can install the dotnet command by running *Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.ps1' -OutFile '.\dotnet-install.ps1'; & '.\dotnet-install.ps1' -Channel Current -Version '2.0.0'*
  - Publish cmdlets on Windows PowerShell supports using the dotnet command for publishing operations.

Breaking Change
- PWSH: Changed the installation location of AllUsers scope to the parent of $PSHOME instead of $PSHOME. It is the SHARED_MODULES folder on PWSH.

Bug fixes
- Update HelpInfoURI to 'https://go.microsoft.com/fwlink/?linkid=855963' (#195)
- Ensure MyDocumentsPSPath path is correct (#179) (Thanks @lwsrbrts)


## 1.5.0.0

New features
* Added support for modules requiring license acceptance (#150)
  - [Documentation](https://docs.microsoft.com/en-us/powershell/gallery/psget/module/RequireLicenseAcceptance)

* Added version for REQUIREDSCRIPTS (#162)
  - Enabled following scenarios for REQUIREDSCRIPTS
    - [1.0] - RequiredVersion
    - [1.0,2.0] - Min and Max Version
    - (,1.0] - Max Version
    - 1.0 - Min Version

Bug fixes
* Fixed empty version value in nuspec (#157)


## 1.1.3.2
* Disabled PowerShellGet Telemetry on PS Core as PowerShell Telemetry APIs got removed in PowerShell Core beta builds. (#153)
* Fixed for DateTime format serialization issue. (#141)
* Update-ModuleManifest should add ExternalModuleDependencies value as a collection. (#129)

## 1.1.3.1

New features
* Added `PrivateData` field to ScriptFileInfo. (#119)

Bug fixes
* Fixed Add-Type issue in v6.0.0-beta.1 release of PowerShellCore. (#125, #124)
* Install-Script -Scope CurrentUser PATH changes should not require a reboot for new PS processes. (#124)
    - Made changes to broadcast the Environment variable changes, so that other processes pick changes to Environment variables without having to reboot or logoff/logon.
* Changed `Get-EnvironmentVariable` to get the unexpanded version of `%path%`. (#117)
* Refactor credential parameter propagation to sub-functions. (#104)
* Added credential parameter to subsequent calls of `Publish-Module/Script`. (#93)
    - This is needed when a module is published that has the RequiredModules attribute in the manifest on a repository that does not have anonymous access because the required module lookups will fail.

## 1.1.2.0

Bug fixes
* Renamed `PublishModuleIsNotSupportedOnNanoServer` errorid to `PublishModuleIsNotSupportedOnPowerShellCoreEdition`. (#44)
    - Also renamed `PublishScriptIsNotSupportedOnNanoServer` to `PublishScriptIsNotSupportedOnPowerShellCoreEdition`.
* Fixed an issue in `Update-Module` and `Update-Script` cmdlets to show proper version of current item being updated in `Confirm`/`WhatIf` message. (#44)
* Updated `Test-ModuleInstalled` function to return single module instead of multiple modules. (#44)
* Updated `ModuleCommandAlreadyAvailable` error message to include all conflicting commands instead of one.  (#44)
    - Corresponding changes to collect the complete set of conflicting commands from the being installed.
    - Also ensured that conflicting commands from PSModule.psm1 are ignored in the command collision analysis as Get-Command includes the commands from current local scope as well.

* Fixed '[Test-ScriptFileInfo] Fails on *NIX newlines (LF vs. CRLF)' (#18)


## 1.1.1.0

Bug fixes
* Fixed 'Update-Module fails with `ModuleAuthenticodeSignature` error for modules with signed PSD1'. (#12) (#8)
* Fixed 'Properties of `AdditionalMetadata` are case-sensitive'. #7
* Changed `ErrorAction` to `Ignore` for few cmdlet usages as they should not show up in ErrorVariable.
    - For example, error returned by `Get-Command Test-FileCatalog` should be ignored.


## 1.1.0.0

* Initial release from GitHub.
* PowerShellCore support.
* Security enhancements including the enforcement of catalog-signed modules during installation.
* Authenticated Repository support.
* Proxy Authentication support.
* Responses to a number of user requests and issues.
'@
    }
}

HelpInfoURI = 'https://go.microsoft.com/fwlink/?linkid=855963'
}

# SIG # Begin signature block
# MIIarAYJKoZIhvcNAQcCoIIanTCCGpkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1jJtWqwEuMQskYw1ykC9MTJ2
# FMmgghV/MIIEwTCCA6mgAwIBAgITMwAAAMKgCcU3dun2zQAAAAAAwjANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTYwOTA3MTc1ODUx
# WhcNMTgwOTA3MTc1ODUxWjCBsTELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEMMAoGA1UECxMDQU9DMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpD
# M0IwLTBGNkEtNDExMTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
# dmljZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJzfPT5gT5YLgF72
# 8Ipv/kMSm0FRtZmMMXMdDBrWM+LOObrNAITBA0w185w4qccTOzXIgsFlOyvvyGfI
# jH+4zLekfpL8U7DuccyDVdS3Lg70hYBCEJll0SwAhfpHR1D4NQaeIRnhnlRuSUwy
# 7LqOxCE6If90dH0+OaVlxiKHw7R5RgeO50m15BHI+6v9US70IZ8JFqRkfLpk52bh
# LNfnossW+CHvAFPVQ0uThMOaoESnJsmban0QaExZvftxreTrz2QQcVw74Y29CYbZ
# RUTIy4zIpuM/i5oBLj9mwf9CogC0rQibwWfEvPyiFuOZ/ncDX5I8KVHa4Y1LoFQq
# YWk/EEkCAwEAAaOCAQkwggEFMB0GA1UdDgQWBBTjHnnY/MhgLBEZmBJtobBujc6d
# rDAfBgNVHSMEGDAWgBQjNPjZUkZwCu1A+3b7syuwwzWzDzBUBgNVHR8ETTBLMEmg
# R6BFhkNodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9N
# aWNyb3NvZnRUaW1lU3RhbXBQQ0EuY3JsMFgGCCsGAQUFBwEBBEwwSjBIBggrBgEF
# BQcwAoY8aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNyb3Nv
# ZnRUaW1lU3RhbXBQQ0EuY3J0MBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3
# DQEBBQUAA4IBAQAoNFRrsA/+bdu8IJvKoxcry0vIPw0qzrUya7ud9MrJ/pp9EO01
# OFrXqbFfuPW0niqZt7hYrs7bzwSlmbBItCkImv0GCLS/3cf0Vl/c0NxUpn8TUjoo
# +qwnPF3qRGUzcwrI/3Xl9EfoDlc8jWd2f5FqrjeQdmkdOUmtxSnVt1kbW+Fnjlyl
# 1q8aWpkXXgNrBD29iXQV7BklsvtzSVLB32UTZqADm/yzqPC+osWN2eHED2nag1w0
# 51bq++5Pc2mA/UbJeqv+J9VhQwyTGoFdCjE9ygfd7aASPsxiAsRBsNRlylFMjePA
# nFZyI0P0rM+CW09Q641SEKIKbT6T1ww+8ByJMIIE6zCCA9OgAwIBAgITMwAAAXgl
# WrXNI8ZflQABAAABeDANBgkqhkiG9w0BAQUFADB5MQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMSMwIQYDVQQDExpNaWNyb3NvZnQgQ29kZSBTaWdu
# aW5nIFBDQTAeFw0xNzA4MTEyMDExMTVaFw0xODA4MTEyMDExMTVaMIGCMQswCQYD
# VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMQwwCgYDVQQLEwNBT0MxHjAc
# BgNVBAMTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjCCASIwDQYJKoZIhvcNAQEBBQAD
# ggEPADCCAQoCggEBAJluHVNVq52yshtdQ88H1zxL4T50pJuyQcpiUbpIZMfyOFOG
# m68aIA7zsXZv0YdU34O+zNoyQbL/FCAdoYQkt+mdveSlqSJzsTRuMMd0bgqcdFue
# j/B9SQYt9Lv2j5zD/9FjwKTrIT7RzMMFzGnQZvDknIY/4oWq/NFH/dO/ee3/nHTl
# mcQ4dg/54NWKQO+f8Mf6jHG2IJ9fe2S+2b/Jfh45vjth2ZgpCMKDPb42KX+W6li9
# TRAUiO+R7eOyGpAg0OeD+873KzaoDR7H+rmGUspBNJP310agzzoZ7oXvbdF5Oioq
# cYs3ySIIbu41qk4AhCukIdmr3oJW6aJoDlm/FT0CAwEAAaOCAWAwggFcMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBSO6G0PcUPu2T9EqWgkVfTlymAuNzBR
# BgNVHREESjBIpEYwRDEMMAoGA1UECxMDQU9DMTQwMgYDVQQFEysyMjk4MDMrMWFi
# ZjllNWYtY2VkMC00MmU2LWE2NWQtZDkzNTA5NTlmZTBlMB8GA1UdIwQYMBaAFMsR
# 6MrStBZYAck3LjMWFrlMmgofMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwu
# bWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY0NvZFNpZ1BDQV8wOC0z
# MS0yMDEwLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljQ29kU2lnUENBXzA4LTMxLTIw
# MTAuY3J0MA0GCSqGSIb3DQEBBQUAA4IBAQBicb+gcb/GBlhHw0Awdn+8T0YzR7jt
# h2G5N5ra5julIbAzvTvCnxZqfQVrp68rU9Z9x39c06HYGkS/mjxGYoOgSwbQQI/X
# cm6DtySV8qt4FUdD4OODjdVUUtmm6jto4BUrrCOVyek9S2f5J8f0rRozYWMMpUkV
# bpcUpcFq3lH5mnq47FZPGlJ4xN4MLnMXohjqiBHW7NT70RChGUC+TBfqmj57EQuc
# wuvj74/5+o7EhT484MigHyKMKUCrDAq8uUw9reqWs0e34vB5My7uW8YL9EDXzBTP
# NcB6ia5nTduVTD5uQ6JWBY6ThLRE3sSdbvOMlXyB3/4bZ1tOhSLVwH99MIIFvDCC
# A6SgAwIBAgIKYTMmGgAAAAAAMTANBgkqhkiG9w0BAQUFADBfMRMwEQYKCZImiZPy
# LGQBGRYDY29tMRkwFwYKCZImiZPyLGQBGRYJbWljcm9zb2Z0MS0wKwYDVQQDEyRN
# aWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcNMTAwODMxMjIx
# OTMyWhcNMjAwODMxMjIyOTMyWjB5MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSMwIQYDVQQDExpNaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQTCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJyWVwZMGS/HZpgICBCmXZT
# bD4b1m/My/Hqa/6XFhDg3zp0gxq3L6Ay7P/ewkJOI9VyANs1VwqJyq4gSfTwaKxN
# S42lvXlLcZtHB9r9Jd+ddYjPqnNEf9eB2/O98jakyVxF3K+tPeAoaJcap6Vyc1bx
# F5Tk/TWUcqDWdl8ed0WDhTgW0HNbBbpnUo2lsmkv2hkL/pJ0KeJ2L1TdFDBZ+NKN
# Yv3LyV9GMVC5JxPkQDDPcikQKCLHN049oDI9kM2hOAaFXE5WgigqBTK3S9dPY+fS
# LWLxRT3nrAgA9kahntFbjCZT6HqqSvJGzzc8OJ60d1ylF56NyxGPVjzBrAlfA9MC
# AwEAAaOCAV4wggFaMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFMsR6MrStBZY
# Ack3LjMWFrlMmgofMAsGA1UdDwQEAwIBhjASBgkrBgEEAYI3FQEEBQIDAQABMCMG
# CSsGAQQBgjcVAgQWBBT90TFO0yaKleGYYDuoMW+mPLzYLTAZBgkrBgEEAYI3FAIE
# DB4KAFMAdQBiAEMAQTAfBgNVHSMEGDAWgBQOrIJgQFYnl+UlE/wq4QpTlVnkpDBQ
# BgNVHR8ESTBHMEWgQ6BBhj9odHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9taWNyb3NvZnRyb290Y2VydC5jcmwwVAYIKwYBBQUHAQEESDBG
# MEQGCCsGAQUFBzAChjhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRz
# L01pY3Jvc29mdFJvb3RDZXJ0LmNydDANBgkqhkiG9w0BAQUFAAOCAgEAWTk+fyZG
# r+tvQLEytWrrDi9uqEn361917Uw7LddDrQv+y+ktMaMjzHxQmIAhXaw9L0y6oqhW
# nONwu7i0+Hm1SXL3PupBf8rhDBdpy6WcIC36C1DEVs0t40rSvHDnqA2iA6VW4LiK
# S1fylUKc8fPv7uOGHzQ8uFaa8FMjhSqkghyT4pQHHfLiTviMocroE6WRTsgb0o9y
# lSpxbZsa+BzwU9ZnzCL/XB3Nooy9J7J5Y1ZEolHN+emjWFbdmwJFRC9f9Nqu1IIy
# bvyklRPk62nnqaIsvsgrEA5ljpnb9aL6EiYJZTiU8XofSrvR4Vbo0HiWGFzJNRZf
# 3ZMdSY4tvq00RBzuEBUaAF3dNVshzpjHCe6FDoxPbQ4TTj18KUicctHzbMrB7HCj
# V5JXfZSNoBtIA1r3z6NnCnSlNu0tLxfI5nI3EvRvsTxngvlSso0zFmUeDordEN5k
# 9G/ORtTTF+l5xAS00/ss3x+KnqwK+xMnQK3k+eGpf0a7B2BHZWBATrBC7E7ts3Z5
# 2Ao0CW0cgDEf4g5U3eWh++VHEK1kmP9QFi58vwUheuKVQSdpw5OPlcmN2Jshrg1c
# nPCiroZogwxqLbt2awAdlq3yFnv2FoMkuYjPaqhHMS+a3ONxPdcAfmJH0c6IybgY
# +g5yjcGjPa8CQGr/aZuW4hCoELQ3UAjWwz0wggYHMIID76ADAgECAgphFmg0AAAA
# AAAcMA0GCSqGSIb3DQEBBQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAXBgoJ
# kiaJk/IsZAEZFgltaWNyb3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290IENl
# cnRpZmljYXRlIEF1dGhvcml0eTAeFw0wNzA0MDMxMjUzMDlaFw0yMTA0MDMxMzAz
# MDlaMHcxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNV
# BAMTGE1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQTCCASIwDQYJKoZIhvcNAQEBBQAD
# ggEPADCCAQoCggEBAJ+hbLHf20iSKnxrLhnhveLjxZlRI1Ctzt0YTiQP7tGn0Uyt
# dDAgEesH1VSVFUmUG0KSrphcMCbaAGvoe73siQcP9w4EmPCJzB/LMySHnfL0Zxws
# /HvniB3q506jocEjU8qN+kXPCdBer9CwQgSi+aZsk2fXKNxGU7CG0OUoRi4nrIZP
# VVIM5AMs+2qQkDBuh/NZMJ36ftaXs+ghl3740hPzCLdTbVK0RZCfSABKR2YRJylm
# qJfk0waBSqL5hKcRRxQJgp+E7VV4/gGaHVAIhQAQMEbtt94jRrvELVSfrx54QTF3
# zJvfO4OToWECtR0Nsfz3m7IBziJLVP/5BcPCIAsCAwEAAaOCAaswggGnMA8GA1Ud
# EwEB/wQFMAMBAf8wHQYDVR0OBBYEFCM0+NlSRnAK7UD7dvuzK7DDNbMPMAsGA1Ud
# DwQEAwIBhjAQBgkrBgEEAYI3FQEEAwIBADCBmAYDVR0jBIGQMIGNgBQOrIJgQFYn
# l+UlE/wq4QpTlVnkpKFjpGEwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcGCgmS
# JomT8ixkARkWCW1pY3Jvc29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3QgQ2Vy
# dGlmaWNhdGUgQXV0aG9yaXR5ghB5rRahSqClrUxzWPQHEy5lMFAGA1UdHwRJMEcw
# RaBDoEGGP2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3Rz
# L21pY3Jvc29mdHJvb3RjZXJ0LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYBBQUH
# MAKGOGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0
# Um9vdENlcnQuY3J0MBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEBBQUA
# A4ICAQAQl4rDXANENt3ptK132855UU0BsS50cVttDBOrzr57j7gu1BKijG1iuFcC
# y04gE1CZ3XpA4le7r1iaHOEdAYasu3jyi9DsOwHu4r6PCgXIjUji8FMV3U+rkuTn
# jWrVgMHmlPIGL4UD6ZEqJCJw+/b85HiZLg33B+JwvBhOnY5rCnKVuKE5nGctxVEO
# 6mJcPxaYiyA/4gcaMvnMMUp2MT0rcgvI6nA9/4UKE9/CCmGO8Ne4F+tOi3/FNSte
# o7/rvH0LQnvUU3Ih7jDKu3hlXFsBFwoUDtLaFJj1PLlmWLMtL+f5hYbMUVbonXCU
# bKw5TNT2eb+qGHpiKe+imyk0BncaYsk9Hm0fgvALxyy7z0Oz5fnsfbXjpKh0NbhO
# xXEjEiZ2CzxSjHFaRkMUvLOzsE1nyJ9C/4B5IYCeFTBm6EISXhrIniIh0EPpK+m7
# 9EjMLNTYMoBMJipIJF9a6lbvpt6Znco6b72BJ3QGEe52Ib+bgsEnVLaxaj2JoXZh
# tG6hE6a/qkfwEm/9ijJssv7fUciMI8lmvZ0dhxJkAj0tr1mPuOQh5bWwymO0eFQF
# 1EEuUKyUsKV4q7OglnUa2ZKHE3UiLzKoCG6gW4wlv6DvhMoh1useT8ma7kng9wFl
# b4kLfchpyOZu6qeXzjEp/w7FW1zYTRuh2Povnj8uVRZryROj/TGCBJcwggSTAgEB
# MIGQMHkxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xIzAhBgNV
# BAMTGk1pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBAhMzAAABeCVatc0jxl+VAAEA
# AAF4MAkGBSsOAwIaBQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYK
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFG97lXXj
# vvul8an8G6EWnJaJZMgQMFAGCisGAQQBgjcCAQwxQjBAoBaAFABQAG8AdwBlAHIA
# UwBoAGUAbABsoSaAJGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9Qb3dlclNoZWxs
# IDANBgkqhkiG9w0BAQEFAASCAQBLK1pUEaBxBx4bYFGQBmfW4EPipYCxBwMwap51
# HZ0CsBttxcVv0DNN9D3zk47rX8OnqocycCXDHac7C2KOOngAaJkUC+pHeUdPC4wf
# QwzGbDjU3HHAZyt7JeASnXdSuiFrW4uSmesfOo2qpIBNVK/Wg2CiozQ8PFOm2RwO
# u3KDJfrzczQ/oM2jyx0+WqzBfCj9Dax7NpYdU+eRJMlbDsnw3a0q2eEbnapJFTmP
# mkYIYpNBgD6LzSo9gIxgKB4zRWu+KDwSdBRRPQNJJzKiE1fCM0G4xuf46qfRdMBb
# 162Pz7DBtlZdPgTX+aqxuXSHWC/9oZuLnj2CeVPQSjSYAS9yoYICKDCCAiQGCSqG
# SIb3DQEJBjGCAhUwggIRAgEBMIGOMHcxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQQIT
# MwAAAMKgCcU3dun2zQAAAAAAwjAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsG
# CSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTcxMjA1MjI1MTM2WjAjBgkqhkiG
# 9w0BCQQxFgQUAK7fX5OIO4Uyfg5OGoLA8BkzcN8wDQYJKoZIhvcNAQEFBQAEggEA
# WjZ7+RBNwbODft8eELfypJV9UgvQ8qNwuBiHDkBYOu2jHXSHDgwH97UA4hrG4nLc
# 4U6oc8gXN7RkndPaoY1DkVKRjKfk9OjCIGh5zjZF8qKIoUDA/vp/HY/JAJA83on4
# 09ai1V3vBW/Qlv87AoGfgbf25WPmiCWcWU3SI6CvDU9s1V1X1XUjiq3RwEKqe8nd
# 5WuhZSVsSH5rhr51nYhQUB3i6gqicUFWP/QEi/9PQstuaRyeW015zWLsrGJQ4iJw
# XPNG/yEnwfXQNu4yUup4mlfXIap+OBio1zIReodfT94WZbEFcat8nFlC6CFD5G25
# H0LVFda6B7zRZ5wEMcqNRQ==
# SIG # End signature block
