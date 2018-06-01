###
# ==++==
#
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
###

<#
	Overrides the default Write-Debug so that the output gets routed back thru the
	$request.Debug() function
#>
function Write-Debug {
	param(
	[Parameter(Mandatory=$true)][string] $message,
	[parameter(ValueFromRemainingArguments=$true)]
	[object[]]
	 $args= @()
	)

	if( -not $request  ) {
		if( -not $args  ) {
			Microsoft.PowerShell.Utility\write-verbose $message
			return
		}

		$msg = [system.string]::format($message, $args)
		Microsoft.PowerShell.Utility\write-verbose $msg
		return
	}

	if( -not $args  ) {
		$null = $request.Debug($message);
		return
	}
	$null = $request.Debug($message,$args);
}

function Write-Error {
	param( 
		[Parameter(Mandatory=$true)][string] $Message,
		[Parameter()][string] $Category,
		[Parameter()][string] $ErrorId,
		[Parameter()][string] $TargetObject
	)

	$null = $request.Warning($Message);
}

<#
	Overrides the default Write-Verbose so that the output gets routed back thru the
	$request.Verbose() function
#>

function Write-Progress {
    param(
        [CmdletBinding()]

        [Parameter(Position=0)]
        [string]
        $Activity,

        # This parameter is not supported by request object
        [Parameter(Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Status,

        [Parameter(Position=2)]
        [ValidateRange(0,[int]::MaxValue)]
        [int]
        $Id,

        [Parameter()]
        [int]
        $PercentComplete=-1,

        # This parameter is not supported by request object
        [Parameter()]
        [int]
        $SecondsRemaining=-1,

        # This parameter is not supported by request object
        [Parameter()]
        [string]
        $CurrentOperation,        

        [Parameter()]
        [ValidateRange(-1,[int]::MaxValue)]
        [int]
        $ParentID=-1,

        [Parameter()]
        [switch]
        $Completed,

        # This parameter is not supported by request object
        [Parameter()]
        [int]
        $SourceID,

	    [object[]]
        $args= @()
    )

    $params = @{}

    if ($PSBoundParameters.ContainsKey("Activity")) {
        $params.Add("Activity", $PSBoundParameters["Activity"])
    }

    if ($PSBoundParameters.ContainsKey("Status")) {
        $params.Add("Status", $PSBoundParameters["Status"])
    }

    if ($PSBoundParameters.ContainsKey("PercentComplete")) {
        $params.Add("PercentComplete", $PSBoundParameters["PercentComplete"])
    }

    if ($PSBoundParameters.ContainsKey("Id")) {
        $params.Add("Id", $PSBoundParameters["Id"])
    }

    if ($PSBoundParameters.ContainsKey("ParentID")) {
        $params.Add("ParentID", $PSBoundParameters["ParentID"])
    }

    if ($PSBoundParameters.ContainsKey("Completed")) {
        $params.Add("Completed", $PSBoundParameters["Completed"])
    }

	if( -not $request  ) {    
		if( -not $args  ) {
			Microsoft.PowerShell.Utility\Write-Progress @params
			return
		}

		$params["Activity"] = [system.string]::format($Activity, $args)
		Microsoft.PowerShell.Utility\Write-Progress @params
		return
	}

	if( -not $args  ) {
        $request.Progress($Activity, $Status, $Id, $PercentComplete, $SecondsRemaining, $CurrentOperation, $ParentID, $Completed)
	}

}

function Write-Verbose{
	param(
	[Parameter(Mandatory=$true)][string] $message,
	[parameter(ValueFromRemainingArguments=$true)]
	[object[]]
	 $args= @()
	)

	if( -not $request ) {
		if( -not $args ) {
			Microsoft.PowerShell.Utility\write-verbose $message
			return
		}

		$msg = [system.string]::format($message, $args)
		Microsoft.PowerShell.Utility\write-verbose $msg
		return
	}

	if( -not $args ) {
		$null = $request.Verbose($message);
		return
	}
	$null = $request.Verbose($message,$args);
}

<#
	Overrides the default Write-Warning so that the output gets routed back thru the
	$request.Warning() function
#>

function Write-Warning{
	param(
	[Parameter(Mandatory=$true)][string] $message,
	[parameter(ValueFromRemainingArguments=$true)]
	[object[]]
	 $args= @()
	)

	if( -not $request ) {
		if( -not $args ) {
			Microsoft.PowerShell.Utility\write-warning $message
			return
		}

		$msg = [system.string]::format($message, $args)
		Microsoft.PowerShell.Utility\write-warning $msg
		return
	}

	if( -not $args ) {
		$null = $request.Warning($message);
		return
	}
	$null = $request.Warning($message,$args);
}

<#
	Creates a new instance of a PackageSource object
#>
function New-PackageSource {
	param(
		[Parameter(Mandatory=$true)][string] $name,
		[Parameter(Mandatory=$true)][string] $location,
		[Parameter(Mandatory=$true)][bool] $trusted,
		[Parameter(Mandatory=$true)][bool] $registered,
		[bool] $valid = $false,
		[System.Collections.Hashtable] $details = $null
	)

	return New-Object -TypeName Microsoft.PackageManagement.MetaProvider.PowerShell.PackageSource -ArgumentList $name,$location,$trusted,$registered,$valid,$details
}

<#
	Creates a new instance of a SoftwareIdentity object
#>
function New-SoftwareIdentity {
	param(
		[Parameter(Mandatory=$true)][string] $fastPackageReference,
		[Parameter(Mandatory=$true)][string] $name,
		[Parameter(Mandatory=$true)][string] $version,
		[Parameter(Mandatory=$true)][string] $versionScheme,
		[Parameter(Mandatory=$true)][string] $source,
		[string] $summary,
		[string] $searchKey = $null,
		[string] $fullPath = $null,
		[string] $filename = $null,
		[System.Collections.Hashtable] $details = $null,
		[System.Collections.ArrayList] $entities = $null,
		[System.Collections.ArrayList] $links = $null,
		[bool] $fromTrustedSource = $false,
		[System.Collections.ArrayList] $dependencies = $null,
		[string] $tagId = $null,
		[string] $culture = $null,
        [string] $destination = $null
	)
	return New-Object -TypeName Microsoft.PackageManagement.MetaProvider.PowerShell.SoftwareIdentity -ArgumentList $fastPackageReference, $name, $version,  $versionScheme,  $source,  $summary,  $searchKey, $fullPath, $filename , $details , $entities, $links, $fromTrustedSource, $dependencies, $tagId, $culture, $destination
}

<#
	Creates a new instance of a SoftwareIdentity object based on an xml string
#>
function New-SoftwareIdentityFromXml {
    param(
        [Parameter(Mandatory=$true)][string] $xmlSwidtag,
        [bool] $commitImmediately = $false
    )

    return New-Object -TypeName Microsoft.PackageManagement.MetaProvider.PowerShell.SoftwareIdentity -ArgumentList $xmlSwidtag, $commitImmediately
}

<#
	Creates a new instance of a DyamicOption object
#>
function New-DynamicOption {
	param(
		[Parameter(Mandatory=$true)][Microsoft.PackageManagement.MetaProvider.PowerShell.OptionCategory] $category,
		[Parameter(Mandatory=$true)][string] $name,
		[Parameter(Mandatory=$true)][Microsoft.PackageManagement.MetaProvider.PowerShell.OptionType] $expectedType,
		[Parameter(Mandatory=$true)][bool] $isRequired,
		[System.Collections.ArrayList] $permittedValues = $null
	)

	if( -not $permittedValues ) {
		return New-Object -TypeName Microsoft.PackageManagement.MetaProvider.PowerShell.DynamicOption -ArgumentList $category,$name,  $expectedType, $isRequired
	}
	return New-Object -TypeName Microsoft.PackageManagement.MetaProvider.PowerShell.DynamicOption -ArgumentList $category,$name,  $expectedType, $isRequired, $permittedValues.ToArray()
}

<#
	Creates a new instance of a Feature object
#>
function New-Feature {
	param(
		[Parameter(Mandatory=$true)][string] $name,
		[System.Collections.ArrayList] $values = $null
	)

	if( -not $values ) {
		return New-Object -TypeName Microsoft.PackageManagement.MetaProvider.PowerShell.Feature -ArgumentList $name
	}
	return New-Object -TypeName Microsoft.PackageManagement.MetaProvider.PowerShell.Feature -ArgumentList $name, $values.ToArray()
}

<#
	Duplicates the $request object and overrides the client-supplied data with the specified values.
#>
function New-Request {
	param(
		[System.Collections.Hashtable] $options = $null,
		[System.Collections.ArrayList] $sources = $null,
		[PSCredential] $credential = $null
	)

	return $request.CloneRequest( $options, $sources, $credential )
}

function New-Entity {
	param(
		[Parameter(Mandatory=$true)][string] $name,
		[Parameter(Mandatory=$true,ParameterSetName="role")][string] $role,
		[Parameter(Mandatory=$true,ParameterSetName="roles")][System.Collections.ArrayList]$roles,
        [string] $regId = $null,
        [string] $thumbprint= $null
	)

	$o = New-Object -TypeName Microsoft.PackageManagement.MetaProvider.PowerShell.Entity
	$o.Name = $name

	# support role as a NMTOKENS string or an array of strings
	if( $role ) {
		$o.Role = $role
	} 
	if( $roles )  {
		$o.Roles = $roles
	}

	$o.regId = $regId
	$o.thumbprint = $thumbprint
	return $o
}

function New-Link {
	param(
		[Parameter(Mandatory=$true)][string] $HRef,
		[Parameter(Mandatory=$true)][string] $relationship,
		[string] $mediaType = $null,
		[string] $ownership = $null,
		[string] $use= $null,
		[string] $appliesToMedia= $null,
		[string] $artifact = $null
	)

	$o = New-Object -TypeName Microsoft.PackageManagement.MetaProvider.PowerShell.Link

	$o.HRef = $HRef
	$o.Relationship =$relationship
	$o.MediaType =$mediaType
	$o.Ownership =$ownership
	$o.Use = $use
	$o.AppliesToMedia = $appliesToMedia
	$o.Artifact = $artifact

	return $o
}

function New-Dependency {
	param(
		[Parameter(Mandatory=$true)][string] $providerName,
		[Parameter(Mandatory=$true)][string] $packageName,
		[string] $version= $null,
		[string] $source = $null,
		[string] $appliesTo = $null
	)

	$o = New-Object -TypeName Microsoft.PackageManagement.MetaProvider.PowerShell.Dependency

	$o.ProviderName = $providerName
	$o.PackageName =$packageName
	$o.Version =$version
	$o.Source =$source
	$o.AppliesTo = $appliesTo

	return $o
}
# SIG # Begin signature block
# MIIarQYJKoZIhvcNAQcCoIIanjCCGpoCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUjKO234+wyrCEMWnBFRlvbf4O
# UcSgghWAMIIEwjCCA6qgAwIBAgITMwAAALu2dyRxSiAAIAAAAAAAuzANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTYwOTA3MTc1ODQ3
# WhcNMTgwOTA3MTc1ODQ3WjCBsjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEMMAoGA1UECxMDQU9DMScwJQYDVQQLEx5uQ2lwaGVyIERTRSBFU046
# MERFOC0yREM1LTNDQTkxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNl
# cnZpY2UwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC48+U38sLxQNu8
# OO1wnT9mKeHv+f/jxafTFXzx9VF59IK/n/jLv4HIXt8ucy3KjBTM5Jf6D0nQlI4h
# Sizjrn6lO61q+V8oZiYYhjgR258rg8MDIrPpZMxK6OmD0d1wtksHW1cG21YKg5jg
# idT2hmQBpiL9Cra3ccY5keu0kl6OfZFoj4DF0i0JRVFSy1C9gKP4H950XIjlA2Yo
# TWN0LuHEHYMvwD1mOpAq2dVwPZh6xeNnpV8U/qLneyb9I/SqY/87tsZCn4FH7R3x
# 0TgK2eRwpWXfwGbUb1R/UTLd20aQ+my4NWwSsndeG+0vsYwaF40heB2lo1ThmByr
# OTBmEosTAgMBAAGjggEJMIIBBTAdBgNVHQ4EFgQUj9yNX+4+R8GZ7rcy4MdnJHXO
# KkswHwYDVR0jBBgwFoAUIzT42VJGcArtQPt2+7MrsMM1sw8wVAYDVR0fBE0wSzBJ
# oEegRYZDaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMv
# TWljcm9zb2Z0VGltZVN0YW1wUENBLmNybDBYBggrBgEFBQcBAQRMMEowSAYIKwYB
# BQUHMAKGPGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9z
# b2Z0VGltZVN0YW1wUENBLmNydDATBgNVHSUEDDAKBggrBgEFBQcDCDANBgkqhkiG
# 9w0BAQUFAAOCAQEAcMI8Q0PxQVvxZSD1fjszuD6VF/qPZjKZj9WLTjWjZT2k9lzG
# yvSL7vy9J7lnyMATrbm5ptqAfdonNygLaBm05MnrIvgPJYK89wyTIyS1u71ro7z+
# EVrGPaKZiD+WvH8SWP+OWZQNf55fEL8tZo+a1oHm3lUARi5rR916OQvb4UnCENyV
# g8IfmupnwpxHcmIBUWZtTKAuKmuX/c8G2z4KJ8WhruYjPDWYQXJrQ5t7PhZa19Ge
# kOOtigge9EKIAWhZUJkw9fnfRm2IFX0gWtOzRXVNhR109ISacbNxd0oUboRYHmlq
# wGrOz64/3SDdOeN7PjvLwFmThuoXIsxrjQD8ODCCBOswggPToAMCAQICEzMAAAF4
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
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRYAVqR
# iyKDjT7HiTWuWCUStG7V/DBQBgorBgEEAYI3AgEMMUIwQKAWgBQAUABvAHcAZQBy
# AFMAaABlAGwAbKEmgCRodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vUG93ZXJTaGVs
# bCAwDQYJKoZIhvcNAQEBBQAEggEAPH3vDUjssuarA0D16NWJwpYBoUCPlc+K8v/W
# UmASq3fgp/0tSin/skxv6Dh0tbRKo3hOAgjKkc5izrvx/D8v20PYobwXv+ysfXnT
# 1nzE9fCAJ+3ovwEzFw9YDdmAahTEoCM3vWq8FINw5rMDN7wqgUfP496DVoUKA65Z
# 4oBML0chDX18C5NoF1Ps4+bRtl0irXSrfy4KCk1e+5IwZmwbQXkVHfzERp/BcbsF
# /nX8TYlRB8CRUNtiVd2f2aHrmZsJFgTx8HBYqIv3u3RFtEsd4SozpP5T5DuA05WH
# YHzbTpVrCnPTGuE0Oa/jhPu89rO9LANMCXi7vIxfWD5fFHcXJ6GCAigwggIkBgkq
# hkiG9w0BCQYxggIVMIICEQIBATCBjjB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSEwHwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EC
# EzMAAAC7tnckcUogACAAAAAAALswCQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzEL
# BgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE3MTAxNzIwMzUxMVowIwYJKoZI
# hvcNAQkEMRYEFHs4F9LvgVyaHin2i3TYlr89AjI/MA0GCSqGSIb3DQEBBQUABIIB
# ACg7na0ApgF3EZqht4tJvbPvsF2WMtL/g4Pg0k56Tq/fuclche1n17x6r2B9SXuI
# bJU31KD6GpkY9lAC93FB5K8Qr5Y0I5G2Ayfo653kOi3kgxGhiXo3rPZvX5UC8IVB
# fmLlqPt6ainXgYs+qpQH6I5p2k3g7WUkzOuYspaDWNDDZA/LMZF4vy2iPQhSqDUF
# 6ZbNJhsxBw238bAtQXkp38pEXUQ44FhEpSxK7/ErAuD9mMzTKD/4jlK8voLeJL+a
# ZHnf6bLWoMWNJREgzNL8/nF7RCYWitTptgV7WwBKTnoP+bS42JdtfsiwK204PN5E
# EYeLpBBMc+RpX8A03GiPOXI=
# SIG # End signature block
