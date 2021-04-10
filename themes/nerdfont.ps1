# Example Nerdfont theme
# If you are using nerdfonts in your terminal
# Add these lines to the end of your $profile to see some nice things

$GdcTheme.FileAttributesColors[([System.IO.FileAttributes]::System + [System.IO.FileAttributes]::Hidden + [System.IO.FileAttributes]::Directory)] = "!{:F1:}$([char]0xf79f){:F220:} "
$GdcTheme.FileAttributesColors[[System.IO.FileAttributes]::Directory] = "{:F172:}$([char]0xf74a){:F220:} "
$GdcTheme.FileAttributesColors[([System.IO.FileAttributes]::Directory + [System.IO.FileAttributes]::ReparsePoint)] = "!{:F166:}$([char]0xf751){:F220:} "
$GdcTheme.FileAttributesColors[([System.IO.FileAttributes]::Directory + [System.IO.FileAttributes]::ReadOnly)] = "!{:F172:}$([char]0xf74f){:F220:} "
$GdcTheme.FileAttributesColors[([System.IO.FileAttributes]::Directory + [System.IO.FileAttributes]::Hidden)] = "!{:F15:}$([char]0xf79f){:F220:} "
$GdcTheme.FileAttributesColors[[System.IO.FileAttributes]::Hidden] = "{:F15:}$([char]0xf79f){:F1:} "
$GdcTheme.HiddenFolderColor = "!{:F172:}$([char]0xf755){:F178:} "
$GdcTheme.TruncationIndicator = "{:F15:}$([char]0xf68f)..{:R:}"
$GdcTheme.ExtensionColors[".lnk"] = "$([char]0xf0c1) {:F26:}"
$GdcTheme.ExtensionColors[".url"] = "$([char]0xf0c1) {:F26:}"
$GdcTheme.ExtensionColors[".pdf"] = "$([char]0xf411) {:F26:}"
$GdcTheme.ExtensionColors[".docx"] = "$([char]0xf718) {:F26:}"