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

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldResolveBuiltinIdentity
{
    $identity = Resolve-CIdentity -Name 'Administrators' -NoWarn
    Assert-Equal 'BUILTIN\Administrators' $identity.FullName
    Assert-Equal 'BUILTIN' $identity.Domain
    Assert-Equal 'Administrators' $identity.Name
    Assert-NotNull $identity.Sid
    Assert-Equal 'Alias' $identity.Type
}

function Test-ShouldResolveNTAuthorityIdentity
{
    $identity = Resolve-CIdentity -Name 'NetworkService' -NoWarn
    Assert-Equal 'NT AUTHORITY\NETWORK SERVICE' $identity.FullName
    Assert-Equal 'NT AUTHORITY' $identity.Domain
    Assert-Equal 'NETWORK SERVICE' $identity.Name
    Assert-NotNull $identity.Sid
    Assert-Equal 'WellKnownGroup' $identity.Type
}

function Test-ShouldResolveEveryone
{
    $identity  = Resolve-CIdentity -Name 'Everyone' -NoWarn
    Assert-Equal 'Everyone' $identity.FullName
    Assert-Equal '' $identity.Domain
    Assert-Equal 'Everyone' $identity.Name
    Assert-NotNull $identity.Sid
    Assert-Equal 'WellKnownGroup' $identity.Type
}

function Test-ShouldNotResolveMadeUpName
{
    $Error.Clear()
    $fullName = Resolve-CIdentity -Name 'IDONotExist' -NoWarn -ErrorAction SilentlyContinue
    Assert-GreaterThan $Error.Count 0
    Assert-Like $Error[0].Exception.Message '*not found*'
    Assert-Null $fullName
}

function Test-ShouldResolveLocalSystem
{
    Assert-Equal 'NT AUTHORITY\SYSTEM' (Resolve-CIdentity -Name 'localsystem' -NoWarn).FullName
}

function Test-ShouldResolveDotAccounts
{
    foreach( $user in (Get-User) )
    {
        $id = Resolve-CIdentity -Name ('.\{0}' -f $user.SamAccountName) -NoWarn
        Assert-NoError
        Assert-NotNull $id
        Assert-Equal $id.Domain $user.ConnectedServer
        Assert-Equal $id.Name $user.SamAccountName
    }
}

function Test-ShouldResolveSid
{
    @( 'NT AUTHORITY\SYSTEM', 'Everyone', 'BUILTIN\Administrators' ) | ForEach-Object {
        $id = Resolve-CIdentity -Name $_ -NoWarn
        $idFromSid = Resolve-CIdentity -Sid $id.Sid -NoWarn
        Assert-Equal $id $idFromSid
    }
}

function Test-ShouldResolveUnknownSid
{
    $id = Resolve-CIdentity -SID 'S-1-5-21-2678556459-1010642102-471947008-1017' -NoWarn -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'not found'
    Assert-Null $id
}

function Test-ShouldResolveSidByByteArray
{
    $id = Resolve-CIdentity -Name 'Administrators' -NoWarn
    Assert-NotNull $id
    $sidBytes = New-Object 'byte[]' $id.Sid.BinaryLength
    $id.Sid.GetBinaryForm( $sidBytes, 0 )

    $idBySid = Resolve-CIdentity -SID $sidBytes -NoWarn
    Assert-NotNull $idBySid
    Assert-NoError
    Assert-Equal $id $idBySid
}

function Test-ShouldHandleInvalidSddl
{
    $Error.Clear()
    $id = Resolve-CIdentity -SID 'iamnotasid' -NoWarn -ErrorAction SilentlyContinue
    Assert-Error 'exception converting'
    Assert-Error -Count 2
    Assert-Null $id
}


function Test-ShouldHandleInvalidBinarySid
{
    $Error.Clear()
    $id = Resolve-CIdentity -SID (New-Object 'byte[]' 28) -NoWarn -ErrorAction SilentlyContinue
    Assert-Error 'exception converting'
    Assert-Error -Count 2
    Assert-Null $id
}
