
function Add-WhiskeyVariable
{
    <#
    .SYNOPSIS
    Adds a variable to the current build.

    .DESCRIPTION
    The `Add-WhiskeyVariable` adds a variable to the current build. Variables can be used in task properties and at runtime are replaced with their values. Variables syntax is `$(VARIABLE_NAME)`. Variable names are case-insensitive.

    .EXAMPLE
    Add-WhiskeyVariable -Context $context -Name 'Timestamp' -Value (Get-Date).ToString('o')

    Demonstrates how to add a variable. In this example, Whiskey will replace any `$(Timestamp)` variables it finds in any task properties with the value returned by `(Get-Date).ToString('o')`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The context of the build here you want to add a variable.
        $Context,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the variable.
        $Name,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [object]
        $Value
    )

    Set-StrictMode -Version 'Latest'

    $Context.Variables[$Name] = $Value

}
