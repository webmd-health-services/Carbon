#
# Copyright (c) Microsoft Corporation.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# This PS DSC resource enables installing a package. The resource uses Install-Package cmdlet
# to install the package from various providers/sources.

Import-LocalizedData -BindingVariable LocalizedData -filename MSFT_PackageManagement.strings.psd1

Import-Module -Name "$PSScriptRoot\..\PackageManagementDscUtilities.psm1"

function Get-TargetResource
{
    <#
    .SYNOPSIS

    This DSC resource provides a mechanism to download and install packages on a computer. 

    Get-TargetResource returns the current state of the resource.

    .PARAMETER Name
    Specifies the name of the Package to be installed or uninstalled.

    .PARAMETER Source
    Specifies the name of the package source where the package can be found.
    This can either be a URI or a source registered with Register-PackageSource cmdlet.
    The DSC resource MSFT_PackageManagementSource can also register a package source.
    
    .PARAMETER RequiredVersion
    Specifies the exact version of the package that you want to install. If you do not specify this parameter, 
    this DSC resource installs the newest available version of the package that also satisfies any
    maximum version specified by the MaximumVersion parameter.

    .PARAMETER MaximumVersion
    Specifies the maximum allowed version of the package that you want to install. If you do not specify this parameter, 
    this DSC resource installs the highest-numbered available version of the package.

    .PARAMETER MinimumVersion
    Specifies the minimum allowed version of the package that you want to install. If you do not add this parameter, 
    this DSC resource intalls the highest available version of the package that also satisfies any maximum 
    specified version specified by the MaximumVersion parameter.

    .PARAMETER SourceCredential
    Specifies a user account that has rights to install a package for a specified package provider or source.

    .PARAMETER ProviderName
    Specifies a package provider name to which to scope your package search. You can get package provider names 
    by running the Get-PackageProvider cmdlet.

    .PARAMETER AdditionalParameters
    Provider specific parameters that are passed as an Hashtable. For example, for NuGet provider you can
    pass additional parameters like DestinationPath.
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $RequiredVersion,
        
        [Parameter()]
        [System.String]
        $MinimumVersion,

        [Parameter()]
        [System.String]
        $MaximumVersion,

        [Parameter()]
        [System.String]
        $Source,

        [Parameter()]
        [PSCredential] $SourceCredential,

        [Parameter()]
        [System.String]
        $ProviderName,
        
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]$AdditionalParameters        
    )
    
    $ensure = "Absent"
    $null = $PSBoundParameters.Remove("Source")
    $null = $PSBoundParameters.Remove("SourceCredential")

    if ($AdditionalParameters)
    {
         foreach($instance in $AdditionalParameters)
         {
             Write-Verbose ('AdditionalParameter: {0}, AdditionalParameterValue: {1}' -f $instance.Key, $instance.Value)
             $null = $PSBoundParameters.Add($instance.Key, $instance.Value)
         }
    }
    $null = $PSBoundParameters.Remove("AdditionalParameters")
    
    $verboseMessage =$localizedData.StartGetPackage -f (GetMessageFromParameterDictionary $PSBoundParameters),$env:PSModulePath
    Write-Verbose -Message $verboseMessage
    $result = PackageManagement\Get-Package @PSBoundParameters -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        

    if ($result.count -eq 1)
    {
        Write-Verbose -Message ($localizedData.PackageFound -f $Name)
        $ensure = "Present"
    }
    elseif ($result.count -gt 1)
    {
        Write-Verbose -Message ($localizedData.MultiplePackagesFound -f $Name)
        $ensure = "Present"
    }
    else
    {
        Write-Verbose -Message ($localizedData.PackageNotFound -f $($Name))
    }

    Write-Debug -Message "Source $($Name) is $($ensure)"
                         
    
    if ($ensure -eq 'Absent')
    {
        return @{
            Ensure       = $ensure
            Name         = $Name
            ProviderName = $ProviderName
            RequiredVersion = $RequiredVersion
            MinimumVersion = $MinimumVersion
            MaximumVersion = $MaximumVersion
        }
    }
    else
    {
        if ($result.Count -gt 1)
        {
          $result = $result[0]
        }

        return  @{
                Ensure             = $ensure
                Name               = $result.Name
                ProviderName       = $result.ProviderName
                Source             = $result.source
                RequiredVersion    = $result.Version
            } 
    } 
}

function Test-TargetResource
{
    <#
    .SYNOPSIS

    This DSC resource provides a mechanism to download and install packages on a computer. 

    Test-TargetResource returns a boolean which determines whether the resource is in
    desired state or not.

    .PARAMETER Name
    Specifies the name of the Package to be installed or uninstalled.

    .PARAMETER Source
    Specifies the name of the package source where the package can be found.
    This can either be a URI or a source registered with Register-PackageSource cmdlet.
    The DSC resource MSFT_PackageManagementSource can also register a package source.
    
    .PARAMETER RequiredVersion
    Specifies the exact version of the package that you want to install. If you do not specify this parameter, 
    this DSC resource installs the newest available version of the package that also satisfies any
    maximum version specified by the MaximumVersion parameter.

    .PARAMETER MaximumVersion
    Specifies the maximum allowed version of the package that you want to install. If you do not specify this parameter, 
    this DSC resource installs the highest-numbered available version of the package.

    .PARAMETER MinimumVersion
    Specifies the minimum allowed version of the package that you want to install. If you do not add this parameter, 
    this DSC resource intalls the highest available version of the package that also satisfies any maximum 
    specified version specified by the MaximumVersion parameter.

    .PARAMETER SourceCredential
    Specifies a user account that has rights to install a package for a specified package provider or source.

    .PARAMETER ProviderName
    Specifies a package provider name to which to scope your package search. You can get package provider names 
    by running the Get-PackageProvider cmdlet.

    .PARAMETER AdditionalParameters
    Provider specific parameters that are passed as an Hashtable. For example, for NuGet provider you can
    pass additional parameters like DestinationPath.
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $RequiredVersion,
        
        [Parameter()]
        [System.String]
        $MinimumVersion,

        [Parameter()]
        [System.String]
        $MaximumVersion,

        [Parameter()]
        [System.String]
        $Source,

        [Parameter()]
        [PSCredential] $SourceCredential,
                
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure="Present",

        [Parameter()]
        [System.String]
        $ProviderName,
        
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]$AdditionalParameters         
    )

    
    Write-Verbose -Message ($localizedData.StartTestPackage -f (GetMessageFromParameterDictionary $PSBoundParameters))
    $null = $PSBoundParameters.Remove("Ensure")
    
    $temp = Get-TargetResource @PSBoundParameters

    if ($temp.Ensure -eq $ensure)
    {
        Write-Verbose -Message ($localizedData.InDesiredState -f $Name, $Ensure, $temp.Ensure)            
        return $True 
    }
    else
    {
        Write-Verbose -Message ($localizedData.NotInDesiredState -f $Name,$ensure,$temp.ensure)            
        return [bool] $False
    }    
}

function Set-TargetResource
{
    <#
    .SYNOPSIS

    This DSC resource provides a mechanism to download and install packages on a computer. 

    Set-TargetResource either intalls or uninstall a package as defined by the vaule of Ensure parameter.

    .PARAMETER Name
    Specifies the name of the Package to be installed or uninstalled.

    .PARAMETER Source
    Specifies the name of the package source where the package can be found.
    This can either be a URI or a source registered with Register-PackageSource cmdlet.
    The DSC resource MSFT_PackageManagementSource can also register a package source.
    
    .PARAMETER RequiredVersion
    Specifies the exact version of the package that you want to install. If you do not specify this parameter, 
    this DSC resource installs the newest available version of the package that also satisfies any
    maximum version specified by the MaximumVersion parameter.

    .PARAMETER MaximumVersion
    Specifies the maximum allowed version of the package that you want to install. If you do not specify this parameter, 
    this DSC resource installs the highest-numbered available version of the package.

    .PARAMETER MinimumVersion
    Specifies the minimum allowed version of the package that you want to install. If you do not add this parameter, 
    this DSC resource intalls the highest available version of the package that also satisfies any maximum 
    specified version specified by the MaximumVersion parameter.

    .PARAMETER SourceCredential
    Specifies a user account that has rights to install a package for a specified package provider or source.

    .PARAMETER ProviderName
    Specifies a package provider name to which to scope your package search. You can get package provider names 
    by running the Get-PackageProvider cmdlet.

    .PARAMETER AdditionalParameters
    Provider specific parameters that are passed as an Hashtable. For example, for NuGet provider you can
    pass additional parameters like DestinationPath.
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $RequiredVersion,
        
        [Parameter()]
        [System.String]
        $MinimumVersion,

        [Parameter()]
        [System.String]
        $MaximumVersion,

        [Parameter()]
        [System.String]
        $Source,

        [Parameter()]
        [PSCredential] $SourceCredential,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure="Present",

        [Parameter()]
        [System.String]
        $ProviderName,
        
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]$AdditionalParameters        
    )

    Write-Verbose -Message ($localizedData.StartSetPackage -f (GetMessageFromParameterDictionary $PSBoundParameters))
    
    $null = $PSBoundParameters.Remove("Ensure")
    
    if ($AdditionalParameters)
    {
         foreach($instance in $AdditionalParameters)
         {
             Write-Verbose ('AdditionalParameter: {0}, AdditionalParameterValue: {1}' -f $instance.Key, $instance.Value)
             $null = $PSBoundParameters.Add($instance.Key, $instance.Value)
         }
    }

    $PSBoundParameters.Remove("AdditionalParameters")

       
        # We do not want others to control the behavior of ErrorAction
        # while calling Install-Package/Uninstall-Package.
        $PSBoundParameters.Remove("ErrorAction")
        if ($Ensure -eq "Present")
        {
            PackageManagement\Install-Package @PSBoundParameters -ErrorAction Stop
        }   
        else
        {
            # we dont source location for uninstalling an already
            # installed package
            $PSBoundParameters.Remove("Source")
            # Ensure is Absent
            PackageManagement\Uninstall-Package @PSBoundParameters -ErrorAction Stop
        }
 }
 
 function GetMessageFromParameterDictionary
 {
    <#
        Returns a strng of form "ParameterName:ParameterValue"
        Used with Write-Verbose message. The input is mostly $PSBoundParameters
    #>
    param([System.Collections.IDictionary] $paramDictionary)

    $returnValue = ""
    $paramDictionary.Keys | ForEach-Object { $returnValue += "-{0} {1} " -f $_,$paramDictionary[$_] }
    return $returnValue
 }

Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource


# SIG # Begin signature block
# MIIarQYJKoZIhvcNAQcCoIIanjCCGpoCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGdi5jrBks7tyGo4tHzRmqb7c
# ckygghWAMIIEwjCCA6qgAwIBAgITMwAAALpqNt4arb08HwAAAAAAujANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTYwOTA3MTc1ODQ2
# WhcNMTgwOTA3MTc1ODQ2WjCBsjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEMMAoGA1UECxMDQU9DMScwJQYDVQQLEx5uQ2lwaGVyIERTRSBFU046
# RjZGRi0yREE3LUJCNzUxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNl
# cnZpY2UwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDbkc0j1DekYIbe
# VMtJHd3kxvCvQnxVC0dNcc2Tvu9dDBtILt4pNaDkO8xhEFIzOgsVucV5UZaQHtmu
# vcwvG3F1xrgKCTDGgRhdCb1/JGBs67K7emkIkF8dgbmZtITASGSjwzy2jhlK+eMn
# cSBuuoatutTxSS86jJxeN5pml2HV+z648r+rkqVmJpTLR2EnI07QcXt0nZ/g9J/k
# /A7mfSfFGeFHRHsVc/abypJdUNWSGv1RVYJ7FoicxUoXudbiYBdTDfsyvZPrOJ28
# 9S8KoZ7KUxGuSGGDkyfctQgZoZFI+XlD89KmKiNbahq9hG5m5weSGwVePfw/99JH
# GTI+jC25AgMBAAGjggEJMIIBBTAdBgNVHQ4EFgQUW+wPFw2KORr5sOGDFIF72bhI
# HKAwHwYDVR0jBBgwFoAUIzT42VJGcArtQPt2+7MrsMM1sw8wVAYDVR0fBE0wSzBJ
# oEegRYZDaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMv
# TWljcm9zb2Z0VGltZVN0YW1wUENBLmNybDBYBggrBgEFBQcBAQRMMEowSAYIKwYB
# BQUHMAKGPGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9z
# b2Z0VGltZVN0YW1wUENBLmNydDATBgNVHSUEDDAKBggrBgEFBQcDCDANBgkqhkiG
# 9w0BAQUFAAOCAQEAB4FDLPBU1MrtqkPH4Y0KmjsyoVUgQhQN/HvuW46j0DrKoDVr
# cloJb21SN2CQe9oKarFfjyxfmXZ3ChKmB42MBaHkETqo9LAG22q3cpxbYO8W0uke
# 4RpYA/rV8V+S310vexazwXLDrhddWQzaRJQT3Brq/H6T2LwBqV3fk0mKUXTKoPf2
# RrQu4+tAmZJBv5QOxhmNRiR4EazqERp4QUmIJfiPw9vmyf0K3mn6inBhYFIFj4wz
# hI1CfKpy/JwM1WozANowmalYYrBUcNa/lk2+9ZeywjI8TynnEo9HxtPhiugw2qGV
# mOKyJZIFdcS2lPoGPPkuPiTikd4ipJgIFAc7SzCCBOswggPToAMCAQICEzMAAAF4
# JVq1zSPGX5UAAQAAAXgwDQYJKoZIhvcNAQEFBQAweTELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEjMCEGA1UEAxMaTWljcm9zb2Z0IENvZGUgU2ln
# bmluZyBQQ0EwHhcNMTcwODExMjAxMTE1WhcNMTgwODExMjAxMTE1WjCBgjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEMMAoGA1UECxMDQU9DMR4w
# HAYDVQQDExVNaWNyb3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQCZbh1TVaudsrIbXUPPB9c8S+E+dKSbskHKYlG6SGTH8jhT
# hpuvGiAO87F2b9GHVN+DvszaMkGy/xQgHaGEJLfpnb3kpakic7E0bjDHdG4KnHRb
# no/wfUkGLfS79o+cw//RY8Ck6yE+0czDBcxp0Gbw5JyGP+KFqvzRR/3Tv3nt/5x0
# 5ZnEOHYP+eDVikDvn/DH+oxxtiCfX3tkvtm/yX4eOb47YdmYKQjCgz2+Nil/lupY
# vU0QFIjvke3jshqQINDng/vO9ys2qA0ex/q5hlLKQTST99dGoM86Ge6F723ReToq
# KnGLN8kiCG7uNapOAIQrpCHZq96CVumiaA5ZvxU9AgMBAAGjggFgMIIBXDATBgNV
# HSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQUjuhtD3FD7tk/RKloJFX05cpgLjcw
# UQYDVR0RBEowSKRGMEQxDDAKBgNVBAsTA0FPQzE0MDIGA1UEBRMrMjI5ODAzKzFh
# YmY5ZTVmLWNlZDAtNDJlNi1hNjVkLWQ5MzUwOTU5ZmUwZTAfBgNVHSMEGDAWgBTL
# EejK0rQWWAHJNy4zFha5TJoKHzBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3Js
# Lm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNDb2RTaWdQQ0FfMDgt
# MzEtMjAxMC5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY0NvZFNpZ1BDQV8wOC0zMS0y
# MDEwLmNydDANBgkqhkiG9w0BAQUFAAOCAQEAYnG/oHG/xgZYR8NAMHZ/vE9GM0e4
# 7YdhuTea2uY7pSGwM707wp8Wan0Fa6evK1PWfcd/XNOh2BpEv5o8RmKDoEsG0ECP
# 13Jug7cklfKreBVHQ+Djg43VVFLZpuo7aOAVK6wjlcnpPUtn+SfH9K0aM2FjDKVJ
# FW6XFKXBat5R+Zp6uOxWTxpSeMTeDC5zF6IY6ogR1uzU+9EQoRlAvkwX6po+exEL
# nMLr4++P+fqOxIU+PODIoB8ijClAqwwKvLlMPa3qlrNHt+LweTMu7lvGC/RA18wU
# zzXAeomuZ03blUw+bkOiVgWOk4S0RN7EnW7zjJV8gd/+G2dbToUi1cB/fTCCBbww
# ggOkoAMCAQICCmEzJhoAAAAAADEwDQYJKoZIhvcNAQEFBQAwXzETMBEGCgmSJomT
# 8ixkARkWA2NvbTEZMBcGCgmSJomT8ixkARkWCW1pY3Jvc29mdDEtMCsGA1UEAxMk
# TWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5MB4XDTEwMDgzMTIy
# MTkzMloXDTIwMDgzMTIyMjkzMloweTELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEjMCEGA1UEAxMaTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0Ew
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCycllcGTBkvx2aYCAgQpl2
# U2w+G9ZvzMvx6mv+lxYQ4N86dIMaty+gMuz/3sJCTiPVcgDbNVcKicquIEn08Gis
# TUuNpb15S3GbRwfa/SXfnXWIz6pzRH/XgdvzvfI2pMlcRdyvrT3gKGiXGqelcnNW
# 8ReU5P01lHKg1nZfHndFg4U4FtBzWwW6Z1KNpbJpL9oZC/6SdCnidi9U3RQwWfjS
# jWL9y8lfRjFQuScT5EAwz3IpECgixzdOPaAyPZDNoTgGhVxOVoIoKgUyt0vXT2Pn
# 0i1i8UU956wIAPZGoZ7RW4wmU+h6qkryRs83PDietHdcpReejcsRj1Y8wawJXwPT
# AgMBAAGjggFeMIIBWjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTLEejK0rQW
# WAHJNy4zFha5TJoKHzALBgNVHQ8EBAMCAYYwEgYJKwYBBAGCNxUBBAUCAwEAATAj
# BgkrBgEEAYI3FQIEFgQU/dExTtMmipXhmGA7qDFvpjy82C0wGQYJKwYBBAGCNxQC
# BAweCgBTAHUAYgBDAEEwHwYDVR0jBBgwFoAUDqyCYEBWJ5flJRP8KuEKU5VZ5KQw
# UAYDVR0fBEkwRzBFoEOgQYY/aHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9j
# cmwvcHJvZHVjdHMvbWljcm9zb2Z0cm9vdGNlcnQuY3JsMFQGCCsGAQUFBwEBBEgw
# RjBEBggrBgEFBQcwAoY4aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0
# cy9NaWNyb3NvZnRSb290Q2VydC5jcnQwDQYJKoZIhvcNAQEFBQADggIBAFk5Pn8m
# Rq/rb0CxMrVq6w4vbqhJ9+tfde1MOy3XQ60L/svpLTGjI8x8UJiAIV2sPS9MuqKo
# VpzjcLu4tPh5tUly9z7qQX/K4QwXaculnCAt+gtQxFbNLeNK0rxw56gNogOlVuC4
# iktX8pVCnPHz7+7jhh80PLhWmvBTI4UqpIIck+KUBx3y4k74jKHK6BOlkU7IG9KP
# cpUqcW2bGvgc8FPWZ8wi/1wdzaKMvSeyeWNWRKJRzfnpo1hW3ZsCRUQvX/TartSC
# Mm78pJUT5Otp56miLL7IKxAOZY6Z2/Wi+hImCWU4lPF6H0q70eFW6NB4lhhcyTUW
# X92THUmOLb6tNEQc7hAVGgBd3TVbIc6YxwnuhQ6MT20OE049fClInHLR82zKwexw
# o1eSV32UjaAbSANa98+jZwp0pTbtLS8XyOZyNxL0b7E8Z4L5UrKNMxZlHg6K3RDe
# ZPRvzkbU0xfpecQEtNP7LN8fip6sCvsTJ0Ct5PnhqX9GuwdgR2VgQE6wQuxO7bN2
# edgKNAltHIAxH+IOVN3lofvlRxCtZJj/UBYufL8FIXrilUEnacOTj5XJjdibIa4N
# XJzwoq6GaIMMai27dmsAHZat8hZ79haDJLmIz2qoRzEvmtzjcT3XAH5iR9HOiMm4
# GPoOco3Boz2vAkBq/2mbluIQqBC0N1AI1sM9MIIGBzCCA++gAwIBAgIKYRZoNAAA
# AAAAHDANBgkqhkiG9w0BAQUFADBfMRMwEQYKCZImiZPyLGQBGRYDY29tMRkwFwYK
# CZImiZPyLGQBGRYJbWljcm9zb2Z0MS0wKwYDVQQDEyRNaWNyb3NvZnQgUm9vdCBD
# ZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcNMDcwNDAzMTI1MzA5WhcNMjEwNDAzMTMw
# MzA5WjB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEwHwYD
# VQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQCfoWyx39tIkip8ay4Z4b3i48WZUSNQrc7dGE4kD+7Rp9FM
# rXQwIBHrB9VUlRVJlBtCkq6YXDAm2gBr6Hu97IkHD/cOBJjwicwfyzMkh53y9Gcc
# LPx754gd6udOo6HBI1PKjfpFzwnQXq/QsEIEovmmbJNn1yjcRlOwhtDlKEYuJ6yG
# T1VSDOQDLPtqkJAwbofzWTCd+n7Wl7PoIZd++NIT8wi3U21StEWQn0gASkdmEScp
# ZqiX5NMGgUqi+YSnEUcUCYKfhO1VeP4Bmh1QCIUAEDBG7bfeI0a7xC1Un68eeEEx
# d8yb3zuDk6FhArUdDbH895uyAc4iS1T/+QXDwiALAgMBAAGjggGrMIIBpzAPBgNV
# HRMBAf8EBTADAQH/MB0GA1UdDgQWBBQjNPjZUkZwCu1A+3b7syuwwzWzDzALBgNV
# HQ8EBAMCAYYwEAYJKwYBBAGCNxUBBAMCAQAwgZgGA1UdIwSBkDCBjYAUDqyCYEBW
# J5flJRP8KuEKU5VZ5KShY6RhMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAXBgoJ
# kiaJk/IsZAEZFgltaWNyb3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290IENl
# cnRpZmljYXRlIEF1dGhvcml0eYIQea0WoUqgpa1Mc1j0BxMuZTBQBgNVHR8ESTBH
# MEWgQ6BBhj9odHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0
# cy9taWNyb3NvZnRyb290Y2VydC5jcmwwVAYIKwYBBQUHAQEESDBGMEQGCCsGAQUF
# BzAChjhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jvc29m
# dFJvb3RDZXJ0LmNydDATBgNVHSUEDDAKBggrBgEFBQcDCDANBgkqhkiG9w0BAQUF
# AAOCAgEAEJeKw1wDRDbd6bStd9vOeVFNAbEudHFbbQwTq86+e4+4LtQSooxtYrhX
# AstOIBNQmd16QOJXu69YmhzhHQGGrLt48ovQ7DsB7uK+jwoFyI1I4vBTFd1Pq5Lk
# 541q1YDB5pTyBi+FA+mRKiQicPv2/OR4mS4N9wficLwYTp2OawpylbihOZxnLcVR
# DupiXD8WmIsgP+IHGjL5zDFKdjE9K3ILyOpwPf+FChPfwgphjvDXuBfrTot/xTUr
# XqO/67x9C0J71FNyIe4wyrt4ZVxbARcKFA7S2hSY9Ty5ZlizLS/n+YWGzFFW6J1w
# lGysOUzU9nm/qhh6YinvopspNAZ3GmLJPR5tH4LwC8csu89Ds+X57H2146SodDW4
# TsVxIxImdgs8UoxxWkZDFLyzs7BNZ8ifQv+AeSGAnhUwZuhCEl4ayJ4iIdBD6Svp
# u/RIzCzU2DKATCYqSCRfWupW76bemZ3KOm+9gSd0BhHudiG/m4LBJ1S2sWo9iaF2
# YbRuoROmv6pH8BJv/YoybLL+31HIjCPJZr2dHYcSZAI9La9Zj7jkIeW1sMpjtHhU
# BdRBLlCslLCleKuzoJZ1GtmShxN1Ii8yqAhuoFuMJb+g74TKIdbrHk/Jmu5J4PcB
# ZW+JC33Iacjmbuqnl84xKf8OxVtc2E0bodj6L54/LlUWa8kTo/0xggSXMIIEkwIB
# ATCBkDB5MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSMwIQYD
# VQQDExpNaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQQITMwAAAXglWrXNI8ZflQAB
# AAABeDAJBgUrDgMCGgUAoIGwMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBSOFGui
# gs9H08zaIeLyj3VmJZtZKTBQBgorBgEEAYI3AgEMMUIwQKAWgBQAUABvAHcAZQBy
# AFMAaABlAGwAbKEmgCRodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vUG93ZXJTaGVs
# bCAwDQYJKoZIhvcNAQEBBQAEggEAeTW5x/2ZGqUBVVH8ErMC6tHbJSQ075v6l8uR
# sn5dnoSBS360gjpFuPCCcndcto8Vto2mj/st5bTC6dqeeXhkc41Zq9Vw9f2s25AG
# Pr3sksd9cxWERN4nzwQYVSD90L+9Gj9FYJ4SBoKpNX7QUvmQkFCCOaCgnJ2ymzeD
# 6sNMHae9izAz3vbufUq0BYQd6xnOdwNMrVCunKnZKv0d8B8Rf4dXO4q/AF/IVw1h
# BVWchzBSVmOzMR2pVKALirol4nCApbR0Ng1bw6culNnwZ2YwzZ9HWKN5UH03NAbF
# D1VXIfEAplmvjEi/cl7qwd93/3zHZ9d0v9vPD1GEkAvsROVWLaGCAigwggIkBgkq
# hkiG9w0BCQYxggIVMIICEQIBATCBjjB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSEwHwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EC
# EzMAAAC6ajbeGq29PB8AAAAAALowCQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzEL
# BgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE3MTAxNzIwMDk0MlowIwYJKoZI
# hvcNAQkEMRYEFN6Xf1jdzcxcheU27jai00HO33XTMA0GCSqGSIb3DQEBBQUABIIB
# AE03crlL5KNUb8tPIIHmHiUH8FLBLZqM8/aHlzXJ2uCM7HD1doD5uo90Vckexd3y
# RwreRIvyvb3VQJIxgKmEEj1OR/nc+wUthsyKOo8+t980RnW9uE8alMjwJFLgHgm/
# /X4r1XkgLimhSJcxgMFoLajeEGcQy+06pSLIbXm3siv38dp66EaFD5ZUGur1sBrH
# YQEtpmFW9Rq0bu0P7nXNLqmnT0bnTmffzJClHDx13WpDl8tgY8NXQ7OgIlrJ9eF+
# hp8YKh4EsTGeW0YZRnMCckEU5YxhwsoYoFshnyX/sz7/tljn+zuP+0NTYY6Ev4ND
# jl6cwvs04VFbYlu2PUOkuJU=
# SIG # End signature block
