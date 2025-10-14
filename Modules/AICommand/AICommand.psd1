@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'AICommand.psm1'

    # Version number of this module.
    ModuleVersion = '1.2.0'

    # ID used to uniquely identify this module
    GUID = 'a3f1c4d7-8e2b-4f9a-b5c6-1d8e7f2a9b3c'

    # Author of this module
    Author = 'Travis Haley'

    # Company or vendor of this module
    CompanyName = 'Personal'

    # Copyright statement for this module
    Copyright = '(c) 2024 Travis Haley. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'AI-powered CLI command generation using Claude or other LLMs. Generate commands from natural language descriptions with context awareness.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @(
        'Invoke-AICommand',
        'Start-AICommandSession',
        'Get-SystemContext',
        'Get-AICommandConfig',
        'Set-AICommandConfig'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @('??', '??!')

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for module discovery
            Tags = @('AI', 'CLI', 'Command', 'Generator', 'Claude', 'LLM', 'Assistant', 'Productivity')

            # A URL to the license for this module
            LicenseUri = ''

            # A URL to the main website for this project
            ProjectUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = @'
Version 1.2.0
- Added configuration system for default provider and model settings
- New functions: Set-AICommandConfig and Get-AICommandConfig
- Users can now set defaults to avoid typing flags every time
- Config stored in ~/.aicommand.config.json
- Example: Set-AICommandConfig -Provider copilot -Model gpt-4

Version 1.1.0
- Added GitHub Copilot CLI as a provider option
- Fixed PowerShell syntax generation (proper use of ; vs && based on PS version)
- Enhanced AI prompt to explicitly request PowerShell-native commands
- Updated documentation with Copilot examples and PowerShell syntax guide

Version 1.0.0 (Initial Release)
- AI-powered command generation from natural language
- Support for multiple AI providers (Claude, OpenAI, Anthropic, Ollama)
- Automatic system context detection (OS, Git, Project type)
- Multiple output modes: clipboard, execute, interactive
- Session mode for conversational command refinement
- Smart context awareness for Git repositories and project types
'@
        }
    }

    # Help Info URI
    HelpInfoURI = ''
}
