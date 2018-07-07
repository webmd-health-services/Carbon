    
function Import-WhiskeyTask
{
    [Whiskey.Task("LoadTask")]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Whiskey.Context]
        $TaskContext,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $TaskParameter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $module = Get-Module -Name 'Whiskey'
    $paths = Resolve-WhiskeyTaskPath -TaskContext $TaskContext -Path $TaskParameter['Path'] -PropertyName 'Path'
    foreach( $path in $paths )
    {
        if( $TaskContext.TaskPaths | Where-Object { $_.FullName -eq $path } )
        {
            Write-WhiskeyVerbose -Context $TaskContext -Message ('Already loaded tasks from file "{0}".' -f $path) -Verbose
            continue
        }

        $knownTasks = @{}
        Get-WhiskeyTask | ForEach-Object { $knownTasks[$_.Name] = $_ }
        # We do this in a background script block to ensure the function is scoped correctly. If it isn't, it 
        # won't be available outside the script block. If it is, it will be visible after the script block completes.
        & {
            . $path
        }
        $newTasks = Get-WhiskeyTask | Where-Object { -not $knownTasks.ContainsKey($_.Name) } 
        if( -not $newTasks )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('File "{0}" contains no Whiskey tasks. Make sure:
 
* the file contains a function
* the function is scoped correctly (e.g. `function script:MyTask`)
* the function has a `[Whiskey.Task("MyTask")]` attribute that declares the task''s name
* a task with the same name hasn''t already been loaded
 
See about_Whiskey_Writing_Tasks for more information.' -f $path)
        }
        
        Write-WhiskeyInfo -Context $TaskContext -Message ($path)
        foreach( $task in $newTasks )
        {
            Write-WhiskeyInfo -Context $TaskContext -Message $task.Name -Indent 1
        }
        $TaskContext.TaskPaths.Add((Get-Item -Path $path))
    }
}
