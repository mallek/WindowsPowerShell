# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Windows PowerShell profile repository that provides a customized PowerShell environment with enhanced Git integration, custom modules for development workflows, and Unix-like command utilities.

## Repository Structure

- **profile.ps1**: Main PowerShell profile that auto-loads on PowerShell startup
- **Modules/**: Custom PowerShell modules providing specialized functionality
- **Scripts/**: Utility scripts that are auto-loaded by the profile
- **Logos/**: ASCII art files for terminal banners

## Prerequisites

- PowerShell 5.0 or later
- fzf (fuzzy finder): Install via Chocolatey with `choco install fzf`
- Git command-line tools
- Visual Studio 2022 Professional (optional, configured in profile)

## Development Workflow

### Installation
The repository should be cloned to the user's Documents folder:
```powershell
# Repository location
C:\Users\<username>\Documents\WindowsPowerShell\
```

### Testing Profile Changes
To reload the profile after making changes:
```powershell
source  # Alias defined in profile.ps1:105-108
```

### Working with Modules

Modules are automatically imported by `profile.ps1`. To test a module independently:
```powershell
Import-Module .\Modules\<ModuleName>\<ModuleName>.psm1 -Force
```

Module manifests (.psd1) define exported functions and metadata. Module implementation (.psm1) contains the actual code.

## Key Custom Modules

### PRReview (Modules/PRReview/)
Generates comprehensive Git PR review files with diffs, statistics, and AI-ready prompts.

**Primary Functions:**
- `New-PRReview` (aliases: `pr-review`, `review`): Generate code review files
- `Get-PRDiff`: Get raw diff data programmatically
- `Get-DefaultBranch`: Auto-detect main/develop/master branch

**Common Usage:**
```powershell
# Review current branch against develop
New-PRReview

# Review uncommitted changes before committing
New-PRReview -CompareUncommitted

# Review only staged changes
New-PRReview -CompareUncommitted -StagedOnly

# Compare against specific branch
New-PRReview -TargetBranch "main"
```

See `Modules/PRReview/README.md` for comprehensive documentation.

### ElasticsearchEncode (Modules/ElasticsearchEncode/)
Generates and tests Elasticsearch API key headers.

**Function:** `Generate-Elastic-Key`
- Encodes API key ID and key as base64
- Tests connection to Elasticsearch cluster
- Optionally copies authorization header to clipboard

### StreamUtils (Modules/StreamUtils/)
Unix-like stream processing utilities for PowerShell pipelines:
- `get`: Extract property from pipeline objects (e.g., `ls | get length`)
- `grep`: Regex filtering with property support
- `head`: Get first N items
- `tail`: Get last N items
- `reverse`: Reverse pipeline order
- `unique`: Filter duplicates while preserving order

### StringUtils (Modules/StringUtils/)
String manipulation utilities:
- `cut`: Slice text lines into fields by indices
- `join`: Join items with separator (handles edge cases better than .NET Join)
- `truncateStringAt`: Truncate strings with ellipsis

## Profile Features

### Auto-loaded Modules
profile.ps1:40-80 imports these modules on startup:
- PSReadline: Bash-like keyboard handling (up/down arrow history search)
- PSFzf: Fuzzy file finder (Ctrl+T for files, Ctrl+R for command history)
- Posh-Git: Git status in prompt
- PSColor: Colorized directory output
- Write-Ascii: ASCII art generation
- Custom modules: StreamUtils, StringUtils, Profile, PRReview

### Custom Aliases
Common aliases defined in profile.ps1:84-103:
- `n`, `vi`: Opens VS Code (`code`)
- `vs`: Opens Visual Studio (`devenv.exe`)
- `krak`: Opens GitKraken (`kraken` function)
- `which`: Shows command definition
- `ls`: Overridden to show hidden files (`-Force`)
- `source`: Reloads PowerShell profile

### Git Aliases
Scripts/Posh-Git-Alias.ps1 defines extensive Git shortcuts:
- Branch: `b` (list), `bc` (create), `co` (checkout)
- Commit: `ci`, `cim <msg>`, `ca` (commit all), `amend`
- Diff: `d` (diff), `dc` (diff cached), `wd` (word diff)
- Status: `s`
- Push: `po` (push origin), `pu` (push upstream)
- Log: `l`, `l1`, `l2`, `ll`, `lx` (various formats)
- Staging: `a` (add), `au` (add -u), `aa` (add -all), `ap` (add -patch)
- Rebase: `r` (interactive), `rc` (continue), `ra` (abort)

### Custom Prompt
The prompt function (profile.ps1:115-188) displays:
- Command number (red)
- Drive letter (cyan) and current directory
- Git branch and status (via Posh-Git)
- Timestamp in top-right corner
- Admin indicator if running elevated

### Visual Studio Integration
profile.ps1:15-22 adds VS2022 Professional to PATH if installed:
```powershell
$vsPath = 'C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\'
```

### Helper Functions
- `kraken()` (profile.ps1:236-242): Opens GitKraken in current directory
- `dev($project)` (profile.ps1:222-225): Navigate to dev project by name
- `test($project)` (profile.ps1:227-230): Navigate to test project by name
- `Restart` (profile.ps1:213-216): Quick system restart

## Architecture Notes

### Module Auto-loading
profile.ps1:30-32 auto-loads all .ps1 files in Scripts/ directory (excluding .Tests. files):
```powershell
Resolve-Path $PSScriptRoot\Scripts\*.ps1 |
Where-Object { -not ($_.ProviderPath.Contains(".Tests.")) } |
    Foreach-Object { . $_.ProviderPath }
```

### PRReview Design
The PRReview module uses Git merge-base comparison (`develop...HEAD`) to find commits since branch divergence. It supports three modes:
1. Branch comparison: `develop...HEAD` (default)
2. Uncommitted changes: `git diff <branch>` (all working tree changes)
3. Staged changes: `git diff --staged <branch>` (only staged changes)

New/untracked files are included in uncommitted reviews by default and their full content is appended (truncated at 10,000 chars for large files).

### Git Branch Detection
PRReview's `Get-DefaultBranch` function checks branches in priority order:
1. develop (local, then remote)
2. main (local, then remote)
3. master (local, then remote)
4. Remote HEAD
5. First available remote branch

## Common Development Tasks

### Adding a New Module
1. Create directory: `Modules/<ModuleName>/`
2. Create module file: `<ModuleName>.psm1` with function definitions
3. Create manifest (optional): `<ModuleName>.psd1`
4. Add `Import-Module <ModuleName>` to profile.ps1
5. Use `Export-ModuleMember -Function <FunctionName>` in .psm1
6. Test with `source` to reload profile

### Adding a New Script
1. Create file in `Scripts/` directory with `.ps1` extension
2. Scripts are automatically dot-sourced on profile load
3. Avoid test files with `.Tests.` in the name (they're excluded)
4. Reload profile with `source` to test

### Modifying Git Aliases
Edit `Scripts/Posh-Git-Alias.ps1` and run `source` to reload.

## Notes

- Profile checks for NuGet module at startup (profile.ps1:1-3) and exits early if detected to avoid conflicts
- The environment variable `$env:ASPNETCORE_ENVIRONMENT` is set to 'Local' (profile.ps1:10)
- PSReadline is configured with MenuComplete on Tab and history search on arrow keys
- Banner.ps1 displays system information and ASCII logo (currently commented out in profile)
