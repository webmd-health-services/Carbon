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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)
$user = $null
$url = 'http://test-gethttpurlacl:10939/'

function Start-Test
{
    $user = Install-User -Credential (New-Credential -UserName 'CarbonTestUser' -Password 'Password1') -PassThru
    netsh http add urlacl ('url={0}' -f $url)('user={0}\{1}' -f $env:COMPUTERNAME,$user.SamAccountName) | Write-Debug
}

function Stop-Test
{
    netsh http delete urlacl ('url={0}' -f $url)
}

function Test-ShouldGetAllUrlAcls
{
    [Carbon.Security.HttpUrlSecurity[]]$acls = Get-HttpUrlAcl
    Assert-NotNull $acls
    $urlacl = netsh http show urlacl
    $urlacl = $urlacl -join [Environment]::NewLine

    foreach( $acl in $acls )
    {
        $header = '' -f $acl.Url

        if( $acl.Access.Count -eq 1 )
        {
            $rule = $acl.Access[0]
            $identity = $rule.IdentityReference.ToString()
            if( $identity -eq 'Everyone' )
            {
                $identity = '\Everyone'
            }

            $listen = 'No'
            if( $rule.HttpUrlAccessRights -eq [Carbon.Security.HttpUrlAccessRights]::Listen -or $rule.HttpUrlAccessRights -eq [Carbon.Security.HttpUrlAccessRights]::ListenAndDelegate )
            {
                $listen = 'Yes'
            }

            $delegate = 'No'
            if( $rule.HttpUrlAccessRights -eq [Carbon.Security.HttpUrlAccessRights]::Delegate -or $rule.HttpUrlAccessRights -eq [Carbon.Security.HttpUrlAccessRights]::ListenAndDelegate )
            {
                $delegate = 'Yes'
            }

            Assert-That $urlacl -Contains (@'
    Reserved URL            : {0} 
        User: {1}
            Listen: {2}
            Delegate: {3}
'@ -f $acl.Url,$identity,$listen,$delegate)

        }
    }
}

function Test-ShouldGetSpecificUrl
{
    [Carbon.Security.HttpUrlSecurity[]]$acls = Get-HttpUrlAcl -LiteralUrl $url
    Assert-TestUrl $acls
}


function Test-ShouldIgnoreWildcardsWithLiteralUrlParameter
{
    [Carbon.Security.HttpUrlSecurity[]]$acls = Get-HttpUrlAcl -LiteralUrl 'http://*:10939/' -ErrorAction SilentlyContinue
    Assert-Null $acls
    Assert-Error -Last -Regex 'not found'
}

function Test-ShouldFindWithWildcard
{
    [Carbon.Security.HttpUrlSecurity[]]$acls = Get-HttpUrlAcl -Url 'http://*:10939/'
    Assert-TestUrl $acls
}

function Test-ShouldWriteErrorIfLiteralUrlNotFound
{
    $acl = Get-HttpUrlAcl -LiteralUrl 'fubar' -ErrorAction SilentlyContinue
    Assert-Null $acl
    Assert-Error -Last -Regex 'not found'
}

function Test-ShouldFailIfUrlWithNoWildcardsNotFound
{
    $acl = Get-HttpUrlAcl -Url 'fubar' -ErrorAction SilentlyContinue
    Assert-Null $acl
    Assert-Error -Last -Regex 'not found'
}

function Test-ShouldNotFailIfUrlWithWildcardsNotFound
{
    $acl = Get-HttpUrlAcl -Url 'fubar*' 
    Assert-Null $acl
    Assert-NoError
}

function Assert-TestUrl
{
    param(
        [Carbon.Security.HttpUrlSecurity[]]
        $Acls 
    )

    Assert-NoError

    Assert-NotNull $Acls
    Assert-Equal 1 $Acls.Count

    $acl = $Acls[0]
    Assert-Equal 1 $acl.Access.Count 
    $rule = $acl.Access[0]
    Assert-Equal ('{0}\{1}' -f $env:COMPUTERNAME,$user.SamAccountName) $rule.IdentityReference
}