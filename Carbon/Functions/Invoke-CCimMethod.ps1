
function Invoke-CCimMethod
{
    <#
    .SYNOPSIS
    Calls a method on a CIM or WMI object.

    .DESCRIPTION
    The `Invoke-CCimMethod` invokes a method on a CIM or WMI object. Pipe the object to the function (or pass it to the
    `InputObject` parameter). Pass the name of the method to the `Name` parameter. Pass the method argumengs (if any)
    to the `Arguments` property. The method is called using WMI or CIM (with preference to CIM). If the method call
    returns a result object with a non-zero exit code, the function writes an error.

    You can call a class (i.e. non-instance) method by passing the class's name to the `ClassName` parameter instead of
    piping an object in.

    `Invoke-CCimMethod` will default to using CIM if it is available on the current system. To force it to use WMI, use
    the `AsWmiObject` switch.

    Because WMI and CIM call methods differently (WMI method arguments are passed in a specific order, while CIM
    arguments are passed by name), the `Arguments` parameter must be an `[ordered]` hashtable, and the parameters *must*
    be added in the same order as defined in the WMI method.

    .EXAMPLE
    $share | Invoke-CCimMethod -Name 'SetShareInfo' -Arguments ([ordered]@{ MaximumAllowed = 100 ; Description = 'Description' ; Access = $securityDescriptor })

    The above example demonstrates how to call a method on an object that could be a WMI or CIM object. It also
    demonstrates how the `Arguments` parameter works. Note the values in that hashtable are added/listed in the same
    order as defined in the `SetShareInfo` method.

    .EXAMPLE
    Invoke-CCimMethod -Name 'Create' -ClassName 'Win32_Share' -AsWmiObject -Arguments ([ordered]@{ Path = 'C:\Share' ; Name = 'Share' ; Type = 0 ; })

    The above example demonstrates how to call a CIM/WMI class method (because a class name is passed to the `ClassName`
    parameter) and how to force the call to happen using WMI (because the `AsWmiObject` is used).
    #>
    [CmdletBinding(DefaultParameterSetName='Default')]
    param(
        # The CIM or WMI object whose method to call.
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='Default')]
        [Object] $InputObject,

        # The method name to call.
        [Parameter(Mandatory)]
        [String] $Name,

        # Call the method on a class, not an object.
        [Parameter(Mandatory, ParameterSetName='Class')]
        [String] $ClassName,

        # The arguments to pass to the method. Must be an ordered hashtable, where the parameters are added by name in
        # the same order as defined by the method. WMI methods are called with arguments by order. CIM methods are
        # called with arguments by name.
        [Collections.Specialized.OrderedDictionary] $Arguments = @{},

        # Force the call to use WMI.
        [switch] $AsWmiObject
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $invokeArgs = @{}
        if (-not $AsWmiObject -and (Test-CCimAvailable))
        {
            if ($ClassName)
            {
                $invokeArgs['ClassName'] = $ClassName
            }
            else
            {
                $invokeArgs['InputObject'] = $InputObject
            }
            $result = Invoke-CimMethod -MethodName $Name -Arguments $Arguments @invokeArgs
        }
        else
        {
            if ($ClassName)
            {
                $invokeArgs['Class'] = $ClassName
            }
            else
            {
                $invokeArgs['InputObject'] = $InputObject
            }
            $result = Invoke-WmiMethod -Name $Name -ArgumentList $Arguments.Values @invokeArgs
        }

        if (-not $result.ReturnValue)
        {
            return
        }

        if (-not $ClassName)
        {
            if ($InputObject | Get-Member -Name 'CimClass')
            {
                $ClassName = $InputObject.CimClass
            }
            elseif ($InputObject | Get-Member '__CLASS')
            {
                $ClassName = $InputObject.__CLASS
            }
        }

        $onMsg = " on $($className)"
        if ($InputObject | Get-Member -Name 'Name')
        {
            $onMsg = "$($onMsg) ""$($InputObject.Name)"
        }
        $msg = "Failed to call method ""$($Name)""$($onMsg)"

        Write-CCimError -Message $msg -Result $result
    }
}
