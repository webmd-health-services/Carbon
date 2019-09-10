
function Find-CADUser
{
    <#
    .SYNOPSIS
    Finds a user in Active Directory.

    .DESCRIPTION
    Searches the Active Directory domain given by `DomainUrl` for a user whose `sAMAccountName` matches the `sAMAccountName` passed in.  Returns the `DirectoryEntry` object for that user.  If there are any errors communicating with the domain controller, `$null` is returned.
    
    .OUTPUTS
    System.DirectoryServices.DirectoryEntry.  The directory entry object of the user's account in Active Directory or `$null` if the user isn't found.
    
    .LINK
    http://msdn.microsoft.com/en-us/library/aa746475.aspx
    
    .EXAMPLE
    Find-CADUser -DomainUrl LDAP://dc.example.com:389 -sAMAccountName $env:USERNAME
    
    Finds the AD user whose Windows username (sAMAccountName) is equal to thecurrently logged on user's username.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The LDAP URL to the domain controller to contact.
        $DomainUrl,
        
        [Parameter(Mandatory=$true,ParameterSetName='BysAMAccountName')]
        [string]
        # Search by a user's sAMAcountName (i.e. Windows username).  Special
        # characters are escaped.
        $sAMAccountName
    )
   
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $domain = [adsi] $DomainUrl
    $searcher = [adsisearcher] $domain
    
    $filterPropertyName = 'sAMAccountName'
    $filterPropertyValue = $sAMAccountName
    
    $filterPropertyValue = Format-CADSearchFilterValue $filterPropertyValue
    
    $searcher.Filter = "(&(objectClass=User) ($filterPropertyName=$filterPropertyValue))"
    try
    {
        $result = $searcher.FindOne() 
        if( $result )
        {
            $result.GetDirectoryEntry() 
        }
    }
    catch
    {
        Write-Error ("Exception finding user {0} on domain controller {1}: {2}" -f $sAMAccountName,$DomainUrl,$_.Exception.Message)
        return $null
    }
    
}

