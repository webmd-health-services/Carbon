
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve)
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldDisplayHelp
{
    $expectedOutput = @"
SubInAcl version 5.2.3790.1180

USAGE
-----

Usage :
     SubInAcl [/option...] /object_type object_name [[/action[=parameter]...]



 /options    :
    /outputlog=FileName                 /errorlog=FileName
    /noverbose                          /verbose (default)
    /notestmode (default)               /testmode
    /alternatesamserver=SamServer       /offlinesam=FileName
    /stringreplaceonoutput=string1=string2
    /expandenvironmentsymbols (default) /noexpandenvironmentsymbols
    /statistic (default)                /nostatistic
    /dumpcachedsids=FileName            /separator=character
    /applyonly=[dacl,sacl,owner,group]
    /nocrossreparsepoint (default)      /crossreparsepoint

 /object_type :
    /service            /keyreg             /subkeyreg
    /file               /subdirectories[=directoriesonly|filesonly]
    /clustershare       /kernelobject       /metabase
    /printer            /onlyfile           /process
    /share              /samobject

 /action      :
    /display[=dacl|sacl|owner|primarygroup|sdsize|sddl] (default)
    /setowner=owner
    /replace=[DomainName\]OldAccount=[DomainName\]New_Account
    /accountmigration=[DomainName\]OldAccount=[DomainName\]New_Account
    /changedomain=OldDomainName=NewDomainName[=MappingFile[=Both]]
    /migratetodomain=SourceDomain=DestDomain=[MappingFile[=Both]]
    /findsid=[DomainName\]Account[=stop|continue]
    /suppresssid=[DomainName\]Account
    /confirm
    /ifchangecontinue
    /cleandeletedsidsfrom=DomainName[=dacl|sacl|owner|primarygroup|all]
    /testmode
    /accesscheck=[DomainName\]Username
    /setprimarygroup=[DomainName\]Group
    /grant=[DomainName\]Username[=Access]
    /deny=[DomainName\]Username[=Access]
    /sgrant=[DomainName\]Username[=Access]
    /sdeny=[DomainName\]Username[=Access]
    /sallowdeny==[DomainName\]Username[=Access]
    /revoke=[DomainName\]Username
    /perm
    /audit
    /compactsecuritydescriptor
    /pathexclude=pattern
    /objectexclude=pattern
    /sddl=sddl_string
    /objectcopysecurity=object_path
    /pathcopysecurity=path_container

Usage  : SubInAcl   [/option...] /playfile file_name

Usage  : SubInAcl   /help [keyword]
         SubInAcl   /help /full
    keyword can be :
    features  usage syntax sids  view_mode test_mode object_type
    domain_migration server_migration substitution_features editing_features
`t - or -
    any [/option] [/action] [/object_type]
"@
    $expectedOutput = $expectedOutput -replace "`r",""
    $output = Invoke-SubInAcl '/help'
    $outputString = ($output -join "`n").Trim()
    Assert-Equal $expectedOutput.Trim() $outputString
}

function Test-ShouldAcceptMultipleParameters
{
    $expectedOutput = "HelloWorldService - OpenService Error : 1060 The specified service does not exist as an installed service."
    
    $output = Invoke-SubInAcl /service HelloWorldService /display
    $outputString = ($output -join "`n").Trim()
    Assert-Equal $expectedOutput.Trim() $outputString    
   
}