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

& (Join-Path -Path $PSScriptRoot 'Import-CarbonForTest.ps1' -Resolve)

Describe 'Write-File' {

    $file = ''
    
    BeforeEach {
        $Global:Error.Clear()
        $file = Join-Path -Path 'TestDrive:' -ChildPath ([IO.Path]::GetRandomFileName())
        New-Item -Path $file -ItemType 'File'
        $file = Get-Item -Path $file | Select-Object -ExpandProperty 'FullName'
    }
    
    It 'should write multiple lines to a file using a pipeline' {
        @( 'a', 'b' ) | Write-File -Path $file

        $contents = [IO.File]::ReadAllText($file)
        $contents | Should Be ("a{0}b{0}" -f [Environment]::NewLine) 
    }
    
    It 'should write one line to a file using a pipeline' {
        'a' | Write-File -Path $file

        $contents = [IO.File]::ReadAllText($file)
        $contents | Should Be ("a{0}" -f [Environment]::NewLine) 
    }
    
    It 'should write nothing to a file using a pipeline' {
        'a' | Set-Content -Path $file

        @() | Write-File -Path $file

        $contents = [IO.File]::ReadAllText($file)
        $contents | Should BeNullOrEmpty
    }
    
    It 'should write an empty string to a file using a parameter' {
        '' | Write-File -Path $file

        $contents = [IO.File]::ReadAllText($file)
        $contents | Should Be ("{0}" -f [Environment]::NewLine) 
    }
    
    It 'should write multiple lines to a file using a parameter' {
        Write-File -Path $file -InputObject @( 'a', 'b' )

        $contents = [IO.File]::ReadAllText($file)
        $contents | Should Be ("a{0}b{0}" -f [Environment]::NewLine) 
    }
    
    It 'should write one line to a file using a parameter' {
        Write-File -Path $file -InputObject 'a' 

        $contents = [IO.File]::ReadAllText($file)
        $contents | Should Be ("a{0}" -f [Environment]::NewLine) 
    }
    
    It 'should write an empty string to a file using a parameter' {
        Write-File -Path $file -InputObject '' 

        $contents = [IO.File]::ReadAllText($file)
        $contents | Should Be ("{0}" -f [Environment]::NewLine) 
    }
    
    It 'should write nothing to a file using a parameter' {
        'a' | Set-Content -Path $file

        Write-File -Path $file -InputObject @()

        $contents = [IO.File]::ReadAllText($file)
        $contents | Should BeNullOrEmpty
    }
    
    It 'should support what if' {
        'a' | Set-Content -Path $file
        'b' | Write-File -Path $file -WhatIf
        [IO.File]::ReadAllText($file) | Should Be ("a{0}" -f [Environment]::NewLine)
    }
    
    It 'should wait while file is in use' {
        'b' | Set-Content -Path $file
        $job = Start-Job -ScriptBlock {
                                            
                                            $file = [IO.File]::Open($using:file, 'Open', 'Write', 'None')
                                            try
                                            {
                                                Start-Sleep -Seconds 1
                                            }
                                            finally
                                            {
                                                $file.Close()
                                            }
                                       }
        try
        {
            # Wait for file to get locked
            do
            {
                Start-Sleep -Milliseconds 100
                Write-Debug -Message ('Waiting for hosts file to get locked.')
            }
            while( (Get-Content -Path $file -ErrorAction SilentlyContinue ) )

            $Global:Error.Clear()

            'a' | Write-File -Path $file
            $Global:Error.Count | Should Be 0
        }
        finally
        {
            $job | Wait-Job | Receive-Job | Write-Debug
        }

        [IO.File]::ReadAllText($file) | Should Be ("a{0}" -f [Environment]::NewLine)
    }
  
    It 'should control how long to wait for file to be released and report final error' {
        'b' | Set-Content -Path $file
        $job = Start-Job -ScriptBlock {
                                            $file = [IO.File]::Open($using:file, 'Open', 'Write', 'None')
                                            try
                                            {
                                                Start-Sleep -Seconds 1
                                            }
                                            finally
                                            {
                                                $file.Close()
                                            }
                                       }
        try
        {
            # Wait for file to get locked
            do
            {
                Start-Sleep -Milliseconds 100
                Write-Debug -Message ('Waiting for hosts file to get locked.')
            }
            while( (Get-Content -Path $file -ErrorAction SilentlyContinue ) )

            $Global:Error.Clear()

            'a' | Write-File -Path $file -MaximumTries 1 -RetryDelayMilliseconds 100 -ErrorAction SilentlyContinue
            $Global:Error.Count | Should Be 1
            $Global:Error | Should Match 'cannot access the file'
        }
        finally
        {
            $job | Wait-Job | Receive-Job | Write-Debug
        }

        [IO.File]::ReadAllText($file) | Should Be ("b{0}" -f [Environment]::NewLine)
    }

}