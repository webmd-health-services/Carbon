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

function Start-DscPullConfiguration
{
    <#
    .SYNOPSIS
    Performs a configuration check on a computer that is using DSC's Pull refresh mode.

    .DESCRIPTION
    The most frequently a computer's LCM will download new configuration is every 15 minutes; the most frequently it will apply it is every 30 minutes. This function contacts a computer's LCM and tells it to apply and download its configuration immediately.

    If a computer's LCM isn't configured to pull its configuration, an error is written, and nothing happens.

    If a configuration check fails, the errors are retrieved from the computer's event log and written out as errors. The `Remote Event Log Management` firewall rules must be enabled on the computer for this to work. If they aren't, you'll see an error explaining this. The `Get-DscError` help topic shows how to enable these firewall rules.

    .LINK
    Get-DscError

    .LINK
    Initialize-DscLcmPullMode

    .EXAMPLE
    Start-DscPullConfiguration -ComputerName '10.1.2.3','10.4.5.6'

    Demonstrates how to immedately download and apply a computer from its pull server.

    .EXAMPLE
    Start-DscPullConfiguration -ComputerName '10.1.2.3' -Credential (Get-Credential domain\username)

    Demonstrates how to use custom credentials to contact the remote server.

    .EXAMPLE
    Start-DscPullConfiguration -CimSession $session

    Demonstrates how to use one or more CIM sessions to invoke a configuration check.
    #>
    [CmdletBinding(DefaultParameterSetName='WithCredentials')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='WithCredentials')]
        [string[]]
        # The credential to use when connecting to the target computer.
        $ComputerName,

        [Parameter(ParameterSetName='WithCredentials')]
        [PSCredential]
        # The credentials to use when connecting to the computers.
        $Credential,

        [Parameter(ParameterSetName='WithCimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]
        $CimSession
    )

    Set-StrictMode -Version 'Latest'

    if( $PSCmdlet.ParameterSetName -eq 'WithCredentials' )
    {
        $newCimSessionParams = @{ }
        if( $Credential )
        {
            $newCimSessionParams.Credential = $Credential
        }

        $CimSession = New-CimSession -ComputerName $ComputerName @newCimSessionParams
        if( -not $CimSession )
        {
            return
        }
    }

    $CimSession = Get-DscLocalConfigurationManager -CimSession $CimSession |
                    ForEach-Object {
                        if( $_.RefreshMode -ne 'Pull' )
                        {
                            Write-Error ('The Local Configuration Manager on ''{0}'' is not in Pull mode (current RefreshMode is ''{1}'').' -f $_.PSComputerName,$_.RefreshMode)
                            return
                        }

                        foreach( $session in $CimSession )
                        {
                            if( $session.ComputerName -eq $_.PSComputerName )
                            {
                                return $session
                            }
                        }
                    }

    if( -not $CimSession )
    {
        return
    }

    # Getting the date/time on the remote computers so we can get errors later.
    $win32OS = Get-CimInstance -CimSession $CimSession -ClassName 'Win32_OperatingSystem'

    $results = Invoke-CimMethod -CimSession $CimSession `
                                -Namespace 'root/microsoft/windows/desiredstateconfiguration' `
                                -Class 'MSFT_DscLocalConfigurationManager' `
                                -MethodName 'PerformRequiredConfigurationChecks' `
                                -Arguments @{ 'Flags' = [uint32]1 } `
                                -Verbose:$VerbosePreference

    $successfulComputers = $results | Where-Object { $_ -and $_.ReturnValue -eq 0 } | Select-Object -ExpandProperty 'PSComputerName'

    $CimSession | 
        Where-Object { $successfulComputers -notcontains $_.ComputerName } |
        ForEach-Object { 
            $session = $_
            $startedAt= $win32OS | Where-Object { $_.PSComputerName -eq $session.ComputerName } | Select-Object -ExpandProperty 'LocalDateTime'
            Get-DscError -ComputerName $session.ComputerName -StartTime $startedAt -Wait 
        } | 
        Write-DscError
}
