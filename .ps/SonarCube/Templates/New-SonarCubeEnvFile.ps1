function New-SonarCubeEnvFile () {
    <#
    .SYNOPSIS
        Writes non-secret SonarQube and PostgreSQL environment settings.
    .DESCRIPTION
        Always overwrites the installer-managed file.
    .REMARKS
        1. Write the database name.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$EnvPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DatabaseName
    )

    Begin {
        $PSBoundParameters | Out-String | Write-Host
    }

    Process {

        $content = @"
POSTGRES_DB=$DatabaseName
"@
        Write-Utf8NoBom -Path $EnvPath -Content $content
    }
}
