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

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:file = ''

    function Lock-File
    {
        param(
            $Seconds
        )

        Start-Job -ScriptBlock {
            $file = [IO.File]::Open($using:file, 'Open', 'Read', 'None')
            try
            {
                Start-Sleep -Seconds $using:Seconds
            }
            finally
            {
                $file.Close()
            }
        }

        $waitFor = New-TimeSpan -Seconds ($Seconds * 2)
        $timer = [Diagnostics.Stopwatch]::StartNew()
        do
        {
            Start-Sleep -Milliseconds 100
            Write-Debug -Message ('Waiting for hosts file to get locked.')
        }
        while ($timer.Elapsed -lt $waitFor -and (Get-Content -Path $script:file -ErrorAction SilentlyContinue))

        $Global:Error.Clear()
    }
}

Describe 'Read-CFile' {
    BeforeEach {
        $script:file = Join-Path -Path $TestDrive -ChildPath ([IO.Path]::GetRandomFileName())
        New-Item -Path $script:file -ItemType 'File'
        $script:file = Get-Item -Path $script:file | Select-Object -ExpandProperty 'FullName'
        $Global:Error.Clear()
    }

    It 'should read multiple lines' {
        @( 'a', 'b' ) | Set-Content -Path $script:file

        $contents = Read-CFile -Path $script:file
        $contents | Should -HaveCount 2
        $contents[0] | Should -Be 'a'
        $contents[1] | Should -Be 'b'
    }

    It 'should read one line' {
        'a' | Write-CFile -Path $script:file

        $contents = Read-CFile -Path $script:file
        $contents | Should -Be 'a'
    }

    It 'should read empty file' {
        Clear-Content -Path $script:file
        $contents = Read-CFile -Path $script:file
        ,$contents | Should -BeNullOrEmpty
    }

    It 'should read raw file' {
        @( 'a', 'b' ) | Set-Content -Path $script:file
        $content = Read-CFile -Path $script:file -Raw
        $content | Should -Be ("a{0}b{0}" -f [Environment]::NewLine)
    }

    It 'should wait while file is in use' {
        'b' | Set-Content -Path $script:file
        $job = Lock-File -Seconds 1

        try
        {
            # Simulate a full error buffer
            Read-CFile -Path $script:file | Should -Be 'b'
            $Global:Error | Should -BeNullOrEmpty
        }
        finally
        {
            $job | Wait-Job | Receive-Job | Write-Debug
        }
    }

    It 'should wait while file is in use and $Global:Error is full' {
        'b' | Set-Content -Path $script:file
        $job = Lock-File -Seconds 1

        try
        {
            # Simulate a full error buffer
            1..256 | ForEach-Object { Write-Error -Message $_ -ErrorAction SilentlyContinue }
            Read-CFile -Path $script:file | Should -Be 'b'
            $Global:Error | Should -HaveCount 256
        }
        finally
        {
            $job | Wait-Job | Receive-Job | Write-Debug
        }
    }
    return
    It 'should control how long to wait for file to be released and report final error' {
        'b' | Set-Content -Path $script:file
        $job = Lock-File -Seconds 1

        try
        {
            Read-CFile -Path $script:file -MaximumTries 1 -RetryDelayMilliseconds 100 -ErrorAction SilentlyContinue  | Should -BeNullOrEmpty
            Read-CFile -Path $script:file -MaximumTries 1 -RetryDelayMilliseconds 100 -Raw -ErrorAction SilentlyContinue| Should -BeNullOrEmpty
            $Global:Error | Should -HaveCount 2
            $Global:Error | Should -Match 'cannot access the file'
        }
        finally
        {
            $job | Wait-Job | Receive-Job | Write-Debug
        }
    }

    It 'should report errors with ErrorVariable parameter' {
        'b' | Set-Content -Path $script:file
        $job = Lock-File -Seconds 1
        try
        {
            $result = Read-CFile -Path $script:file -MaximumTries 1 -ErrorVariable 'cmdErrors' -ErrorAction SilentlyContinue
            ,$result | Should -BeNullOrEmpty
            ,$cmdErrors | Should -Not -BeNullOrEmpty
            $cmdErrors.Count | Should -BeGreaterThan 0
            $cmdErrors | Should -Match 'cannot access the file'

            $Global:Error.Clear()

            $result = Read-CFile -Path $script:file -MaximumTries 1 -Raw -ErrorVariable 'cmdErrors2' -ErrorAction SilentlyContinue
            ,$result | Should -BeNullOrEmpty
            ,$cmdErrors2 | Should -Not -BeNullOrEmpty
            $cmdErrors2.Count | Should -BeGreaterThan 0
            $cmdErrors2 | Should -Match 'cannot access the file'
        }
        finally
        {
            $job | Wait-Job | Receive-Job | Write-Debug
        }

    }
}