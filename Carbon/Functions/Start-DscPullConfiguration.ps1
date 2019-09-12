
function Start-CDscPullConfiguration
{
    <#
    .SYNOPSIS
    Performs a configuration check on a computer that is using DSC's Pull refresh mode.

    .DESCRIPTION
    The most frequently a computer's LCM will download new configuration is every 15 minutes; the most frequently it will apply it is every 30 minutes. This function contacts a computer's LCM and tells it to apply and download its configuration immediately.

    If a computer's LCM isn't configured to pull its configuration, an error is written, and nothing happens.

    If a configuration check fails, the errors are retrieved from the computer's event log and written out as errors. The `Remote Event Log Management` firewall rules must be enabled on the computer for this to work. If they aren't, you'll see an error explaining this. The `Get-CDscError` help topic shows how to enable these firewall rules.

    Sometimes, the LCM does a really crappy job of updating to the latest version of a module. `Start-CDscPullConfiguration` will delete modules on the target computers. Specify the names of the modules to delete with the `ModuleName` parameter. Make sure you only delete modules that will get installed by the LCM. Only modules installed in the `$env:ProgramFiles\WindowsPowerShell\Modules` directory are removed.

    `Start-CDscPullConfiguration` is new in Carbon 2.0.

    .LINK
    Get-CDscError

    .LINK
    Initialize-CLcm

    .LINK
    Get-CDscWinEvent

    .EXAMPLE
    Start-CDscPullConfiguration -ComputerName '10.1.2.3','10.4.5.6'

    Demonstrates how to immedately download and apply a computer from its pull server.

    .EXAMPLE
    Start-CDscPullConfiguration -ComputerName '10.1.2.3' -Credential (Get-Credential domain\username)

    Demonstrates how to use custom credentials to contact the remote server.

    .EXAMPLE
    Start-CDscPullConfiguration -CimSession $session

    Demonstrates how to use one or more CIM sessions to invoke a configuration check.

    .EXAMPLE
    Start-CDscPullConfiguration -ComputerName 'example.com' -ModuleName 'Carbon'

    Demonstrates how to delete modules on the target computers, because sometimes the LCM does a really crappy job of it.
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
        $CimSession,

        [string[]]
        # Any modules that should be removed from the target computer's PSModulePath (since the LCM does a *really* crappy job of removing them).
        $ModuleName
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $credentialParam = @{ }
    if( $PSCmdlet.ParameterSetName -eq 'WithCredentials' )
    {
        if( $Credential )
        {
            $credentialParam.Credential = $Credential
        }

        $CimSession = New-CimSession -ComputerName $ComputerName @credentialParam
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

    # Get rid of any _tmp directories you might find out there.
    Invoke-Command -ComputerName $CimSession.ComputerName @credentialParam -ScriptBlock {
        $modulesRoot = Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell\Modules'
        Get-ChildItem -Path $modulesRoot -Filter '*_tmp' -Directory | 
            Remove-Item -Recurse
    }

    if( $ModuleName )
    {
        # Now, get rid of any modules we know will need to get updated
        Invoke-Command -ComputerName $CimSession.ComputerName @credentialParam -ScriptBlock {
            param(
                [string[]]
                $ModuleName
            )

            $dscProcessID = Get-WmiObject msft_providers | 
                                Where-Object {$_.provider -like 'dsccore'} | 
                                Select-Object -ExpandProperty HostProcessIdentifier 
            Stop-Process -Id $dscProcessID -Force

            $modulesRoot = Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell\Modules'
            Get-ChildItem -Path $modulesRoot -Directory |
                Where-Object { $ModuleName -contains $_.Name } |
                Remove-Item -Recurse

        } -ArgumentList (,$ModuleName)
    }

    # Getting the date/time on the remote computers so we can get errors later.
    $win32OS = Get-CimInstance -CimSession $CimSession -ClassName 'Win32_OperatingSystem'

    $results = Invoke-CimMethod -CimSession $CimSession `
                                -Namespace 'root/microsoft/windows/desiredstateconfiguration' `
                                -Class 'MSFT_DscLocalConfigurationManager' `
                                -MethodName 'PerformRequiredConfigurationChecks' `
                                -Arguments @{ 'Flags' = [uint32]1 } 

    $successfulComputers = $results | Where-Object { $_ -and $_.ReturnValue -eq 0 } | Select-Object -ExpandProperty 'PSComputerName'

    $CimSession | 
        Where-Object { $successfulComputers -notcontains $_.ComputerName } |
        ForEach-Object { 
            $session = $_
            $startedAt= $win32OS | Where-Object { $_.PSComputerName -eq $session.ComputerName } | Select-Object -ExpandProperty 'LocalDateTime'
            Get-CDscError -ComputerName $session.ComputerName -StartTime $startedAt -Wait 
        } | 
        Write-CDscError
}

