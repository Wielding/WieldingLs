WieldingLs
==========

:warning: This is a work in progress so the master branch could break your Powershell profile if you customize any of the settings.:warning: 

This is a lightweight Powershell module which aims for basic **nix* `ls` compatibility as well as colorizing directory listing output with the ability to customize file colors. 

This module depends on the WieldingAnsi module for ANSI escape codes which enables colors and styles with *nix compatibility.  It can be found at https://github.com/Wielding/WieldingAnsi.

Inspired by and occasionally borrowed from https://github.com/joonro/Get-ChildItemColor. 

There is more work to be done. Here are the known limitations and planned enhancements.
1. File attribute handling needs to be enhanced for Non-Windows systems.  This prevents the ability to identify 'executable' files on those systems since they don't rely on file extensions. 
   * A workaround for this is to use $GDCNakedFileColor.  This is a special color for all files without an extension.
   * So far all attempts to read **nix* file attributes are unacceptably slow for large directory listings.
2. You can't easily pipe output from this command since it is not returning Powershell objects.  This is just for formatting your directory listing nicely.  If you need to pipe files just use `Get-ChildItem`.
3. There is a slight delay when listing large folders in the default `Short` format since the module has to retrieve a list of all of the files before displaying them. This is necessary to format them in columns determined by the length of the longest filename and can't be helped.
4. This list will grow since I have not done any real testing on Non-Windows systems.

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
$GDCNakedFileColor
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

