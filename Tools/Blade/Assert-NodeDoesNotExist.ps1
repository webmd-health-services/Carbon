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

function Assert-NodeDoesNotExist
{
    <#
    .SYNOPSIS
    Asserts that a node doesn't exist in an XML document.

    .DESCRIPTION
    It's usually pretty easy in PowerShell to check if a node doesn't exist in an XML document: simply test if a property exists on that node.  If, however, that XML document has namespaces, you have to do extra setup with the XML document so that you can find the node.  This function does that work for you.

    .LINK
    Assert-NodeExists

    .LINK
    Test-NodeExists

    .EXAMPLE
    Assert-NodeDoesNotExist '<foo><bar><baz /></bar></foo>' '/foo/bar/biz'

    Demonstrates how to assert that an XML document doesn't contain a node.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [xml]
        # The XML document to check.
        $Xml,

        [Parameter(Mandatory=$true,Position=1)]
        [string]
        # The XPath expression for the node to check.
        $XPath,

        [Parameter(Position=2)]
        [string]
        # The short prefix for the document's default namespace, if any.
        $DefaultNamespacePrefix, 

        [Parameter(Position=3)]
        [string]
        # The message to describe the failure if the assertion fails.
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( Test-NodeExists $Xml $XPath $DefaultNamespacePrefix )
    {
        Fail "Found node with XPath '$XPath': $Message"
    }
}

