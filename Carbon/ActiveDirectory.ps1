
Add-Type -AssemblyName System.DirectoryServices.AccountManagement

function Get-ADDomainController
{
    <#
    .SYNOPSIS
    Gets the domain controller of the current computer's domain, or for specific domain.
    #>
    [CmdletBinding()]
    param(
        [string]
        # The domain whose domain controller to get.  If not given, gets the current computer's domain controller.
        $Domain
    )
    
    if( $Domain )
    {
        try
        {
            $principalContext = New-Object DirectoryServices.AccountManagement.PrincipalContext Domain,$Domain
            return $principalContext.ConnectedServer
        }
        catch
        {
            Write-Error "Unable to find domain controller for domain '$Domain'."
            return $null
        }
    }
    else
    {
        $root = New-Object DirectoryServices.DirectoryEntry "LDAP://RootDSE"
        return  $root.Properties["dnsHostName"][0].ToString();
    }
}

function Find-ADUser
{
    <#
    .SYNOPSIS
    Finds a user in Active Directory.
    .LINK
    http://msdn.microsoft.com/en-us/library/aa746475.aspx
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The LDAP URL to the domain controller to contact.  
        $DomainUrl,
        
        [Parameter(Mandatory=$true,ParameterSetName='BysAMAccountName')]
        [string]
        # Search by a user's sAMAcountName.
        $sAMAccountName
    )
   
    $domain = [adsi] $DomainUrl
    $searcher = [adsisearcher] $domain
    
    $filterPropertyName = 'sAMAccountName'
    $filterPropertyValue = $sAMAccountName
    
    $filterPropertyValue = Format-ADSpecialCharacters $filterPropertyValue
    
    $searcher.Filter = "(&(objectClass=User) ($filterPropertyName=$filterPropertyValue))"
    $result = $searcher.FindOne() 
    if( $result )
    {
        $result.GetDirectoryEntry() 
    }
}

function Format-ADSpecialCharacters
{
    <#
    .SYNOPSIS
    Escapes Active Directory special characters from a string.
    .LINK
    http://msdn.microsoft.com/en-us/library/aa746475.aspx#special_characters
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The string to escape
        $String
    )
    
    $string = $string.Replace('\', '\5c')
    $string = $string.Replace('*', '\2a')
    $string = $string.Replace('(', '\28')
    $string = $string.Replace(')', '\29')
    $string = $string.Replace('/', '\2f')
    $string.Replace("`0", '\00')
}