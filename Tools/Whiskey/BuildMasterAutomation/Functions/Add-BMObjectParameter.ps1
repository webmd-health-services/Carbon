
function Add-BMObjectParameter
{
    <#
    .SYNOPSIS
    Adds an object to a parameter hashtable based on the object's type.

    .DESCRIPTION
    The `Add-BMObjectParameter` adds a parameter to a parameter hashtable based on the parameter's type. Many of BuildMaster's APIs take an ID or a name. For example, many of the Release and Package Deployment methods accept either an `applicationId` parameter *or* an `applicationName` parameter. This function takes either application object, an application ID, or an application name, figures out what was passed, and adds the correct `applicationId`, or `applicationName` parameter.

    The hashtable is passed to the `Parameter` parameter (or you can pipe it to `Add-BMObjectParameter` function). Use the `PassThru` switch to return the hashtable to the pipeline.

    Pass the name of the parameter, without the `Id` or `Name` suffix via the `Name` parameter, e.g. `pipeline`, `application`, `release`, etc.

    Pass the value of the parameter to the `Value` parameter. This can be an object, an integer, or a string. If you pass an integer, a parameter with the name `$($Name)Id` is added to the hashtable. If you pass a string, a parameter with the name `$($Name)Name` is added. If you pass an object, `Add-BMObjectParameter` looks for `id`, `$($Name)_Id`, `name`, or `$($Name)_Name` properties on it (in that order) and adds an `$($Name)Id` parameter if it finds an ID property or a `$($Name)Name` parameter if it finds an Name property.

    .EXAMPLE
    $parameters | Add-BMObjectParameter -Name 'application' -Value $app

    Demonstrates how to add an ID or Name parameter `$parameters` hashtable. In this case, `Add-BMObjectParameter` will check if `$app` is an integer. If it is, it will add an `applicationId` parameter to the `$parameters` hashtable. If `$app` is a string, it will add an `applicationName` parameter. If `$app` is an object, `Add-BMObjectParameter` will look for an `Application_Id` or `id` property. If it finds one, it adds an `applicationId` parameter to `$parameters`. If it doesn't, it looks for an `Application_Name` or `name` property. If it finds one, it adds an `applicationName` parameter to `$parameters`. Otherwise, it will write an error and not add anything.

    .EXAMPLE
    $parameter | Add-BMObjectParmaeter -Name 'application -Value $app -PassThru | Add-BMObjectParameter -Name 'pipeline' -Value $pipeline

    Demonstrates how you can use the `PassThru` switch to add multiple parameters to a parameters hashtable.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [hashtable]
        # The hashtable to add the parameter to.
        $Parameter,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the parameter, *without* the `Id` or `Name` suffix. The suffix is added automatically based on the type of the parameter value.
        $Name,

        [Parameter(Mandatory=$true)]
        [object]
        # The object 
        $Value,

        [Switch]
        $PassThru
    )

    process
    {
        Set-StrictMode -Version 'Latest'

        $idParamName = '{0}Id' -f $Name
        $nameParamName = '{0}Name' -f $Name
        $idPropertyName = '{0}_Id' -f $Name
        $namePropertyName = '{0}_Name' -f $Name

        if( $Value -is [int] )
        {
            $Parameter[$idParamName] = $Value
        }
        elseif( $Value -is [string] )
        {
            $Parameter[$nameParamName] = $Value
        }
        elseif( $Value | Get-Member -Name 'id' )
        {
            $Parameter[$idParamName] = $Value.id
        }
        elseif( $Value | Get-Member -Name $idPropertyName )
        {
            $Parameter[$idParamName] = $Value.$idPropertyName
        }
        elseif( $Value | Get-Member -Name 'name' )
        {
            $Parameter[$nameParamName] = $Value.name
        }
        elseif( $Value | Get-Member -Name $namePropertyName )
        {
            $Parameter[$nameParamName] = $value.$namePropertyName
        }

        if( $PassThru )
        {
            return $Parameter
        }
    }


}

