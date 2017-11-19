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