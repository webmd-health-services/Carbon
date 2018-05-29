
function Invoke-WhiskeyNodeNspCheck
{
    <#
    .SYNOPSIS
    Runs the Node Security Platform against a module's dependenices.
    
    .DESCRIPTION
    The `NodeNspCheck` task runs `node.exe nsp check`, the Node Security Platform, which checks a `package.json` and `npm-shrinkwrap.json` for known security vulnerabilities against the Node Security API. The latest version of the NSP module is installed into a dedicated Node environment you can find in a .node directory in the same directory as your whiskey.yml file. If any security vulnerabilties are found, the NSP module returns a non-zero exit code which will fail the task.

    You must specify what version of Node.js you want in the engines field of your package.json file. (See https://docs.npmjs.com/files/package.json#engines for more information.) The version of Node is installed into a .node directory in the same directory as your whiskey.yml file.

    If the application's `package.json` file does not exist in the build root next to the `whiskey.yml` file, specify a `WorkingDirectory` where it can be found.

    This task will install the latest LTS version of Node into a `.node` directory (in the same directory as your whiskey.yml file). To use a specific version, set the `engines.node` property in your package.json file to the version you want. (See https://docs.npmjs.com/files/package.json#engines for more information.)

    # Properties

    * `WorkingDirectory`: the directory where the `package.json` exists. Defaults to the directory where the build's `whiskey.yml` file was found. Must be relative to the `whiskey.yml` file.
    * `Version`: the version of NSP to install and utilize for security checks. Defaults to the latest stable version of NSP.
    * `NodeVersion`: the version of Node to use. By default, the version in the `engines.node` property of your package.json file is used. If that is missing, the latest LTS version of Node is used. 

    # Examples

    ## Example 1

        Build:
        - NodeNspCheck
    
    This example will run `node.exe nsp check` against the modules listed in the `package.json` file located in the build root.

    ## Example 2

        Build:
        - NodeNspCheck:
            WorkingDirectory: app
    
    This example will run `node.exe nsp check` against the modules listed in the `package.json` file that is located in the `(BUILD_ROOT)\app` directory.

    ## Example 3

        Build:
        - NodeNspCheck:
            Version: 2.7.0
    
    This example will run `node.exe nsp check` by installing and running NSP version 2.7.0.
    #>
    [Whiskey.Task("NodeNspCheck")]
    [Whiskey.RequiresTool("Node", "NodePath", VersionParameterName='NodeVersion')]
    [Whiskey.RequiresTool("NodeModule::nsp", "NspPath", VersionParameterName="Version")]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Whiskey.Context]
        $TaskContext,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $TaskParameter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $nspPath = Assert-WhiskeyNodeModulePath -Path $TaskParameter['NspPath'] -CommandPath 'bin\nsp' -ErrorAction Stop

    $nodePath = Assert-WhiskeyNodePath -Path $TaskParameter['NodePath'] -ErrorAction Stop

    $formattingArg = '--reporter'
    $isPreNsp3 = $TaskParameter.ContainsKey('Version') -and $TaskParameter['Version'] -match '^(0|1|2)\.'
    if( $isPreNsp3 )
    {
        $formattingArg = '--output'
    }

    Write-WhiskeyTiming -Message 'Running NSP security check'
    $output = Invoke-Command -NoNewScope -ScriptBlock {
        param(
            $JsonOutputFormat
        )

        & $nodePath $nspPath 'check' $JsonOutputFormat 'json' 2>&1 |
            ForEach-Object { if( $_ -is [Management.Automation.ErrorRecord]) { $_.Exception.Message } else { $_ } }
    } -ArgumentList $formattingArg

    Write-WhiskeyTiming -Message 'COMPLETE'

    try
    {
        $results = ($output -join [Environment]::NewLine) | ConvertFrom-Json
    }
    catch
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('NSP, the Node Security Platform, did not run successfully as it did not return valid JSON (exit code: {0}):{1}{2}' -f $LASTEXITCODE,[Environment]::NewLine,$output)
    }

    if ($Global:LASTEXITCODE -ne 0)
    {
        $summary = $results | Format-List | Out-String
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('NSP, the Node Security Platform, found the following security vulnerabilities in your dependencies (exit code: {0}):{1}{2}' -f $LASTEXITCODE,[Environment]::NewLine,$summary)
    }
}
