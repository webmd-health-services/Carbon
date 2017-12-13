    Set-StrictMode -version 'latest'
    
    function Write-CommandOutput
    {
        param(
            [Parameter(ValueFromPipeline=$true)]
            [string]
            $InputObject,

            [Parameter(Mandatory=$true)]
            [string]
            $Description
        )

        process
        {
            Set-StrictMode -Version 'Latest'
            Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

            if( $InputObject -match '^WARNING\b' )
            {
                $InputObject | Write-Warning 
            }
            elseif( $InputObject -match '^ERROR\b' )
            {
                $InputObject | Write-Error
            }
            else
            {
                $InputObject | ForEach-Object { Write-Verbose -Message ('[{0}] {1}' -f $Description,$InputObject) }
            }
        }
    }