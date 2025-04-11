<#
.SYNOPSIS
    Generates and tests Elasticsearch API key headers.

.DESCRIPTION
    This function generates an Elasticsearch API key header by encoding the ID:Key pair and optionally tests 
    the connection to an Elasticsearch server. It can also copy the generated authorization header to the clipboard.

.PARAMETER Url
    (Optional) The Elasticsearch server URL to test the connection. If not provided, the user will be prompted.

.PARAMETER CopyToClipboard
    If specified, copies the generated authorization header to the clipboard.

.EXAMPLE
    Generate-Elastic-Key
    Prompts for API key ID, key, and optionally server URL. Then generates and optionally tests the header.

.EXAMPLE
    Generate-Elastic-Key -CopyToClipboard -Url "https://my-es-instance.com:9243"
    Generates the header, copies it to the clipboard, and tests the connection.

.NOTES
    Author: Travis Haley
    Version: 1.1.0
#>
function Generate-Elastic-Key {
    [CmdletBinding()]
    param (
        [string]$Url,
        [switch]$CopyToClipboard
    )

    # Define status symbols using PowerShell's native character support
    $successSymbol = [char]0x2714  # ✓
    $failureSymbol = [char]0x2718  # ✘

    # Prompt for URL if not provided
    if (-not $Url) {
        $Url = Read-Host "Enter your Elasticsearch server URL (press Enter to skip connection test)"
    }

    # Prompt for API Key ID and Key
    $apiKeyId = Read-Host "Enter your API Key ID"
    $secureApiKey = Read-Host "Enter your API Key" -AsSecureString
    $apiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureApiKey)
    )

    # Encode as base64
    $raw = "$apiKeyId`:$apiKey"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($raw)
    $encoded = [System.Convert]::ToBase64String($bytes)

    # Build header
    $authHeader = "Authorization: ApiKey $encoded"
    $headers = @{
        Authorization = "ApiKey $encoded"
    }

    # Output header
    Write-Host "`nYour Authorization Header:"
    Write-Host $authHeader

    # Optional: copy to clipboard
    if ($CopyToClipboard) {
        Set-Clipboard -Value $authHeader
        Write-Host "`n(Header copied to clipboard $successSymbol)"
    }

    # Test the connection only if URL was provided
    if ($Url) {
        Write-Host "`nTesting connection to $Url ..."
        try {
            $response = Invoke-RestMethod -Uri $Url -Headers $headers -Method Get -ErrorAction Stop
            Write-Host "`n$successSymbol Connection successful. Cluster Info:"
            $response
        }
        catch {
            Write-Host "`n$failureSymbol Connection failed:"
            $_.Exception.Message
            if ($_.ErrorDetails) {
                Write-Host $_.ErrorDetails.Message
            }
        }
    }
    else {
        Write-Host "`nSkipping connection test as no URL was provided"
    }
}

# Export the function
Export-ModuleMember -Function Generate-Elastic-Key
