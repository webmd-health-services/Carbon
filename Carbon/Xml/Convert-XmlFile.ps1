# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
            <!-- You can also use the "assembly" attribute (PowerShell v3 
                 *only*).  In PowerShell v2, you can only use the `path` 
                 attribute.
                 
                 All classes in `namespace` that inherit from the XDT 
                 `Transform` class are loaded. -->
            <xdt:Import path="C:\Projects\Carbon\Lib\ExtraTransforms.dll"
                        namespace="ExtraTransforms" />
            <!-- ...snip... -->
        </root>
   
    You also have to pass the path to your custom transformation assembly as a value to the `TransformAssemblyPath` parameter. That's it! (Note: Carbon does *not* ship with any extra transformations.)
    
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

    .EXAMPLE
    Convert-XmlFile -Path ".\web.config" -XdtPath ".\web.debug.config" -Destination '\\webserver\wwwroot\web.config' -TransformAssemblyPath C:\Projects\CustomTransforms.dll
    
    Shows how to reference a custom transformation assembly.  It should also be loaded in your XDT file via the `xdt:Import`.
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
        $Destination,
        
        [string[]]
        # List of assemblies to load which contain custom transforms.
        $TransformAssemblyPath = @(),

        [Switch]
        # Overwrite the destination file if it exists.
        $Force
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
    $TransformAssemblyPath = $TransformAssemblyPath | ForEach-Object { Resolve-FullPath -path $_ }
    if( $TransformAssemblyPath )
    {
        $badPaths = $TransformAssemblyPath | Where-Object { -not (Test-Path -Path $_ -PathType Leaf) }
        if( $badPaths )
        {
            $errorMsg = "TransformAssemblyPath not found:`n * {0}" -f ($badPaths -join "`n * ")
            Write-Error -Message $errorMsg -Category ObjectNotFound
            return
        }
    }
    
    if( $Path -eq $Destination )
    {
        $errorMsg = 'Can''t transform Path {0} onto Destination {1}: Path is the same as Destination. XDT is designed to transform an XML file from a known state to a new XML file. Please supply a new, unique path for the Destination XML file.' -f `
                        $Path,$Destination
        Write-Error -Message $errorMsg -Category InvalidOperation -RecommendedAction 'Set Destination parameter to a unique path.'
        return
    }

    if( -not $Force -and (Test-Path -Path $Destination -PathType Leaf) )
    {
        $errorMsg = 'Can''t transform ''{0}'': Destination ''{1}'' exists. Use the -Force switch to overwrite.' -f $Path,$Destination
        Write-Error $errorMsg -Category InvalidOperation -RecommendedAction 'Use the -Force switch to overwrite.'
        return
    }
    
    
    $scriptBlock = {
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
            $Destination,
            
            [Parameter(Position=4)]
            [string[]]
            $TransformAssemblyPath
        )
        
        Add-Type -Path (Join-Path $CarbonBinDir "Microsoft.Web.XmlTransform.dll")
        Add-Type -Path (Join-Path $CarbonBinDir "Carbon.Xdt.dll")
        if( $TransformAssemblyPath )
        {
            $TransformAssemblyPath | ForEach-Object { Add-Type -Path $_ }
        }
                
        function Convert-XmlFile
        {
            [CmdletBinding()]
            param(
                [string]
                $Path,

                [string]
                $XdtPath,

                [string]
                $Destination
            )

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
        
        $PsBoundParameters.Remove( 'CarbonBinDir' )
        $PSBoundParameters.Remove( 'TransformAssemblyPath' )
        Convert-XmlFile @PSBoundParameters
    }

    try
    {
        if( $PSCmdlet.ShouldProcess( $Path, ('transform with {0} -> {1}' -f $xdtPathForShouldProcess,$Destination) ) )
        {
            $argumentList = $CarbonBinDir,$Path,$XdtPath,$Destination,$TransformAssemblyPath
            if( $PSVersionTable.CLRVersion.Major -ge 4 )
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

