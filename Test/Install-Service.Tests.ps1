
using namespace System.ServiceProcess

#Requires -Version 5.1
#Requires -RunAsAdministrator
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon' -Resolve) -Verbose:$false

    $script:serviceNameSuffix = [IO.Path]::GetRandomFileName() -replace '\.', ''
    $script:testDirPath = ''
    $script:testNum = 0
    $script:servicePath = ''
    $script:serviceNamePrefix = 'CarbonTestInstallCService'
    $script:serviceName = $null
    $script:serviceAcct = "CISvc${script:serviceNameSuffix}"
    # Make sure we escape characters that sc.exe needs to have escaped.
    $servicePassword = ConvertTo-SecureString """a1""'~!@# $%^&*(""" -Force -AsPlainText
    $script:serviceCredential = [pscredential]::New($script:serviceAcct, $servicePassword)
    Install-CUser -Credential $script:serviceCredential `
                  -Description "Account for testing the Carbon Install-CService function."
    $script:defaultServiceAccountName = Resolve-CIdentityName -Name 'NT AUTHORITY\NetworkService'
    $script:inModule = @{ ModuleName = 'Carbon' }

    function ThenError
    {
        param(
            [Parameter(Mandatory, ParameterSetName='IsEmpty')]
            [switch] $IsEmpty,

            [Parameter(Mandatory, ParameterSetName='Matches')]
            [String] $MatchesRegex
        )

        if ($IsEmpty)
        {
            $Global:Error | Should -BeNullOrEmpty
        }

        if ($MatchesRegex)
        {
            $Global:Error | Should -Match $MatchesRegex
        }
    }

    function ThenOutput
    {
        param(
            [Parameter(Mandatory, ParameterSetName='IsEmpty')]
            [switch] $IsEmpty,

            [Parameter(Mandatory, ParameterSetName='IsServiceController')]
            [switch] $IsServiceController
        )

        if ($IsEmpty)
        {
            $script:output | Should -BeNullOrEmpty
        }

        if ($IsServiceController)
        {
            $script:output | Should -Not -BeNullOrEmpty
            $script:output | Should -BeOfType ([ServiceController])
        }
    }

    function ThenService
    {
        [CmdletBinding(DefaultParameterSetName='Exists')]
        param(
            [Parameter(Position=0)]
            [String] $Named,

            [Parameter(Mandatory, ParameterSetName='Not')]
            [switch] $Not,

            [Parameter(Mandatory, ParameterSetName='Not')]
            [switch] $Exists,

            [String] $Runs,

            [String] $WithArgs,

            [String] $HasStartMode,

            [String] $OnFirstFailure,

            [String] $OnSecondFailure,

            [String] $OnThirdFailure,

            [TimeSpan] $HasRestartDelay,

            [TimeSpan] $HasRebootDelay,

            [TimeSpan] $HasRunCommandDelay,

            [String] $RunsFailureCommand,

            [String[]] $DependsOn,

            [switch] $StartsDelayed,

            [String] $Is,

            [String] $RunAs,

            [String] $HasDisplayName,

            [TimeSpan] $ResetsFailuresEvery,

            [String] $HasDescription
        )

        if (-not $Named)
        {
            $Named = $script:serviceName
        }

        if ($Not -and $Exists)
        {
            Test-CService -Name $Named | Should -BeFalse
            return
        }

        Test-CService -Name $Named | Should -BeTrue

        $service = Get-Service -Name $script:serviceName
        $service | Should -Not -BeNullOrEmpty
        $config = $service | Get-CServiceConfiguration
        $config | Should -Not -BeNullOrEmpty

        if (-not $Runs)
        {
            $Runs = $script:servicePath
        }

        # Can be empty array.
        if ($PSBoundParameters.ContainsKey('DependsOn'))
        {
            $service.DependentServices | Should -HaveCount 0
            $service.ServicesDependedOn | Should -HaveCount ($DependsOn | Measure-Object).Count
            $service.ServicesDependedOn |
                Select-Object -ExpandPRoperty 'Name' |
                Sort-Object |
                Should -Be ($DependsOn | Sort-Object)
        }

        if ($HasStartMode)
        {
            $service.StartMode | Should -Be $HasStartMode
        }

        # Can be false.
        if ($PSBoundParameters.ContainsKey('StartsDelayed'))
        {
            $service.DelayedAutoStart | Should -Be $StartsDelayed.IsPresent
        }

        if ($Is)
        {
            $service.Status | Should -Be $Is
        }

        if (-not $RunAs)
        {
            $RunAs = 'NetworkService'
        }

        $expectedPrincipalName = Resolve-TCPrincipalName $RunAs
        $expectedPrincipalName | Should -Not -BeNullOrEmpty -Because "identity ${RunAs} should exist"
        $expectedPrincipalName = $expectedPrincipalName.Replace("$([Environment]::MachineName)\", '.\')
        $service.UserName | Should -Be $expectedPrincipalName

        Test-TCNtfsPermission -Path $Runs -Identity $RunAs -Permission ReadAndExecute | Should -BeTrue
        Test-TCPrivilege -Identity $RunAs -Privilege SeServiceLogonRight | Should -BeTrue

        if ($HasDisplayName)
        {
            $service.DisplayName | Should -Be $HasDisplayName
        }

        $runCommand = $Runs
        If ($WithArgs)
        {
            $runCommand = "${Runs} ${WithArgs}"
        }

        $config.Path | Should -Be $runCommand

        if ($ResetsFailuresEvery)
        {
            $config.ResetPeriod | Should -Be $ResetsFailuresEvery.TotalMilliseconds
        }

        if ($OnFirstFailure)
        {
            $config.FirstFailure | Should -Be $OnFirstFailure
        }

        if ($OnSecondFailure)
        {
            $config.SecondFailure | Should -Be $OnSecondFailure
        }

        if ($OnThirdFailure)
        {
            $config.ThirdFailure | Should -Be $OnThirdFailure
        }

        if ($HasRestartDelay)
        {
            $config.RestartDelay | Should -Be $HasRestartDelay.TotalMilliseconds
        }
        else
        {
            $config.RestartDelay | Should -Be 0
        }

        if ($HasRebootDelay)
        {
            $config.RebootDelay | Should -Be $HasRebootDelay.TotalMilliseconds
        }
        else
        {
            $config.RebootDelay | Should -Be 0
        }

        if ($HasRunCommandDelay)
        {
            $config.RunCommandDelay | Should -Be $HasRunCommandDelay.TotalMilliseconds
        }
        else
        {
            $config.RunCommandDelay | Should -Be 0
        }

        if ($RunsFailureCommand)
        {
            $config.FailureProgram | Should -Be $RunsFailureCommand
        }
    }

    function WhenInstalling
    {
        [CmdletBinding(DefaultParameterSetName='SkipIdempotentCheck')]
        param(
            [hashtable] $WithArgs = @{},

            [Parameter(ParameterSetName='EnsureIdempotent')]
            [switch] $Not,

            [Parameter(Mandatory, ParameterSetName='EnsureIdempotent')]
            [switch] $IsIdempotent,

            [Parameter(ParameterSetName='EnsureIdempotent')]
            [hashtable] $WithIdempotentArgs = @{}
        )

        if (-not $WithArgs.ContainsKey('Name'))
        {
            $WithArgs['Name'] = $script:serviceName
        }

        if (-not $WithArgs.ContainsKey('Path'))
        {
            $WithArgs['Path'] = $script:servicePath
        }

        $script:output = Install-CService @WithArgs
        if ($WithArgs['PassThru'])
        {
            $script:output | Should -Not -BeNullOrEmpty
        }
        else
        {
            $script:output | Should -BeNullOrEmpty
        }

        if ($PSCmdlet.ParameterSetName -ne 'EnsureIdempotent')
        {
            return
        }

        # To test that Install-CService is idempotent, make it fail if it runs any sc.exe commands.
        Mock -CommandName 'Join-Path' @inModule -ParameterFilter { $ChildPath -in @('sc.exe', 'sc') }
        Mock -CommandName 'Get-Command' @inModule -ParameterFilter { $Name -in @('sc.exe', 'sc') }
        Mock -CommandName 'Grant-CPrivilege' @inModule
        Mock -CommandName 'Grant-CPermission' @inModule
        $installErrors = @()
        $output = $null
        try
        {
            $output = Install-CService @WithArgs @WithIdempotentArgs -ErrorVariable 'installErrors'
        }
        catch
        {
        }
        $output | Should -BeNullOrEmpty

        if ($Not)
        {
            $becauseMsg = $WithIdempotentArgs.Keys | ForEach-Object { "$_ = $($WithIdempotentArgs[$_])"}
            $becauseMsg = $becauseMsg -join ' ; '
            $becauseMsg = "Install-CService should not be idempotent when passed @{ ${becauseMsg} }"
            $installErrors | Should -Not -BeNullOrEmpty -Because $becauseMsg
        }
        else
        {
            $installErrors | Should -BeNullOrEmpty -Because 'Install-CService should be idempotent'
        }
    }
}

AfterAll {
    Get-Service -Name 'Carbon*' |
        Where-Object 'Name' -NotIn @('CarbonBlack') |
        ForEach-Object {
            $_ | Stop-Service
            sc.exe delete $_.Name
        }
}

Describe 'Install-CService' {
    BeforeEach {
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath $script:testNum
        New-Item -Path $script:testDirPath -ItemType 'Directory'

        Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Service\NoOpService.exe' -Resolve) `
                  -Destination $script:testDirPath
        $script:servicePath = Join-Path -Path $script:testDirPath -ChildPath 'NoOpService.exe' -Resolve

        $numCarbonServices =
            Get-Service -Name ('{0}*' -f $script:serviceNamePrefix) |
            Measure-Object |
            Select-Object -ExpandProperty 'Count'
        $script:serviceName = "${script:serviceNamePrefix}-${script:serviceNameSuffix}-$($numCarbonServices + 1)"
        $Global:Error.Clear()
    }

    AfterEach {
        $script:testNum++
    }

    Context 'service does not exist' {
        It 'sets all properties' {
            $dependencies = Get-Service -ErrorAction Ignore | Select-Object -First 2 | Select-Object -ExpandProperty 'Name'
            WhenInstalling -WithArgs @{
                Name = $script:serviceName
                Path = $script:servicePath
                ArgumentList = @('-k', 'Fubar')
                StartUpType = 'Manual'
                DisplayName = 'carbon display name 001'
                Description = 'description 001'
                Dependency = $dependencies
                ResetFailureCount = 3456
                OnFirstFailure = 'Restart'
                RestartDelay = 1234
                OnSecondFailure = 'RunCommand'
                Command = 'echo "Failed!"'
                RunCommandDelay = 5678
                OnThirdFailure = 'Reboot'
                RebootDelay = 9012
            } -IsIdempotent
            ThenError -IsEmpty
            ThenOutput -IsEmpty
            ThenService $script:serviceName `
                        -Runs $script:servicePath `
                        -WithArgs "-k Fubar" `
                        -Is 'Stopped' `
                        -HasStartMode Manual `
                        -HasDisplayName 'carbon display name 001' `
                        -HasDescription 'description 001' `
                        -DependsOn $dependencies `
                        -ResetsFailuresEvery '0:00:03.456' `
                        -OnFirstFailure 'Restart' `
                        -HasRestartDelay '0:00:01.234' `
                        -OnSecondFailure 'RunCommand' `
                        -RunsFailureCommand 'echo "Failed!"' `
                        -HasRunCommandDelay '0:00:05.678' `
                        -OnThirdFailure 'Reboot' `
                        -HasRebootDelay '0:00:09.012' `
                        -RunAs 'NETWORKSERVICE'
        }

        It 'can install service to run as custom credential' {
            WhenInstalling -WithArgs @{ Credential = $script:serviceCredential } -IsIdempotent
            ThenError -IsEmpty
            ThenOutput -IsEmpty
            ThenService -RunAs $script:serviceCredential.UserName
        }

        It 'can install service to run as built-in account' {
            WhenInstalling -WithArgs @{ UserName = 'SYSTEM' } -IsIdempotent
            ThenError -IsEmpty
            ThenOutput -IsEmpty
            ThenService -RunAs 'SYSTEM'
        }

        # We don't have the ability to create a gMSA or virtual account, but we can kind of mimic it by allowing someone to
        # pass any username without a password.
        It 'can install service to run as gMSA or virtual account' {
            WhenInstalling -WithArgs @{ UserName = $script:serviceAcct ; ErrorAction = 'SilentlyContinue' }
            ThenError -Matches 'cannot start service'
            ThenOutput -IsEmpty
            ThenService -Is 'Stopped' -RunAs $script:serviceAcct
        }

        # Can only set delayed if service start mode is automatic.
        It 'installs automatic delayed service' {
            WhenInstalling -WithArg @{ Delayed = $true } -IsIdempotent
            ThenError -IsEmpty
            ThenOutput -IsEmpty
            ThenService -Is 'Running' -HasStartMode 'Automatic' -StartsDelayed
        }
    }

    Context 'service exists' {
        BeforeEach {
            WhenInstalling
            ThenService $script:serviceName `
                        -Runs $script:servicePath `
                        -WithArgs '' `
                        -Is 'Running' `
                        -HasStartMode Automatic `
                        -HasDisplayName $script:serviceName `
                        -HasDescription '' `
                        -DependsOn @() `
                        -ResetsFailuresEvery '0:00:00' `
                        -OnFirstFailure 'TakeNoAction' `
                        -HasRestartDelay '0:00:00' `
                        -OnSecondFailure 'TakeNoAction' `
                        -RunsFailureCommand '' `
                        -HasRunCommandDelay '0:00:00' `
                        -OnThirdFailure 'TakeNoAction' `
                        -HasRebootDelay '0:00:00' `
                        -RunAs 'NETWORKSERVICE'
        }

        $dependencies = Get-Service -ErrorAction Ignore | Select-Object -First 2 | Select-Object -ExpandProperty 'Name'
        $propertyTestCases = @(
            @{
                PropertyName = 'Name'
                InstallWith = @{ Name = '-2' }
                ThenService = @{ Named = '-2' ; }
            },
            @{
                PropertyName = 'Path'
                InstallWith = @{ Path = 'NoOpCoreService2.exe' }
                ThenService = @{ Runs = 'NoOpCoreService2.exe' }
            },
            @{
                PropertyName = 'ArgumentList'
                InstallWith = @{ ArgumentList = @('-k', 'Fubar') }
                ThenService = @{ WithArgs = '-k Fubar' }
            },
            @{
                PropertyName = 'StartupType'
                InstallWith = @{ StartupType = 'Manual' }
                ThenService = @{ HasStartMode = 'Manual' }
            },
            @{
                PropertyName = 'Delayed'
                InstallWith = @{ Delayed = $true }
                ThenService = @{ HasStartMode = 'Automatic' ; StartsDelayed = $true }
            },
            @{
                PropertyName = 'OnFirstFailure'
                InstallWith = @{ OnFirstFailure = 'Restart' }
                ThenService = @{ OnFirstFailure = 'Restart' ; HasRestartDelay = '0:01:00' }
            },
            @{
                PropertyName = 'OnSecondFailure'
                InstallWith = @{ OnFirstFailure = 'Restart' }
                ThenService = @{ OnFirstFailure = 'Restart' ; HasRestartDelay = '0:01:00' }
            },
            @{
                PropertyName = 'OnThirdFailure'
                InstallWith = @{ OnFirstFailure = 'Restart' }
                ThenService = @{ OnFirstFailure = 'Restart' ; HasRestartDelay = '0:01:00' }
            },
            @{
                PropertyName = 'ResetFailureCount'
                InstallWith = @{ ResetFailurecount = 3456 }
                ThenService = @{ ResetsFailuresEvery = '0:00:03.456'}
            },
            @{
                PropertyName = 'RestartDelay'
                InstallWith = @{ RestartDelay = 78901 }
                ThenService = @{ HasRestartDelay = '0:00:00' }
            },
            @{
                PropertyName = 'RebootDelay'
                InstallWith = @{ RebootDelay = 2345 }
                ThenService = @{ HasRebootDelay = '0:00:00:00' }
            },
            @{
                PropertyName = 'Dependency'
                InstallWith = @{ Dependency = $dependencies }
                ThenService = @{ DependsOn = $dependencies }
            },
            @{
                PropertyName = 'FailureCommand'
                InstallWith = @{ Command = 'echo "Failed 2!"' }
                ThenService = @{ RunsFailureCommand = ''}
            },
            @{
                PropertyName = 'RunCommandDelay'
                InstallWith = @{ RunCommandDelay = 6789012 }
                ThenService = @{ HasRunCommandDelay = '0:00:00' }
            },
            @{
                PropertyName = 'Description'
                InstallWith = @{ Description = 'new description' }
                ThenService = @{ HasDescription = 'new description' }
            },
            @{
                PropertyName = 'DisplayName'
                InstallWith = @{ DisplayName = 'carbon display name' }
                ThenService = @{ HasDisplayName = 'carbon display name'}
            },
            @{
                PropertyName = 'UserName'
                InstallWith = @{ UserName = 'SYSTEM' }
                ThenService = @{ RunAs = 'SYSTEM' }
            }
        )

        It 're-installs idempotently when only <PropertyName> changes' -ForEach $propertyTestCases {
            if ($InstallWith['Name'])
            {
                $InstallWith['Name'] = "${script:serviceName}$($InstallWith['Name'])"
            }
            if ($InstallWith['Path'])
            {
                $InstallWith['Path'] =
                    Join-Path -Path ($script:servicePath | Split-Path -Parent) -ChildPath $InstallWith['Path']
                Copy-Item -Path $script:servicePath -Destination $InstallWith['Path']
            }
            WhenInstalling -WithArgs $InstallWith -IsIdempotent

            if ($ThenService['Named'])
            {
                $ThenService['Named'] = "${script:serviceName}$($ThenService['Named'])"
            }
            if ($ThenService['Runs'])
            {
                $ThenService['Runs'] =
                    Join-Path -Path ($script:servicePath | Split-Path -Parent) -ChildPath $ThenService['Runs']
            }

            $thenArgs = @{
                Named = $script:serviceName
                Runs = $script:servicePath
                WithArgs = ''
                Is = 'Running'
                HasStartMode = 'Automatic'
                HasDisplayName = $script:serviceName
                HasDescription = ''
                DependsOn = @()
                ResetsFailuresEvery = '0:00:00'
                OnFirstFailure = 'TakeNoAction'
                HasRestartDelay = '0:00:00'
                OnSecondFailure = 'TakeNoAction'
                RunsFailureCommand = ''
                HasRunCommandDelay = '0:00:00'
                OnThirdFailure = 'TakeNoAction'
                HasRebootDelay = '0:00:00'
                RunAs = 'NETWORKSERVICE'
            }
            foreach ($thenArgName in $ThenService.Keys)
            {
                $thenArgs[$thenArgName] = $ThenService[$thenArgName]
            }
            ThenService @thenArgs
        }
    }

    Context 'failure actions' {
        $delayTestCases = @(
            @{
                FailureAction = 'Reboot'
                DefaultDelay = '00:01:00'
                NewDelay = '0:00:01.234'
            },
            @{
                FailureAction = 'Restart'
                DefaultDelay = '00:01:00'
                NewDelay = '0:00:05.678'
            },
            @{
                FailureAction = 'RunCommand'
                DefaultDelay = '00:00:00'
                NewDelay = '0:00:09.012'
            }
        )

        It 're-installs idempotently when <FailureAction> failure action delay changes' -ForEach $delayTestCases {
            WhenInstalling -WithArgs @{ OnFirstFailure = $FailureAction }

            $thenServiceDelayArgName = "Has${FailureAction}Delay"
            $hasDefaulDelay = @{ $thenServiceDelayArgName = $DefaultDelay }
            ThenService -OnFirstFailure $FailureAction @hasDefaulDelay

            $installArgName = "${FailureAction}Delay"
            $NewDelay = [TimeSpan]$NewDelay
            $installArgs = @{ OnFirstFailure = $FailureAction ; $installArgName = $NewDelay.TotalMilliseconds }
            WhenInstalling -WithArgs $installArgs -IsIdempotent

            $hasNewDelay = @{ $thenServiceDelayArgName = $NewDelay }
            ThenService -OnFirstFailure $FailureAction @hasNewDelay
        }

        It 're-installs idempotently when FailureCommand changes' {
            WhenInstalling -WithArgs @{ OnFirstFailure = 'RunCommand' }
            ThenService -OnFirstFailure 'RunCommand' -HasRunCommandDelay '0:00:00' -RunsFailureCommand ''
            WhenInstalling -WithArgs @{ OnFirstFailure = 'RunCommand' ; Command = 'echo "Fail 3!"' } -IsIdempotent
            ThenService -OnFirstFailure 'RunCommand' -HasRunCommandDelay '0:00:00' -RunsFailureCommand 'echo "Fail 3!"'
        }
    }

    It 'supports WhatIf' {
        WhenInstalling -WithArgs @{ WhatIf = $true }
        ThenService -Not -Exists
    }

    It 'forces re-install of unchanged service' {
        WhenInstalling -WithIdempotentArgs @{ Force = $true } -Not -IsIdempotent
        ThenService -Is 'Running'
    }

    It 'quotes service argumens' {
        WhenInstalling -WithArgs @{ ArgumentList = "-k","Fu bar","-w",'"Surrounded By Quotes"' }
        ThenError -IsEmpty
        ThenService -Runs $script:servicePath -WithArgs '-k "Fu bar" -w "Surrounded By Quotes"'
    }

    It 'resets missing properties of missing arguments back to defaults' {
            WhenInstalling -WithArgs @{
                Name = $script:serviceName
                Path = $script:servicePath
                ArgumentList = @('-k', 'Fubar')
                StartUpType = 'Manual'
                DisplayName = 'carbon display name 001'
                Description = 'description 001'
                Dependency = @('W32Time')
                ResetFailureCount = 3456
                OnFirstFailure = 'Restart'
                RestartDelay = 1234
                OnSecondFailure = 'RunCommand'
                Command = 'echo "Failed!"'
                RunCommandDelay = 5678
                OnThirdFailure = 'Reboot'
                RebootDelay = 9012
            }
            ThenError -IsEmpty
            ThenOutput -IsEmpty
            WhenInstalling -WithArgs @{ Name = $script:serviceName ; Path = $script:servicePath }
            ThenService $script:serviceName `
                        -Runs $script:servicePath `
                        -WithArgs '' `
                        -Is 'Running' `
                        -HasStartMode Automatic `
                        -HasDisplayName $script:serviceName `
                        -HasDescription '' `
                        -DependsOn @() `
                        -ResetsFailuresEvery '0:00:00:00' `
                        -OnFirstFailure 'TakeNoAction' `
                        -HasRestartDelay '0:00:00' `
                        -OnSecondFailure 'TakeNoAction' `
                        -RunsFailureCommand '' `
                        -HasRunCommandDelay '0:00:00' `
                        -OnThirdFailure 'TakeNoAction' `
                        -HasRebootDelay '0:00:00' `
                        -RunAs 'NETWORKSERVICE'
    }

    It 'ensures dependencies exist' {
        WhenInstalling -WithArgs @{ Dependency = 'IAmAServiceThatDoesNotExist' ; ErrorAction = 'SilentlyContinue' }
        ThenError -Matches 'Dependent service .* not found'
        ThenService -Not -Exists
    }

    It 'supports relative path to service' {
        $workingDir = $script:servicePath | Split-Path -Parent | Split-Path -Parent
        $dirName = $script:servicePath | Split-Path -Parent | Split-Path -Leaf
        $serviceExeName = $script:servicePath | Split-Path -Leaf
        $svcPath = ".\${dirName}\${serviceExeName}"

        Push-Location -Path $workingDir
        try
        {
            WhenInstalling -WithArgs @{ Path = $svcPath }
            ThenService -Is 'Running' -Runs $script:servicePath
        }
        finally
        {
            Pop-Location
        }
    }

    Context 'service status' {
        Context 'Automatic' {
            It 'preserves existing service status' {
                WhenInstalling -WithArgs @{ StartupType = 'Automatic' }
                ThenService -Is 'Running'
                Stop-Service -Name $script:serviceName
                ThenService -Is 'Stopped'
                WhenInstalling -WithArgs @{ StartupType = 'Automatic' }
                ThenService -Is 'Stopped'
            }

            It 'ensures service started' {
                WhenInstalling -WithArgs @{ StartupType = 'Automatic' }
                ThenService -Is 'Running'
                Stop-Service -Name $script:serviceName
                ThenService -Is 'Stopped'
                WhenInstalling -WithArgs @{ StartupType = 'Automatic' ; EnsureRunning = $true }
                ThenService -Is 'Running'
            }
        }

        Context 'Manual' {
            It 'preserves existing service status' {
                WhenInstalling -WithArgs @{ StartupType = 'Manual' }
                ThenService -Is 'Stopped' -HasStartMode 'Manual'
                Start-Service $script:serviceName
                ThenService -Is 'Running' -HasStartMode 'Manual'
                WhenInstalling -WithArgs @{ StartupType = 'Manual' }
                ThenService -Is 'Running' -HasStartMode 'Manual'
            }

            It 'does not start service' {
                WhenInstalling -WithArgs @{ StartupType = 'Manual' }
                ThenService -Is 'Stopped' -HasStartMode 'Manual'
            }

            It 'ensures service started' {
                WhenInstalling -WithArgs @{ StartupType = 'Manual' ; EnsureRunning = $true}
                ThenService -Is 'Running' -HasStartMode 'Manual'
            }
        }
    }

    It 'returns service object' {
        WhenInstalling -WithArgs @{ StartupType = 'Automatic' ; PassThru = $true }
        ThenOutput -IsServiceController

        # Change service, make sure  object reeturned
        WhenInstalling -WithArgs @{ StartupType = 'Manual' ; PassThru = $true }
        ThenOutput -IsServiceController

        # No changes, service still returned
        WhenInstalling -WithArgs @{ StartupType = 'Manual' ; PassThru = $true }
        ThenOutput -IsServiceController
    }
}
