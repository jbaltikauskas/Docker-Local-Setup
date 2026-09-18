function New-SnowflakeComposeFile () {
    <#
    .SYNOPSIS
        Writes the Snowflake Docker Compose file.
    .DESCRIPTION
        Renders the local Snowflake emulator service and persists its database
        file in the install-folder snowflake-dat directory. Runtime values come
        from one env file at config/.env.
    .REMARKS
        1. Render the single-service compose file.
        2. Attach config/.env and mount snowflake-dat to /data for emulator database persistence.
        3. Write UTF-8 without BOM, replacing any existing file.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComposePath,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 65535)]
        [int]$Port,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SnowflakeImage
    )

    Begin {
        $PSBoundParameters | Out-String | Write-Host
    }

    Process {

        $content = @"
version: '3.8'

services:
  snowflake-emulator:
    image: $SnowflakeImage
    container_name: local-snowflake
    ports:
      - "${Port}:8080"
    env_file:
      - ./config/.env
    volumes:
      - ./snowflake-dat:/data
    restart: unless-stopped
"@

        Write-Utf8NoBom -Path $ComposePath -Content $content

        Write-Host "Compose file: $ComposePath"
        Write-Host $content
    }
}
