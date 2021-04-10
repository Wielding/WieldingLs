Import-Module Pester
Remove-Module WieldingLs -ErrorAction SilentlyContinue
Import-Module ./WieldingLs.psm1        

Context -Name "WieldingLsTests" -Fixture {

    BeforeEach {
        Remove-Module WieldingLs -ErrorAction SilentlyContinue
        Import-Module ./WieldingLs.psm1        
    }

    Describe 'GetFileColor-ReparsePointFolder' {

        $GdcTheme.FileAttributesColors[([System.IO.FileAttributes]::Directory + [System.IO.FileAttributes]::ReparsePoint)] = "!RD"

        $file = Get-ChildItem ~/OneDrive
        
        $style = Get-FileColor $file[0]

        $style | Should -Be "RD"
    }
}