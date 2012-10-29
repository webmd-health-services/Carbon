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

$groupName = 'CarbonCOM'

function Setup
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
    Install-Group -Name $groupName -Description 'Group used by the Carbon PowerShell module tests for COM grant/revoke methods.'
    Revoke-TestComPermissions
}

function TearDown
{
    Revoke-TestComPermissions
    Remove-Module Carbon
}

function Revoke-TestComPermissions
{
    Revoke-ComPermissions -Identity $groupName -Access -Default
    Revoke-ComPermissions -Identity $groupName -Access -Limits
    Revoke-ComPermissions -Identity $groupName -LaunchAndActivation -Default
    Revoke-ComPermissions -Identity $groupName -LaunchAndActivation -Limits
    Get-ComAccessPermissions -Identity $groupName -Default | 
        ForEach-Object { Fail ('{0} has COM Access permissions.' -f $groupName) }
    Get-ComAccessPermissions -Identity $groupName -Limits | 
        ForEach-Object { Fail ('{0} has COM Access restrictions.' -f $groupName) }
    Get-ComLaunchAndActivationPermissions -Identity $groupName -Default | 
        ForEach-Object { Fail ('{0} has COM Launch and ACtivation permissions.' -f $groupName) }
    Get-ComLaunchAndActivationPermissions -Identity $groupName -Limits | 
        ForEach-Object { Fail ('{0} has COM Launch and ACtivation restrictions.' -f $groupName) }
}

function Test-ShouldSetAccessPermissions
{
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
            Grant-ComPermissions -Access -Identity $groupName @grantArgs
            
            $getArgs = @{ }
            if( $grantArgs.Default )
            {
                $getArgs.Default = $true
            }
            else
            {
                $getArgs.Limits = $true
            }
            $accessRule = Get-ComAccessPermissions -Identity $groupName @getArgs
            Assert-NotNull $accessRule
            
            $expectedRights = [Carbon.Security.ComAccessRights]::Execute
            if( $grantArgs.Local )
            {
                $expectedrights = $expectedRights -bor [Carbon.Security.ComAccessRights]::ExecuteLocal
            }
            if( $grantArgs.Remote )
            {
                $expectedrights = $expectedRights -bor [Carbon.Security.ComAccessRights]::ExecuteRemote
            }
            Assert-Equal $expectedRights $accessRule.ComAccessRights
        }
}

function Test-ShouldSetLaunchAndActivationPermissions
{
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

                        Grant-ComPermissions -Identity $groupName -LaunchAndActivation @grantArgs
                        
                        $getArgs = @{ }
                        $getArgs.$type = $true

                        $accessRule = Get-ComLaunchAndActivationPermissions  -Identity $groupName @getArgs
                        Assert-NotNull $accessRule
                        
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
                        Assert-Equal $expectedRights $accessRule.ComAccessRights
                        
                    }
                } 
        }
}
