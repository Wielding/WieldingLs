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
}

class Style {
    [string]$Codes
}

class FileItem {
    [object]$File
    [string]$Style
}

$GDCSourceCodeColor = "{:F82:}"
$GDCSourceCodeExtensions = @(
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

$GDCDataFileColor = "{:F14:}"
$GDCDataFileExtensions = @(
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

$GDCLogFileColor = "{:F9:}"
$GDCLogFileExtensions = @(
    ".log"
)

$GDCDocumentFileColor = "{:F12:}"
$GDCDocumentFileExtensions = @(
    ".doc",
    ".docx",
    ".md",
    ".xls"
)    

$GDCExecutableFileColor = "{:F2:}"
$GDCExecutableFileExtensions = @(
    ".exe",
    ".bat",
    ".ps1",
    ".sh"
)    

$GDCCompressedFileColor = "{:F129:}"
$GDCCompressedFileExtensions = @(
    ".zip",
    ".tz",
    ".gz",
    ".7z",
    ".deb",
    ".rpm"
)

$GDCFileAttributes = [System.IO.FileAttributes].GetEnumNames()

$GDCFileAttributesColors = @{
    Directory    = "{:F11:}"
    ReparsePoint = "{:F0:}{:B11:}"
}

$GDCHiddenFileColor = "{:F240:}"
$GDCHiddenFolderColor = "{:F136:}"
$GDCNakedFileColor = "{:F28:}"
$GDCDefaultFileColor = "{:R:}"
[DisplayFormat]$GDCDefaultDisplayFormat = [DisplayFormat]::Short

$GDCExtensionColors = @{}

function Update-GDCColors {
    foreach ($extension in $GDCSourceCodeExtensions) {
        $GDCExtensionColors[$extension] = $GDCSourceCodeColor
    }

    foreach ($extension in $GDCDataFileExtensions) {
        $GDCExtensionColors[$extension] = $GDCDataFileColor
    }

    foreach ($extension in $GDCLogFileExtensions) {
        $GDCExtensionColors[$extension] = $GDCLogFileColor
    }    

    foreach ($extension in $GDCCompressedFileExtensions) {
        $GDCExtensionColors[$extension] = $GDCCompressedFileColor
    }        

    foreach ($extension in $GDCExecutableFileExtensions) {
        $GDCExtensionColors[$extension] = $GDCExecutableFileColor
    }            

    foreach ($extension in $GDCDocumentFileExtensions) {
        $GDCExtensionColors[$extension] = $GDCDocumentFileColor
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
    $fileStyle = $GDCDefaultFileColor
    $foundAttribute = $false
    $isDir = ($file.Attributes -band [System.IO.FileAttributes]::Directory) -eq [System.IO.FileAttributes]::Directory

    foreach ($attribute in $GDCFileAttributes) {
        if (($file.Attributes -band $attribute) -eq $attribute ) {
            if ($GDCFileAttributesColors.ContainsKey($attribute)) {
                $fileStyle = $GDCFileAttributesColors[$attribute]
                $foundAttribute = $true
            }
        }        
    }

    if ($isDir -and $file.Name.StartsWith(".")) {
        $fileStyle = $GDCHiddenFolderColor
    }

    if ($foundAttribute) {
        return $fileStyle
    }

    if (!$isDir -and $file.Extension.Length -lt 1) {
        return $GDCNakedFileColor
    }

    if ($file.Name.StartsWith(".")) {
        return $GDCHiddenFileColor
    }

    if ($GDCExtensionColors.ContainsKey($file.Extension)) {
        return $GDCExtensionColors[$file.Extension]
    }

    return $fileStyle
}

function Get-DirectoryContentsWithOptions {
    param (
        [GDCOptions]$options
    )

    $defaultColor = "{:R:}"
    $longestName = 0
    $totalSize = 0
    $index = 0
    $fileList = @()
    $attributes = "!System"
    
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
        Write-Host ("{0, 5}`t{1, 19}`t{2, 10}`t{3}" -f "Mode", "LastWriteTime", "Length", "Name")
        Write-Host ("{0, 5}`t{1, 19}`t{2, 10}`t{3}" -f "-----", "-------------------", "----------", "----")
    }

    foreach ($file in $files) {
        ++$index

        if (!$options.ShowHidden) {
            if ($file.Name.StartsWith(".")) {
                continue
            }
        }

        if ($file.Name.Length + 2 -gt $longestName) {
            $longestName = $file.Name.Length + 2
        }


        if ($options.ShowColor) {
            $fileStyle = Get-FileColor $file
        }
        else {
            $fileStyle = $defaultColor
        }

        $isDir = ($file.Attributes -band [System.IO.FileAttributes]::Directory) -eq [System.IO.FileAttributes]::Directory

        if (!$isDir) {
            $totalSize += $file.Length
        }

        # Long Format
        if ($options.Format -eq [DisplayFormat]::Long) {
            Write-Host "$($file.Mode)`t" -NoNewline
            Write-Host ("{0, 10} {1, 8}`t" -f $($file.LastWriteTime.ToString("d"), $file.LastWriteTime.ToString("t"))) -NoNewline
            if ($isDir) {
                Write-Host ("{0, 9}`t" -f "-") -NoNewline
            }
            else {
                Write-Host ("{0, 10}`t" -f $(Write-FileLength $file.Length)) -NoNewline
            }
            Write-Wansi ("$($fileStyle)$($file.Name){:R:}`n")
        }

        # Build Short Format Array for display after the loop
        if ($options.Format -eq [DisplayFormat]::Short) {
            $t = New-Object -TypeName FileItem
            $t.File = $file
            $t.Style = $fileStyle
            $fileList += $t
        }
    }

    # Display the short format
    if ($options.Format -eq [DisplayFormat]::Short) {
        $boundary = 0
        foreach ($i in $fileList) {
            if ($boundary + $longestName -ge $options.Width) {
                Write-Host
                $boundary = 0
            }

            $boundary += $longestName

            $ansiString = ConvertTo-AnsiString "$($i.Style)$($i.File.Name){:R:}"
            Write-Host $ansiString.Value -NoNewline    
            if ($longestName - $ansiString.NakedLength -gt 0) {
                $padding =  " ".PadRight($longestName - $ansiString.NakedLength, " ")
                Write-Host $padding -NoNewline
            } 


        }     
    }
   
    if ($options.ShowTotal) {
        if ($totalSize -gt 0) {
            Write-Host ("`t`t`t`t{0, 10} total" -f $(Write-FileLength $totalSize))
        }
    }

    Write-Host  
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
        [DisplayFormat]$DisplayFormat = $GDCDefaultDisplayFormat,
        [switch]$HideHeader,
        [switch]$HideTotal,
        [switch]$NoColor,
        [Alias("a")]
        [switch]$ShowHidden,
        [Alias("l")]
        [switch]$ShowLong,
        [Alias("w")]
        [switch]$ShowSystem,
        [switch]$Help

    )

    $returnCode = 0

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

    $returnCode = Get-DirectoryContentsWithOptions $options      

    if ($returnCode -gt 0) {
        return
    }
   
}

Update-GDCColors

$GDCExtensionColors[".xxx"] = "{:F40:}*{:F93:}{:UnderlineOn:}"

Export-ModuleMember -Function Out-Default, 'Get-DirectoryContents'
Export-ModuleMember -Function Out-Default, 'Update-GDCColors'
Export-ModuleMember -Function Out-Default, 'Get-AnsiCodes'
Export-ModuleMember -Variable 'GDCExtensionColors'
Export-ModuleMember -Variable 'GDCSourceCodeColor'
Export-ModuleMember -Variable 'GDCSourceCodeExtensions'
Export-ModuleMember -Variable 'GDCDataFileColor'
Export-ModuleMember -Variable 'GDCDataFileExtensions'
Export-ModuleMember -Variable 'GDCCompressedFileColor'
Export-ModuleMember -Variable 'GDCCompressedFileExtensions'
Export-ModuleMember -Variable 'GDCExecutableFileColor'
Export-ModuleMember -Variable 'GDCExecutableFileExtensions'
Export-ModuleMember -Variable 'GDCDocumentFileColor'
Export-ModuleMember -Variable 'GDCDocumentFileExtensions'
Export-ModuleMember -Variable 'GDCHiddenFileColor'
Export-ModuleMember -Variable 'GDCHiddenFolderColor'
Export-ModuleMember -Variable 'GDCFileAttributesColors'
Export-ModuleMember -Variable 'GDCDefaultFileColor'
Export-ModuleMember -Variable 'GDCFileAttributes'
Export-ModuleMember -Variable 'GDCNakedFileColor'
Export-ModuleMember -Variable 'GDCDefaultDisplayFormat'