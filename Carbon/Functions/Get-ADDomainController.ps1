
function Get-CADDomainController
{
    <#
    .SYNOPSIS
    Gets the domain controller of the current computer's domain, or for a 
    specific domain.
    
    .DESCRIPTION
    When working with Active Directory, it's important to have the hostname of 
    the domain controller you need to work with.  This function will find the 
    domain controller for the domain of the current computer or the domain 
    controller for a given domain.
    
    .OUTPUTS
    System.String. The hostname for the domain controller.  If the domain 
    controller is not found, $null is returned.
    
    .EXAMPLE
    > Get-CADDomainController
    Returns the domain controller for the current computer's domain.  
    Approximately equivialent to the hostname given in the LOGONSERVER 
    environment variable.
    
    .EXAMPLE
    > Get-CADDomainController -Domain MYDOMAIN
    Returns the domain controller for the MYDOMAIN domain.
    #>
    [CmdletBinding()]
    param(
        [string]
        # The domain whose domain controller to get.  If not given, gets the 
        # current computer's domain controller.
        $Domain
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( $Domain )
    {
        $principalContext = $null
        try
        {
            Add-Type -AssemblyName System.DirectoryServices.AccountManagement
            $principalContext = New-Object DirectoryServices.AccountManagement.PrincipalContext Domain,$Domain
            return $principalContext.ConnectedServer
        }
        catch
        {
            $firstException = $_.Exception
            while( $firstException.InnerException )
            {
                $firstException = $firstException.InnerException
            }
            Write-Error ("Unable to find domain controller for domain '{0}': {1}: {2}" -f $Domain,$firstException.GetType().FullName,$firstException.Message)
            return $null
        }
        finally
        {
            if( $principalContext )
            {
                $principalContext.Dispose()
            }
        }
    }
    else
    {
        $root = New-Object DirectoryServices.DirectoryEntry "LDAP://RootDSE"
        try
        {
            return  $root.Properties["dnsHostName"][0].ToString();
        }
        finally
        {
            $root.Dispose()
        }
    }
}

