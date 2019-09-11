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
    Write-Warning -Message ('Find-ADUser tests can''t run because this computer is not part of a domain.')
}
else
{
    $domainUrl = ''

    function Start-TestFixture
    {
        & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
    }

    function Setup
    {
        $domainController = Get-ADDomainController -Domain $env:USERDOMAIN
        Assert-NotNull $domainController
        $domainUrl = "LDAP://{0}:389" -f $domainController
    }

    function Test-ShouldFindUser
    {
        $me = Find-ADUser -DomainUrl $domainUrl -sAMAccountName $env:USERNAME
        Assert-NotNull $me
        Assert-Equal $env:USERNAME $me.sAMAccountName
    }

    function Test-ShouldEscapeSpecialCharacters
    {
        $me = Find-ADUser -DomainUrl $domainUrl -sAMAccountName "(user*with\special/characters)"
        Assert-Null $me
    }
}