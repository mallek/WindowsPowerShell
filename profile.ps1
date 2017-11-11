#poshgit colors referance https://github.com/dahlbyk/posh-git/blob/master/src/GitPrompt.ps1

Import-Module posh-git
$global:GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
$global:GitPromptSettings.DefaultPromptSuffix = '`n$(''>'' * ($nestedPromptLevel + 1)) '
$global:GitPromptSettings.BeforeText = '['
$global:GitPromptSettings.AfterText  = '] '
$global:GitPromptSettings.EnableFileStatus = $true

# Background colors
$GitPromptSettings.AfterBackgroundColor = "Black"
$GitPromptSettings.AfterStashBackgroundColor = $GitPromptSettings.AfterBackgroundColor
$GitPromptSettings.BeforeBackgroundColor = $GitPromptSettings.AfterBackgroundColor
$GitPromptSettings.BeforeIndexBackgroundColor = $GitPromptSettings.AfterBackgroundColor
$GitPromptSettings.BeforeStashBackgroundColor = $GitPromptSettings.AfterBackgroundColor
$GitPromptSettings.BranchAheadStatusBackgroundColor = $GitPromptSettings.AfterBackgroundColor
$GitPromptSettings.BranchBackgroundColor = $GitPromptSettings.AfterBackgroundColor
$GitPromptSettings.BranchBehindAndAheadStatusBackgroundColor = $GitPromptSettings.AfterBackgroundColor
$GitPromptSettings.BranchBehindStatusBackgroundColor = $GitPromptSettings.AfterBackgroundColor
$GitPromptSettings.BranchIdenticalStatusToBackgroundColor = $GitPromptSettings.AfterBackgroundColor
$GitPromptSettings.DelimBackgroundColor = $GitPromptSettings.AfterBackgroundColor
$GitPromptSettings.IndexBackgroundColor = $GitPromptSettings.AfterBackgroundColor
$GitPromptSettings.LocalDefaultStatusBackgroundColor = $GitPromptSettings.AfterBackgroundColor
$GitPromptSettings.LocalStagedStatusBackgroundColor = $GitPromptSettings.AfterBackgroundColor
$GitPromptSettings.LocalWorkingStatusBackgroundColor = $GitPromptSettings.AfterBackgroundColor
$GitPromptSettings.StashBackgroundColor = $GitPromptSettings.AfterBackgroundColor
$GitPromptSettings.WorkingBackgroundColor = $GitPromptSettings.AfterBackgroundColor

# Foreground colors
$GitPromptSettings.BranchForegroundColor = [ConsoleColor]::DarkCyan
$GitPromptSettings.BranchIdenticalStatusToForegroundColor = "White"
$GitPromptSettings.DelimForegroundColor = "Blue"
$GitPromptSettings.IndexForegroundColor = "Red"
$GitPromptSettings.WorkingForegroundColor = "Yellow"
$GitPromptSettings.BranchBehindStatusForegroundColor = [ConsoleColor]::Red
$GitPromptSettings.BranchAheadStatusForegroundColor = [ConsoleColor]::Yellow

# Prompt shape
$GitPromptSettings.BranchIdenticalStatusToSymbol = ""
$GitPromptSettings.DelimText = " ॥"
$GitPromptSettings.LocalStagedStatusSymbol = ""
$GitPromptSettings.LocalWorkingStatusSymbol = ""
$GitPromptSettings.ShowStatusWhenZero = $false

function prompt {
    $origLastExitCode = $LASTEXITCODE
    Write-VcsStatus

    $curPath = $ExecutionContext.SessionState.Path.CurrentLocation.Path
    if ($curPath.ToLower().StartsWith($Home.ToLower()))
    {
        $curPath = "~" + $curPath.SubString($Home.Length)
    }

    $maxPathLength = 40
    if ($curPath.Length -gt $maxPathLength) {
        $curPath = '...' + $curPath.SubString($curPath.Length - $maxPathLength + 3)
    }

    Write-Host $curPath -ForegroundColor DarkGreen

    $txtRight = "$(get-date)"
    $startposx = $Host.UI.RawUI.windowsize.width - $txtRight.length - 2
    $startposy = $Host.UI.RawUI.CursorPosition.Y - 1
    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $startposx,$startposy
    $host.UI.RawUI.ForegroundColor = "White"
    $Host.UI.Write("[")
    $host.UI.RawUI.ForegroundColor = "Cyan"
    $Host.UI.Write($txtRight)
    $host.UI.RawUI.ForegroundColor = "White"
    $Host.UI.Write("]")



    $LASTEXITCODE = $origLastExitCode
    "$('>' * ($nestedPromptLevel + 1)) "
}



Write-Host @"
__________                           _________.__           .__  .__
\______   \______  _  __ ___________/   _____/|  |__   ____ |  | |  |
 |     ___/  _ \ \/ \/ // __ \_  __ \_____  \ |  |  \_/ __ \|  | |  |
 |    |  (  <_> )     /\  ___/|  | \/        \|   Y  \  ___/|  |_|  |__
 |____|   \____/ \/\_/  \___  >__| /_______  /|___|  /\___  >____/____/
                            \/             \/      \/     \/

"@ -foregroundcolor "magenta"