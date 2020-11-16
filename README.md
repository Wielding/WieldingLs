WieldingLs
==========

:warning: This is a work in progress so the master branch could break your Powershell profile if you customize any of the settings.:warning: 

This is a lightweight Powershell module which aims for basic **nix* `ls` compatibility as well as colorizing directory listing output with the ability to customize file colors. 

This Powershell module is a replacement for my standalone version in https://github.com/Wielding/Get-DirectoryContents.  It quickly became apparent that I wanted the ANSI escape code in it's own module for use in other scripts so I broke them up and used better naming conventions.

This module depends on the WieldingAnsi module being installed which is located at https://github.com/Wielding/WieldingAnsi

It has been converted to using ANSI escape codes for colors and styles to enable *nix compatibility as well as more configuration options with 256 colors plus bold, underline and inverted attributes.

Inspired by and occasionally borrowed from https://github.com/joonro/Get-ChildItemColor. 


There is more work to be done. Here are the known limitations and planned enhancements.
1. File attribute handling needs to be enhanced for Non-Windows systems.  This prevents the ability to identify 'executable' files on those systems since they don't rely on file extensions.
2. Does not identify common packaging files (.e.g. '.deb', '.rpm').
3. You can't easily pipe output from this command since it is not returning Powershell objects.  This is just for formatting your directory listing nicely.  If you need to pipe files just use `Get-ChildItem`.
4. There is a slight delay when listing large folders in the default `Short` format since the module has to retrieve a list of all of the files before displaying them. This is necessary to format them in columns determined by the length of the longest filename and can't be helped.
5. This list will grow since I have not done any real testing on Non-Windows systems.

Main Function
==============

Get-DirectoryContents
---------------------
The current command line parameters are:
* `-DisplayFormat` -
  The format to display files.  Must be one of `"Long"`, `"Short"`. The default value is `"Short"`.

* `-l` -
  The same as `-DisplayFormat Long`.  

* `-SortProperty` -
  The file property to sort on.  Must be one of `"Name"`, `"Attributes"`, `"LastWriteTime"`, `"Length"`. The default sort method is to display files in the native order from Get-ChildItem.

* `-HideHeader` -
  Disables displaying the directory list header. The default value is False.

* `-HideTotal` -
  Disables displaying the file size total. The default value is False.

* `-ShowHidden` | `-a` -
  Enables displaying files that start with `"."` and\or have the `Hidden` attribute. The default value is False.

* `-ShowSystem` | `-w` -
  Enables displaying files with the `System` attribute. The default value is False.  

* `-NoColor` -
  Disables colorizing output. The default value is False.  

The parameters `-l, -a` and` -w` can be combined in any order into a single parameter.  For example
```powershell
Get-DirectoryContents -la
```

-and-

```powershell
Get-DirectoryContents -al
```

will enable `ShowHidden + DisplayFormat Long`.


Examples:
---------
Display all files in users home directory including files starting with "." and with the Hidden attribute set.
```powershell
Get-DirectoryContents -ShowHidden ~
```

Display all files in current directory sorted by name
```powershell
Get-DirectoryContents -SortProperty Name
```

To use this module place the file Get-DirectoryContents.psm1 in you user Powershell Modules folder.

On Windows this would be something like `~\Documents\PowerShell\Modules\Get-DirectoryContents`.

On **nix* I usually use `~/.local/share/powershell/Modules/Get-DirectoryContents`

You can inspect your module locations with `$Env:PSModulePath` to verify where you can place the module.

If the folder does not exist create it.

If you want to be able to easily keep it up to date you can use git to clone https://github.com/Wielding/Get-DirectoryContents under `~\Documents\PowerShell\Modules `

I will look into adding this module to the Powershell gallery once it has been fully tested across platforms.

After that, add the following line to your Powershell profile:

```powershell
Import-Module Get-DirectoryContents
```

Customization
-------------
This module uses ANSI color and format codes to apply styles to your filenames.  I have picked my defaults which are hard coded for now but they can be overridden in your Powershell profile.

The module exports a variable called `$Wansi` which holds all of the predefined style and color attributes you can use.  If there is an ANSI sequence that is not supplied you can use your own.

To see the colors and styles that can be used type `Get-AnsiCodes` on the command line after you have imported the module to see what is available.  The attributes and a color table will be displayed with the foreground colors starting with an 'F' and background colors starting with a 'B' (e.g. `$Wansi.F7` is a 'white' foreground color).

You can also set Bold, Inverse and Underline styles using these values in $Wansi.

1. Bold - `$Wansi.BoldOn` : `$Wansi.BoldOff`
2. Underline - `$Wansi.UnderlineOn` : `$Wansi.UnderlineOff`
3. Inverse - `$Wansi.InverseOn` : `$Wansi.InverseOff`

The group colors and styles that can be overridden are in the following variables:
```powershell
$GDCSourceCodeColor
$GDCDataFileColor
$GDCCompressedFileColor
$GDCExecutableFileColor
$GDCDocumentFileColor
$GDCHiddenFileColor
$GDCHiddenFolderColor
$GDCDefaultFileColor
```
You can add or override specific extensions with the variable:
```powershell
$GDCExtensionColors
```

You can override specific file attributes with the variable:
```powershell
$GDCFileAttributesColors
```

Example overrides
---
Here are some examples of overriding the defaults by placing some code in your Powershell profile.

The following will change all files categorized as Data Files to be shown with a Dark Magenta foreground color, the default background color and underlined.  Note that `'Update-GDCColors'` needs to be called after modifying a category.
```powershell
Import-Module Get-DirectoryContents
$GDCDataFileColor = $Wansi.F13 + $Wansi.UnderlineOn
Update-GDCColors
```
The following will cause all files with a '.xxx' extension to be shown with a Red foreground and a White background.  Calling `Update-GDCColors` is not required here since we are directly setting the extension color outside of any category.
```powershell
Import-Module Get-DirectoryContents
$GDCExtensionColors[".xxx"] = $Wansi.F9 + $Wansi.B7
```
The following will show files with a '.pl1' extension to show as if it was in the 'Source Code' category.
```powershell
Import-Module Get-DirectoryContents
$GDCExtensionColors[".pl1"] = $GDCSourceCodeColor
```
The following will also show files with a ".pl1" extension with the color for 'Source Code' but this requires a call to `Update-GDCColors` since we are adding the extension to the category.
```powershell
Import-Module Get-DirectoryContents
$GDCSourceCodeExtensions += ".pl1"
Update-GDCColors
```

The following will change all files with the `Directory` attribute to be shown with a `Blue` foreground and the default background.
```powershell
$GDCFileAttributesColors["Directory"] = $Wansi.F4
```
You can look at the code in `Get-DirectoryContents.pms1` to see the default file extension values as well as the exported values that can be overridden or modified.

Sample Output
-------------
![output](images/default.png)
![output](images/long.png)
![output](images/showhidden.png)
![output](images/showhidden_long.png)
![output](images/sort_size.png)

For ease of use I also add the following to my Powershell profile to override the default Powershell alias for `ls`.
```powershell
Set-Alias -Name ls -Value Get-DirectoryContents
```

Now that you have imported the module, as a bonus you can use the `$Wansi` Class in your everyday Powershell life. You now can mix all 256 colors and styles on a single Write-Host line without remembering all of the escape sequences. You can just use `Get-AnsiCodes` to see the available values and plop them in your script. I like a simple prompt with a separator line and domain identification since I log into many machines.  Here is my prompt function.

```powershell
function prompt {
  $line =  "-".PadRight($host.UI.RawUI.WindowSize.Width - $env:USERDOMAIN.Length - 1, "-")
  Write-Host "$($Wansi.F226)$line$($Wansi.F202) $($Wansi.BoldOn)$env:USERDOMAIN$($Wansi.R)"
  Write-Host "$($Wansi.F15)[$($Wansi.F46)$((Get-Location).Path.Replace($($HOME), '~'))$($Wansi.F15)]$($Wansi.R)" -NoNewline
  Write-Host "$($Wansi.F2)`n▶$($Wansi.R)" -NoNewline
 
  return " "
}
```

Which gives me this

![output](images/prompt.png)

I may spawn off the Ansi code to a new module at some point and add some functionality since it comes in useful for cross platform Powershell goodness.