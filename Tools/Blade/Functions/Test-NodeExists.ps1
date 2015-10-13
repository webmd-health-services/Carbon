# Copyright 2012 - 2015 Aaron Jensen
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

function Test-NodeExists
{
    <#
    .SYNOPSIS
    Tests if a node exists in an XML document.

    .DESCRIPTION
    It's usually pretty easy in PowerShell to check if a node exists in an XML document: simply test if a property exists on that node.  If, however, that XML document has namespaces, you have to do extra setup with the XML document so that you can find the node.  This function does that work for you.

    .LINK
    Assert-NodeExists

    .LINK
    Assert-NodeDoesNotExist

    .EXAMPLE
    Test-NodeExists '<foo><bar><baz /></bar></foo>' '/foo/bar/baz'

    Returns `$true` if a node selected by `XPath` is found.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [xml]
        # The XML Document to check
        $Xml,

        [Parameter(Mandatory=$true,Position=1)]
        [string]
        # The XPath to use for the node whose existence to check.
        $XPath,

        [Parameter(Position=2)]
        [string]
        # The prefix of the XML document's default namespace.
        $DefaultNamespacePrefix
    )

    Set-StrictMode -Version 'Latest'

    $nsManager = New-Object 'System.Xml.XmlNamespaceManager' $xml.NameTable
    if( $xml.DocumentElement.NamespaceURI -ne '' -and $xml.DocumentElement.Prefix -eq '' )
    {
        Write-Debug -Message "XML document has a default namespace, setting prefix to '$defaultNamespacePrefix'."
        $nsManager.AddNamespace($defaultNamespacePrefix, $xml.DocumentElement.NamespaceURI)
    }
    
    $node = $xml.SelectSingleNode( $xpath, $nsManager )
    return ($node -ne $null)
}

