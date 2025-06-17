# PRReview PowerShell Module

A comprehensive PowerShell module for generating detailed code review reports from Git diffs, designed to facilitate thorough PR reviews with AI assistance.

## Features

- **Comprehensive Review Reports**: Generates markdown files with commit history, file changes, statistics, and full diffs
- **Smart Branch Detection**: Automatically detects the main branch (develop → main → master → remote HEAD)
- **Review Prompt Templates**: Creates structured prompts for AI-assisted code reviews
- **Cursor IDE Integration**: Optional automatic opening of generated files in Cursor
- **Multiple Output Options**: Supports different output paths and file naming conventions

## Installation

The module is already installed in your PowerShell Modules directory. To use it in your PowerShell session:

```powershell
Import-Module PRReview
```

To auto-load the module in all PowerShell sessions, add the import command to your PowerShell profile.

## Functions

### New-PRReview

Main function that generates comprehensive PR review files.

**Parameters:**
- `TargetBranch` (string): Branch to compare against (auto-detects: develop → main → master → remote HEAD)
- `OutputPath` (string): Output directory (default: current directory)
- `IncludePrompt` (bool): Generate prompt template (default: true)
- `OpenInCursor` (bool): Open files in Cursor IDE (default: false)
- `CompareUncommitted` (switch): Compare uncommitted changes against target branch
- `StagedOnly` (switch): When used with CompareUncommitted, only review staged changes
- `IncludeNewFiles` (bool): When used with CompareUncommitted, include new/untracked files (default: true)

**Examples:**
```powershell
# Basic usage - compare current branch to develop
New-PRReview

# Compare to different branch
New-PRReview -TargetBranch "main"

# Specify output directory and open in Cursor
New-PRReview -OutputPath "C:\Reviews" -OpenInCursor $true

# Just generate review file without prompt template
New-PRReview -IncludePrompt $false

# Review uncommitted changes (staged and unstaged) against develop
New-PRReview -CompareUncommitted

# Review only staged changes against main branch
New-PRReview -CompareUncommitted -StagedOnly -TargetBranch "main"

# Review uncommitted work and open in Cursor for immediate analysis
New-PRReview -CompareUncommitted -OpenInCursor $true

# Review uncommitted changes without including new/untracked files
New-PRReview -CompareUncommitted -IncludeNewFiles $false

# Review only staged changes including any new files that are staged
New-PRReview -CompareUncommitted -StagedOnly -IncludeNewFiles $true
```

**Aliases:**
- `pr-review`
- `review`

### Get-PRDiff

Helper function to get raw diff data programmatically.

**Parameters:**
- `TargetBranch` (string): Branch to compare against (auto-detects: develop → main → master → remote HEAD)
- `NameOnly` (switch): Return only changed file names
- `Stat` (switch): Return diff statistics only
- `CompareUncommitted` (switch): Compare uncommitted changes against target branch
- `StagedOnly` (switch): When used with CompareUncommitted, only compare staged changes

**Examples:**
```powershell
# Get full diff
Get-PRDiff

# Get only changed file names
Get-PRDiff -NameOnly

# Get diff statistics
Get-PRDiff -Stat

# Compare to main branch
Get-PRDiff -TargetBranch "main"

# Get uncommitted changes (staged and unstaged)
Get-PRDiff -CompareUncommitted

# Get only staged changes as statistics
Get-PRDiff -CompareUncommitted -StagedOnly -Stat

# Get file names of uncommitted changes
Get-PRDiff -CompareUncommitted -NameOnly
```

### New-ReviewPrompt

Creates a structured prompt template for AI-assisted code reviews.

**Parameters:**
- `OutputPath` (string): Output directory (default: current directory)
- `Timestamp` (string): Optional timestamp for filename

**Example:**
```powershell
New-ReviewPrompt -OutputPath "C:\Reviews"
```

### Get-DefaultBranch

Helper function that automatically detects the default/main branch for the repository.

**Description:**
Attempts to determine the default branch by checking common branch names in order:
1. `develop` (locally, then remote)
2. `main` (locally, then remote)  
3. `master` (locally, then remote)
4. Remote HEAD
5. First available remote branch

**Example:**
```powershell
# Check what branch will be used as default
Get-DefaultBranch
```

## Usage Workflows

### Self-Review Workflow (Before Committing)
1. **Make your changes** (edit files, stage some changes if desired)
2. **Generate review of uncommitted work:**
   ```powershell
   # Review all uncommitted changes
   New-PRReview -CompareUncommitted
   
   # Or review only staged changes
   New-PRReview -CompareUncommitted -StagedOnly
   ```
3. **Review the generated files:**
   - `code-review_uncommitted_[timestamp].md` or `code-review_staged_[timestamp].md`
   - `review-prompt-template_[timestamp].txt`
4. **Refine your changes** based on the review
5. **Commit when satisfied**

### PR Review Workflow
1. **Navigate to your Git repository**
2. **Switch to the branch you want to review**
3. **Generate the review files:**
   ```powershell
   New-PRReview
   ```
4. **Review the generated files:**
   - `code-review_[branch]_[timestamp].md` - Contains the comprehensive diff and change information
   - `review-prompt-template_[timestamp].txt` - Contains the structured prompt for AI review

### AI-Assisted Review
- Copy the content from the review markdown file
- Paste it into the prompt template
- Submit to your preferred AI assistant (ChatGPT, Claude, etc.)
- Use Cursor's built-in AI features with the generated files

## Output Files

### Review File Format
```markdown
# Code Review: [latest commit]
**Branch:** [current branch]
**Target Branch:** [target branch]
**Date:** [timestamp]
**Files Changed:** [count]

## Summary of Changes
[git diff --stat output]

## Commit Messages
[commit history]

## File Changes
### Added/Modified/Deleted : [filename]
### New (Untracked) : [new filename]

## Full Diff
```diff
[complete diff output]
```

## New Files Content
### [new filename]
```
[complete file content]
```

### Prompt Template
The generated prompt template includes structured sections for:
- Summary
- Technical Assessment
- Security Review
- Maintainability
- Testing
- Breaking Changes
- Suggestions
- Questions

## Integration with Cursor IDE

If you have Cursor IDE installed, you can automatically open the generated files:

```powershell
New-PRReview -OpenInCursor $true
```

This will:
1. Generate the review files
2. Open them in Cursor IDE
3. Allow you to use Cursor's AI features for additional analysis

## Common Use Cases

### Self-Review Before Committing
```powershell
# Review all uncommitted changes (staged and unstaged) against develop
New-PRReview -CompareUncommitted

# Review only staged changes before committing
New-PRReview -CompareUncommitted -StagedOnly

# Quick check of what files you've modified
Get-PRDiff -CompareUncommitted -NameOnly

# See statistics of your uncommitted work
Get-PRDiff -CompareUncommitted -Stat

# Review including new files you've created
New-PRReview -CompareUncommitted -IncludeNewFiles $true

# Review without new files (only changes to existing files)
New-PRReview -CompareUncommitted -IncludeNewFiles $false
```

### Standard PR Review
```powershell
# Switch to your feature branch
git checkout feature/new-feature

# Generate review against develop
New-PRReview
```

### Release Review
```powershell
# Compare release branch to main
New-PRReview -TargetBranch "main" -OutputPath "C:\Releases"
```

### Quick File Analysis
```powershell
# Just see what files changed
Get-PRDiff -NameOnly

# Get diff statistics
Get-PRDiff -Stat
```

## Tips

1. **Self-Review Early**: Use `-CompareUncommitted` frequently to catch issues before committing
2. **Staged vs Unstaged**: Use `-StagedOnly` to review just what you're about to commit
3. **Large Diffs**: For large changes, consider reviewing file-by-file rather than the entire diff at once
4. **Branch Naming**: The module includes the branch name in the output filename for easy identification
5. **Timestamp**: All files include timestamps to avoid conflicts and track review history
6. **AI Integration**: The structured prompt template works well with various AI assistants
7. **Cursor Features**: Use Cursor's codebase chat feature along with the generated files for deeper analysis
8. **Quick Checks**: Use `Get-PRDiff -CompareUncommitted -NameOnly` for a quick overview of modified files
9. **Iterative Review**: Review uncommitted changes, refine code, review again before committing
10. **Branch Detection**: The module automatically detects your main branch, but you can always override with `-TargetBranch`
11. **New Files**: By default, new/untracked files are included in uncommitted reviews - use `-IncludeNewFiles $false` to exclude them
12. **Large Files**: New files over 10,000 characters are automatically truncated in the review to keep file sizes manageable

## Requirements

- PowerShell 5.0 or later
- Git repository
- Git command-line tools
- Optional: Cursor IDE for enhanced integration

## Troubleshooting

- **"Not in a git repository"**: Ensure you're running the command from within a Git repository
- **"Target branch not found"**: The module auto-detects branches, but you can check available branches with `git branch -a`
- **"Unknown revision develop/main/master"**: Use `Get-DefaultBranch` to see what branch is detected, or specify `-TargetBranch` explicitly
- **"Cursor command not found"**: Install Cursor IDE or set `OpenInCursor` to `$false` 