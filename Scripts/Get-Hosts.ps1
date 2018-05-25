#
# Powershell script for adding/removing/showing entries to the hosts file.
#
# Known limitations:
# - does not handle entries with comments afterwards ("<ip>    <host>    # comment")
#

function Get-Hosts ($hostArgsIn) {
    <#
.SYNOPSIS
  Powershell script for adding/removing/showing entries to the hosts file.
#>

    $hostArgs = $bits = [regex]::Split($hostArgsIn, "\t+")

    $file = "C:\Windows\System32\drivers\etc\hosts"

    function add-host([string]$filename, [string]$ip, [string]$hostname) {
        remove-host $filename $hostname
        $ip + "`t`t" + $hostname | Out-File -encoding ASCII -append $filename
    }

    function remove-host([string]$filename, [string]$hostname) {
        $c = Get-Content $filename
        $newLines = @()

        foreach ($line in $c) {
            $bits = [regex]::Split($line, "\t+")
            if ($bits.count -eq 2) {
                if ($bits[1] -ne $hostname) {
                    $newLines += $line
                }
            }
            else {
                $newLines += $line
            }
        }

        # Write file
        Clear-Content $filename
        foreach ($line in $newLines) {
            $line | Out-File -encoding ASCII -append $filename
        }
    }

    function print-hosts([string]$filename) {
        $c = Get-Content $filename

        foreach ($line in $c) {
            $bits = [regex]::Split($line, "^(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b)\s+")
            if ($bits.count -eq 3) {
                Write-Host $bits[1] `t`t $bits[2]
            }
        }
    }

    function open-hosts([string]$filename) {
        n $filename
    }

    try {
        if ($hostArgs[0] -eq "add") {

            if ($args.count -lt 3) {
                throw "Not enough arguments for add."
            }
            else {
                add-host $file $hostArgs[1] $hostArgs[2]
            }

        }
        elseif ($hostArgs[0] -eq "remove") {

            if ($hostArgs.count -lt 2) {
                throw "Not enough arguments for remove."
            }
            else {
                remove-host $file $hostArgs[1]
            }

        }
        elseif ($hostArgs[0] -eq "show") {
            print-hosts $file
        }
        elseif ($hostArgs[0] -eq "open") {
            open-hosts $file
        }
        else {
            throw "Invalid operation '" + $hostArgs[0] + "' - must be one of 'add', 'remove', 'show', 'open'."
        }
    }
    catch {
        Write-Host $error[0]
        Write-Host "`nUsage: hosts add <ip> <hostname>`n       hosts remove <hostname>`n       hosts show`n       hosts open"
    }
}

function Hosts ($hostArgs) {
    Get-Hosts $hostArgs
}

