#
# AICommand PowerShell Module
# Author: Travis Haley
# Description: AI-powered CLI command generation using Claude or other LLMs
#

# Configuration file path
$script:ConfigPath = Join-Path $env:USERPROFILE ".aicommand.config.json"

<#
.SYNOPSIS
    Generate CLI commands using AI assistance with prompt replacement.

.DESCRIPTION
    The ?? function allows you to describe what you want to do in natural language,
    and it will use Claude AI (or other LLMs) to generate the appropriate command.
    The generated command replaces your prompt text on the command line, ready to execute.

    This function integrates with the 'claude' CLI tool to provide intelligent
    command suggestions based on your current context, Git repository state,
    operating system, and shell environment.

.PARAMETER Prompt
    Natural language description of what you want to accomplish.
    Can be provided as individual arguments that will be joined.

.PARAMETER Provider
    The AI provider to use. Options: 'claude', 'openai', 'anthropic'
    Default: 'claude'

.PARAMETER Model
    Specific model to use (provider-specific).
    Examples: 'claude-3-5-sonnet-20241022', 'gpt-4', etc.

.PARAMETER Execute
    Automatically execute the generated command without confirmation.
    Use with caution!

.PARAMETER Copy
    Copy the generated command to clipboard instead of replacing prompt text.

.PARAMETER Verbose
    Show detailed information about the command generation process.

.PARAMETER SystemContext
    Include additional system context (current directory, git status, etc.)
    Default: $true

.EXAMPLE
    ?? create git branch for vv-1123 and push it to origin

    Generates: git checkout -b vv-1123 && git push -u origin vv-1123

.EXAMPLE
    ?? find all js files modified in last week

    Generates: git log --since="1 week ago" --name-only --pretty=format: | grep '\.js$' | sort | unique

.EXAMPLE
    ?? -Execute npm install and start dev server

    Generates and immediately executes: npm install && npm run dev

.EXAMPLE
    ?? -Copy compress all log files older than 30 days

    Generates command and copies to clipboard without executing

.NOTES
    Requires 'claude' CLI tool to be installed and configured.
    Install: npm install -g @anthropic-ai/claude-cli
    Configure: claude configure
#>
function Invoke-AICommand {
    [CmdletBinding()]
    [Alias('??')]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [string[]]$Prompt,

        [Parameter()]
        [ValidateSet('claude', 'openai', 'anthropic', 'ollama', 'copilot')]
        [string]$Provider,

        [Parameter()]
        [string]$Model,

        [Parameter()]
        [switch]$Execute,

        [Parameter()]
        [switch]$Copy,

        [Parameter()]
        [switch]$Interactive,

        [Parameter()]
        [bool]$SystemContext = $true
    )

    # Load configuration defaults
    $config = Get-AICommandConfig

    # Use config defaults if parameters not explicitly provided
    if (-not $PSBoundParameters.ContainsKey('Provider')) {
        $Provider = $config.Provider
    }

    if (-not $PSBoundParameters.ContainsKey('Model') -and $config.Model) {
        $Model = $config.Model
    }

    # Join prompt arguments into a single string
    $promptText = $Prompt -join ' '

    if ([string]::IsNullOrWhiteSpace($promptText)) {
        Write-Host "Usage: ?? <what you want to do>" -ForegroundColor Yellow
        Write-Host "Example: ?? create git branch for vv-1123 and push it to origin" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Options:" -ForegroundColor Green
        Write-Host "  -Execute          Automatically run the generated command" -ForegroundColor Gray
        Write-Host "  -Copy             Copy command to clipboard" -ForegroundColor Gray
        Write-Host "  -Interactive      Use interactive mode (experimental)" -ForegroundColor Gray
        Write-Host "  -Provider <name>  Use specific AI provider (claude|openai|anthropic|ollama|copilot)" -ForegroundColor Gray
        Write-Host "  -Model <name>     Use specific model" -ForegroundColor Gray
        return
    }

    # Check if provider CLI is available
    $providerCommand = Get-ProviderCommand -Provider $Provider
    if (-not $providerCommand) {
        Write-Error "AI provider '$Provider' CLI not found. Please install it first."
        Write-Host ""
        Write-Host "Installation instructions:" -ForegroundColor Yellow
        switch ($Provider) {
            'claude' {
                Write-Host "  npm install -g @anthropic-ai/claude-cli" -ForegroundColor Cyan
                Write-Host "  claude configure" -ForegroundColor Cyan
            }
            'openai' {
                Write-Host "  pip install openai-cli" -ForegroundColor Cyan
            }
            'anthropic' {
                Write-Host "  pip install anthropic-cli" -ForegroundColor Cyan
            }
            'ollama' {
                Write-Host "  Visit: https://ollama.ai/download" -ForegroundColor Cyan
            }
            'copilot' {
                Write-Host "  GitHub CLI: gh auth login" -ForegroundColor Cyan
                Write-Host "  Copilot: gh extension install github/gh-copilot" -ForegroundColor Cyan
            }
        }
        return
    }

    # Build system context
    $context = ""
    if ($SystemContext) {
        $context = Get-SystemContext
    }

    # Build the full prompt with system context
    $fullPrompt = Build-CommandPrompt -UserPrompt $promptText -Context $context

    Write-Verbose "Generating command for: $promptText"
    if ($VerbosePreference -eq 'Continue') {
        Write-Host "Context:" -ForegroundColor DarkGray
        Write-Host $context -ForegroundColor DarkGray
    }

    # Generate command using AI provider
    try {
        $generatedCommand = Invoke-ProviderCommand -Provider $Provider -Prompt $fullPrompt -Model $Model

        if ([string]::IsNullOrWhiteSpace($generatedCommand)) {
            Write-Error "Failed to generate command. The AI returned an empty response."
            return
        }

        # Clean up the generated command
        $generatedCommand = $generatedCommand.Trim()

        # Remove markdown code blocks if present
        if ($generatedCommand -match '^```(?:powershell|bash|sh)?\s*\n(.*)\n```$') {
            $generatedCommand = $matches[1].Trim()
        }

        Write-Host ""
        Write-Host "Generated command:" -ForegroundColor Green
        Write-Host $generatedCommand -ForegroundColor Cyan
        Write-Host ""

        # Handle different output modes
        if ($Copy) {
            Set-Clipboard -Value $generatedCommand
            Write-Host "Command copied to clipboard!" -ForegroundColor Green
        }
        elseif ($Execute) {
            Write-Host "Executing..." -ForegroundColor Yellow
            Invoke-Expression $generatedCommand
        }
        elseif ($Interactive) {
            # Use PSReadLine to replace the current command line
            [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($generatedCommand)
        }
        else {
            # Default: Copy to clipboard and inform user
            Set-Clipboard -Value $generatedCommand
            Write-Host "Command copied to clipboard! Press Ctrl+V to paste and execute." -ForegroundColor Green
            Write-Host "Tip: Use '-Execute' to run immediately or '-Copy' to suppress this message." -ForegroundColor DarkGray
        }

    } catch {
        Write-Error "Error generating command: $($_.Exception.Message)"
        Write-Verbose $_.Exception.StackTrace
    }
}

<#
.SYNOPSIS
    Get the command for the specified AI provider.

.DESCRIPTION
    Returns the CLI command name for the specified provider if it's available.
#>
function Get-ProviderCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Provider
    )

    $commands = @{
        'claude'     = 'claude'
        'openai'     = 'openai'
        'anthropic'  = 'anthropic'
        'ollama'     = 'ollama'
        'copilot'    = 'copilot'
    }

    $commandName = $commands[$Provider]
    if (-not $commandName) {
        return $null
    }

    if (Get-Command $commandName -ErrorAction SilentlyContinue) {
        return $commandName
    }

    return $null
}

<#
.SYNOPSIS
    Invoke the AI provider's CLI with the given prompt.

.DESCRIPTION
    Executes the appropriate CLI command for the specified provider.
#>
function Invoke-ProviderCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Provider,

        [Parameter(Mandatory = $true)]
        [string]$Prompt,

        [Parameter()]
        [string]$Model
    )

    $output = ""

    switch ($Provider) {
        'claude' {
            # Use Claude Code CLI with print mode
            try {
                $args = @(
                    '--print',  # Print mode for non-interactive use
                    '--dangerously-skip-permissions'  # Skip permission prompts
                )

                if ($Model) {
                    $args += @('--model', $Model)
                }

                # Add the prompt as the last argument
                $args += $Prompt

                $output = & claude @args 2>&1 | Out-String
            } catch {
                throw "Failed to invoke Claude CLI: $($_.Exception.Message). Try using -Provider ollama or install Ollama for local AI."
            }
        }
        'openai' {
            $args = @('complete')
            if ($Model) {
                $args += @('--model', $Model)
            }
            $args += @('--prompt', $Prompt)

            $output = & openai @args 2>&1 | Out-String
        }
        'anthropic' {
            $args = @('complete')
            if ($Model) {
                $args += @('--model', $Model)
            }
            $args += @('--prompt', $Prompt)

            $output = & anthropic @args 2>&1 | Out-String
        }
        'ollama' {
            $args = @('run')
            if ($Model) {
                $args += $Model
            } else {
                $args += 'llama2'
            }
            $args += $Prompt

            $output = & ollama @args 2>&1 | Out-String
        }
        'copilot' {
            # Use GitHub Copilot CLI
            try {
                $args = @('--allow-all-tools', '-p')

                if ($Model) {
                    $args = @('--model', $Model) + $args
                }

                # Add the prompt as the last argument
                $args += $Prompt

                $output = & copilot @args 2>&1 | Out-String
            } catch {
                throw "Failed to invoke GitHub Copilot CLI: $($_.Exception.Message). Make sure gh-copilot extension is installed."
            }
        }
        default {
            throw "Unsupported provider: $Provider"
        }
    }

    return $output.Trim()
}

<#
.SYNOPSIS
    Build system context for better command generation.

.DESCRIPTION
    Gathers information about the current environment to provide context to the AI.
#>
function Get-SystemContext {
    [CmdletBinding()]
    param()

    $context = @()

    # Operating System
    $os = if ($IsWindows) { "Windows" } elseif ($IsLinux) { "Linux" } elseif ($IsMacOS) { "macOS" } else { "Windows" }
    $context += "OS: $os"

    # Shell
    $context += "Shell: PowerShell $($PSVersionTable.PSVersion)"

    # Current Directory
    $currentDir = (Get-Location).Path
    $context += "Current Directory: $currentDir"

    # Git Repository Context
    $isGitRepo = Test-Path ".git" -ErrorAction SilentlyContinue
    if (-not $isGitRepo) {
        # Check if we're in a subdirectory of a git repo
        try {
            git rev-parse --git-dir 2>&1 | Out-Null
            $isGitRepo = $LASTEXITCODE -eq 0
        } catch {
            $isGitRepo = $false
        }
    }

    if ($isGitRepo) {
        try {
            $branch = git branch --show-current 2>$null
            if ($branch) {
                $context += "Git Branch: $branch"
            }

            $status = git status --short 2>$null
            if ($status) {
                $statusCount = ($status | Measure-Object).Count
                $context += "Git Status: $statusCount file(s) with changes"
            }

            $remote = git remote get-url origin 2>$null
            if ($remote) {
                $context += "Git Remote: $remote"
            }
        } catch {
            # Ignore git errors
        }
    }

    # Node.js project context
    if (Test-Path "package.json") {
        $context += "Node.js Project: Detected (package.json exists)"
        try {
            $packageJson = Get-Content "package.json" -Raw | ConvertFrom-Json
            if ($packageJson.scripts) {
                $scriptNames = ($packageJson.scripts | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) -join ', '
                $context += "Available npm scripts: $scriptNames"
            }
        } catch {
            # Ignore parsing errors
        }
    }

    # .NET project context
    $csprojFiles = Get-ChildItem -Filter "*.csproj" -ErrorAction SilentlyContinue
    if ($csprojFiles) {
        $context += ".NET Project: Detected ($($csprojFiles.Count) .csproj file(s))"
    }

    # Python project context
    if ((Test-Path "requirements.txt") -or (Test-Path "setup.py") -or (Test-Path "pyproject.toml")) {
        $context += "Python Project: Detected"
    }

    return $context -join "`n"
}

<#
.SYNOPSIS
    Build the complete prompt for command generation.

.DESCRIPTION
    Combines the user's request with system context and instructions.
#>
function Build-CommandPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserPrompt,

        [Parameter()]
        [string]$Context
    )

    # Detect PowerShell version to determine proper syntax
    $psVersion = $PSVersionTable.PSVersion.Major
    $commandSeparator = if ($psVersion -ge 7) { "&&" } else { ";" }

    $systemInstructions = @"
You are a PowerShell command generator. Your job is to generate a single, executable PowerShell command based on the user's request.

CRITICAL POWERSHELL SYNTAX RULES:
1. Return ONLY the PowerShell command - no explanations, no markdown, no additional text
2. This is PowerShell $psVersion - you MUST use PowerShell syntax, NOT bash/Linux syntax
3. For chaining multiple commands, use '$commandSeparator' as the separator (NOT '&&' unless PowerShell 7+)
4. Use PowerShell cmdlets when available (Get-ChildItem, Set-Location, Remove-Item, etc.)
5. Use PowerShell operators and syntax (backticks for line continuation, proper quoting)
6. For file paths on Windows, use either forward slashes or escaped backslashes
7. Prefer PowerShell native commands over external tools when possible
8. Use double quotes for strings that need variable expansion, single quotes for literal strings

EXAMPLES OF CORRECT POWERSHELL SYNTAX:
- Multiple commands: git add . $commandSeparator git commit -m "message" $commandSeparator git push
- File operations: Get-ChildItem -Filter "*.txt" | Remove-Item
- Conditions: if (Test-Path file.txt) { Remove-Item file.txt }
- Piping: Get-Process | Where-Object { `$_.CPU -gt 100 } | Stop-Process

DO NOT USE bash/Linux syntax like:
- find, grep (use Get-ChildItem, Select-String instead)
- cat (use Get-Content)
- rm -rf (use Remove-Item -Recurse -Force)
- ls -la (use Get-ChildItem -Force)

Current Context:
$Context

User Request: $UserPrompt

Generate the PowerShell command:
"@

    return $systemInstructions
}

<#
.SYNOPSIS
    Interactive command builder with conversation mode.

.DESCRIPTION
    Allows you to have a conversation with the AI to refine commands.
#>
function Start-AICommandSession {
    [CmdletBinding()]
    [Alias('??!')]
    param(
        [Parameter()]
        [ValidateSet('claude', 'openai', 'anthropic', 'ollama', 'copilot')]
        [string]$Provider
    )

    # Load configuration defaults
    $config = Get-AICommandConfig

    # Use config default if provider not explicitly provided
    if (-not $PSBoundParameters.ContainsKey('Provider')) {
        $Provider = $config.Provider
    }

    Write-Host "Starting AI Command Session with $Provider..." -ForegroundColor Green
    Write-Host "Type 'exit' or 'quit' to end the session" -ForegroundColor DarkGray
    Write-Host "Type 'execute' or 'run' to run the last generated command" -ForegroundColor DarkGray
    Write-Host ""

    $lastCommand = ""
    $context = Get-SystemContext

    while ($true) {
        Write-Host "?? " -NoNewline -ForegroundColor Cyan
        $input = Read-Host

        if ($input -in @('exit', 'quit', 'q')) {
            Write-Host "Goodbye!" -ForegroundColor Green
            break
        }

        if ($input -in @('execute', 'run', 'x') -and $lastCommand) {
            Write-Host "Executing: $lastCommand" -ForegroundColor Yellow
            Invoke-Expression $lastCommand
            continue
        }

        if ([string]::IsNullOrWhiteSpace($input)) {
            continue
        }

        try {
            $fullPrompt = Build-CommandPrompt -UserPrompt $input -Context $context
            $command = Invoke-ProviderCommand -Provider $Provider -Prompt $fullPrompt

            # Clean command
            if ($command -match '^```(?:powershell|bash|sh)?\s*\n(.*)\n```$') {
                $command = $matches[1].Trim()
            }

            $command = $command.Trim()
            $lastCommand = $command

            Write-Host $command -ForegroundColor Green
            Write-Host ""
        } catch {
            Write-Error "Error: $($_.Exception.Message)"
        }
    }
}

<#
.SYNOPSIS
    Get the current AICommand configuration.

.DESCRIPTION
    Retrieves the stored configuration for default provider and model settings.
    If no config file exists, returns default values.

.EXAMPLE
    Get-AICommandConfig
    # Returns current configuration

.EXAMPLE
    $config = Get-AICommandConfig
    Write-Host "Current provider: $($config.Provider)"
#>
function Get-AICommandConfig {
    [CmdletBinding()]
    param()

    $defaultConfig = @{
        Provider = 'claude'
        Model = $null
    }

    if (Test-Path $script:ConfigPath) {
        try {
            $configJson = Get-Content $script:ConfigPath -Raw -ErrorAction Stop
            $config = $configJson | ConvertFrom-Json

            # Convert PSCustomObject to hashtable
            $configHash = @{
                Provider = if ($config.Provider) { $config.Provider } else { $defaultConfig.Provider }
                Model = $config.Model
            }

            return $configHash
        } catch {
            Write-Warning "Failed to load config file. Using defaults. Error: $($_.Exception.Message)"
            return $defaultConfig
        }
    }

    return $defaultConfig
}

<#
.SYNOPSIS
    Set default provider and/or model for AICommand.

.DESCRIPTION
    Saves default provider and model preferences to a config file.
    These defaults will be used when no explicit provider/model is specified.

.PARAMETER Provider
    The default AI provider to use (claude, openai, anthropic, ollama, copilot).

.PARAMETER Model
    The default model to use for the provider.

.PARAMETER Clear
    Clear the configuration file and reset to defaults.

.EXAMPLE
    Set-AICommandConfig -Provider copilot
    # Set GitHub Copilot as default provider

.EXAMPLE
    Set-AICommandConfig -Provider copilot -Model gpt-4
    # Set Copilot with GPT-4 as defaults

.EXAMPLE
    Set-AICommandConfig -Provider ollama -Model llama2
    # Set Ollama with llama2 as defaults

.EXAMPLE
    Set-AICommandConfig -Clear
    # Reset to default configuration
#>
function Set-AICommandConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('claude', 'openai', 'anthropic', 'ollama', 'copilot')]
        [string]$Provider,

        [Parameter()]
        [string]$Model,

        [Parameter()]
        [switch]$Clear
    )

    if ($Clear) {
        if (Test-Path $script:ConfigPath) {
            Remove-Item $script:ConfigPath -Force
            Write-Host "AICommand configuration cleared. Using defaults (Provider: claude)." -ForegroundColor Green
        } else {
            Write-Host "No configuration file found. Already using defaults." -ForegroundColor Yellow
        }
        return
    }

    # Load existing config or create new one
    $config = Get-AICommandConfig

    # Update only the provided parameters
    if ($PSBoundParameters.ContainsKey('Provider')) {
        $config.Provider = $Provider
    }

    if ($PSBoundParameters.ContainsKey('Model')) {
        $config.Model = $Model
    }

    # Save to file
    try {
        $config | ConvertTo-Json | Set-Content -Path $script:ConfigPath -Force
        Write-Host "AICommand configuration saved:" -ForegroundColor Green
        Write-Host "  Provider: $($config.Provider)" -ForegroundColor Cyan
        if ($config.Model) {
            Write-Host "  Model: $($config.Model)" -ForegroundColor Cyan
        } else {
            Write-Host "  Model: (provider default)" -ForegroundColor DarkGray
        }
        Write-Host ""
        Write-Host "Config file: $script:ConfigPath" -ForegroundColor DarkGray
    } catch {
        Write-Error "Failed to save configuration: $($_.Exception.Message)"
    }
}

# Export functions and aliases
Export-ModuleMember -Function Invoke-AICommand, Start-AICommandSession, Get-SystemContext, Get-AICommandConfig, Set-AICommandConfig -Alias '??', '??!'
