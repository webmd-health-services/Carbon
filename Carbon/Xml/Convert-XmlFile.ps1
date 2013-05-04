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
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path of the XML file to convert.
        $Path,

        [Parameter(Mandatory=$true)]
        [string]
        # The path to the XDT file.
        $XdtPath,
        
        [Parameter(Mandatory=$true)]
		[string]
        # The destination XML file's path.
        $Destination
    )
    
	if( $PSVersionTable.CLRVersion -lt '4.0' )
	{
		Write-Error ("Convert-XmlFile requires .NET 4.0.  Please upgrade to PowerShell v3.")
		return
	}

	Add-Type -Path (Join-Path $CarbonBinDir "Microsoft.Web.XmlTransform.dll")
	Add-Type -Path (Join-Path $CarbonBinDir "Carbon.Xdt.dll")

	if( -not (Test-Path -Path $Path -PathType Leaf))
	{
		Write-Error ("Path '{0}' not found." -f $Path)
        return
	}
	
	if( -not (Test-Path -Path $XdtPath -PathType Leaf) )
	{
		Write-Error ("XdtPath '{0}' not found." -f $XdtPath)
        return
	}
	
	$document = New-Object Microsoft.Web.XmlTransform.XmlTransformableDocument
	$document.PreserveWhitespace = $true
	$document.Load($Path)
	
    $showVerbose = $VerbosePreference -ne 'SilentlyContinue' -and $VerbosePreference -ne 'Ignore'
    $showWarnings = $WarningPreference -ne 'SilentlyContinue' -and $WarningPreference -ne 'Ignore'
    $showErrors = $ErrorActionPreference -ne 'SilentlyContinue' -and $ErrorActionPreference -ne 'Ignore'

    $logger = New-Object Carbon.Xdt.PSHostUserInterfaceTransformationLogger $host.UI,$showVerbose,$showWarnings,$showErrors
    $xmlTransform = New-Object Microsoft.Web.XmlTransform.XmlTransformation $XdtPath,$logger
	
	$success = $xmlTransform.Apply($document)
	
	if($success)
	{
    	$document.Save($Destination)
	}
	
	$xmlTransform.Dispose()
	$document.Dispose()
}
