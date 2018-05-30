 function Set-WhiskeyVariable 
{
    <#
    .SYNOPSIS
    Sets a variable for the current build.

    .DESCRIPTION
    The `SetVariable` task sets a variable. If the variable doesn't exist, it is added. If it already exists, its value is updated. Variables are referenced in your whiskey.yml file using the syntax `$(VARIABLE NAME)`, where `VARIABLE NAME` is replaced with the name of the variable. Any of Whiskey's pre-defined variables are not allowed to be changed. Attempting to change them will result in a build error.

    All the task's properties are variable names. Each property's value becomes that variables value. You may reference other variables in a value. They will be replaced with values when they are used, not when they are added by this task.

        Build:
        - SetVariable:
            ReleaseName: 6.8
            BuildMasterPackageName: $(WHISKEY_BUILD_NUMBER)@$(WHISKEY_SCM_BRANCH)

    Would add a `ReleaseName` variable whose value is `6.8` and a `BuildMasterPackageName` variable whose value is `$(WHISKEY_BUILD_NUMBER)@$(WHISKEY_SCM_BRANCH)`.
    #>
    [CmdletBinding()]
    [Whiskey.Task("SetVariable",SupportsClean=$true,SupportsInitialize=$true)]
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

    foreach( $key in $TaskParameter.Keys )
    {
        if( $key -match '^WHISKEY_' )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Variable ''{0}'' is a built-in Whiskey variable and can not be changed.' -f $key)
            continue
        }
        Add-WhiskeyVariable -Context $TaskContext -Name $key -Value $TaskParameter[$key]
    }
}