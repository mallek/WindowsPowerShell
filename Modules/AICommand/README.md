# AICommand PowerShell Module

AI-powered CLI command generation using Claude or other LLMs. Transform natural language descriptions into executable commands with intelligent context awareness.

## Overview

The AICommand module brings AI-powered command generation to PowerShell, allowing you to describe what you want to do in plain English and get the exact command you need. It's context-aware, understanding your Git repository state, project type, and operating system.

## Features

- **Natural Language to Commands**: Describe what you want, get the command
- **PowerShell-Native**: Generates proper PowerShell syntax (not bash/Linux commands)
  - Automatically detects PowerShell version (5.x uses `;`, 7+ supports `&&`)
  - Uses PowerShell cmdlets (Get-ChildItem, Remove-Item, etc.)
  - Proper PowerShell quoting and operators
- **Context-Aware**: Automatically detects Git repos, project types (Node.js, .NET, Python), and system state
- **Multiple AI Providers**: Support for Claude, OpenAI, Anthropic, and Ollama
- **Flexible Output Modes**:
  - Default: Copy to clipboard
  - `-Execute`: Run immediately
  - `-Copy`: Silent clipboard copy
  - `-Interactive`: Replace prompt text (experimental)
- **Session Mode**: Conversational command refinement with `??!`
- **Smart Integration**: Works seamlessly with your PowerShell profile

## Prerequisites

### Claude Code CLI (Default)

This is the Claude CLI that comes with Claude Code IDE integration.

```powershell
# Usually installed automatically with Claude Code
# Check if available:
Get-Command claude
```

### Alternative Providers

- **GitHub Copilot** (Recommended if you have GitHub Copilot):
  ```powershell
  # Install GitHub CLI first (if not already installed)
  winget install GitHub.cli

  # Authenticate
  gh auth login

  # Install Copilot extension
  gh extension install github/gh-copilot
  ```

- **OpenAI**: `pip install openai-cli`
- **Anthropic**: `pip install anthropic-cli`
- **Ollama** (Local, free): [Download from ollama.ai](https://ollama.ai/download)

## Installation

The module should be installed in your PowerShell Modules directory:

```
C:\Users\<username>\Documents\WindowsPowerShell\Modules\AICommand\
```

Add to your `profile.ps1`:

```powershell
Import-Module AICommand
```

## Usage

### Basic Command Generation

The `??` alias is your gateway to AI-powered commands:

```powershell
# Git operations
?? create git branch for vv-1123 and push it to origin
# Generates: git checkout -b vv-1123 && git push -u origin vv-1123

# File operations
?? find all js files modified in last week
# Generates: git log --since="1 week ago" --name-only --pretty=format: | grep '\.js$' | sort -u

# Complex chains
?? compress all log files older than 30 days to archive folder
# Generates appropriate command for your OS
```

### Execution Modes

#### Default: Clipboard Copy
```powershell
?? list all running processes by memory usage
# Command copied to clipboard - press Ctrl+V to paste
```

#### Auto-Execute (Use with Caution!)
```powershell
?? -Execute npm install and start dev server
# Immediately runs: npm install && npm run dev
```

#### Silent Clipboard
```powershell
?? -Copy git rebase interactive last 5 commits
# Copies to clipboard without message
```

### Session Mode

For iterative command refinement:

```powershell
??!  # Start interactive session

?? create a new git branch
> git checkout -b new-branch

?? no, include the ticket number ABC-123
> git checkout -b ABC-123-new-branch

?? and push it
> git checkout -b ABC-123-new-branch && git push -u origin ABC-123-new-branch

execute  # Run the last command
exit     # End session
```

Session commands:
- `execute`, `run`, `x` - Execute the last generated command
- `exit`, `quit`, `q` - Exit session mode

### Advanced Options

```powershell
# Use GitHub Copilot
?? -Provider copilot list all docker containers

# Use Ollama (local)
?? -Provider ollama list all running processes

# Use a specific model
?? -Provider copilot -Model gpt-5 optimize this query

# Get detailed output
?? -Verbose find large files over 100MB
```

## PowerShell Syntax

**Important**: This module generates **PowerShell commands**, not bash/Linux commands. It automatically adapts to your PowerShell version:

### PowerShell 5.x (Your Version)
- Uses `;` to chain multiple commands
- Example: `git add . ; git commit -m "message" ; git push`

### PowerShell 7+
- Supports both `;` and `&&` operators
- Example: `git add . && git commit -m "message" && git push`

### What This Means
The AI will generate commands like:
```powershell
# ✓ CORRECT - PowerShell syntax
Get-ChildItem -Filter "*.txt" | Remove-Item
git add . ; git commit -m "Update files" ; git push origin master

# ✗ WRONG - bash/Linux syntax (will cause errors)
find . -name "*.txt" -delete
git add . && git commit -m "Update files" && git push origin master
```

If you see `&&` in the output and get an error, the AI didn't follow instructions. Simply try again or use session mode (`??!`) to refine the command.

## Context Detection

The module automatically gathers context to improve command generation:

### Git Repository Context
- Current branch name
- Number of changed files
- Remote origin URL
- Repository state

### Project Type Detection
- **Node.js**: Detects `package.json`, lists available npm scripts
- **.NET**: Detects `.csproj` files
- **Python**: Detects `requirements.txt`, `setup.py`, `pyproject.toml`

### System Information
- Operating system (Windows/Linux/macOS)
- PowerShell version
- Current working directory

## Examples

### Git Workflows

```powershell
# Branch management
?? create feature branch for ticket XYZ-456
?? switch to main branch and pull latest changes
?? delete local branch feature/old-feature

# Commit operations
?? commit all changes with message "fix: resolve auth issue"
?? amend last commit to include new files
?? cherry pick commit abc123 to current branch

# History and logs
?? show commit history for src/auth.js last month
?? show files changed between develop and current branch
```

### File Operations

```powershell
# Search and find
?? find all TODO comments in js and ts files
?? list files larger than 10MB in current directory
?? search for function named calculateTotal in all cs files

# Bulk operations
?? rename all .txt files to .md in current folder
?? move all log files to archive/logs directory
?? delete empty directories recursively
```

### Development Tasks

```powershell
# Node.js/npm
?? install dev dependencies and run tests
?? update all outdated npm packages
?? run build and deploy to staging

# .NET
?? build solution in release mode
?? run all unit tests with coverage
?? publish project to folder bin/publish

# Docker
?? build docker image with tag v1.2.3
?? start all docker containers in compose file
?? show logs for container api-server last hour
```

### System Administration

```powershell
# Process management
?? kill process using port 3000
?? list top 10 processes by CPU usage
?? restart service named "MyAppService"

# Network
?? show all listening ports
?? test connection to api.example.com port 443
?? clear DNS cache
```

## Function Reference

### `Invoke-AICommand` (Alias: `??`)

Generate commands from natural language descriptions.

**Parameters:**
- `Prompt` - What you want to accomplish (positional, required)
- `Provider` - AI provider: claude, copilot, openai, anthropic, ollama (default: claude)
- `Model` - Specific model to use (provider-specific, e.g., 'gpt-5' for copilot)
- `Execute` - Run command immediately
- `Copy` - Copy to clipboard silently
- `Interactive` - Replace prompt text (experimental)
- `SystemContext` - Include system context (default: true)

### `Start-AICommandSession` (Alias: `??!`)

Start an interactive session for command refinement.

**Parameters:**
- `Provider` - AI provider to use (default: claude)

### `Get-SystemContext`

Get current system context information. Useful for debugging or understanding what context is being sent to the AI.

```powershell
Get-SystemContext
# Returns:
# OS: Windows
# Shell: PowerShell 7.4.0
# Current Directory: C:\Projects\MyApp
# Git Branch: feature/new-feature
# Git Status: 3 file(s) with changes
# Node.js Project: Detected (package.json exists)
# Available npm scripts: start, test, build, dev
```

### `Set-AICommandConfig`

Configure default provider and model preferences.

**Parameters:**
- `Provider` - Default AI provider: claude, copilot, openai, anthropic, ollama
- `Model` - Default model name (optional, provider-specific)
- `Clear` - Reset configuration to defaults

**Examples:**
```powershell
# Set default provider
Set-AICommandConfig -Provider copilot

# Set provider with specific model
Set-AICommandConfig -Provider copilot -Model gpt-4

# Update just the model (keeps existing provider)
Set-AICommandConfig -Model claude-3-5-sonnet-20241022

# Reset to defaults
Set-AICommandConfig -Clear
```

### `Get-AICommandConfig`

View current configuration settings.

**Returns:** Hashtable with Provider and Model keys

**Examples:**
```powershell
# Display current config
Get-AICommandConfig

# Use in scripts
$config = Get-AICommandConfig
if ($config.Provider -eq 'ollama') {
    Write-Host "Using local Ollama provider"
}
```

## Configuration

The module provides a built-in configuration system to set default provider and model preferences. This eliminates the need to type `-Provider` and `-Model` flags every time.

### Setting Default Provider and Model

Use `Set-AICommandConfig` to configure your defaults:

```powershell
# Set GitHub Copilot as default provider
Set-AICommandConfig -Provider copilot

# Set Copilot with a specific model
Set-AICommandConfig -Provider copilot -Model gpt-4

# Set Ollama with llama2 as defaults
Set-AICommandConfig -Provider ollama -Model llama2

# Set Claude with a specific model
Set-AICommandConfig -Provider claude -Model claude-3-5-sonnet-20241022
```

After setting defaults, you can use `??` without flags:

```powershell
# Uses your configured default provider/model
?? create git branch for feature-123

# Override for a single command if needed
?? -Provider claude list all docker containers
```

### Viewing Current Configuration

Check your current settings:

```powershell
Get-AICommandConfig
# Returns:
# Provider: copilot
# Model: gpt-4
```

Or inline:

```powershell
$config = Get-AICommandConfig
Write-Host "Using provider: $($config.Provider)"
```

### Resetting to Defaults

Clear your configuration and return to built-in defaults (claude):

```powershell
Set-AICommandConfig -Clear
```

### Configuration File Location

Settings are stored in a JSON file at:
```
C:\Users\<username>\.aicommand.config.json
```

You can manually edit this file if needed, but using `Set-AICommandConfig` is recommended.

### Legacy Configuration (Alternative Method)

You can also create a wrapper function in your profile for customization:

```powershell
# Use GitHub Copilot by default
function ?? {
    Invoke-AICommand -Provider copilot @args
}

# Or use Ollama (local, free)
function ?? {
    Invoke-AICommand -Provider ollama @args
}
```

**Note:** The built-in configuration system (`Set-AICommandConfig`) is the preferred method as it doesn't require profile modifications.

### Disable System Context

If you want faster responses without context:

```powershell
?? -SystemContext $false your command description here
```

## Tips and Best Practices

1. **Be Specific**: More details lead to better commands
   - Good: `?? create git branch for ticket ABC-123 with feature prefix`
   - Better: The above is specific enough

2. **Review Before Executing**: Always review generated commands before running with `-Execute`

3. **Use Session Mode**: For complex or multi-step tasks, use `??!` to refine iteratively

4. **Leverage Context**: The AI knows your Git state and project type - use it!
   ```powershell
   # In a Node.js project with package.json
   ?? run tests
   # Generates: npm test

   # In a .NET project with .csproj
   ?? run tests
   # Generates: dotnet test
   ```

5. **Chain Commands**: Ask for complex workflows
   ```powershell
   ?? stash changes, pull latest from main, pop stash, and check status
   ```

6. **Safety First**: Be cautious with:
   - File deletions
   - System modifications
   - Network operations
   - Always review destructive commands

## Troubleshooting

### "AI provider not found"

Ensure the CLI tool is installed and in your PATH:

```powershell
# Test if claude is available
Get-Command claude

# If not found, reinstall
npm install -g @anthropic-ai/claude-cli
```

### "Failed to generate command"

- Check your API key configuration: `claude configure`
- Verify internet connectivity
- Try with `-Verbose` to see detailed errors
- Check provider-specific authentication

### Commands not context-aware

- Ensure you're in the correct directory
- Verify Git repository is initialized
- Check that project files (package.json, etc.) exist
- Use `Get-SystemContext` to see what context is detected

### PowerShell version issues

The module requires PowerShell 5.1 or later:

```powershell
$PSVersionTable.PSVersion
# Should be 5.1 or higher
```

## Security Considerations

- **API Keys**: Protect your API keys - never commit them to version control
- **Command Review**: Always review generated commands, especially with `-Execute`
- **Context Sharing**: System context is sent to the AI provider - be aware of sensitive information
- **Skip Permissions Flag**: The module uses `--dangerously-skip-permissions` for Claude CLI convenience
- **Untrusted Input**: Don't use this module with untrusted or malicious prompts

## Limitations

- Requires internet connection and AI provider access
- Command quality depends on the AI model used
- May not understand very domain-specific or niche tools
- Interactive mode (`-Interactive`) is experimental
- Cost considerations for API usage (check your provider's pricing)

## Contributing

To extend or modify the module:

1. Edit `AICommand.psm1` for core functionality
2. Update `AICommand.psd1` manifest for version/metadata
3. Test with `Import-Module -Force`
4. Reload profile: `. $PROFILE` or use the `source` function

## Version History

### 1.0.0 (Initial Release)
- AI-powered command generation from natural language
- Support for Claude, OpenAI, Anthropic, Ollama
- Automatic context detection (OS, Git, Projects)
- Multiple output modes: clipboard, execute, interactive
- Session mode for conversational refinement
- Context awareness for Git and project types

## License

Personal use - Travis Haley

## Acknowledgments

- Inspired by GitHub Copilot CLI and other AI command assistants
- Built for the Windows PowerShell environment
- Powered by Claude AI and compatible with multiple LLM providers

## Support

For issues, suggestions, or contributions:
1. Test with `-Verbose` for detailed errors
2. Check the troubleshooting section
3. Verify prerequisites are installed
4. Review provider-specific documentation

## Related Modules

- **PRReview**: Generate comprehensive PR review files
- **StreamUtils**: Unix-like stream processing utilities
- **StringUtils**: String manipulation helpers

---

**Happy command generating! 🚀**
