
filter Add-IisServerManagerMember
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        # The object on which the server manager members will be added.
        $InputObject,
        
        [Parameter(Mandatory=$true)]
        [Microsoft.Web.Administration.ServerManager]
        # The server manager object to use as the basis for the new members.
        $ServerManager,
        
        [Switch]
        # If set, will return the input object.
        $PassThru
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $InputObject | 
        Add-Member -MemberType NoteProperty -Name 'ServerManager' -Value $ServerManager -PassThru |
        Add-Member -MemberType ScriptMethod -Name 'CommitChanges' -Value { $this.ServerManager.CommitChanges() }
        
    if( $PassThru )
    {
        return $InputObject
    }
}

