
function Resolve-WhiskeyVariable
{
    <#
    .SYNOPSIS
    Replaces any variables in a string to their values.

    .DESCRIPTION
    The `Resolve-WhiskeyVariable` function replaces any variables in strings, arrays, or hashtables with their values. Variables have the format `$(VARIABLE_NAME)`. Variables are expanded in each item of an array. Variables are expanded in each value of a hashtable. If an array or hashtable contains an array or hashtable, variables are expanded in those objects as well, i.e. `Resolve-WhiskeyVariable` recursivelye expands variables in all arrays and hashtables.
    
    You can add variables to replace via the `Add-WhiskeyVariable` function. If a variable doesn't exist, environment variables are used. If a variable has the same name as an environment variable, the variable value is used instead of the environment variable's value. If no variable or environment variable is found, `Resolve-WhiskeyVariable` will write an error and return the origin string.

    Well-known Whiskey variables you can use are:

    * `WHISKEY_MSBUILD_CONFIGURATION`: The configuration used when building with MSBuild. `Debug` when run by a developer. `Release` otherwise.
    * `WHISKEY_ENVIRONMENT`: The environment.
    * `WHISKEY_BUILD_ROOT`: The directory of the `whiskey.yml` file that controls this build.
    * `WHISKEY_OUTPUT_DIRECTORY`: The directory where build output is put.
    * `WHISKEY_PIPELINE_NAME`: The name of the pipeline being run. `Build` when a build is running. `Publish` when publishing.
    * `WHISKEY_TASK_NAME`: The name of the current task.
    * `WHISKEY_SEMVER2`: The semantic version of the current build in the Semantic Versioning 2.0.0 format.
    * `WHISKEY_SEMVER2_NO_BUILD_METADATA`: The semantic version of the curren build with no build metadata.
    * `WHISKEY_VERSION`: The version number of the build, with no prerelease or build metadata.
    * `WHISKEY_SEMVER1`: The semantic version of the current build in the Semantic Versioning 1.0.0 format.

    The following additional variables are available, but they only have values when running under a build server.

    * `WHISKEY_BUILD_NUMBER`: The current build number.
    * `WHISKEY_BUILD_ID`: The unique ID that distinguishes this build from all others.
    * `WHISKEY_BUILD_SERVER_NAME`: The name of the build server running the build.
    * `WHISKEY_BUILD_URI`: The URI to this build's build report.
    * `WHISKEY_JOB_URI`: The URI to the jobs that is running this build.
    * `WHISKEY_SCM_BRANCH`: The branch the build is happening on.
    * `WHISKEY_SCM_COMMIT_ID`: The commit ID that is being built.
    * `WHISKEY_SCM_URI`: The URI to the repository where the source code being built came from.

    .EXAMPLE
    '$(COMPUTERNAME)' | Resolve-WhiskeyVariable

    Demonstrates that you can use environment variable as variables. In this case, `Resolve-WhiskeyVariable` would return the name of the current computer.

    .EXAMPLE
    @( '$(VARIABLE)', 4, @{ 'Key' = '$(VARIABLE') } ) | Resolve-WhiskeyVariable

    Demonstrates how to replace all the variables in an array. Any value of the array that isn't a string is ignored. Any hashtable in the array will have any variables in its values replaced. In this example, if the value of `VARIABLE` is 'Whiskey`, `Resolve-WhiskeyVariable` would return:

        @(
            'Whiskey',
            4,
            @{
                Key = 'Whiskey'
            }
        )

    .EXAMPLE
    @{ 'Key' = '$(Variable)'; 'Array' = @( '$(VARIABLE)', 4 ) 'Integer' = 4; } | Resolve-WhiskeyVariable

    Demonstrates that `Resolve-WhiskeyVariable` searches hashtable values and replaces any variables in any strings it finds. If the value of `VARIABLE` is set to `Whiskey`, then the code in this example would return:

        @{
            'Key' = 'Whiskey';
            'Array' = @(
                            'Whiskey',
                            4
                      );
            'Integer' = 4;
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [AllowNull()]
        [object]
        # The object on which to perform variable replacement/substitution. If the value is a string, all variables in the string are replaced with their values.
        #
        # If the value is an array, variable expansion is done on each item in the array. 
        #
        # If the value is a hashtable, variable replcement is done on each value of the hashtable. 
        #
        # Variable expansion is performed on any arrays and hashtables found in other arrays and hashtables, i.e. arrays and hashtables are searched recursively.
        $InputObject,

        [Parameter(Mandatory=$true)]
        [object]
        # The context of the current build. Necessary to lookup any variables.
        $Context
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $version = $Context.Version
        $buildInfo = $Context.BuildMetadata;
        $wellKnownVariables = @{
                                    'WHISKEY_MSBUILD_CONFIGURATION' = (Get-WhiskeyMSBuildConfiguration -Context $Context);
                                    'WHISKEY_ENVIRONMENT' = $Context.Environment;
                                    'WHISKEY_BUILD_ROOT' = $Context.BuildRoot;
                                    'WHISKEY_OUTPUT_DIRECTORY' = $Context.OutputDirectory;
                                    'WHISKEY_PIPELINE_NAME' = $Context.PipelineName;
                                    'WHISKEY_TASK_NAME' = $Context.TaskName;
                                    'WHISKEY_SEMVER2' = $version.SemVer2;
                                    'WHISKEY_SEMVER2_NO_BUILD_METADATA' = $version.SemVer2NoBuildMetadata;
                                    'WHISKEY_VERSION' = $version.Version;
                                    'WHISKEY_SEMVER1' = $version.SemVer1;
                                    'WHISKEY_BUILD_NUMBER' = $buildInfo.BuildNumber;
                                    'WHISKEY_BUILD_ID' = $buildInfo.BuildID;
                                    'WHISKEY_BUILD_SERVER_NAME' = $buildInfo.BuildServerName;
                                    'WHISKEY_BUILD_URI' = $buildInfo.BuildUri;
                                    'WHISKEY_JOB_URI' = $buildInfo.JobUri;
                                    'WHISKEY_SCM_BRANCH' = $buildInfo.ScmBranch;
                                    'WHISKEY_SCM_COMMIT_ID' = $buildInfo.ScmCommitID;
                                    'WHISKEY_SCM_URI' = $buildInfo.ScmUri;
                               }
    }

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if( $InputObject -eq $null )
        {
            return $InputObject
        }

        if( (Get-Member -Name 'Keys' -InputObject $InputObject) )
        {
            $newValues = @{ }
            $toRemove = New-Object 'Collections.Generic.List[string]'
            # Can't modify a collection while enumerating it.
            foreach( $key in $InputObject.Keys )
            {
                $newKey = $key | Resolve-WhiskeyVariable -Context $Context  
                if( $newKey -ne $key )
                {
                    $toRemove.Add($key)
                }
                $newValues[$newKey] = Resolve-WhiskeyVariable -Context $Context -InputObject $InputObject[$key]
            }
            foreach( $key in $newValues.Keys )
            {
                $InputObject[$key] = $newValues[$key]
            }
            $toRemove | ForEach-Object { $InputObject.Remove($_) }
            return $InputObject
        }

        if( (Get-Member -Name 'Count' -InputObject $InputObject) )
        {
            for( $idx = 0; $idx -lt $InputObject.Count; ++$idx )
            {
                $InputObject[$idx] = Resolve-WhiskeyVariable -Context $Context -InputObject $InputObject[$idx]
            }
            return ,$InputObject
        }

        $startAt = 0
        $haystack = $InputObject.ToString()
        do
        {
            $needleStart = $haystack.IndexOf('$(',$startAt)
            if( $needleStart -lt 0 )
            {
                break
            }
            elseif( $needleStart -gt 0 )
            {
                if( $haystack[$needleStart - 1] -eq '$' )
                {
                    $haystack = $haystack.Remove($needleStart - 1, 1)
                    $startAt = $needleStart
                    continue
                }
            }

            $needleEnd = $haystack.IndexOf(')', $needleStart)
            $variableName = $haystack.Substring($needleStart + 2, $needleEnd - $needleStart - 2)

            $envVarPath = 'env:{0}' -f $variableName
            if( $Context.Variables.ContainsKey($variableName) )
            {
                $value = $Context.Variables[$variableName]
            }
            elseif( $wellKnownVariables.ContainsKey($variableName) )
            {
                $value = $wellKnownVariables[$variableName]
            }
            elseif( (Test-Path -Path $envVarPath) )
            {
                $value = (Get-Item -Path $envVarPath).Value
            }
            else
            {
                Write-Error -Message ('Variable ''{0}'' does not exist. We were trying to replace it in the string ''{1}''. You can:
                
* Use the `Add-WhiskeyVariable` function to add a variable named ''{0}'', e.g. Add-WhiskeyVariable -Context $context -Name ''{0}'' -Value VALUE.
* Create an environment variable named ''{0}''.
* Prevent variable expansion by escaping the variable with a backtick or backslash, e.g. `$({0}) or \$({0}).
* Remove the variable from the string.
  ' -f $variableName,$InputObject) -ErrorAction $ErrorActionPreference
                return $InputObject
            }

            if( $value -eq $null )
            {
                $value = ''
            }

            $haystack = $haystack.Remove($needleStart,$needleEnd - $needleStart + 1)
            $haystack = $haystack.Insert($needleStart,$value)
            # No need to keep searching where we've already looked.
            $startAt = $needleStart
        }
        while( $true )

        return $haystack
    }
}
