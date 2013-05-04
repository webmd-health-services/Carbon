function Convert-XmlFile
{
    <#
    .SYNOPSIS
    Transforms an XML document using XDT (XML Document Transformation).
    
    .DESCRIPTION
	An XDT file specifies how to change an XML file from a *known* beginning state into a new state.  This is usually helpful when deploying IIS websites.  Usually, the website's default web.config file won't work in different environments, and needs to be changed during deployment to reflect settings needed for the target environment.

    XDT was designed to apply a tranformation against an XML file in a *known* state.  **Do not use this method to transform an XML file in-place.**  There lies madness, and you will never get that square peg into XDT's round whole.

    .LINK
    http://msdn.microsoft.com/en-us/library/dd465326.aspx
	
    .EXAMPLE
    Convert-XmlFile -Path ".\web.config" -XdtPath ".\web.debug.config" -Destination '\\webserver\wwwroot\web.config'
    
    Transforms `web.config` with the XDT in `web.debug.config` to a new file at `\\webserver\wwwroot\web.config`.

    .EXAMPLE
    Convert-XmlFile -Path ".\web.config" -XdtXml "<configuration><connectionStrings><add name=""MyConn"" xdt:Transform=""Insert"" /></connectionStrings></configuration>" -Destination '\\webserver\wwwroot\web.config'
    
    Transforms `web.config` with the given XDT XML to a new file at `\\webserver\wwwroot\web.config`.
    #>
    [CmdletBinding()]
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
    }
    
    $Path = Resolve-FullPath -Path $Path
    $XdtPath = Resolve-FullPath -Path $XdtPath
    $Destination = Resolve-FullPath -Path $Destination
    	
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
	
	    $xmlTransform.Dispose()
	    $document.Dispose()
    }

    try
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
    finally
    {
        if( $PSCmdlet.ParameterSetName -eq 'ByXdtXml' )
        {
            Remove-Item -Path $XdtPath
        }
    }
}

