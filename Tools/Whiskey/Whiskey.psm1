
$events = @{ }

$type = [AppDomain]::CurrentDomain.GetAssemblies() | ForEach-Object { $_.GetType('Whiskey.TaskAttribute') } | Select-Object -First 1

if( -not $type )
{
    Add-Type -TypeDefinition @"

namespace Whiskey {

    public sealed class TaskAttribute : System.Attribute {

        public TaskAttribute(string name)
        {
            Name = name;
        }

        public string CommandName { get; set; }

        public string Name { get; private set; }

        public bool SupportsClean { get; set; }

        public bool SupportsInitialize { get; set; }
    }

}

"@ -ErrorAction Ignore
}

$attr = New-Object -TypeName 'Whiskey.TaskAttribute' -ArgumentList 'Whiskey' -ErrorAction Ignore
if( -not ($attr | Get-Member 'SupportsClean') )
{
    Write-Error -Message ('You''ve got an old version of Whiskey loaded. Please open a new PowerShell session.') -ErrorAction Stop
}


Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Functions'),(Join-Path -Path $PSScriptRoot -ChildPath 'Tasks') -Filter '*.ps1' |
    ForEach-Object { . $_.FullName }
