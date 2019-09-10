
function Get-CCertificateStore
{
    <#
    .SYNOPSIS
    Gets an `X509CertificateStore` object for the given location and store name.

    .DESCRIPTION
    Returns an `X509Store` for a given store location and store name.  The store must exist.  Before being retured, it is opened for writing.  If you don't have permission to write to the store, you'll get an error.

    If you just want to read a store, we recommend using PowerShell's `cert:` drive.

    .OUTPUTS
    Security.Cryptography.X509Certificates.X509Store.

    .EXAMPLE
    Get-CCertificateStore -StoreLocation LocalMachine -StoreName My

    Get the local computer's Personal certificate store.

    .EXAMPLE
    Get-CCertificateStore -StoreLocation CurrentUser -StoreName Root

    Get the current user's Trusted Root Certification Authorities certificate store.
    #>
    [CmdletBinding(DefaultParameterSetName='ByStoreName')]
    param(
        [Parameter(Mandatory=$true)]
        [Security.Cryptography.X509Certificates.StoreLocation]
        # The location of the certificate store to get.
        $StoreLocation,
        
        [Parameter(Mandatory=$true,ParameterSetName='ByStoreName')]
        [Security.Cryptography.X509Certificates.StoreName]
        # The name of the certificate store to get.
        $StoreName,

        [Parameter(Mandatory=$true,ParameterSetName='ByCustomStoreName')]
        [string]
        # The name of the non-standard certificate store to get. Use this to pull certificates from a non-standard store.
        $CustomStoreName
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( $PSCmdlet.ParameterSetName -eq 'ByStoreName' )
    {
        $store = New-Object Security.Cryptography.X509Certificates.X509Store $StoreName,$StoreLocation
    }
    else
    {
        $store = New-Object Security.Cryptography.X509Certificates.X509Store $CustomStoreName,$StoreLocation
    }

    $store.Open( ([Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite) )
    return $store
}

