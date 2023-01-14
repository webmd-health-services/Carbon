
function Write-CCimError
{
    <#
    .SYNOPSIS
    Writes an error if a CIM/WMI result object's return value has an non-zero result.

    .DESCRIPTION
    The `Write-CCimError` function writes an error message based on the `ReturnValue` property of a CIM/WMI return
    object. It includes in the error message the error code and a description of the error. Pass your own message to
    the `Message` parameter and the result object to the `Result` property.

    If the object passed to the `Result` parameter is `$null` or doesn't have a `ReturnValue` property, or the
    `ReturnValue` is `0`, nothing happens.

    .EXAMPLE
    Write-CCimError -Message 'Failed to create share "MyShare"' -Result $result
    #>
    [CmdletBinding()]
    param(
        # The message to write. A description of the error and the error code are appended to this message.
        [Parameter(Mandatory)]
        [String] $Message,

        # The result object returned from a CIM/WMI method call that has a `ReturnValue` property.
        [Object] $Result
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $Result -or -not ($Result | Get-Member -Name 'ReturnValue') -or -not $Result.ReturnValue)
    {
        return
    }

    $errorCodeToDescriptionMap = @{
        [uint32]2 = 'Access Denied';
        [uint32]8 = 'Unknown Failure';
        [uint32]9 = 'Invalid Name';
        [uint32]10 = 'Invalid Level';
        [uint32]21 = 'Invalid Parameter';
        [uint32]22 = 'Duplicate Share';
        [uint32]23 = 'Restricted Path';
        [uint32]24 = 'Unknown Device or Directory';
        [uint32]25 = 'Net Name Not Found';
    }

    $msg = "$($msg): $($errorCodeToDescriptionMap[$Result.ReturnValue]) (error code $($Result.ReturnValue))."
    Write-Error -Message $msg -ErrorAction $ErrorActionPreference
}