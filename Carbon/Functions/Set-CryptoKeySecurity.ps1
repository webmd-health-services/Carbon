
function Set-CryptoKeySecurity
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,

        [Parameter(Mandatory=$true)]
        [Security.AccessControl.CryptoKeySecurity]
        $CryptoKeySecurity,

        [Parameter(Mandatory=$true)]
        [string]
        $Action
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $keyContainerInfo = $Certificate.PrivateKey.CspKeyContainerInfo
    $cspParams = New-Object 'Security.Cryptography.CspParameters' ($keyContainerInfo.ProviderType, $keyContainerInfo.ProviderName, $keyContainerInfo.KeyContainerName)
    $cspParams.Flags = [Security.Cryptography.CspProviderFlags]::UseExistingKey
    $cspParams.KeyNumber = $keyContainerInfo.KeyNumber
    if( (Split-Path -NoQualifier -Path $Certificate.PSPath) -like 'LocalMachine\*' )
    {
        $cspParams.Flags = $cspParams.Flags -bor [Security.Cryptography.CspProviderFlags]::UseMachineKeyStore
    }
    $cspParams.CryptoKeySecurity = $CryptoKeySecurity
                        
    try
    {                    
        # persist the rule change
        if( $PSCmdlet.ShouldProcess( ('{0} ({1})' -f $Certificate.Subject,$Certificate.Thumbprint), $Action ) )
        {
            $null = New-Object 'Security.Cryptography.RSACryptoServiceProvider' ($cspParams)
        }
    }
    catch
    {
        $actualException = $_.Exception
        while( $actualException.InnerException )
        {
            $actualException = $actualException.InnerException
        }
        Write-Error ('Failed to {0} to ''{1}'' ({2}) certificate''s private key: {3}: {4}' -f $Action,$Certificate.Subject,$Certificate.Thumbprint,$actualException.GetType().FullName,$actualException.Message)
    }
}
