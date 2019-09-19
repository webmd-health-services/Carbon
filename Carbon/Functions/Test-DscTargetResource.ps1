
function Test-CDscTargetResource
{
    <#
    .SYNOPSIS
    Tests that all the properties on a resource and object are the same.

    .DESCRIPTION
    DSC expects a resource's `Test-TargetResource` function to return `$false` if an object needs to be updated. Usually, you compare the current state of a resource with the desired state, and return `$false` if anything doesn't match.

    This function takes in a hashtable of the current resource's state (what's returned by `Get-TargetResource`) and compares it to the desired state (the values passed to `Test-TargetResource`). If any property in the target resource is different than the desired resource, a list of stale resources is written to the verbose stream and `$false` is returned. 

    Here's a quick example:

        return Test-TargetResource -TargetResource (Get-TargetResource -Name 'fubar') -DesiredResource $PSBoundParameters -Target ('my resource ''fubar''')

    If you want to exclude properties from the evaluation, just remove them from the hashtable returned by `Get-TargetResource`:

        $resource = Get-TargetResource -Name 'fubar'
        $resource.Remove( 'PropertyThatDoesNotMatter' )
        return Test-TargetResource -TargetResource $resource -DesiredResource $PSBoundParameters -Target ('my resource ''fubar''')
    
    `Test-CDscTargetResource` is new in Carbon 2.0.

    .OUTPUTS
    System.Boolean.

    .EXAMPLE
    Test-TargetResource -TargetResource (Get-TargetResource -Name 'fubar') -DesiredResource $PSBoundParameters -Target ('my resource ''fubar''')

    Demonstrates how to test that all the properties on a DSC resource are the same was what's desired.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        # The current state of the resource.
        $TargetResource,

        [Parameter(Mandatory=$true)]
        [hashtable]
        # The desired state of the resource. Properties not in this hashtable are skipped. Usually you'll pass `PSBoundParameters` from your `Test-TargetResource` function.
        $DesiredResource,

        [Parameter(Mandatory=$true)]
        [string]
        # The a description of the target object being tested. Output in verbose messages.
        $Target
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $notEqualProperties = $TargetResource.Keys | 
                            Where-Object { $_ -ne 'Ensure' } |  
                            Where-Object { $DesiredResource.ContainsKey( $_ ) } |
                            Where-Object { 
                                $desiredObj = $DesiredResource[$_]
                                $targetObj = $TargetResource[$_]

                                if( $desiredobj -eq $null -or $targetObj -eq $null )
                                {
                                    return ($desiredObj -ne $targetObj)
                                }

                                if( -not $desiredObj.GetType().IsArray -or -not $targetObj.GetType().IsArray )
                                {
                                    return ($desiredObj -ne $targetObj)
                                }

                                if( $desiredObj.Length -ne $targetObj.Length )
                                {
                                    return $true
                                }

                                $desiredObj | Where-Object { $targetObj -notcontains $_ }
                            }

    if( $notEqualProperties )
    {
        Write-Verbose ('{0} has stale properties: ''{1}''' -f $Target,($notEqualProperties -join ''','''))
        return $false
    }

    return $true
}
