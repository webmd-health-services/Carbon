<#
.SYNOPSIS
Publishes a file to Bitbucket so it is available on a project's download page.

.LINK
https://bitbucket.org/Swyter/bitbucket-curl-upload-to-repo-downloads
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [pscredential]
    # The Bitbucket credentials to use.
    $Credential,

    [Parameter(Mandatory=$true)]
    [string]
    # The account of the project you're uploading a file to.
    $Username,

    [Parameter(Mandatory=$true)]
    [string]
    # The name of the project you're uploading a file to.
    $ProjectName,

    [Parameter(Mandatory=$true)]
    [string]
    # The file to upload.
    $FilePath 
)

Set-StrictMode -Version 'Latest'
#Requires -Version 4

function Assert-Response
{
    param(
        [Microsoft.PowerShell.Commands.HtmlWebResponseObject]
        $Response,

        [Uri]
        $ExpectedUri
    )

    if( -not $Response )
    {
        Write-Error ('No response.')
        return $false
    }

    if( $Response.BaseResponse.StatusCode -ne [Net.HttpStatusCode]::OK )
    {
        Write-Error ('Response failed.')
        return $false
    }

    if( $Response.BaseResponse.ResponseUri -ne $ExpectedUri )
    {
        Write-Error ('Response didn''t finish on URI {0} ({1}).' -f $ExpectedUri,$Response.BaseResponse.ResponseUri)
        return $false
    }

    $errorElement = $Response.ParsedHtml.getElementById('error')
    if( $errorElement )
    {
        Write-Error $errorElement.innerHtml
        return $false
    }

    return $true

}

$outFile = '{0}+{1}' -f (Split-Path -Leaf -Path $PSCommandPath),[IO.Path]::GetRandomFileName()
$outFile = Join-Path -Path $env:TEMP -ChildPath $outFile

$PSDefaultParameterValues.Clear()
$PSDefaultParameterValues['Invoke-WebRequest:PassThru'] = $true
$PSDefaultParameterValues['Invoke-WebRequest:OutFile'] = $outFile

$session = $null
$loginUri = 'https://bitbucket.org/account/signin/'
$resp = Invoke-WebRequest -Uri $loginUri -SessionVariable 'session' -Method Get 
if( -not (Assert-Response -Response $resp -ExpectedUri $loginUri) )
{
    exit 1
}

$PSDefaultParameterValues['Invoke-WebRequest:WebSession'] = $session

$form = $resp.Forms | 
            Where-Object { $_.Action -eq '/account/signin/' }
$formFields = $form.Fields
$formFields.id_username = $Credential.UserName
$formFields.id_password = $Credential.GetNetworkCredential().Password

$FilePath = Resolve-Path -Path $FilePath
if( -not $FilePath )
{
    return
}

$loginUri = 'https://bitbucket.org{0}' -f $form.Action
$body = @{
                'username' = $Credential.UserName;
                'password' = $Credential.GetNetworkCredential().Password;
                'csrfmiddlewaretoken' = $formFields.csrfmiddlewaretoken;
                'submit' = '';
                'next' = '';
             }
$resp = Invoke-WebRequest -Uri $loginUri -Method $form.Method -Body $body -Headers @{ Referer = $loginUri }
if( -not (Assert-Response -Response $resp -ExpectedUri 'https://bitbucket.org/') )
{
    exit 1
}

$downloadUri = 'https://bitbucket.org/{0}/{1}/downloads' -f $Username,$ProjectName
$resp = Invoke-WebRequest -Uri $downloadUri -Method Get 
if( -not (Assert-Response -Response $resp -ExpectedUri $downloadUri) )
{
    exit 1
}

$csrfToken = $resp.Forms |
                Where-Object { $_.Fields.ContainsKey( 'csrfmiddlewaretoken' ) } |
                ForEach-Object { $_.Fields.csrfmiddlewaretoken }
Write-Debug $csrfToken

$bytes = $fileBin = [IO.File]::ReadAllBytes($FilePath)
$bytes = [Text.Encoding]::ASCII.GetString($bytes)

$boundary = [Guid]::NewGuid().ToString()

$body = @"
--$boundary
Content-Disposition: form-data; name="csrfmiddlewaretoken"

$csrfToken
--$boundary
Content-Disposition: form-data; name="token"

--$boundary
Content-Disposition: form-data; name="files"; filename="$(Split-Path -Leaf -Path $FilePath)"
Content-Type: application/octet-stream

$bytes
--$boundary--
"@

Write-Debug $body

$contentType = 'multipart/form-data; boundary={0}' -f $boundary

$resp = Invoke-WebRequest -Uri $downloadUri -Method Post -Body $body -ContentType $contentType -Headers @{ Referer = $downloadUri }
if( -not (Assert-Response -Response $resp -ExpectedUri $downloadUri) )
{
    exit 1
}