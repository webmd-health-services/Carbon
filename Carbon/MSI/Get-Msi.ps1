
function Get-Msi
{
    <#
    .SYNOPSIS
    Gets details about an MSI file.

    .DESCRIPTION
    The `Get-Msi` function reads the installer properties from an MSI file and returns a `Carbon.Msi.MsiInfo` object representing an MSI's properties. `Carbon.Msi.MsiInfo` has properties for the following required MSI properties:

     * ProductName
     * ProductCode
     * ProduceLanguage
     * Manufacturer
     * ProductVersion

    All other properties are accessible via the `Properties` property, which is a hashtable of property name/value pairs.

    There is an additioanl `Path` property to capture the path of the MSI the properties came from.

    `Get-Msi` was introduced in Carbon 2.0.

    .LINK
    https://msdn.microsoft.com/en-us/library/aa370905.aspx

    .EXAMPLE
    Get-Msi -Path MyCool.msi

    Demonstrates how to read the properties from `MyCool.msi` file.

    .EXAMPLE
    Get-ChildItem *.msi -Recurse | Get-Msi

    Demonstrates how you can pipe file info objects into `Get-Msi`.
    #>
    [CmdletBinding()]
    [OutputType('Carbon.Msi.MsiInfo')]
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('FullName')]
        [string[]]
        # Path to the MSI file whose information to retrieve. Wildcards supported.
        $Path
    )
    
    begin 
    {
    }

    process 
    {
        $Path |
            Resolve-Path |
            Select-Object -ExpandProperty 'ProviderPath' |
            ForEach-Object {

                $msiPath = $_

                try
                {
                    Write-Verbose ('Opening MSI {0}' -f $msiPath)
                    New-Object -TypeName 'Carbon.Msi.MsiInfo' -ArgumentList $msiPath
                }
                catch
                {
                    $ex = $_.Exception
                    $errMsg = 'Failed to open MSI file ''{0}''.' -f $msiPath
                    if( $ex )
                    {
                        $errMsg = '{0} {1} was thrown. The exception message is: ''{2}''.' -f $errMsg,$ex.GetType().FullName,$ex.Message
                        if( $ex -is [Runtime.InteropServices.COMException] )
                        {
                            $errMsg = '{0} HRESULT: {1:x}. (You can look up the meaning of HRESULT values at https://msdn.microsoft.com/en-us/library/cc704587.aspx.)' -f $errMsg,$ex.ErrorCode
                        }
                    }
                    Write-Error -Message $errMsg
                    return
                }


            }
    }

    end 
    {
    }
}