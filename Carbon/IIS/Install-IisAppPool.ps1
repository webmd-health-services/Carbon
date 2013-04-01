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

function Install-IisAppPool
{
    <#
    .SYNOPSIS
    Creates a new app pool.
    
    .DESCRIPTION
    By default, creates a 64-bit app pool running as the `ApplicationPoolIdentity` service account under .NET v4.0 with an integrated pipeline.
    
    You can control which version of .NET is used to run an app pool with the `ManagedRuntimeVersion` parameter: versions `v1.0`, `v1.1`, `v2.0`, and `v4.0` are supported.

    To run an application pool using the classic pipeline mode, set the `ClassicPipelineMode` switch.

    To run an app pool using the 32-bit version of the .NET framework, set the `Enable32BitApps` switch.

    An app pool can run as several built-in service accounts, by passing one of them as the value of the `ServiceAccount` parameter: `NetworkService`, `LocalService`, or `LocalSystem`  The default is `ApplicationPoolIdentity`, which causes IIS to create and use a custom local account with the name of the app pool.  See [Application Pool Identities](http://learn.iis.net/page.aspx/624/application-pool-identities/) for more information.

    To run the app pool as a specific user, pass the username and password for the account to the `Username` and `Password` parameters, respectively. This user will be granted the `SeBatchLogonRight` privilege.

    If an existing app pool exists with name `Name`, it's settings are modified.  The app pool isn't deleted.  (You can't delete an app pool if there are any websites using it, that's why.)

    By default, this function will create an application pool running the latest version of .NET, with an integrated pipeline, as the NetworkService account.

    .LINK
    http://learn.iis.net/page.aspx/624/application-pool-identities/
    
    .EXAMPLE
    Install-IisAppPool -Name Cyberdyne -ServiceAccount NetworkService

    Creates a new Cyberdyne application pool, running as NetworkService, using .NET 4.0 and an integrated pipeline.  If the Cyberdyne app pool already exists, it is modified to run as NetworkService, to use .NET 4.0 and to use an integrated pipeline.

    .EXAMPLE
    Install-IisAppPool -Name Cyberdyne -ServiceAccount NetworkService -Enable32BitApps -ClassicPipelineMode

    Creates or sets the Cyberdyne app pool to run as NetworkService, in 32-bit mode (i.e. 32-bit applications are enabled), using the classic IIS request pipeline.

    .EXAMPLE
    Install-IisAppPool -Name Cyberdyne -Username 'PEANUTS\charliebrown' -Password '5noopyrulez'

    Creates or sets the Cyberdyne app pool to run as the `PEANUTS\charliebrown` domain account, under .NET 4.0, with an integrated pipeline.
    #>
    [CmdletBinding(DefaultParameterSetName='AsServiceAccount')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The app pool's name.
        $Name,
        
        [string]
        [ValidateSet('v1.0','v1.1','v2.0','v4.0')]
        # The managed .NET runtime version to use.  Default is 'v4.0'.  Valid values are `v1.0`, `v1.1`, `v2.0`, or `v4.0`.
        $ManagedRuntimeVersion = 'v4.0',
        
        [int]
        [ValidateScript({$_ -gt 0})]
        #Idle Timeout value in minutes. Default is 0.
        $IdleTimeout = 0,
        
        [Switch]
        # Use the classic pipeline mode, i.e. don't use an integrated pipeline.
        $ClassicPipelineMode,
        
        [Switch]
        # Enable 32-bit applications.
        $Enable32BitApps,
        
        [string]
        [ValidateSet('NetworkService','LocalService','LocalSystem')]
        # Run the app pool under the given local service account.  Valid values are `NetworkService`, `LocalService`, and `LocalSystem`.  The default is `ApplicationPoolIdentity`, which causes IIS to create a custom local user account for the app pool's identity.  The default is `ApplicationPoolIdentity`.
        $ServiceAccount,
        
        [Parameter(ParameterSetName='AsSpecificUser',Mandatory=$true)]
        [string]
        # Runs the app pool under a specific user account.
        $UserName,
        
        [Parameter(ParameterSetName='AsSpecificUser',Mandatory=$true)]
        # The password for the user account.  Can be a string or a SecureString.
        $Password
    )
    
    if( $pscmdlet.ParameterSetName -eq 'AsSpecificUser' -and -not (Test-Identity -Name $UserName) )
    {
        Write-Error ('Identity {0} not found. {0} IIS websites and applications assigned to this app pool won''t run.' -f $UserName,$Name)
    }
    
    if( -not (Test-IisAppPool -Name $Name) )
    {
        Invoke-AppCmd add apppool /name:`"$Name`" /commit:apphost
    }
    
    $pipelineMode = 'Integrated'
    if( $ClassicPipelineMode )
    {
        $pipelineMode = 'Classic'
    }
    
    Invoke-AppCmd set apppool `"$Name`" /managedRuntimeVersion:$ManagedRuntimeVersion /managedPipelineMode:$pipelineMode
    
    Invoke-AppCmd set config /section:applicationPools /[name=`'$Name`'].processModel.idleTimeout:"$(New-TimeSpan -minutes $IdleTimeout)"
    
    Invoke-AppCmd set config /section:applicationPools /[name=`'$name`'].enable32BitAppOnWin64:$Enable32BitApps
    
    if( $pscmdlet.ParameterSetName -eq 'AsSpecificUser' )
    {
        if( $Password -is [Security.SecureString] )
        {
            $Password = Convert-SecureStringToString $Password
        }
        Invoke-AppCmd set config /section:applicationPools /[name=`'$Name`'].processModel.identityType:SpecificUser `
                                                           /[name=`'$Name`'].processModel.userName:$UserName `
                                                           /[name=`'$Name`'].processModel.password:$Password

        # On Windows Server 2008 R2, custom app pool users need this privilege.
        Grant-Privilege -Identity $UserName -Privilege SeBatchLogonRight
    }
    else
    {
        if( $ServiceAccount )
        {
            Invoke-AppCmd set config /section:applicationPools /[name=`'$Name`'].processModel.identityType:$ServiceAccount
        }
        else
        {
            Invoke-AppCmd clear config /section:applicationPools /[name=`'$Name`'].processModel.identityType
        }
    }
    
    # TODO: Pull this out into its own Start-IisAppPool function.  I think.
    $appPool = Get-IisAppPool -Name $Name
    if($appPool -and $appPool.state -eq [Microsoft.Web.Administration.ObjectState]::Stopped )
    {
        try
        {
            $appPool.Start()
        }
        catch
        {
            Write-Error ('Failed to start {0} app pool: {1}' -f $Name,$_.Exception.Message)
        }
    }
}
