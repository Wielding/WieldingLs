Import-Module WieldingAnsi

enum DisplayFormat {
    Long;
    Short;
}

enum SortProperty {
    Name;
    Attributes;
    LastWriteTime;
    Length;    
}

class GDCOptions {
    [string]$Path
    [string]$SortProperty
    [bool]$ShowHeader
    [bool]$ShowTotal
    [bool]$ShowColor
    [bool]$ShowHidden
    [bool]$ShowSystem
    [DisplayFormat]$Format
    [int]$Width
    [int]$MaxNameLength
}

class Style {
    [string]$Codes
}

class FileItem {
    [object]$File
    [string]$Style
    [string]$AdjustedName
}

class GdcTheme {
    [string]$SourceCodeColor
    $SourceCodeExtensions = @()
    [string]$DataFileColor
    $DataFileExtensions = @()
    [string]$LogFileColor
    $LogFileExtensions = @()
    [string]$DocumentFileColor
    $DocumentFileExtensions = @()
    [string]$ExecutableFileColor
    $ExecutableFileExtensions = @()
    [string]$CompressedFileColor
    $CompressedFileExtensions = @()
    $FileAttributes = @()
    $FileAttributesColors =  @{}
    [string]$HiddenFileColor
    [string]$HiddenFolderColor
    [string]$NakedFileColor
    [string]$DefaultFileColor
    $ExtensionColors = @{}
    [string]$DefaultDisplayFormat
    [string]$TruncationIndicator
}


$GdcTheme = New-Object -TypeName GdcTheme

$GdcTheme.SourceCodeColor = "{:F82:}"
$GdcTheme.SourceCodeExtensions = @(
    ".ahk",
    ".awk",
    ".c", ".h",
    ".cc", ".cpp", ".cxx", ".c++", ".hh", ".hpp", ".hxx", ".h++",
    ".cs",
    ".go",
    ".groovy",
    ".html", ".htm", ".hta", ".css", ".scss", ".sass",
    ".java",
    ".js", ".mjs", ".ts", ".tsx"
    ".pl", ".pm", ".t", ".pod",
    ".php", ".phtml", ".php3", ".php4", ".php5", ".php7", ".phps", ".php-s", ".pht",
    ".pp", ".pas", ".inc",
    ".psm1", ".ps1xml", ".psc1", ".psd1", ".pssc", ".cdxml",
    ".py", ".pyx", ".pyc", ".pyd", ".pyo", ".pyw", ".pyz",
    ".r", ".RData", ".rds", ".rda",
    ".rb"
    ".rs", ".rlib",
    ".scala", ".sc",
    ".scm", ".ss",
    ".swift",
    ".sql",
    ".vbs", ".vbe", ".wsf", ".wsc", ".asp"
)

$GdcTheme.DataFileColor = "{:F14:}"
$GdcTheme.DataFileExtensions = @(
    ".csv",
    ".dat",
    ".dxf",
    ".geojson"
    ".gpx",
    ".json",
    ".kml",    
    ".shp",    
    ".xml"
)

$GdcTheme.LogFileColor = "{:F9:}"
$GdcTheme.LogFileExtensions = @(
    ".log"
)

$GdcTheme.DocumentFileColor = "{:F12:}"
$GdcTheme.DocumentFileExtensions = @(
    ".doc",
    ".docx",
    ".md",
    ".xls"
)    

$GdcTheme.ExecutableFileColor = "{:F2:}"
$GdcTheme.ExecutableFileExtensions = @(
    ".exe",
    ".bat",
    ".ps1",
    ".sh"
)    

$GdcTheme.CompressedFileColor = "{:F129:}"
$GdcTheme.CompressedFileExtensions = @(
    ".zip",
    ".tz",
    ".gz",
    ".7z",
    ".deb",
    ".rpm"
)

$GdcTheme.FileAttributes = [System.IO.FileAttributes].GetEnumNames()

$GdcTheme.FileAttributesColors = @{
    Directory    = "{:F11:}"
    ReparsePoint = "{:F0:}{:B11:}"
}

$GdcTheme.HiddenFileColor = "{:F240:}"
$GdcTheme.HiddenFolderColor = "{:F136:}"
$GdcTheme.NakedFileColor = "{:F28:}"
$GdcTheme.DefaultFileColor = "{:R:}"
$GdcTheme.TruncationIndicator = "{:F15:}...{:R:}"
[DisplayFormat]$GdcTheme.DefaultDisplayFormat = [DisplayFormat]::Short

function Get-WieldingLsInfo {
    $moduleName = (Get-ChildItem "$PSScriptRoot/*.psd1").Name

    Import-PowerShellDataFile -Path "$PSScriptRoot/$moduleName"
}

function Update-GDCColors {
    foreach ($extension in $GdcTheme.SourceCodeExtensions) {
        $GdcTheme.ExtensionColors[$extension] = $GdcTheme.SourceCodeColor
    }

    foreach ($extension in $GdcTheme.DataFileExtensions) {
        $GdcTheme.ExtensionColors[$extension] = $GdcTheme.DataFileColor
    }

    foreach ($extension in $GdcTheme.LogFileExtensions) {
        $GdcTheme.ExtensionColors[$extension] = $GdcTheme.LogFileColor
    }    

    foreach ($extension in $GdcTheme.CompressedFileExtensions) {
        $GdcTheme.ExtensionColors[$extension] = $GdcTheme.CompressedFileColor
    }        

    foreach ($extension in $GdcTheme.ExecutableFileExtensions) {
        $GdcTheme.ExtensionColors[$extension] = $GdcTheme.ExecutableFileColor
    }            

    foreach ($extension in $GdcTheme.DocumentFileExtensions) {
        $GdcTheme.ExtensionColors[$extension] = $GdcTheme.DocumentFileColor
    }                
}

function Write-FileLength {
    Param ($Length)

    If ($null -eq $Length) {
        Return ""
    }
    ElseIf ($Length -ge 1GB) {
        Return ($Length / 1GB).ToString("F") + 'GB'
    }
    ElseIf ($Length -ge 1MB) {
        Return ($Length / 1MB).ToString("F") + 'MB'
    }
    ElseIf ($Length -ge 1KB) {
        Return ($Length / 1KB).ToString("F") + 'KB'
    }

    Return $Length.ToString() + ' '
}

function Get-FileColor([Object]$file) {
    $fileStyle = $GdcTheme.DefaultFileColor
    $foundAttribute = $false
    $isDir = ($file.Attributes -band [System.IO.FileAttributes]::Directory) -eq [System.IO.FileAttributes]::Directory

    foreach ($attribute in $GdcTheme.FileAttributes) {
        if (($file.Attributes -band $attribute) -eq $attribute ) {
            if ($GdcTheme.FileAttributesColors.ContainsKey($attribute)) {
                $fileStyle = $GdcTheme.FileAttributesColors[$attribute]
                $foundAttribute = $true
            }
        }        
    }

    if ($isDir -and $file.Name.StartsWith(".")) {
        $fileStyle = $GdcTheme.HiddenFolderColor
    }

    if ($foundAttribute) {
        return $fileStyle
    }

    if (!$isDir -and $file.Extension.Length -lt 1) {
        return $GdcTheme.NakedFileColor
    }

    if ($file.Name.StartsWith(".")) {
        return $GdcTheme.HiddenFileColor
    }

    if ($GdcTheme.ExtensionColors.ContainsKey($file.Extension)) {
        return $GdcTheme.ExtensionColors[$file.Extension]
    }

    return $fileStyle
}

function Get-DirectoryContentsWithOptions {
    param (
        [GDCOptions]$options
    )

    $longestName = 0
    $totalSize = 0
    $index = 0
    $fileList = @()
    $attributes = "!System"
    

    if (-not $options.ShowColor) {
        $Wansi.Enabled = $false
    }
    
    if ($options.ShowHidden) {
        $attributes = "!System,Hidden+!System"
    }

    if ($options.ShowSystem) {
        $attributes = "!System,Hidden+System"
    }

    try {
        if ($options.SortProperty -ne "") {
            $files = Get-ChildItem $options.Path -Attributes $attributes -ErrorAction stop | Sort-Object -Property $options.SortProperty
        }
        else {
            $files = Get-ChildItem $options.Path -Attributes $attributes -ErrorAction stop
        }
    }
    catch {
        if ($options.Path -ne ".") {
            Write-Wansi "{:F9:}[$($options.Path)] was not found{:R:}`n"
            return 8
        }
        return 0
    }

    if ($options.ShowHeader) {
        $mode = ConvertTo-AnsiString "{:BoldOn:}{:F15:}{:UnderlineOn:}Mode{:R:}" -PadRight 8
        $lastWriteTime = ConvertTo-AnsiString "{:UnderlineOn:}{:F15:}LastWriteTime{:R:}" -PadLeft 19
        $Length = ConvertTo-AnsiString "{:UnderlineOn:}{:F15:}Length{:R:}" -PadLeft 15
        $Name = ConvertTo-AnsiString "{:UnderlineOn:}{:F15:}Name{:R:}" -PadLeft 10
        Write-Wansi ("{0}{1}{2}{3}`n" -f $mode.Value, $lastWriteTime.Value, $Length.Value, $Name.Value)
    }


    foreach ($file in $files) {
        ++$index

        if (!$options.ShowHidden) {
            if ($file.Name.StartsWith(".")) {
                continue
            }
        }

        if ($file.Name.Length + 3 -gt $longestName) {
            $longestName = $file.Name.Length + 3
            if ($longestName -ge $Host.Ui.RawUI.BufferSize.Width) {
                $longestName = $Host.Ui.RawUI.BufferSize.Width - 1
            }
        }

        $adjustedName = $file.Name

        $fileStyle = Get-FileColor $file

        if ($longestName -gt $options.MaxNameLength) {
            $longestName = $options.MaxNameLength
            $ti = ConvertTo-AnsiString $GdcTheme.TruncationIndicator
            $adjustedName = $file.Name.Substring(0, $options.MaxNameLength - ($ti.NakedLength + 1 + (ConvertTo-AnsiString $fileStyle).NakedLength))
            $adjustedName += $ti.value
        }



        $isDir = ($file.Attributes -band [System.IO.FileAttributes]::Directory) -eq [System.IO.FileAttributes]::Directory

        if (!$isDir) {
            $totalSize += $file.Length
        }

        # Long Format
        if ($options.Format -eq [DisplayFormat]::Long) {
            Write-Wansi "$($file.Mode)`t" -NoNewline
            Write-Wansi ("{0, 10} {1, 8}`t" -f $($file.LastWriteTime.ToString("d"), $file.LastWriteTime.ToString("t"))) -NoNewline
            if ($isDir) {
                Write-Wansi ("{0, 9}`t" -f "-") -NoNewline
            }
            else {
                Write-Wansi ("{0, 10}`t" -f $(Write-FileLength $file.Length)) -NoNewline
            }
            Write-Wansi ("$($fileStyle)$($file.Name){:R:}`n")
        }

        # Build Short Format Array for display after the loop
        if ($options.Format -eq [DisplayFormat]::Short) {
            $t = New-Object -TypeName FileItem
            $t.File = $file
            $t.Style = $fileStyle
            $t.AdjustedName = $adjustedName
            $fileList += $t
        }
    }

    # Display the short format
    if ($options.Format -eq [DisplayFormat]::Short) {
        $boundary = 0
        foreach ($i in $fileList) {
            if ($boundary + $longestName -ge $options.Width) {
                Write-Wansi "`n"
                $boundary = 0
            }

            $boundary += $longestName

            $ansiString = ConvertTo-AnsiString "$($i.Style)$($i.AdjustedName) {:R:}" -PadRight $longestName
            Write-Wansi $ansiString.Value
        }     
    }
   
    if ($options.ShowTotal) {
        if ($totalSize -gt 0) {
            Write-Wansi ("`t`t`t`t{0, 10} total`n" -f $(Write-FileLength $totalSize))
        }
    }

    Write-Wansi "`n`n"
}
function Get-DirectoryContents {
    <#
 .SYNOPSIS
    Display files in specified directory

 .DESCRIPTION
    Display colorized list of files for current or specified directory with options for color and format.

 .PARAMETER DisplayFormat
    The display format for output. Must be one of "Long", "Short"  

 .PARAMETER SortProperty
    The file property to sort on.  Must be one of "Name", "Attributes", "LastWriteTime", "Length"

 .PARAMETER HideHeader
    Disables displaying the directory list header

 .PARAMETER MinColumns
    The minumum number of columns to display in short format before truncating filenames

 .PARAMETER HideTotal
    Disables displaying the file size total

 .PARAMETER ShowHidden
    Enables displaying files that start with "."

 .PARAMETER NoColor
    Disables colorizing output  

 .EXAMPLE   
    Get-DirectoryContents -ShowHidden ~
    Display all files in users home directory including hidden files and files starting with "."

 .EXAMPLE  
    Get-DirectoryContents -SortProperty Name
    DISPLAY all files except for files with Hidden and System attributes in the current directory sorted by name

 .EXAMPLE  
    Get-DirectoryContents -la
    DISPLAY all files in the current directory using the long format with hidden files shown

 .NOTES
    Author: Andrew Kunkel 
    Inspired by and occasionally borrowed from https://github.com/joonro/Get-ChildItemColor

 .LINK
    https://github.com/Wielding/WieldingLs
    
#>    
    param (
        [string]$Path = ".",
        [ValidateSet("Name", "Attributes", "LastWriteTime", "Length")]
        [SortProperty]$SortProperty,
        [ValidateSet("Long", "Short")]
        [DisplayFormat]$DisplayFormat =$GdcTheme.DefaultDisplayFormat,
        [switch]$HideHeader,
        [switch]$HideTotal,
        [switch]$NoColor,
        [int]$MinColumns = 4,
        [Alias("a")]
        [switch]$ShowHidden,
        [Alias("l")]
        [switch]$ShowLong,
        [Alias("w")]
        [switch]$ShowSystem,
        [switch]$Help
    )

    $returnCode = 0

    if ($MinColumns -lt 1) {
        $MinColumns = 1
    }

    $options = New-Object -TypeName GDCOptions
    $options.Path = $Path
    $options.ShowHeader = !$HideHeader
    $options.ShowTotal = !$HideTotal
    $options.SortProperty = $SortProperty
    $options.ShowColor = !$NoColor
    $options.ShowHidden = $ShowHidden
    $options.ShowSystem = $ShowSystem
    $options.Format = $DisplayFormat
    $options.Width = $host.ui.RawUI.WindowSize.Width
    $options.MaxNameLength = ($host.ui.RawUI.WindowSize.Width / $MinColumns) - 3

    if ($args.Length -gt 0) {
        foreach ($arg in $args) {
            if ($arg.StartsWith("-")) {
                foreach ($char in $arg.ToCharArray()) {
                    switch ($char) {
                        "l" {
                            $options.Format = [DisplayFormat]::Long
                            $DisplayFormat = [DisplayFormat]::Long
                            $options.ShowHeader = $true
                            $options.ShowTotal = $true
                        }
                        "w" {
                            $options.ShowSystem = $true
                        }
                        "a" {
                            $options.ShowHidden = $true
                        }
                        "-" {}
                        default {
                            Write-Wansi "{:F9:}[$char] unknown option{:R:}`n"
                            $returnCode = 8
                        }
                    }
                }
            }
            else {
                $options.Path = $arg
            }
        }
    }    

    if ($ShowLong) {
        $options.Format = [DisplayFormat]::Long
        $DisplayFormat = [DisplayFormat]::Long
    }

    if ($DisplayFormat -eq [DisplayFormat]::Short) {
        $options.ShowHeader = $false
        $options.ShowTotal = $false
    }
    
    if ($returnCode -gt 0) {
        return
    }

    $originalWansiEnabled = $Wansi.Enabled

    $returnCode = Get-DirectoryContentsWithOptions $options      

    $Wansi.Enabled = $originalWansiEnabled

    if ($returnCode -gt 0) {
        return
    }
   
}

Update-GDCColors

Export-ModuleMember -Function Out-Default, 'Get-DirectoryContents'
Export-ModuleMember -Function Out-Default, 'Update-GDCColors'
Export-ModuleMember -Function Out-Default, 'Get-AnsiCodes'
Export-ModuleMember -Function Out-Default, 'Get-WieldingLsInfo'
Export-ModuleMember -Variable 'GdcTheme'
