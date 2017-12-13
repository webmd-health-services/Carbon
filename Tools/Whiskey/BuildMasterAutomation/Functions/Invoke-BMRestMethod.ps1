
function Invoke-BMRestMethod
{
    <#
    .SYNOPSIS
    Invokes a BuildMaster REST method.

    .DESCRIPTION
    The `Invoke-BMRestMethod` invokes a BuildMaster REST API method. You pass the path to the endpoint (everything after `/api/`) via the `Name` parameter, the HTTP method to use via the `Method` parameter, and the parameters to pass in the body of the request via the `Parameter` parameter.  This function converts the `Parameter` hashtable to JSON and sends it in the body of the request.

    You also need to pass an object that represents the BuildMaster instance and API key to use when connecting via the `Session` parameter. Use the `New-BMSession` function to create a session object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # A session object that represents the BuildMaster instance to use. Use the `New-BMSession` function to create session objects.
        $Session,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the API to use. The should be everything after `/api/` in the method's URI.
        $Name,

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        # The HTTP/web method to use. The default is `POST`.
        $Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Post,

        [hashtable]
        # That parameters to pass to the method. These are converted to JSON and sent to the API in the body of the request.
        $Parameter,

        [Switch]
        # Send the request as JSON. Otherwise, the data is sent as name/value pairs.
        $AsJson
    )

    Set-StrictMode -Version 'Latest'

    $uri = '{0}api/{1}' -f $Session.Uri,$Name
    
    $contentType = 'application/json; charset=utf-8'
    $debugBody = ''
    $body = ''
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

    $headers = @{
                    'X-ApiKey' = $Session.ApiKey;
                }

    #$DebugPreference = 'Continue'
    Write-Debug -Message ('{0} {1}' -f $Method.ToString().ToUpperInvariant(),($uri -replace '\b(API_Key=)([^&]+)','$1********'))
    Write-Debug -Message ('    Content-Type: {0}' -f $contentType)
    foreach( $headerName in $headers.Keys )
    {
        $value = $headers[$headerName]
        if( $headerName -eq 'X-ApiKey' )
        {
            $value = '*' * 8
        }

        Write-Debug -Message ('    {0}: {1}' -f $headerName,$value)
    }
    
    $debugBody | Write-Debug

    try
    {
        Invoke-RestMethod -Method $Method -Uri $uri -Body $body -ContentType $contentType -Headers $headers | 
            ForEach-Object { $_ } 
    }
    catch [Net.WebException]
    {
        Write-Error -ErrorRecord $_
    }
}