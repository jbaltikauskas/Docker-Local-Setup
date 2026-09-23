function Write-CosmosDbWebUiShortcut () {
    <#
    .SYNOPSIS
        Writes a Windows Internet Shortcut for the Cosmos DB Data Explorer.
    .DESCRIPTION
        Always refreshes CosmosDb.url with the configured Data Explorer URL.
    .REMARKS
        1. Write CosmosDb.url.
        2. Return the path.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerRoot,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ExplorerUrl
    )

    Begin {
        $PSBoundParameters | Out-String | Write-Host
    }

    Process {

        $path = Join-Path $ServerRoot 'CosmosDb.url'
        Write-Utf8NoBom -Path $path -Content "[InternetShortcut]`nURL=$ExplorerUrl`n"
        return $path
    }
}
