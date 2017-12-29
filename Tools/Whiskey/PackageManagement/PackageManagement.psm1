#
# Script module for module 'PackageManagement'
#
Set-StrictMode -Version Latest
Microsoft.PowerShell.Utility\Import-LocalizedData  LocalizedData -filename PackageManagement.Resources.psd1

# Summary: PackageManagement is supported on Windows PowerShell 3.0 or later, Nano Server and PowerShellCore
$isCore = ($PSVersionTable.Keys -contains "PSEdition") -and ($PSVersionTable.PSEdition -ne 'Desktop')
$binarySubPath = ''
if ($isCore)
{
    # Using the Assembly.LoadFrom API to determine if this is netcoreapp2.0 or if it's older
    $loadFromMethod = [System.Reflection.Assembly].GetMethods() | Where-Object { $_.Name -eq 'LoadFrom' }
    if ($loadFromMethod)
    {
        $binarySubPath = Join-Path -Path 'coreclr' -ChildPath 'netcoreapp2.0'
    } else {
        $binarySubPath = Join-Path -Path 'coreclr' -ChildPath 'netstandard1.6'
    }
} else {
    $binarySubPath = 'fullclr'
}

# Set up some helper variables to make it easier to work with the module
$script:PSModule = $ExecutionContext.SessionState.Module
$script:PSModuleRoot = $script:PSModule.ModuleBase

$script:PkgMgmt = 'Microsoft.PackageManagement.dll'
$script:PSPkgMgmt = 'Microsoft.PowerShell.PackageManagement.dll'


# Try to import the OneGet assemblies at the same directory regardless fullclr or coreclr
$OneGetModulePath = Join-Path -Path $script:PSModuleRoot -ChildPath $script:PkgMgmt
$binaryModuleRoot = $script:PSModuleRoot


if(-not (Test-Path -Path $OneGetModulePath))
{
    # Import the appropriate nested binary module based on the current PowerShell version
    $binaryModuleRoot = Join-Path -Path $script:PSModuleRoot -ChildPath $binarySubPath
    $OneGetModulePath = Join-Path -Path $binaryModuleRoot -ChildPath $script:PkgMgmt
}

$PSOneGetModulePath = Join-Path -Path $binaryModuleRoot -ChildPath $script:PSPkgMgmt
$OneGetModule = Import-Module -Name $OneGetModulePath -PassThru
$PSOneGetModule = Import-Module -Name $PSOneGetModulePath -PassThru


# When the module is unloaded, remove the nested binary module that was loaded with it
if($OneGetModule)
{
    $script:PSModule.OnRemove = {
        Remove-Module -ModuleInfo $OneGetModule
    }
}

if($PSOneGetModule)
{
    $script:PSModule.OnRemove = {
        Remove-Module -ModuleInfo $PSOneGetModule
    }
}
# SIG # Begin signature block
# MIIarAYJKoZIhvcNAQcCoIIanTCCGpkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU35RgBArpdVmQgD58AT7InXLQ
# Qs6gghV/MIIEwTCCA6mgAwIBAgITMwAAANjkdflFb0j3rgAAAAAA2DANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTcxMDAyMjI1NzU3
# WhcNMTkwMTAyMjI1NzU3WjCBsTELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEMMAoGA1UECxMDQU9DMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjo3
# MERELTRCNUItNDU2ODElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
# dmljZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMR2sf6C9y+kIdyj
# 16QouyVvlvPjzdmE1FFIAb7gUl7UCknd2nlquXeGJHQdX22zmY18QH/8EjH8voTu
# 57DqKJRFkqkD+PQ87+M4j2aW27QCHiHVATEHdHelT0ANUSoxETlAe4d6gd6sL/aA
# wkqFSqTncLfVeAenMJ7Te3tLmLYBk59CI/Tmf2YCsU+Z0nQ0S0AH6IHAKbDLLUPZ
# 1KW4d5Mmig1YMInsaoDHJvmuXyUZ6GxluZ7GX+WxF2XoxFRuMo6OWrCER3gnx/W3
# omzHOc1/C/oBI8hELBQH8uTJYqI8iGx8yqDyYETHoZNdH0oFeIOfAvVFlUYTE3JW
# pbMtF0cCAwEAAaOCAQkwggEFMB0GA1UdDgQWBBSgHm6PHyXdykNng5Up+ne9UdYe
# VjAfBgNVHSMEGDAWgBQjNPjZUkZwCu1A+3b7syuwwzWzDzBUBgNVHR8ETTBLMEmg
# R6BFhkNodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9N
# aWNyb3NvZnRUaW1lU3RhbXBQQ0EuY3JsMFgGCCsGAQUFBwEBBEwwSjBIBggrBgEF
# BQcwAoY8aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNyb3Nv
# ZnRUaW1lU3RhbXBQQ0EuY3J0MBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3
# DQEBBQUAA4IBAQCFDewTPdV6/bMFMK0kqgvI8Y7t1YvHrGmvpdA/Y2zx+ERd0g9d
# ENtHTlfAPC1X15YlDXZNPdo7LY6wMJco/rXcjzFZ/tIvGHcIaQE52tJKW+pmXfrv
# QWW4X3pQdbPTsCwcDSGPcDImnec0dathWPicWxBg1NIeSDDsdsqpESp0kSs9g9fL
# QWUi9wHlFehburgOJCWpQ1jkNspUvJ7xMmtTTEIu6WPEDGHU8LxHraClsL0/BzPN
# KE85uB3+5/yOurKU/V8kH/obxzB03XxI4QpbpU1D2yasOd7JVmCGEbHBRamtHVz6
# SnVVVviJUsoGV5/jdzHuXyUIy9LKSUwuTdykMIIE6zCCA9OgAwIBAgITMwAAAXgl
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
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFGzHNpRS
# 4M90lFCxdEFaYWm0fuMJMFAGCisGAQQBgjcCAQwxQjBAoBaAFABQAG8AdwBlAHIA
# UwBoAGUAbABsoSaAJGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9Qb3dlclNoZWxs
# IDANBgkqhkiG9w0BAQEFAASCAQBNuuxIP4v1LirSvd0JeBjro5JmZ8Hn5VCj+gM9
# 1ckVitoeDvSUv22Aun0LWM89bzOS132tSEtk5YUABCEFvBWAohK4zl2gb4F1bZ3+
# lwZg+/NsnRDjV4VUBDcdQgfMMXBD3mYEWIpmbRe+amGwff+3BeC7bTUuR2b7wMLm
# bs8WN+QIQJLkcPgFut2O4qQxYWCtaDjvWapkeYaTCmhzTtlvAUmqH1egBAcSKxF8
# 3dRQ4IXyDZz97EyfRLKxLKfVdyoyv3fhm76F5+FyFWg26mJpe+P2mxnz2Z3cprFB
# IoQ2esLddWd1K995teeRE4EARxQrv3SWwQbjmXjCREqjyQLooYICKDCCAiQGCSqG
# SIb3DQEJBjGCAhUwggIRAgEBMIGOMHcxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQQIT
# MwAAANjkdflFb0j3rgAAAAAA2DAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsG
# CSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTcxMDE3MjAzNTA4WjAjBgkqhkiG
# 9w0BCQQxFgQUR038f2kUFbBQ7pkuxNlgvGH+00gwDQYJKoZIhvcNAQEFBQAEggEA
# UDNJMgUwFZsPtl6uvMcKxAomGs4t50548W3uPXyMwyZUFU6zjFQMwexPOiKjVYZe
# O2twYqbSxoo4P/dWh4389zaFWkesuP63t3U9FMB63wtYGCr7iFjhIqHw80+HNMBS
# Uq0q9PqddoKdwjwDh+W2ekf3nQTmx8LfGHGdzrBOW7EA3cMfEuhecPKhmRhQ8AJ2
# 24OmgP7VtPW2nli9NLrKzpi0KlSMrs4gSbD3BvYnOMiHPfMKSQkSikRu1qy/QY/2
# cXNMLnxd6pzna0eZpioWPCqfZhIV9hjsZrYzKNV/omWDGBxWSdVFwNzXlcPlOGqO
# fC5lOqcLOMjBjEehAVbk+g==
# SIG # End signature block
