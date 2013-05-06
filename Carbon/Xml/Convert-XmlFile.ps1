function Convert-XmlFile
{
    <#
    .SYNOPSIS
    Transforms an XML document using XDT (XML Document Transformation).
    
    .DESCRIPTION
    An XDT file specifies how to change an XML file from a *known* beginning state into a new state.  This is usually helpful when deploying IIS websites.  Usually, the website's default web.config file won't work in different environments, and needs to be changed during deployment to reflect settings needed for the target environment.

    XDT was designed to apply a tranformation against an XML file in a *known* state.  **Do not use this method to transform an XML file in-place.**  There lies madness, and you will never get that square peg into XDT's round hole.  If you *really* want to transform in-place, you're responsible for checking if the source/destination file has already been transformed, and if it hasn't, calling `Convert-XmlFile` to transform to a temporary file, then copying the temporary file onto the source/destination file.
    
    You can load custom transformations.  In your XDT XML, use the `xdt:Import` element to import your transformations.  In your XDT file:
    
        <?xml version="1.0"?>
        <root xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
            <!-- You can also use the "assembly" attribute if the assembly is in the GAC or in your path, otherwise use the "path" parameter.  
                 All classes in `namespace` that inherit from the XDT `Transform` class are loaded. -->
            <xdt:Import path="C:\Projects\Carbon\Lib\ExtraTransforms.dll"
                        namespace="ExtraTransforms" />
            <!-- ...snip... -->
        </root>
        
    That's it! (Note: Carbon does *not* ship with any extra transformations.)
    
    When transforming a file, the XDT framework will write warnings and errors to the PowerShell error and warning stream.  Informational and debug messages are written to the verbose stream (i.e. use the `Verbose` switch to see all the XDT log messages).
     
    .LINK
    http://msdn.microsoft.com/en-us/library/dd465326.aspx
    
    .LINK
    http://stackoverflow.com/questions/2915329/advanced-tasks-using-web-config-transformation
    
    .LINK
    Set-DotNetConnectionString
    
    .LINK
    Set-DotNetAppSetting

    .EXAMPLE
    Convert-XmlFile -Path ".\web.config" -XdtPath ".\web.debug.config" -Destination '\\webserver\wwwroot\web.config'
    
    Transforms `web.config` with the XDT in `web.debug.config` to a new file at `\\webserver\wwwroot\web.config`.

    .EXAMPLE
    Convert-XmlFile -Path ".\web.config" -XdtXml "<configuration><connectionStrings><add name=""MyConn"" xdt:Transform=""Insert"" /></connectionStrings></configuration>" -Destination '\\webserver\wwwroot\web.config'
    
    Transforms `web.config` with the given XDT XML to a new file at `\\webserver\wwwroot\web.config`.
    
    .EXAMPLE
    Convert-XmlFile -Path ".\web.config" -XdtPath ".\web.debug.config" -Destination '\\webserver\wwwroot\web.config' -Verbose
    
    See that `Verbose` switch? It will show informational/debug messages written by the XDT framework.  Very helpful in debugging what XDT framework is doing.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path of the XML file to convert.
        $Path,

        [Parameter(Mandatory=$true,ParameterSetName='ByXdtFile')]
        [string]
        # The path to the XDT file.
        $XdtPath,

        [Parameter(Mandatory=$true,ParameterSetName='ByXdtXml')]
        [xml]
        # The raw XDT XML to use.
        $XdtXml,
        
        [Parameter(Mandatory=$true)]
		[string]
        # The destination XML file's path.
        $Destination
    )
    

	if( -not (Test-Path -Path $Path -PathType Leaf))
	{
		Write-Error ("Path '{0}' not found." -f $Path)
        return
	}
	
    if( $PSCmdlet.ParameterSetName -eq 'ByXdtXml' )
    {
        $xdtPathForInfoMsg = ''
        $xdtPathForShouldProcess = 'raw XDT XML'
        $XdtPath = 'Carbon_Convert-XmlFile_{0}' -f ([IO.Path]::GetRandomFileName())
        $XdtPath = Join-Path $env:TEMP $XdtPath
        $xdtXml.Save( $XdtPath )
    }
    else
    {
	    if( -not (Test-Path -Path $XdtPath -PathType Leaf) )
	    {
		    Write-Error ("XdtPath '{0}' not found." -f $XdtPath)
            return
	    }
        $XdtPath = Resolve-FullPath -Path $XdtPath
        $xdtPathForShouldProcess = $XdtPath
        $xdtPathForInfoMsg = 'with ''{0}'' ' -f $XdtPath
    }
    
    $Path = Resolve-FullPath -Path $Path
    $Destination = Resolve-FullPath -Path $Destination

    if( $Path -eq $Destination )
    {
        $errorMsg = 'Can''t transform Path {0} onto Destination {1}: Path is the same as Destination. XDT is designed to transform an XML file from a known starting state to a new XML file. Please supply a new, unique path for the Destination XML file.' -f `
                        $Path,$Destination
        Write-Error -Message $errorMsg -Category InvalidOperation -RecommendedAction 'Set Destination parameter to a unique path.'
        return
    }
    	
    $scriptBlock = {
        [CmdletBinding()]
        param(
            [Parameter(Position=0)]
            [string]
            $CarbonBinDir,

            [Parameter(Position=1)]
            [string]
            $Path,

            [Parameter(Position=2)]
            [string]
            $XdtPath,

            [Parameter(Position=3)]
            [string]
            $Destination
        )

        Add-Type -Path (Join-Path $CarbonBinDir "Microsoft.Web.XmlTransform.dll")
        Add-Type -Path (Join-Path $CarbonBinDir "Carbon.Xdt.dll")

        try
        {
            $document = New-Object Microsoft.Web.XmlTransform.XmlTransformableDocument
            $document.PreserveWhitespace = $true
            $document.Load($Path)

            $logger = New-Object Carbon.Xdt.PSHostUserInterfaceTransformationLogger $PSCmdlet.CommandRuntime
            $xmlTransform = New-Object Microsoft.Web.XmlTransform.XmlTransformation $XdtPath,$logger

            $success = $xmlTransform.Apply($document)

            if($success)
            {
                $document.Save($Destination)
            }
        }
        finally
        {
            if( $xmlTransform )
            {	
                $xmlTransform.Dispose()
            }
            if( $document )
            {
                $document.Dispose()
            }
        }
    }

    try
    {
        Write-Host ('Transforming ''{0}'' {1}to ''{2}''.' -f $Path,$xdtPathForInfoMsg,$Destination)

        if( $PSCmdlet.ShouldProcess( $Path, ('transform with {0} -> {1}' -f $xdtPathForShouldProcess,$Destination) ) )
        {
            $argumentList = $CarbonBinDir,$Path,$XdtPath,$Destination
            if( $PSVersionTable.PSVersion -ge '3.0' )
            {
                Invoke-Command -ScriptBlock $scriptBlock -ArgumentList $argumentList
            }
            else
            {
                Invoke-PowerShell -Command $scriptBlock -Args $argumentList -Runtime 'v4.0'
            }
        }
    }
    finally
    {
        if( $PSCmdlet.ParameterSetName -eq 'ByXdtXml' )
        {
            Remove-Item -Path $XdtPath
        }
    }
}

