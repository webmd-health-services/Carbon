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

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\..\Carbon\Import-Carbon.ps1' -Resolve)
}

function Test-ShouldProtectString
{
    $cipherText = Protect-String -String 'Hello World!' -ForUser
    Assert-IsBase64EncodedString( $cipherText )
}

function Test-ShouldProtectStringWithScope
{
    $user = Protect-String -String 'Hello World' -ForUser 
    $machine = Protect-String -String 'Hello World' -ForComputer
    Assert-NotEqual $user $machine 'encrypting at different scopes resulted in the same string'
}

function Test-ShouldProtectStringsInPipeline
{
    $secrets = @('Foo','Fizz','Buzz','Bar') | Protect-String -ForUser
    Assert-Equal 4 $secrets.Length 'Didn''t encrypt all items in the pipeline.'
    foreach( $secret in $secrets )
    {
        Assert-IsBase64EncodedString $secret
    }
}

if( -not (Test-Path -Path 'env:CCNetArtifactDirectory') )
{
    function Test-ShouldProtectStringForCredential
    {
        $password = 'Tt6QML1lmDrFSf'
        Install-User -Username 'CarbonTestUser' -Password $password -Description 'Carbon test user.'

        $credential = New-Credential 'CarbonTestUser' -Password $password
        # special chars to make sure they get handled correctly
        $string = ' f u b a r '' " > ~!@#$%^&*()_+`-={}|:"<>?[]\;,./'
        $protectedString = Protect-String -String $string -Credential $credential
        if( -not $protectedString )
        {
            Fail ('Failed to protect a string as user {0}.' -f $credential.UserName)
        }

        $outFile = New-TempDir -Prefix (Split-Path -Leaf -Path $PSCommandPath)
        $outFile = Join-Path -Path $outFile -ChildPath 'secret'
        try
        {
            $p = Start-Process -FilePath "powershell.exe" `
                               -ArgumentList (Join-Path -Path $PSScriptRoot -ChildPath 'Unprotect-String.ps1'),'-ProtectedString',$protectedString `
                               -WindowStyle Hidden `
                               -Credential $credential `
                               -PassThru `
                               -Wait `
                               -RedirectStandardOutput $outFile
            $p.WaitForExit()

            $decrypedString = Get-Content -Path $outFile -TotalCount 1
            Assert-Equal $string $decrypedString
        }
        finally
        {
            Remove-Item -Recurse -Path (Split-Path -Parent -Path $outFile)
        }
    }
}
else
{
    Write-Warning ('Can''t test protecting string under another identity: running under CC.Net, and the service user''s profile isn''t loaded, so can''t use Microsoft''s DPAPI.')
}

function Assert-IsBase64EncodedString($String)
{
    Assert-NotEmpty $String 'Didn''t encrypt cipher text.'
    [Convert]::FromBase64String( $String )
}
