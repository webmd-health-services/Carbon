
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
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, HelpMessage='What is the path of the MSI you would like to query?')]
        [Alias('FullName')]
        [string[]]
        # Path to the MSI file whose information to retrieve.
        $Path
    )
    
    begin 
    {
    }

    process 
    {
        foreach( $item in $Path )
        {
            $item = Resolve-Path -Path $item 
            if( -not $item )
            {
                continue
            }

            $msi = New-Object -ComObject 'WindowsInstaller.Installer'
            Write-Verbose ('Opening MSI {0}' -f $item)

            $database = $null
            try
            {
                $database = $msi.OpenDatabase( [string]$item, 0 )
            }
            catch
            {
                Write-Error -Exception $_.Exception
            }

            if( -not $database )
            {
                Write-Error ('Failed to open database in MSI ''{0}''.' -f $item)
                continue
            }

            try
            {
                $query = "SELECT * FROM Property"
            
                $view = $database.OpenView( $query )
                if( -not $view )
                {
                    Write-Error ('Failed to query properties for MSI ''{0}''.' -f $item)
                    continue
                }

                $null = $view.Execute()
                $record = $view.Fetch()

                $properties = @{ }
                while ($record -ne $null) 
                {
                    $properties[$record.StringData(1)] = $record.StringData(2)
                    $record = $view.Fetch()
                }

                New-Object -TypeName 'Carbon.Msi.MsiInfo' -ArgumentList $item,$properties
            }
            finally
            {
                if( $view )
                {
                    [void]$view.Close()
                    [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($view);
                }

                [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($database);
                [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($msi);
            }

        }
    }

    end 
    {
    }
}