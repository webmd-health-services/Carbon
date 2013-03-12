# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Get-ADDomainController
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
    > Get-ADDomainController
    Returns the domain controller for the current computer's domain.  
    Approximately equivialent to the hostname given in the LOGONSERVER 
    environment variable.
    
    .EXAMPLE
    > Get-ADDomainController -Domain MYDOMAIN
    Returns the domain controller for the MYDOMAIN domain.
    #>
    [CmdletBinding()]
    param(
        [string]
        # The domain whose domain controller to get.  If not given, gets the 
        # current computer's domain controller.
        $Domain
    )
    
    if( $Domain )
    {
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
    }
    else
    {
        $root = New-Object DirectoryServices.DirectoryEntry "LDAP://RootDSE"
        return  $root.Properties["dnsHostName"][0].ToString();
    }
}
