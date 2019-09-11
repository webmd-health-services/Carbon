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

if( (Get-WmiObject -Class 'Win32_ComputerSystem').Domain -eq 'WORKGROUP' )
{
    Write-Warning -Message ('Get-ADDomainController tests can''t run because this computer is not part of a domain.')
}
else
{
    function Start-TestFixture
    {
        & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
    }

    function Test-ShouldFindDomainController
    {
        $domainController = Get-ADDomainController
        
        Assert-NotNull $domainController
        
        Assert-CanFindCurrentUser $domainController
        
    }

    function Test-ShouldFindDomainControllerForSpecificDomain
    {
        $domainController = Get-ADDomainController -Domain $env:USERDOMAIN
        
        Assert-NotNull $domainController
        
        Assert-CanFindCurrentUser $domainController
    }

    function Test-ShouldNotFindNonExistentDomain
    {
        $error.Clear()
        $domainController = Get-ADDomainController -Domain 'FJDSKLJDSKLFJSDA' -ErrorAction SilentlyContinue
        Assert-Null $domainController
        Assert-equal 2 $error.Count
    }

    function Assert-CanFindCurrentUser($domainController)
    {
        $domain = [adsi] "LDAP://$domainController"
        $searcher = [adsisearcher] $domain
        
        $searcher.Filter = "(&(objectClass=User) (sAMAccountName=$($env:Username)))"
        $result = $searcher.FindOne() 
        Assert-NotNull $result
    }
}
