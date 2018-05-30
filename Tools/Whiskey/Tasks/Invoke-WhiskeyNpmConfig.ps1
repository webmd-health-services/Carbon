
function Invoke-WhiskeyNpmConfig
{
    <#
    .SYNOPSIS
    Runs the `npm config` command to set global-level, user-level, or project-level NPM configuration.

    .DESCRIPTION
    The `NpmConfig` task runs the `npm config` command to set NPM configuration. By default, it sets configuration at the project level (i.e. in a .npmrc file in the current directory). To set the configuration at the user-level, set the `Scope` property to `User`. To set the configuration globally, set the `Scope` property to `Global`.

    Set the `Configuration` property to key/value pairs. The keys should be the name of the configuration setting; the value should be its value. For example,

        Build:
        - NpmConfig:
            Configuration:
                registry: https://registry.npmjs.org
                email: buildmaster@example.com
     
    # Properties

    * `Configuration` (*mandatory*): the key/value pairs to set.
    * `Scope`: the level at which the configuration is set. By default (i.e. if this property is missing), the configuration is set at the project level, in an .npmrc file in the current directory. Allowed value are `Project`, `User`, or `Global` to set the configuration in the project, user, or global  NPM configuration files, respectively.
    * `WorkingDirectory`: the directory in which to run the `npm config` command. The default is the directory of your whiskey.yml file.

    # Examples

    ## Example 1

        Build:
        - NpmConfig:
            Configuration:
                registry: https://registry.npmjs.org
                email: buildmaster@example.com

    Will create a .npmrc file in the current directory that looks like this:

        registry=https://registry.npmjs.org
        email=buildmaster@example.com
        
    ## Example 2

        Build:
        - NpmConfig:
            Configuration:
                registry: https://registry.npmjs.org
                email: buildmaster@example.com
            Scope: User

    Will create a .npmrc file in the user's home directory that looks like this (assuming the user's .npmrc file doesn't exist):

        registry=https://registry.npmjs.org
        email=buildmaster@example.com
    #>
    [Whiskey.Task('NpmConfig')]
    [Whiskey.RequiresTool('Node','NodePath',VersionParameterName='NodeVersion')]
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

    $configuration = $TaskParameter['Configuration']
    if( -not $configuration )
    {
        Write-Warning -Message ('Your NpmConfig task isn''t doing anything. Its Configuration property is missing. Please update the NpmConfig task in your whiskey.yml file so that it is actually setting configuration, e.g.

    Build:
    - NpmConfig:
        Configuration:
            key1: value1
            key2: value2
            ')
        return
    }

    if( -not ($configuration | Get-Member -Name 'Keys') )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Configuration property is invalid. It must have only key/value pairs, e.g.
    
    Build:
    - NpmConfig:
        Configuration:
            key1: value1
            key2: value2
     ')
    }

    $scope = $TaskParameter['Scope']
    if( $scope )
    {
        if( @('Project', 'User', 'Global') -notcontains $scope )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Scope property ''{0}'' is invalid. Allowed values are `Project`, `User`, `Global` to set configuration at the project, user, or global level. You may also remove the `Scope` property to set configuration at the project level (i.e. in the current directory).' -f $scope)
        }
    }

    foreach( $key in $TaskParameter['Configuration'].Keys )
    {
        $argumentList = & {
                                'set'
                                $key
                                $configuration[$key]
                                if( $scope -eq 'User' )
                                {
                                }
                                elseif( $scope -eq 'Global' )
                                {
                                    '-g'
                                }
                                else
                                {
                                    '-userconfig'
                                    '.npmrc'
                                }
                        }

        Invoke-WhiskeyNpmCommand -Name 'config' -ArgumentList $argumentList -NodePath $TaskParameter['NodePath'] -ForDeveloper:$TaskContext.ByDeveloper
    }
    
}