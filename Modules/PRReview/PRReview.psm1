#
# PRReview PowerShell Module
# Author: Travis Haley
# Description: Generate comprehensive code review reports from Git diffs for PR analysis
#

<#
.SYNOPSIS
    Gets the default branch for the current repository.

.DESCRIPTION
    Attempts to determine the default branch by checking common branch names and remote HEAD.
    Returns the first available branch from: develop, main, master, then falls back to remote HEAD.

.EXAMPLE
    Get-DefaultBranch
    Returns the default branch name for the current repository.
#>
function Get-DefaultBranch {
    [CmdletBinding()]
    param()
    
    # Check common branch names in order of preference
    $commonBranches = @('develop', 'main', 'master')
    
    foreach ($branch in $commonBranches) {
        # Check if branch exists locally
        $localExists = git show-ref --verify --quiet "refs/heads/$branch" 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $branch
        }
        
        # Check if branch exists on remote
        $remoteExists = git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>$null
        if ($LASTEXITCODE -eq 0) {
            return "origin/$branch"
        }
    }
    
    # Fall back to remote HEAD if available
    try {
        $remoteHead = git symbolic-ref refs/remotes/origin/HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $remoteHead) {
            return $remoteHead -replace 'refs/remotes/origin/', ''
        }
    } catch {
        # Ignore errors, continue to fallback
    }
    
    # Last resort: use the first branch we can find
    try {
        $firstBranch = git branch -r | Select-Object -First 1 | ForEach-Object { $_.Trim() -replace 'origin/', '' }
        if ($firstBranch) {
            return $firstBranch
        }
    } catch {
        # Ignore errors
    }
    
    # If all else fails, return develop as fallback
    return 'develop'
}

<#
.SYNOPSIS
    Generates a comprehensive PR review file with diff information and statistics.

.DESCRIPTION
    Creates a markdown file containing detailed information about changes between the current branch
    and a target branch (default: develop). Includes commit messages, file changes, statistics, and full diff.

.PARAMETER TargetBranch
    The branch to compare against. Defaults to 'develop'.

.PARAMETER OutputPath
    The directory where the review file will be created. Defaults to current directory.

.PARAMETER IncludePrompt
    Whether to also generate a review prompt template file. Defaults to $true.

.PARAMETER OpenInCursor
    Whether to attempt to open the generated files in Cursor IDE. Defaults to $false.

.PARAMETER CompareUncommitted
    Compare uncommitted changes (staged and unstaged) against the target branch instead of comparing branches. Useful for self-review before committing.

.PARAMETER StagedOnly
    When used with CompareUncommitted, only compare staged changes. Defaults to false (includes both staged and unstaged).

.PARAMETER IncludeNewFiles
    When used with CompareUncommitted, include untracked/new files in the review. Defaults to true.

.EXAMPLE
    New-PRReview
    Generates a review file comparing current branch to develop.

.EXAMPLE
    New-PRReview -TargetBranch "main" -OutputPath "C:\Reviews"
    Generates a review file comparing current branch to main, saving to specified path.

.EXAMPLE
    New-PRReview -IncludePrompt $false
    Generates only the review file without the prompt template.

.EXAMPLE
    New-PRReview -CompareUncommitted
    Reviews uncommitted changes (staged and unstaged) against develop branch.

.EXAMPLE
    New-PRReview -CompareUncommitted -StagedOnly -TargetBranch "main"
    Reviews only staged changes against main branch.

.EXAMPLE
    New-PRReview -CompareUncommitted -IncludeNewFiles $false
    Reviews uncommitted changes without including new/untracked files.
#>
function New-PRReview {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$TargetBranch,
        
        [Parameter()]
        [string]$OutputPath = (Get-Location).Path,
        
        [Parameter()]
        [bool]$IncludePrompt = $true,
        
        [Parameter()]
        [bool]$OpenInCursor = $false,
        
        [Parameter()]
        [switch]$CompareUncommitted,
        
        [Parameter()]
        [switch]$StagedOnly,
        
        [Parameter()]
        [bool]$IncludeNewFiles = $true
    )
    
    begin {
        # Verify we're in a git repository
        try {
            $null = git rev-parse --git-dir 2>$null
        } catch {
            Write-Error "Not in a git repository. Please run this command from within a git repository."
            return
        }
        
        # Verify target branch exists (skip check for uncommitted comparisons as we handle it differently)
        if (-not $CompareUncommitted) {
            $branchExists = git show-ref --verify --quiet "refs/heads/$TargetBranch" 2>$null
            if ($LASTEXITCODE -ne 0) {
                # Try remote branch
                $branchExists = git show-ref --verify --quiet "refs/remotes/origin/$TargetBranch" 2>$null
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "Target branch '$TargetBranch' not found locally or on origin."
                    return
                }
            }
        } else {
            # For uncommitted comparisons, verify the target branch exists
            $localExists = git show-ref --verify --quiet "refs/heads/$TargetBranch" 2>$null
            $remoteExists = git show-ref --verify --quiet "refs/remotes/origin/$TargetBranch" 2>$null
            
            if ($LASTEXITCODE -ne 0 -and $localExists -ne 0 -and $remoteExists -ne 0) {
                Write-Error "Target branch '$TargetBranch' not found. Available branches: $(git branch -a | ForEach-Object { $_.Trim() -replace '^\*\s*', '' } | Where-Object { $_ -ne '' } | Select-Object -First 5 | Join-String -Separator ', ')"
                return
            }
            
            # Use origin/ prefix if only remote exists
            if ($localExists -ne 0 -and $remoteExists -eq 0) {
                $TargetBranch = "origin/$TargetBranch"
            }
        }
    }
    
    process {
        # Set default target branch if not specified
        if (-not $TargetBranch) {
            $TargetBranch = Get-DefaultBranch
            Write-Verbose "Auto-detected target branch: $TargetBranch"
        }
        
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $currentBranch = git branch --show-current
        
        if ($CompareUncommitted) {
            $reviewType = if ($StagedOnly) { "staged" } else { "uncommitted" }
            $reviewFile = Join-Path $OutputPath "code-review_${reviewType}_$timestamp.md"
            Write-Host "Generating review for $reviewType changes against '$TargetBranch'..." -ForegroundColor Green
        } else {
            $reviewFile = Join-Path $OutputPath "code-review_${currentBranch}_$timestamp.md"
            Write-Host "Generating PR review for branch '$currentBranch' against '$TargetBranch'..." -ForegroundColor Green
        }
        
        # Determine git diff parameters based on comparison type
        if ($CompareUncommitted) {
            if ($StagedOnly) {
                $diffParams = @("--staged", $TargetBranch)
                $statusMessage = "staged changes"
            } else {
                $diffParams = @($TargetBranch)
                $statusMessage = "uncommitted changes (staged and unstaged)"
            }
            
            # Add note about new files inclusion
            if ($IncludeNewFiles) {
                $statusMessage += " including new files"
            }
        } else {
            $diffParams = @("$TargetBranch...HEAD")
            $statusMessage = "branch comparison"
        }
        
        # Get basic information
        $latestCommit = git log --oneline -1 HEAD
        $currentDate = Get-Date
        $filesChanged = git diff @diffParams --name-only | Measure-Object -Line | Select-Object -ExpandProperty Lines
        $diffStat = git diff @diffParams --stat
        $fileStatus = git diff @diffParams --name-status
        
        # Get new/untracked files if requested for uncommitted reviews
        $newFiles = @()
        if ($CompareUncommitted -and $IncludeNewFiles) {
            $newFiles = git ls-files --others --exclude-standard
            if ($newFiles) {
                $filesChanged += $newFiles.Count
                Write-Verbose "Found $($newFiles.Count) new/untracked files"
            }
        }
        
        # Check if there are any changes
        if ($filesChanged -eq 0) {
            $changeType = if ($CompareUncommitted) { 
                if ($StagedOnly) { "staged changes" } else { "uncommitted changes" }
            } else { 
                "changes between branches" 
            }
            Write-Warning "No $changeType found."
            return @{
                ReviewFile = $null
                PromptFile = $null
                Branch = $currentBranch
                TargetBranch = $TargetBranch
                FilesChanged = 0
                Status = "No changes found"
            }
        }
        
        # Get commit messages (only for branch comparison)
        if ($CompareUncommitted) {
            $commitMessages = "N/A - Reviewing uncommitted changes"
        } else {
            $commitMessages = git log "$TargetBranch...HEAD" --oneline --reverse
        }
        
        # Create comprehensive review file
        if ($CompareUncommitted) {
            $reviewTitle = if ($StagedOnly) { "Staged Changes Review" } else { "Uncommitted Changes Review" }
            $reviewContent = @"
# $reviewTitle
**Current Branch:** $currentBranch  
**Comparing Against:** $TargetBranch  
**Review Type:** $statusMessage  
**Date:** $currentDate  
**Files Changed:** $filesChanged  

## Summary of Changes
``````
$diffStat
``````

## Status
Reviewing $statusMessage before committing.

## File Changes
"@
        } else {
            $reviewContent = @"
# Code Review: $latestCommit
**Branch:** $currentBranch  
**Target Branch:** $TargetBranch  
**Date:** $currentDate  
**Files Changed:** $filesChanged  

## Summary of Changes
``````
$diffStat
``````

## Commit Messages
``````
$commitMessages
``````

## File Changes
"@
        }

        # Add file status information
        $fileStatus | ForEach-Object {
            $status, $file = $_ -split '\s+', 2
            $statusDescription = switch ($status) {
                'A' { 'Added' }
                'M' { 'Modified' }
                'D' { 'Deleted' }
                'R' { 'Renamed' }
                'C' { 'Copied' }
                'T' { 'Type Changed' }
                default { $status }
            }
            $reviewContent += "`n### $statusDescription : $file"
        }
        
        # Add new/untracked files information
        if ($newFiles) {
            $reviewContent += "`n"
            $newFiles | ForEach-Object {
                $reviewContent += "`n### New (Untracked) : $_"
            }
        }
        
        # Add full diff
        $reviewContent += "`n`n## Full Diff`n``````diff"
        
        # Write initial content
        $reviewContent | Out-File -FilePath $reviewFile -Encoding UTF8
        
        # Append the diff (can be large)
        git diff @diffParams | Add-Content -Path $reviewFile -Encoding UTF8
        
        # Append new files content if any
        if ($newFiles) {
            "`n`n## New Files Content" | Add-Content -Path $reviewFile
            
            $newFiles | ForEach-Object {
                $filePath = $_
                "`n### $filePath" | Add-Content -Path $reviewFile
                "``````" | Add-Content -Path $reviewFile
                
                # Check if file is binary or text
                try {
                    $content = Get-Content -Path $filePath -Raw -ErrorAction Stop
                    if ($content -and $content.Length -gt 0) {
                        # Limit large files to prevent massive review files
                        if ($content.Length -gt 10000) {
                            "# File too large ($($content.Length) characters) - showing first 10000 characters`n" | Add-Content -Path $reviewFile
                            $content.Substring(0, 10000) | Add-Content -Path $reviewFile -Encoding UTF8
                            "`n`n# ... (truncated)" | Add-Content -Path $reviewFile
                        } else {
                            $content | Add-Content -Path $reviewFile -Encoding UTF8
                        }
                    } else {
                        "# Empty file" | Add-Content -Path $reviewFile
                    }
                } catch {
                    "# Unable to read file content (possibly binary): $($_.Exception.Message)" | Add-Content -Path $reviewFile
                }
                
                "``````" | Add-Content -Path $reviewFile
            }
        }
        
        "``````" | Add-Content -Path $reviewFile
        
        Write-Host "Review file created: $reviewFile" -ForegroundColor Cyan
        
        # Generate prompt template if requested
        if ($IncludePrompt) {
            $promptFile = New-ReviewPrompt -OutputPath $OutputPath -Timestamp $timestamp
            Write-Host "Prompt template created: $promptFile" -ForegroundColor Cyan
        }
        
        # Attempt to open in Cursor if requested
        if ($OpenInCursor) {
            try {
                if (Get-Command cursor -ErrorAction SilentlyContinue) {
                    cursor $reviewFile
                    if ($IncludePrompt) {
                        cursor $promptFile
                    }
                    Write-Host "Opened files in Cursor IDE" -ForegroundColor Green
                } else {
                    Write-Warning "Cursor command not found. Please open the files manually."
                }
            } catch {
                Write-Warning "Could not open in Cursor: $($_.Exception.Message)"
            }
        }
        
        return @{
            ReviewFile = $reviewFile
            PromptFile = if ($IncludePrompt) { $promptFile } else { $null }
            Branch = $currentBranch
            TargetBranch = $TargetBranch
            FilesChanged = $filesChanged
            NewFilesFound = if ($CompareUncommitted) { $newFiles.Count } else { 0 }
            NewFiles = if ($CompareUncommitted) { $newFiles } else { @() }
            ReviewType = if ($CompareUncommitted) { 
                if ($StagedOnly) { "StagedChanges" } else { "UncommittedChanges" }
            } else { 
                "BranchComparison" 
            }
            Status = "Success"
        }
    }
}

<#
.SYNOPSIS
    Gets the diff between current branch and target branch.

.DESCRIPTION
    Returns the raw diff output between the current branch and target branch.
    Useful for programmatic access to diff data.

.PARAMETER TargetBranch
    The branch to compare against. Defaults to 'develop'.

.PARAMETER NameOnly
    Return only the names of changed files.

.PARAMETER Stat
    Return diff statistics.

.PARAMETER CompareUncommitted
    Compare uncommitted changes against the target branch instead of comparing branches.

.PARAMETER StagedOnly
    When used with CompareUncommitted, only compare staged changes.

.EXAMPLE
    Get-PRDiff
    Gets full diff against develop branch.

.EXAMPLE
    Get-PRDiff -TargetBranch "main" -NameOnly
    Gets only file names that changed compared to main.

.EXAMPLE
    Get-PRDiff -CompareUncommitted
    Gets uncommitted changes against develop branch.

.EXAMPLE
    Get-PRDiff -CompareUncommitted -StagedOnly -Stat
    Gets statistics for staged changes only.
#>
function Get-PRDiff {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$TargetBranch,
        
        [Parameter()]
        [switch]$NameOnly,
        
        [Parameter()]
        [switch]$Stat,
        
        [Parameter()]
        [switch]$CompareUncommitted,
        
        [Parameter()]
        [switch]$StagedOnly
    )
    
    # Set default target branch if not specified
    if (-not $TargetBranch) {
        $TargetBranch = Get-DefaultBranch
        Write-Verbose "Auto-detected target branch: $TargetBranch"
    }
    
    # Verify target branch exists for uncommitted comparisons
    if ($CompareUncommitted) {
        $localExists = git show-ref --verify --quiet "refs/heads/$TargetBranch" 2>$null
        $remoteExists = git show-ref --verify --quiet "refs/remotes/origin/$TargetBranch" 2>$null
        
        if ($LASTEXITCODE -ne 0 -and $localExists -ne 0 -and $remoteExists -ne 0) {
            Write-Error "Target branch '$TargetBranch' not found. Available branches: $(git branch -a | ForEach-Object { $_.Trim() -replace '^\*\s*', '' } | Where-Object { $_ -ne '' } | Select-Object -First 5 | Join-String -Separator ', ')"
            return
        }
        
        # Use origin/ prefix if only remote exists
        if ($localExists -ne 0 -and $remoteExists -eq 0) {
            $TargetBranch = "origin/$TargetBranch"
        }
    }
    
    # Determine git diff parameters based on comparison type
    if ($CompareUncommitted) {
        if ($StagedOnly) {
            $diffParams = @("--staged", $TargetBranch)
        } else {
            $diffParams = @($TargetBranch)
        }
    } else {
        $diffParams = @("$TargetBranch...HEAD")
    }
    
    # Add additional flags
    if ($NameOnly) {
        $diffParams += "--name-only"
    } elseif ($Stat) {
        $diffParams += "--stat"
    }
    
    return git diff @diffParams
}

<#
.SYNOPSIS
    Creates a review prompt template file.

.DESCRIPTION
    Generates a template file with prompts for conducting thorough code reviews.

.PARAMETER OutputPath
    The directory where the prompt file will be created.

.PARAMETER Timestamp
    Optional timestamp to include in filename.

.EXAMPLE
    New-ReviewPrompt
    Creates a review prompt template in the current directory.
#>
function New-ReviewPrompt {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$OutputPath = (Get-Location).Path,
        
        [Parameter()]
        [string]$Timestamp = (Get-Date -Format "yyyy-MM-dd_HH-mm-ss")
    )
    
    $promptFile = Join-Path $OutputPath "review-prompt-template_$Timestamp.txt"
    
    $promptContent = @"
Please review this code change and provide:

1. **Summary**: Brief overview of what this PR accomplishes

2. **Technical Assessment**: 
   - Code quality and best practices
   - Potential bugs or issues
   - Performance considerations
   - Architecture and design patterns

3. **Security Review**: 
   - Security vulnerabilities or concerns
   - Input validation issues
   - Authentication/authorization impacts

4. **Maintainability**: 
   - Code readability and documentation
   - Adherence to coding standards
   - Refactoring opportunities

5. **Testing**: 
   - Test coverage assessment
   - Edge cases that need testing
   - Integration testing considerations

6. **Breaking Changes**: 
   - Backward compatibility issues
   - API changes that affect consumers
   - Migration requirements

7. **Suggestions**: 
   - Specific improvement recommendations
   - Alternative approaches to consider
   - Best practice recommendations

8. **Questions**: 
   - Areas that need clarification from the author
   - Unclear business logic or requirements

**Focus Areas:**
- Logic errors and edge cases
- Code maintainability and readability
- Adherence to coding standards
- Performance implications
- Security considerations
- Error handling and resilience

**Instructions:**
1. Copy the content from the generated code-review_*.md file
2. Paste it after this prompt
3. Submit to your preferred AI assistant for analysis
4. Review the AI's feedback and add your own insights

---

Here's the code change data:

"@
    
    $promptContent | Out-File -FilePath $promptFile -Encoding UTF8
    return $promptFile
}

# Create aliases for convenience
Set-Alias -Name pr-review -Value New-PRReview
Set-Alias -Name review -Value New-PRReview

# Export functions (this complements the manifest file)
Export-ModuleMember -Function New-PRReview, Get-PRDiff, New-ReviewPrompt, Get-DefaultBranch -Alias pr-review, review 