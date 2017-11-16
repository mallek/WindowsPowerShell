# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
Invoke-Expression $psscriptroot\scripts\Banner.ps1

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------
$MaximumHistoryCount = 512
$FormatEnumerationLimit = 100

# ---------------------------------------------------------------------------
# Path
# ---------------------------------------------------------------------------
$vsPath = 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\'

#Temporarily add visual studio to the path, This will only persist in this powershell
#check if folder exists and directory isn't already in the path
if ((Test-Path $vsPath) -And (!$env:Path.Contains($vsPath))) {
    $env:Path += ';' + $vsPath;
}

remove-variable vsPath;

# ---------------------------------------------------------------------------
# Modules
# ---------------------------------------------------------------------------

# PSReadline provides Bash like keyboard cursor handling
if ($host.Name -eq 'ConsoleHost')
{
	Import-Module PSReadline

	Set-PSReadLineOption -MaximumHistoryCount 4000
	Set-PSReadlineOption -ShowToolTips:$true

	# With these bindings, up arrow/down arrow will work like
	# PowerShell/cmd if the current command line is blank. If you've
	# entered some text though, it will search the history for commands
	# that start with the currently entered text.
	Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
	Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

	Set-PSReadlineKeyHandler -Key "Tab" -Function "MenuComplete"
	Set-PSReadlineKeyHandler -Chord 'Shift+Tab' -Function "Complete"
}

# fzf is a fuzzy file finder, and will provide fuzzy location searching
# when using Ctrl+T, and will provide better reverse command searching via
# Ctrl-R.
Import-Module PSFzf -ArgumentList 'Ctrl+T','Ctrl+R'

# Git support
Import-Module Git
Initialize-Git
Import-Module Posh-Git

# Colorize directory output
Import-Module PSColor

# Utils
Import-Module StreamUtils
Import-Module StringUtils
Import-Module Profile

# ---------------------------------------------------------------------------
# Custom Aliases
# ---------------------------------------------------------------------------
set-alias unset      remove-variable
set-alias mo         measure-object
set-alias eval       invoke-expression
Set-Alias touch      Update-File
Set-Alias sudo       Elevate-Process
set-alias n          code
set-alias vi         code
Set-Alias vs         devenv.exe

#Remap ls to show hidden folders
Remove-Item alias:ls
function ls () {
	Get-ChildItem -Force @args
}

# ---------------------------------------------------------------------------
# Visuals
# ---------------------------------------------------------------------------
set-variable -Scope Global WindowTitle ''

function prompt
{
	$local:pathObj = (get-location)
	$local:path    = $pathObj.Path
	$local:drive   = $pathObj.Drive.Name

	if(!$drive) # if there's no drive, it might be a special path (eg, a UNC path)
	{
		if($path.contains('::')) # if it's a special path, get the provider's path name
		{
			$path = $pathObj.ProviderPath
		}
		if($path -match "^\\\\([^\\]+)\\") # if it's a UNC path, use the server name as the drive
		{
			$drive = $matches[1]
		}
	}

	$local:title = $path
	if($WindowTitle) { $title += " - $WindowTitle" }

	$host.ui.rawUi.windowTitle = $title
	$path = [IO.Path]::GetFileName($path)
	if(!$path) { $path = '\' }

	if($NestedPromptLevel)
	{
		Write-Host -NoNewline -ForeGroundColor Green "$NestedPromptLevel-";
	}

	$private:h = @(Get-History);
	$private:nextCommand = $private:h[$private:h.Count - 1].Id + 1;
	Write-Host -NoNewline -ForeGroundColor Red "${private:nextCommand}|";

	Write-Host -NoNewline -ForeGroundColor Cyan "${drive}";
	Write-Host -NoNewline -ForeGroundColor White ":";
	Write-Host -NoNewline -ForeGroundColor White "$path";

	# Show GIT Status, if loaded:
	if (Get-Command "Write-VcsStatus" -ErrorAction SilentlyContinue)
	{
		$realLASTEXITCODE = $LASTEXITCODE
		Write-VcsStatus
		$global:LASTEXITCODE = $realLASTEXITCODE
	}

    $txtRight = "[$(get-date)]`n"
    $startposx = $Host.UI.RawUI.windowsize.width - $txtRight.length
    $startposy = $Host.UI.RawUI.CursorPosition.Y
    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $startposx,$startposy
    $host.UI.RawUI.ForegroundColor = "White"
    $Host.UI.Write($txtRight)

	return ">";
}

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------


Function Update-File {
	<#
.SYNOPSIS
  Used for touch alias, output file is ascii encoded (useful for Update-File .gitignore)
#>
    $file = $args[0]
    if ($file -eq $null) {
        throw "No filename supplied"
    }

    if (Test-Path $file) {
        (Get-ChildItem $file).LastWriteTime = Get-Date
    }
    else {
        Out-File $file -Encoding ASCII
    }
}


function Elevate-Process
{
<#
.SYNOPSIS
  Used for sudo alias
  Runs a process as administrator. Stolen from http://weestro.blogspot.com/2009/08/sudo-for-powershell.html.
#>
    $file, [string]$arguments = $args
    $psi = New-Object System.Diagnostics.ProcessStartInfo $file
    $psi.Arguments = $arguments
    $psi.Verb = "runas"
    $psi.WorkingDirectory = Get-Location
    [System.Diagnostics.Process]::Start($psi) | Out-Null
}

# starts a new execution scope
function Start-NewScope
{
	param($Prompt = $null) Write-Host "Starting New Scope"
	if ($Prompt -ne $null)
	{
		if ($Prompt -is [ScriptBlock])
		{
			$null = New-Item function:Prompt -Value $Prompt -force
		}
		else
		{
			function Prompt {"$Prompt"}
		}
	}
	$host.EnterNestedPrompt()
}

# 'cause shutdown commands are too long and hard to type...
function Restart
{
	shutdown /r /t 1
}

# --------------------------------------------------------------------------
# EXO Helpers
# --------------------------------------------------------------------------

function dev($project)
{
	cd "$(get-content Env:INETROOT)\sources\dev\$project"
}

function test($project)
{
	cd "$(get-content Env:INETROOT)\sources\test\$project"
}

function bcc {
    build -Cc
}


# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------





