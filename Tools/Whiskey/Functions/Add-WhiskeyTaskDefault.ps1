
function Add-WhiskeyTaskDefault
{
    <#
    .SYNOPSIS
    Sets default values for task parameters.

    .DESCRIPTION
    The `Add-WhiskeyTaskDefault` functions sets default properties for tasks. These defaults are only used if the property is missing from the task in your `whiskey.yml` file, i.e. properties defined in your whiskey.yml file take precedence over task defaults.

    `TaskName` must be the name of an existing task. Otherwise, `Add-WhiskeyTaskDefault` will throw an terminating error.

    By default, existing defaults are left in place. To override any existing defaults, use the `-Force`... switch.

    .EXAMPLE
    Add-WhiskeyTaskDefault -Context $context -TaskName 'MSBuild' -PropertyName 'Version' -Value 12.0

    Demonstrates setting the default value of the `MSBuild` task's `Version` property to `12.0`.

    .EXAMPLE
    Add-WhiskeyTaskDefault -Context $context -TaskName 'MSBuild' -PropertyName 'Version' -Value 15.0 -Force

    Demonstrates overwriting the current default value for `MSBuild` task's `Version` property to `15.0`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [object]
        # The current build context. Use `New-WhiskeyContext` to create context objects.
        $Context,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the task that a default parameter value will be set.
        $TaskName,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the task parameter to set a default value for.
        $PropertyName,

        [Parameter(Mandatory=$true)]
        # The default value for the task parameter.
        $Value,

        [switch]
        # Overwrite an existing task default with a new value.
        $Force
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if (-not ($Context | Get-Member -Name 'TaskDefaults'))
    {
        throw 'The given ''Context'' object does not contain a ''TaskDefaults'' property. Create a proper Whiskey context object using the ''New-WhiskeyContext'' function.'
    }

    if ($TaskName -notin (Get-WhiskeyTask | Select-Object -ExpandProperty 'Name'))
    {
        throw 'Task ''{0}'' does not exist.' -f $TaskName
    }

    if ($context.TaskDefaults.ContainsKey($TaskName))
    {
        if ($context.TaskDefaults[$TaskName].ContainsKey($PropertyName) -and -not $Force)
        {
            throw 'The ''{0}'' task already contains a default value for the property ''{1}''. Use the ''Force'' parameter to overwrite the current value.' -f $TaskName,$PropertyName
        }
        else
        {
            $context.TaskDefaults[$TaskName][$PropertyName] = $Value
        }
    }
    else
    {
        $context.TaskDefaults[$TaskName] = @{ $PropertyName = $Value }
    }
}
