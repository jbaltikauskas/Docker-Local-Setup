function Write-AspireDashboardWebUiShortcut () {
    <#
    .SYNOPSIS
        Writes a Windows Internet Shortcut for the Aspire Dashboard Web UI.
    .DESCRIPTION
        Always refreshes AspireDashboard.url with the configured dashboard URL.
    .REMARKS
        1. Write AspireDashboard.url.
        2. Return the path.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerRoot,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DashboardUrl
    )

    Begin {
        $PSBoundParameters | Out-String | Write-Host
    }

    Process {

        $path = Join-Path $ServerRoot 'AspireDashboard.url'
        Write-Utf8NoBom -Path $path -Content "[InternetShortcut]`nURL=$DashboardUrl`n"
        return $path
    }
}
