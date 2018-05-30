
function Write-WhiskeyCommand
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Whiskey.Context]
        $Context,

        [string]
        $Path,

        [string[]]
        $ArgumentList
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    $logArgumentList = Invoke-Command {
                                          if( $Path -match '\ ' )
                                          {
                                              '&'
                                          }
                                          $Path
                                          $ArgumentList
                                      } |
                                      ForEach-Object { 
                                          if( $_ -match '\ ' )
                                          {
                                              '"{0}"' -f $_.Trim('"',"'")
                                          }
                                          else
                                          {
                                              $_
                                          }
                                      }

    Write-WhiskeyInfo -Context $TaskContext -Message ($logArgumentList -join ' ')
    Write-WhiskeyVerbose -Context $TaskContext -Message $path
    $argumentPrefix = ' ' * ($path.Length + 2)
    foreach( $argument in $ArgumentList )
    {
        Write-WhiskeyVerbose -Context $TaskContext -Message ('{0}{1}' -f $argumentPrefix,$argument)
    }
}
