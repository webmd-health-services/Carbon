
function Invoke-WhiskeyNpmCommand
{
    <#
    .SYNOPSIS
    Runs `npm` with given command and argument.
    
    .DESCRIPTION
    The `Invoke-WhiskeyNpmCommand` function runs `npm` commands with given arguments in a Node.js project. The function will first call `Install-WhiskeyNodeJs` and `Get-WhiskeyNPMPath` to download and install the desired versions of Node.js and npm listed in the project's `package.json` `engines` field. Then `npm` will be invoked with the given `NpmCommand` and `Argument` in the `ApplicationRoot` directory. If `npm` returns a non-zero exit code this function will write an error indicating that the npm command failed.

    You must specify the `npm` command you would like to run with the `NpmCommand` parameter. Optionally, you may specify arguments for the `npm command` with the `Argument` parameter.

    The `ApplicationRoot` parameter must contain the path to the directory where the Node.js module's `package.json` can be found.

    .EXAMPLE
    Invoke-WhiskeyNpmCommand -NpmCommand 'install' -ApplicationRoot 'src\app' -RegistryUri 'http://registry.npmjs.org' -ForDeveloper

    Runs the `npm install' command without any arguments in the 'src\app' directory as a developer.

    .EXAMPLE
    Invoke-WhiskeyNpmCommand -NpmCommand 'run' -Argument 'test --silent' -ApplicationRoot 'src\app' -RegistryUri 'http://registry.npmjs.org'

    Executes `npm run test --silent` in the 'src\app' directory.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='InvokeNpm')]
        [string]
        # The NPM command to execute.
        $NpmCommand,
        
        [Parameter(ParameterSetName='InvokeNpm')]
        [string[]]
        # An array of arguments to be given to the NPM command being executed.
        $Argument,

        [Parameter(ParameterSetName='InitializeOnly')]
        [switch]
        $InitializeOnly,

        [Parameter(Mandatory=$true)]
        [string]
        # The root directory of the target Node.js application. This directory will contain the application's `package.json` config file and will be where NPM will be executed from.
        $ApplicationRoot,

        [Parameter(Mandatory=$true)]
        # The URI to the registry from which NPM packages should be downloaded.
        $RegistryUri,

        [switch]
        # NPM commands are being run on a developer computer.
        $ForDeveloper
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $startedAt = Get-Date
    function Write-Timing
    {
        param(
            $Message
        )

        $now = Get-Date
        Write-Debug -Message ('[{0}]  [{1}]  {2}' -f $now,($now - $startedAt),$Message)
    }

    $activity = ('Invoke npm command ''{0}''' -f $NpmCommand)
    Write-Progress -Activity $activity -Status 'Validating package.json and starting installation of Node.js version required for this package (if required)'

    Write-Timing -Message 'Installing Node.js'
    $nodePath = Install-WhiskeyNodeJs -RegistryUri $RegistryUri -ApplicationRoot $ApplicationRoot -ForDeveloper:$ForDeveloper
    Write-Timing -Message ('COMPLETE')

    if (-not $nodePath)
    {
        Write-Error -Message 'Node.js version required for this package failed to install. Please see previous errors for details.'
        $Global:LASTEXITCODE = 1
        return
    }
    
    $nodeRoot = $nodePath | Split-Path
    $npmGlobalPath = Join-Path -Path $nodeRoot -ChildPath 'node_modules\npm\bin\npm-cli.js' -Resolve
    if (-not $npmGlobalPath)
    {
        Write-Error -Message 'NPM didn''t get installed by NVM when installing Node. Please use NVM to uninstall this version of Node.'
        $Global:LASTEXITCODE = 2
        return
    }

    Write-Progress -Activity $activity -Status 'Getting path to the version of NPM required for this package'

    Write-Timing -Message 'Resolving path to NPM.'
    $npmPath = Get-WhiskeyNPMPath -NodePath $nodePath -ApplicationRoot $ApplicationRoot
    Write-Timing -Message ('COMPLETE')
    
    if (-not $npmPath)
    {
        Write-Error -Message ('Could not locate version of NPM that is required for this package. Please see previous errors for details.')
        $Global:LASTEXITCODE = 3
        return
    }

    if ($InitializeOnly)
    {
        $Global:LASTEXITCODE = 0
        Write-Timing -Message 'Initialization complete.'
        return
    }

    $originalPath = $env:PATH

    Push-Location -Path $ApplicationRoot
    try
    {
        Set-Item -Path 'env:PATH' -Value ('{0};{1}' -f $nodeRoot,$env:Path)

        $defaultArguments = @('--scripts-prepend-node-path=auto')
        if (-not $ForDeveloper)
        {
            $defaultArguments += '--no-color'
        }

        $npmCommandString = ('npm {0} {1} {2}' -f $NpmCommand,($Argument -join ' '),($defaultArguments -join ' '))
        Write-Progress -Activity $activity -Status ('Executing ''{0}''' -f $npmCommandString)
        Invoke-Command -NoNewScope -ScriptBlock {
            & $nodePath $npmPath $NpmCommand $Argument $defaultArguments
        }

        if ($LASTEXITCODE -ne 0)
        {
            Write-Error -Message ('NPM command ''{0}'' failed with exit code {1}.' -f $npmCommandString,$LASTEXITCODE)
        }
    }
    finally
    {
        Set-Item -Path 'env:PATH' -Value $originalPath

        Pop-Location
    }
}
