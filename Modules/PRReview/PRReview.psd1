@{
    # Script module or binary module file associated with this manifest
    ModuleToProcess = 'PRReview.psm1'

    # Version number of this module
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = 'f4b2c8d6-1a3e-4d5f-8c9b-2e1f4a6d8c9b'

    # Author of this module
    Author = 'Travis Haley'

    # Company or vendor of this module
    CompanyName = 'Haley Computer Solutions'

    # Copyright statement for this module
    Copyright = '(c) 2024 Haley Computer Solutions. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Module for generating comprehensive code review reports from Git diffs for PR analysis'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Functions to export from this module
    FunctionsToExport = @('New-PRReview', 'Get-PRDiff', 'New-ReviewPrompt', 'Get-DefaultBranch')

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @('pr-review', 'review')

    # List of all modules packaged with this module
    ModuleList = @()

    # List of all files packaged with this module
    FileList = @('PRReview.psm1', 'PRReview.psd1')
} 