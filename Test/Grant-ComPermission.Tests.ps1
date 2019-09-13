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

Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$groupName = 'CarbonCOM'

$maxTries = 100
$tryNum = 0
while( $tryNum++ -lt $maxTries )
{
    try
    {
        Install-CGroup -Name $groupName -Description 'Group used by the Carbon PowerShell module tests for COM grant/revoke methods.'
        break
    }
    catch
    {
        Write-Warning -Message ('[Grant-ComPermission.Tests]  Attempt {0,3} of {1} to create group "{0}" failed.' -f $tryNum,$maxTries,$groupName)
        Start-Sleep -Milliseconds 100
    }
}

Describe 'Grant-ComPermission' {
    
    BeforeEach {
        $Global:Error.Clear()
        Revoke-TestComPermissions
    }
    
    AfterEach {
        Revoke-TestComPermissions
    }
    
    function Revoke-TestComPermissions
    {
        Revoke-ComPermission -Identity $groupName -Access -Default
        Revoke-ComPermission -Identity $groupName -Access -Limits
        Revoke-ComPermission -Identity $groupName -LaunchAndActivation -Default
        Revoke-ComPermission -Identity $groupName -LaunchAndActivation -Limits
        Get-ComPermission -Identity $groupName -Access -Default | 
            ForEach-Object { Fail ('{0} has COM Access permissions.' -f $groupName) }
        Get-ComPermission -Identity $groupName -Access -Limits | 
            ForEach-Object { Fail ('{0} has COM Access restrictions.' -f $groupName) }
        Get-ComPermission -Identity $groupName -LaunchAndActivation -Default | 
            ForEach-Object { Fail ('{0} has COM Launch and ACtivation permissions.' -f $groupName) }
        Get-ComPermission -Identity $groupName -LaunchAndActivation -Limits | 
            ForEach-Object { Fail ('{0} has COM Launch and ACtivation restrictions.' -f $groupName) }
    }
    
    It 'should set access permissions' {
        @(
            @{ Default = $true; Allow = $true; Local = $true;  Remote = $false },
            @{ Default = $true; Allow = $true; Local = $false; Remote = $true },
            @{ Default = $true; Allow = $true; Local = $true;  Remote = $true },
            @{ Default = $true; Deny = $true;  Local = $true;  Remote = $false },
            @{ Default = $true; Deny = $true;  Local = $false; Remote = $true },
            @{ Default = $true; Deny = $true;  Local = $true;  Remote = $true },
            @{ Limits = $true; Allow = $true; Local = $true;  Remote = $false },
            @{ Limits = $true; Allow = $true; Local = $false; Remote = $true },
            @{ Limits = $true; Allow = $true; Local = $true;  Remote = $true },
            @{ Limits = $true; Deny = $true;  Local = $true;  Remote = $false },
            @{ Limits = $true; Deny = $true;  Local = $false; Remote = $true },
            @{ Limits = $true; Deny = $true;  Local = $true;  Remote = $true }
        ) |
            ForEach-Object {
                $grantArgs = $_
    
                $accessRule = Grant-ComPermission -Access -Identity $groupName @grantArgs -PassThru
                $accessRule | Should -Not -BeNullOrEmpty
                
                $expectedRights = [Carbon.Security.ComAccessRights]::Execute
                if( $grantArgs.Local )
                {
                    $expectedrights = $expectedRights -bor [Carbon.Security.ComAccessRights]::ExecuteLocal
                }
                if( $grantArgs.Remote )
                {
                    $expectedrights = $expectedRights -bor [Carbon.Security.ComAccessRights]::ExecuteRemote
                }
                $accessRule.ComAccessRights | Should -Be $expectedRights
            }
    }
    
    It 'should set launch and activation permissions' {
        @( 'Default', 'Limits' ) |
            ForEach-Object {
                $type = $_
                @( 'Allow', 'Deny' ) |
                    ForEach-Object {
                        $aceType = $_
                        @(
                            @{ 'LocalLaunch' = $true;  'RemoteLaunch' = $false; 'LocalActivation' = $false; 'RemoteActivation' = $false; },
                            @{ 'LocalLaunch' = $false; 'RemoteLaunch' = $true;  'LocalActivation' = $false; 'RemoteActivation' = $false; },
                            @{ 'LocalLaunch' = $true;  'RemoteLaunch' = $true;  'LocalActivation' = $false; 'RemoteActivation' = $false; },
                            @{ 'LocalLaunch' = $false; 'RemoteLaunch' = $false; 'LocalActivation' = $true;  'RemoteActivation' = $false; },
                            @{ 'LocalLaunch' = $true;  'RemoteLaunch' = $false; 'LocalActivation' = $true;  'RemoteActivation' = $false; },
                            @{ 'LocalLaunch' = $false; 'RemoteLaunch' = $true;  'LocalActivation' = $true;  'RemoteActivation' = $false; },
                            @{ 'LocalLaunch' = $true;  'RemoteLaunch' = $true;  'LocalActivation' = $true;  'RemoteActivation' = $false; },
                            @{ 'LocalLaunch' = $false; 'RemoteLaunch' = $false; 'LocalActivation' = $false; 'RemoteActivation' = $true; },
                            @{ 'LocalLaunch' = $true;  'RemoteLaunch' = $false; 'LocalActivation' = $false; 'RemoteActivation' = $true; },
                            @{ 'LocalLaunch' = $false; 'RemoteLaunch' = $true;  'LocalActivation' = $false; 'RemoteActivation' = $true; },
                            @{ 'LocalLaunch' = $true;  'RemoteLaunch' = $true;  'LocalActivation' = $false; 'RemoteActivation' = $true; },
                            @{ 'LocalLaunch' = $false; 'RemoteLaunch' = $false; 'LocalActivation' = $true;  'RemoteActivation' = $true; },
                            @{ 'LocalLaunch' = $true;  'RemoteLaunch' = $false; 'LocalActivation' = $true;  'RemoteActivation' = $true; },
                            @{ 'LocalLaunch' = $false; 'RemoteLaunch' = $true;  'LocalActivation' = $true;  'RemoteActivation' = $true; },
                            @{ 'LocalLaunch' = $true;  'RemoteLaunch' = $true;  'LocalActivation' = $true;  'RemoteActivation' = $true; }
                        ) | 
                        ForEach-Object {
                            $grantArgs = $_
                            $grantArgs.$type = $true
                            $grantArgs.$aceType = $true
    
                            $accessRule = Grant-ComPermission -Identity $groupName -LaunchAndActivation @grantArgs -PassThru
                            $accessRule | Should -Not -BeNullOrEmpty
                            
                            $expectedRights = [Carbon.Security.ComAccessRights]::Execute
                            if( $grantArgs.LocalLaunch )
                            {
                                $expectedrights = $expectedRights -bor [Carbon.Security.ComAccessRights]::ExecuteLocal
                            }
                            if( $grantArgs.RemoteLaunch )
                            {
                                $expectedrights = $expectedRights -bor [Carbon.Security.ComAccessRights]::ExecuteRemote
                            }
                            if( $grantArgs.LocalActivation )
                            {
                                $expectedrights = $expectedRights -bor [Carbon.Security.ComAccessRights]::ActivateLocal
                            }
                            if( $grantArgs.RemoteActivation )
                            {
                                $expectedrights = $expectedRights -bor [Carbon.Security.ComAccessRights]::ActivateRemote
                            }
                            $accessRule.ComAccessRights | Should -Be $expectedRights
                            
                        }
                    } 
            }
    }
    
    It 'should not return access rule' {
        $result = Grant-ComPermission -Identity $groupName -Access -Default -Allow -Local
        $result | Should -BeNullOrEmpty
        $perm = Get-ComPermission -Access -Identity $groupName -Default
        $perm | Should -Not -BeNullOrEmpty
        $expectedRights = [Carbon.Security.ComAccessrights]::ExecuteLocal -bor [Carbon.Security.ComAccessRights]::Execute
        $perm.ComAccessRights | Should -Be $expectedRights
    }
}
