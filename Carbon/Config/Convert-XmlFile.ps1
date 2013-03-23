function Convert-XmlFile
{
    <#
    .SYNOPSIS
    Applies a xdt transformation to the xml file provided
    
	Convert-XmlFile -Path <string> [-XdtPath <string> | -Transform <string>] [-Destination <string>] [-SkipIdempotencyCheck]
	
	
    .DESCRIPTION
	Xdt transformations allow complex edits to be made to xml files.
		http://msdn.microsoft.com/en-us/library/dd465326.aspx
	
    .EXAMPLE
    > Convert-XmlFile -Path ".\web.config" -XdtPath ".\web.debug.config"
    
    Applies the Xdt transformation to the web.config and updates the web.config file
    
    #>
    [CmdletBinding(SupportsShouldProcess=$true, DefaultParameterSetName='All')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path of the file convert
        $Path,

        [string]
        # The path to the xdt file to use
        $XdtPath,
        
		[string]
        # The path to the xdt file to use
        $Transform,
        
		[string]
        # The destination of the converted file
        $Destination,
		
		[switch]
		$SkipIdempotencyCheck
    )
    
	if ([Environment]::Version.Major -eq 2)
	{
		Write-Error ("Convert-XmlFile is only available on systems running .Net 4.0 or higher. Please run Enable-DotNet4Access -Console and restart your PowerShell session.")
		return
	}
	try 
	{
		Add-Type -Path (Join-Path $PSScriptRoot "bin\Microsoft.Web.XmlTransform.dll")
		Add-Type -Path (Join-Path $PSScriptRoot "bin\Carbon.Transforms.dll")
    } 
	catch [Reflection.ReflectionTypeLoadException] { 
		Write-Host -foreground yellow "LoadException"
		$Error | format-list -force
	}
	
	if(!(Test-Path $Path))
	{
		Write-Error ("Path '{0}' not found." -f $Path)
        return
	}
	
	if ($Transform)
	{
		# write transform to temp path
		$XdtPath = [IO.Path]::GetTempFileName()
		$Transform > $XdtPath
	}
	
	if($XdtPath -and !(Test-Path $XdtPath))
	{
		Write-Error ("XdtPath '{0}' not found." -f $Path)
        return
	}
	
	$document = New-Object Microsoft.Web.XmlTransform.XmlTransformableDocument
	$document.PreserveWhitespace = $true
	$document.Load($Path)
	
	if($XdtPath)
	{
		Write-Debug ("Using file transformation - $XsdPath")
		$xmlTransform = New-Object Microsoft.Web.XmlTransform.XmlTransformation($XdtPath)
	}
	
	$success = $xmlTransform.Apply($document)
	
	if($success)
	{
		if (!$SkipIdempotencyCheck)
		{
			$documentIdempotent = New-Object Microsoft.Web.XmlTransform.XmlTransformableDocument
			$documentIdempotent.PreserveWhitespace = $true
			$documentIdempotent.Load($Path)
		
			# check idempotent
			$idempotentSuccess = $xmlTransform.Apply($documentIdempotent)
			if (!$idempotentSuccess)
			{
				Write-Error ("Idempotent check failed. First transformation")
				return
			}
			
			$idempotentSuccess = $xmlTransform.Apply($documentIdempotent)
			if (!$idempotentSuccess)
			{
				Write-Error ("Idempotent check failed. Second transformation")
				return
			}

			$diff = Compare-Object ($document.SelectNodes("//*") | Select-Object -Expand Name) ($documentIdempotent.SelectNodes("//*") | Select-Object -Expand Name)
		
			if ($diff)
			{
				$documentIdempotent.Save($Destination + ".failed")
				Write-Error ("Idempotent check failed. Differences were detected")
				return
			}
			
			$documentIdempotent.Dispose()
		}

		if ($Destination)
		{
			$document.Save($Destination)
		}
		else
		{
			# overwrite
			$document.Save($Path)
		}
	}
	else
	{
		Write-Error ("Transformation failed")
	}
	
	$xmlTransform.Dispose()
	$document.Dispose()   
}


