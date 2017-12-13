
function Invoke-ProGetRestMethod
{
    <#
    .SYNOPSIS
    Invokes a ProGet REST method.

    .DESCRIPTION
    The `Invoke-ProGetRestMethod` invokes a ProGet REST API method. You pass the path to the endpoint (everything after `/api/`) via the `Name` parameter, the HTTP method to use via the `Method` parameter, and the parameters to pass in the body of the request via the `Parameter` parameter.  This function converts the `Parameter` hashtable to JSON and sends it in the body of the request.

    You also need to pass an object that represents the ProGet instance and API key to use when connecting via the `Session` parameter. Use the `New-ProGetSession` function to create a session object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # A session object that represents the ProGet instance to use. Use the `New-ProGetSession` function to create session objects.
        $Session,

        [Parameter(Mandatory=$true)]
        [string]
        # The path to the API endpoint.
        $Path,

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        # The HTTP/web method to use. The default is `POST`.
        $Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Post,

        [hashtable]
        # That parameters to pass to the method. These are converted to JSON and sent to the API in the body of the request.
        $Parameter,

        [Switch]
        # Send the request as JSON. Otherwise, the data is sent as name/value pairs.
        $AsJson,
        
        # Sends the contents of the file at this path as the body of the web request.
        [String]
        $InFile
    )

    Set-StrictMode -Version 'Latest'

    $uri = New-Object 'Uri' -ArgumentList $Session.Uri,$Path
    
    $contentType = 'application/json; charset=utf-8'
    $bodyParam = @{ }
    $body = ''
    $debugBody = ''
    if( $Parameter )
    {
        if( $AsJson )
        {
            $body = $Parameter | ConvertTo-Json -Depth 100
            $debugBody = $body -replace '("API_Key": +")[^"]+','$1********'
        }
        else
        {
            $body = $Parameter.Keys | ForEach-Object { '{0}={1}' -f [Web.HttpUtility]::UrlEncode($_),[Web.HttpUtility]::UrlEncode($Parameter[$_]) }
            $body = $body -join '&'
            $contentType = 'application/x-www-form-urlencoded; charset=utf-8'
            $debugBody = $Parameter.Keys | ForEach-Object {
                $value = $Parameter[$_]
                if( $_ -eq 'API_Key' )
                {
                    $value = '********'
                }
                '    {0}={1}' -f $_,$value }
        }
    }

    $headers = @{ }

    if( $Session.ApiKey )
    {
        $headers['X-ApiKey'] = $Session.ApiKey;
    }

    if( $Session.Credential )
    {
        $bytes = [Text.Encoding]::UTF8.GetBytes(('{0}:{1}' -f $Session.Credential.UserName,$Session.Credential.GetNetworkCredential().Password))
        $creds = 'Basic ' + [Convert]::ToBase64String($bytes)
        $headers['Authorization'] = $creds
    }

    #$DebugPreference = 'Continue'
    Write-Debug -Message ('{0} {1}' -f $Method.ToString().ToUpperInvariant(),($uri -replace '\b(API_Key=)([^&]+)','$1********'))
    Write-Debug -Message ('    Content-Type: {0}' -f $contentType)
    foreach( $headerName in $headers.Keys )
    {
        $value = $headers[$headerName]
        if( @( 'X-ApiKey', 'Authorization' ) -contains $headerName )
        {
            $value = '*' * 8
        }

        Write-Debug -Message ('    {0}: {1}' -f $headerName,$value)
    }
    
    if( $debugBody )
    {
        $debugBody | Write-Debug
    }

    $errorsAtStart = $Global:Error.Count
    try
    {
        $bodyParam = @{ }
        if( $body )
        {
            $bodyParam['Body'] = $body
        }
        elseif( $Infile )
        {
            $body = @{ }
            $bodyParam['Infile'] = $Infile
            $contentType = 'multipart/form-data'
        }
        $credentialParam = @{ }
        if( $Session.Credential )
        {
            $credentialParam['Credential'] = $Session.Credential
        }

        Invoke-RestMethod -Method $Method -Uri $uri @bodyParam -ContentType $contentType -Headers $headers @credentialParam | 
            ForEach-Object { $_ } 
    }
    catch [Net.WebException]
    {
        for( $idx = $errorsAtStart; $idx -lt $Global:Error.Count; ++$idx )
        {
            $Global:Error.RemoveAt(0)
        }

        Write-Error -ErrorRecord $_ -ErrorAction $ErrorActionPreference
    }
}
