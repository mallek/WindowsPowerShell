# AICommand Usage Examples

Quick reference guide for common use cases.

## Basic Usage

### Simple Git Operations
```powershell
# Create and push a feature branch
?? create git branch for ticket ABC-123 and push to origin

# Commit all changes
?? commit all changes with message "fix: authentication bug"

# Rebase on main
?? rebase current branch on main
```

### File Searching
```powershell
# Find files by pattern
?? find all typescript files in src directory

# Find files by size
?? list all files larger than 50MB

# Find recent files
?? show files modified in last 3 days
```

### Code Search
```powershell
# Search for patterns
?? find all TODO comments in js files

# Search specific functions
?? find function definitions containing "calculate"

# Search with context
?? grep for error handling in all controllers
```

## Advanced Usage

### Multi-Step Operations
```powershell
# Stash, pull, and pop
?? stash changes, pull from origin, and pop stash

# Install, build, and test
?? npm install then build then run tests

# Clean build
?? clean build artifacts and rebuild project
```

### Git History and Analysis
```powershell
# View commit history
?? show last 10 commits with file changes

# Compare branches
?? show files changed between develop and current branch

# Find commits
?? find commits by author John Doe last month
```

### Docker Operations
```powershell
# Container management
?? stop all running docker containers

# Image operations
?? remove all unused docker images

# Logs
?? show docker logs for container api-server last 100 lines
```

### Process Management
```powershell
# Find and kill
?? kill process using port 3000

# Resource monitoring
?? show top 10 processes by memory usage

# Service management
?? restart IIS service
```

## Execution Modes

### Auto-Execute (Immediate)
```powershell
# Run command without review
?? -Execute npm run build

# Use with caution for destructive operations!
?? -Execute remove node_modules folder
```

### Silent Clipboard Copy
```powershell
# Copy without confirmation message
?? -Copy git log --oneline -10

# Then paste and modify as needed
```

### Interactive Session Mode
```powershell
??!  # Start session

?? create branch
> git checkout -b new-branch

?? no, for ticket XYZ-789
> git checkout -b XYZ-789

?? and switch to it
> git checkout -b XYZ-789

execute  # Run the command
exit     # End session
```

## Provider-Specific Usage

### Using Different AI Providers
```powershell
# Use OpenAI
?? -Provider openai compress all logs to archive

# Use Ollama (local)
?? -Provider ollama -Model llama2 find large files

# Use specific Claude model
?? -Model claude-3-5-sonnet-20241022 optimize this query
```

## Project-Specific Context

### Node.js Projects
When in a directory with `package.json`:
```powershell
?? run tests
# Generates: npm test (because it detects package.json)

?? install dependencies
# Generates: npm install

?? start dev server
# Generates: npm run dev (if "dev" script exists)
```

### .NET Projects
When in a directory with `.csproj` files:
```powershell
?? run tests
# Generates: dotnet test

?? build in release mode
# Generates: dotnet build -c Release

?? publish to folder
# Generates: dotnet publish -o ./publish
```

### Git Repositories
When in a Git repo:
```powershell
?? create branch
# Generates: git checkout -b <branch-name>
# (Includes current branch name in context)

?? push changes
# Generates: git push origin <current-branch>
# (Uses your actual current branch)
```

## Tips and Tricks

### Complex Chains
```powershell
# Backup, modify, test, restore pattern
?? backup database, run migrations, then restore if failed

# CI/CD-like workflow
?? lint code, run tests, build project, then deploy to staging
```

### Conditional Logic
```powershell
# With error handling
?? try to pull latest changes, if conflict then stash first

# Verification
?? check if port 8080 is available, if not kill process
```

### Path Operations
```powershell
# Recursive operations
?? find all package.json files recursively and show their paths

# Archive operations
?? compress all files from last month into archive.zip
```

### Text Processing
```powershell
# Parse and transform
?? extract all email addresses from contacts.txt

# Count and summarize
?? count lines of code in all cs files excluding tests
```

### System Information
```powershell
# Diagnostics
?? show disk usage for all drives

# Network
?? test network latency to google.com

# Services
?? list all running windows services containing "SQL"
```

## Common Patterns

### Daily Workflow
```powershell
# Morning routine
?? pull latest from develop and update dependencies

# Pre-commit check
?? show unstaged changes and run linter

# End of day
?? commit work in progress and push to origin
```

### Code Review Preparation
```powershell
# Generate review materials
?? show all commits since last release

?? compare current branch with develop

?? list all modified files with line counts
```

### Troubleshooting
```powershell
# Debug process
?? show all node processes with ports

# Check resources
?? show memory usage of process named myapp

# Logs analysis
?? tail error log and filter for exceptions
```

## Safety Notes

### Review Before Executing
Always review commands before running, especially:
- File deletions
- System modifications
- Network operations
- Database changes

```powershell
# GOOD - Review first
?? delete all log files older than 90 days
# Review the command, then Ctrl+V to paste

# RISKY - Auto-execute
?? -Execute delete all log files older than 90 days
# Runs immediately!
```

### Use Verbose Mode
```powershell
# See what context is being sent
?? -Verbose create git branch for feature
```

### Test in Safe Environment
```powershell
# Try commands in a test directory first
cd C:\Temp\TestArea
?? complex operation
# Verify it works before using in production
```

## Getting Help

### Show Usage
```powershell
??
# Displays help and options
```

### Check Context
```powershell
Get-SystemContext
# See what information AI will receive
```

### Test Provider
```powershell
Get-Command claude
# Verify provider CLI is installed
```

## Troubleshooting Examples

### Provider Not Found
```powershell
# Check if installed
Get-Command claude

# If not found, install
npm install -g @anthropic-ai/claude-cli
claude configure
```

### Empty Responses
```powershell
# Try with more context
?? -Verbose your command

# Or simpler prompt
?? list files
```

### Clipboard Issues
```powershell
# Use -Execute to avoid clipboard
?? -Execute simple safe command

# Or -Copy for silent copy
?? -Copy your command
```

---

**Pro Tip**: Start simple and build complexity. The AI learns from context, so being in the right directory with proper project files helps!
