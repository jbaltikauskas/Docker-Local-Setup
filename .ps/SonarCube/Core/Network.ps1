function Test-SonarCubeTcpPortAvailable () {
    <#
    .SYNOPSIS
        Returns true when a TCP port has no local listener.
    .DESCRIPTION
        Checks active TCP listeners on the Windows host.
    .REMARKS
        1. Query active listeners.
        2. Return whether Port is absent.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 65535)]
        [int]$Port
    )

    Begin {
        $PSBoundParameters | Out-String | Write-Host
    }

    Process {

        $listeners = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()
        return -not ($listeners | Where-Object { $_.Port -eq $Port })
    }
}

function Resolve-SonarCubeInstallerPort () {
    <#
    .SYNOPSIS
        Validates the SonarQube Web UI port loaded from config-sonarcube.json.
    .DESCRIPTION
        Returns the configured port when available and throws when it is already in use.
    .REMARKS
        1. Check the configured port.
        2. Throw when busy.
        3. Return the configured port.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 65535)]
        [int]$ConfiguredPort,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$BindAddress
    )

    Begin {
        $PSBoundParameters | Out-String | Write-Host
    }

    Process {

        if (-not (Test-SonarCubeTcpPortAvailable -Port $ConfiguredPort)) {
            throw "Configured PORT $ConfiguredPort is already in use. Change PORT in config-sonarcube.json."
        }

        return $ConfiguredPort
    }
}
