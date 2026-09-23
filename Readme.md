# Local DockerStack Provisioner

This repo provisions self-contained local Docker stacks on Windows 11 with
Docker Desktop. Each installer creates a dated install folder under the
configured `INSTALL_ROOT_FOLDER`. The checked-in config files default to
`..\Local-DockerStack-Provisioner--Installs`, which is a folder beside this
repo. Each install folder has its own `docker-compose.yml`, generated
management scripts, configuration, and install-folder `README.md`.

## Prerequisites

Before running the installers, ensure the following prerequisites are installed and running:

### 1. PowerShell 7 (`pwsh`)

The installer scripts require PowerShell 7 or higher.

- **Documentation**: [Install PowerShell on Windows (MSI)](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows?view=powershell-7.6#msi)
- **Manual Installation (MSI)**:
  1. Download the latest `x64` MSI package from the [PowerShell GitHub Releases](https://github.com/PowerShell/PowerShell/releases/latest) (for example, `PowerShell-7.x.x-win-x64.msi`).
  2. Double-click the downloaded `.msi` file and follow the setup wizard prompts to complete the installation.
- **Alternative (WinGet MSI install)**:
  ```powershell
  winget install --id Microsoft.PowerShell --source winget --installer-type wix
  ```
- **Verification**:
  Open a terminal and verify the version:
  ```powershell
  pwsh --version
  ```

### 2. Docker Desktop for Windows

Docker Desktop with Docker Compose v2 is required to run the local container stacks.

- **Documentation**: [Install Docker Desktop on Windows](https://docs.docker.com/desktop/setup/install/windows-install/)
- **System Requirements**:
  - Windows 11 or Windows 10 64-bit (Pro, Enterprise, or Home).
  - Hardware virtualization enabled in BIOS/UEFI.
  - WSL 2 (Windows Subsystem for Linux) enabled.
- **Manual Installation**:
  1. Download the installer: [Docker Desktop for Windows - x86_64](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe).
  2. Double-click `Docker Desktop Installer.exe` to start the installation.
  3. Select your preferred installation mode (per-user is recommended and does not require administrator privileges).
  4. On the Configuration screen, ensure **Use WSL 2 instead of Hyper-V** is selected.
  5. Follow the remaining prompts, click **Close** once finished, and launch **Docker Desktop** from the Windows Start menu.
- **Verification**:
  Once Docker Desktop is started and the engine is running, verify Docker and Docker Compose v2:
  ```powershell
  docker --version
  docker compose version
  ```

## Available Installers

```powershell
pwsh -File .\Install-SonarCube.ps1 -ServerNamePrefix CustomName
pwsh -File .\Install-MSSql.ps1 -ServerNamePrefix CustomName
pwsh -File .\Install-AspireDashboard.ps1 -ServerNamePrefix CustomName
pwsh -File .\Install-PostgreSql.ps1 -ServerNamePrefix CustomName
pwsh -File .\Install-Snowflake.ps1 -ServerNamePrefix CustomName
pwsh -File .\Install-CosmosDb.ps1 -ServerNamePrefix CustomName
```

Each installer reads runtime settings from its matching required config file:

- `config-sonarcube.json`
- `config-mssql.json`
- `config-aspire-dashboard.json`
- `config-postgresql.json`
- `config-snowflake.json`
- `config-cosmosdb.json`

`ServerNamePrefix` is always supplied directly to the installer. It is not read
from config files. Install folders use the pattern
`<ServerNamePrefix>-<StackName>-yyyyMMdd`.

Each config file sets `INSTALL_ROOT_FOLDER` to control where the dated install
folder is created. Relative paths are resolved from the installer script
folder. Leave it empty to use the installer script folder. If the configured
root folder does not exist, the installer creates it.

```json
"INSTALL_ROOT_FOLDER": "..\\Local-DockerStack-Provisioner--Installs"
```

## Generated Files

Generated install folders include stack-specific files such as:

- `docker-compose.yml`
- Stack-specific start and stop scripts (`.ps1` and `.cmd` / `.bat`)
- Windows Internet Shortcuts (`*.url`) for 1-click browser navigation (`SonarCube.url`, `AspireDashboard.url`, `CosmosDb.url`)
- Standalone helper utilities, such as `Scan-SonarCube.ps1` with embedded credentials
- `config\.env`
- `config\.env.secrets` when the stack needs secrets
- `config\account.key` for Cosmos DB
- Install-folder `README.md` with connection strings and daily commands

Installer-managed non-secret files and generated management scripts are
overwritten when their writers run. Existing `.env.secrets` files are preserved
when the installer creates secrets.

## Data Persistence

SonarCube and PostgreSQL use Docker named volumes for persistent database and
application data. PostgreSQL uses a single generated `config\.env` file and
Windows batch start/stop scripts. Snowflake uses one `config\.env` file and
stores emulator data in an install-local `snowflake-dat` folder. Cosmos DB uses
one `config\.env` file, writes the account key to `config\account.key`, and
stores emulator data in an install-local `cosmos-data` folder. MSSQL
currently uses an install-local `mssql_dev_data` folder beside its generated
compose file. Aspire Dashboard does not create persistent data storage.

Do not run `docker compose down -v` or `docker volume prune` unless you intend
to delete persistent data.

## Defaults

### Install-SonarCube.ps1

Web UI defaults to `http://localhost:9000`; login uses the configured
`SONAR_ADMIN_USERNAME` and `SONAR_ADMIN_PASSWORD`. The password must be at
least 12 characters and include uppercase, lowercase, number, and
special-character content. SonarCube PostgreSQL credentials come from
`POSTGRES_USER`, `POSTGRES_PASSWORD`, and `POSTGRES_DB` in
`config-sonarcube.json`. The installer repairs the configured PostgreSQL
user's password in existing named volumes before SonarCube starts.

After the Web API is ready, the installer appends global `sonar.exclusions`
(`**/Scan-SonarCube.ps1,.ps1/**,.claude/**,.cursor/**,docs/**`), installs or
updates the global `dotnet-sonarscanner` tool (requires the .NET SDK) with
`dotnet tool install --global dotnet-sonarscanner` or
`dotnet tool update --global dotnet-sonarscanner`, verifies with
`dotnet sonarscanner --version`, generates a no-expiration Global Analysis
Token (`local-global-analysis`), and writes `SONAR_TOKEN` to the install folder
`config\.env.secrets`.

**Generated files:**

Each installation folder (for example, `<ServerNamePrefix>-SonarCube-yyyyMMdd`)
generates:

- `Scan-SonarCube.ps1`: Standalone scanner helper script with the Web UI URL and
  analysis token embedded (treat that file as secret).
- `SonarCube.url`: Windows Internet Shortcut pointing to the Web UI
  (`http://localhost:9000`).
- `Start-SonarCube.ps1` and `Stop-SonarCube.ps1` (plus `.cmd` wrappers).
- `docker-compose.yml`, `config\.env`, `config\.env.secrets`, and `README.md`.

**Using `Scan-SonarCube.ps1` and `SonarCube.url` in .NET projects:**

The generated `Scan-SonarCube.ps1` and `SonarCube.url` can be copied directly
into any .NET project repository containing a `.slnx` or `.sln` solution file
and run directly:

1. Copy `Scan-SonarCube.ps1` and `SonarCube.url` into the target .NET project
   root.
2. Run `.\Scan-SonarCube.ps1` in PowerShell directly from that project folder
   without passing parameters. The script automatically detects the first
   `*.slnx` in the current directory (or first `*.sln`, or inside a `src` folder),
   computes the SonarQube project key as `<solution-name>` (or
   `<solution-name>--<git-branch>`), passes standard exclusions, and runs
   `dotnet sonarscanner begin`, `dotnet build`, and `dotnet sonarscanner end`.
3. Double-click `SonarCube.url` (or open it from the terminal) to immediately
   launch the SonarQube dashboard in your browser and view the scan results.

### Install-MSSql.ps1

SQL Server Developer Edition running on port `1433`.

**Generated files:**

- `Start-MSSql.ps1` and `Stop-MSSql.ps1` (plus `Start-MSSql.bat` and `Stop-MSSql.bat`).
- `docker-compose.yml` mapping `./mssql_dev_data` to `/var/opt/mssql/data`.
- `config\.env` (setting `MSSQL_PID`).
- `config\.env.secrets` (containing `SA_PASSWORD` from `config-mssql.json`).
- Install-folder `README.md` with complete connection strings and sample code.

**Connection details:**

- Standard connection string:
  ```text
  Server=localhost,1433;User Id=sa;Password=<MSSQL_SA_PASSWORD>;TrustServerCertificate=True;
  ```
- C# connection string:
  ```csharp
  var connectionString = "Server=localhost,1433;Database=master;User Id=sa;Password=<MSSQL_SA_PASSWORD>;Encrypt=False;TrustServerCertificate=True;";
  ```

### Install-AspireDashboard.ps1

Standalone .NET Aspire Dashboard for OpenTelemetry traces, metrics, and logs.

**Endpoints:**

- Dashboard UI: `http://localhost:18888`
- OTLP gRPC endpoint: `http://localhost:4317`
- OTLP HTTP endpoint: `http://localhost:4318`

**Generated files:**

- `AspireDashboard.url`: Windows Internet Shortcut to open the dashboard UI directly in your browser.
- `Start-AspireDashboard.ps1` and `Stop-AspireDashboard.ps1` (plus `Start-AspireDashboard.bat` and `Stop-AspireDashboard.bat`).
- `docker-compose.yml` and `config\.env` (`DOTNET_DASHBOARD_UNSECURED_ALLOW_ANONYMOUS=true`).
- Install-folder `README.md` documenting telemetry endpoints and daily commands.

### Install-PostgreSql.ps1

Standalone PostgreSQL (`postgres:16-alpine`) running on port `5432` with
database credentials from `config-postgresql.json`.

**Generated files:**

- `Start-PostgreSql.ps1` and `Stop-PostgreSql.ps1` (plus `Start-PostgreSql.bat` and `Stop-PostgreSql.bat`).
- `docker-compose.yml` utilizing a dedicated Docker named volume for `/var/lib/postgresql/data`.
- `config\.env` containing `POSTGRES_USER`, `POSTGRES_PASSWORD`, and `POSTGRES_DB`.
- Install-folder `README.md` with connection strings and management commands.

**Connection details:**

- Standard connection string:
  ```text
  Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=<POSTGRES_PASSWORD>;
  ```
- C# connection string:
  ```csharp
  var connectionString = "Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=<POSTGRES_PASSWORD>;";
  ```

### Install-Snowflake.ps1

`ghcr.io/nnnkkk7/snowflake-emulator:latest` on port `8080` with local account
settings from `config-snowflake.json`.

**Generated files:**

- `Start-Snowflake.ps1` and `Stop-Snowflake.ps1` (plus `Start-Snowflake.bat` and `Stop-Snowflake.bat`).
- `docker-compose.yml` binding `./snowflake-dat` to `/data` so `DB_PATH=/data/snowflake.db` persists.
- `config\.env` containing account, user, warehouse, database, schema, and role settings.
- Install-folder `README.md` documenting connection strings and drivers.

**Connection details:**

You can connect to the Snowflake emulator using the standard gosnowflake driver
or REST API. The default connection string/DSN is:

```text
user:pass@localhost:8080/TEST_DB/PUBLIC?account=test&protocol=http
```

`Install-Snowflake.ps1` generates `docker-compose.yml` like this:

```yaml
version: '3.8'

services:
  snowflake-emulator:
    image: ghcr.io/nnnkkk7/snowflake-emulator:latest
    container_name: local-snowflake
    ports:
      - "8080:8080"
    env_file:
      - ./config/.env
    volumes:
      - ./snowflake-dat:/data
    restart: unless-stopped
```

### Install-CosmosDb.ps1

`mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator:vnext-latest` with
gateway port `8081`, health port `8080`, and Data Explorer port `1234`.
`PROTOCOL` defaults to `https` so the .NET SDK can connect. The well-known
emulator `ACCOUNT_KEY` comes from `config-cosmosdb.json`.

**Generated files:**

- `CosmosDb.url`: Windows Internet Shortcut to open the Cosmos DB Data Explorer directly at `https://localhost:1234`.
- `Start-CosmosDb.ps1` and `Stop-CosmosDb.ps1` (plus `Start-CosmosDb.bat` and `Stop-CosmosDb.bat`).
- `docker-compose.yml` binding `./cosmos-data` to `/data` and `./config/account.key` to `/account.key:ro`.
- `config\.env` and `config\account.key`.
- Install-folder `README.md` documenting connection options and C# code samples.

**Connection details:**

The Data Explorer defaults to `https://localhost:1234`. The gateway endpoint
defaults to `https://localhost:8081`. The default connection string is:

```text
AccountEndpoint=https://localhost:8081/;AccountKey=<ACCOUNT_KEY from config-cosmosdb.json>
```

The .NET SDK requires gateway mode. For `https`, ignore the emulator's local
certificate or use `PROTOCOL` `https-insecure`. Health probes stay on HTTP at
`http://localhost:8080/ready`.

`Install-CosmosDb.ps1` generates `docker-compose.yml` like this:

```yaml
services:
  cosmosdb-JB:
    image: mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator:vnext-latest
    container_name: cosmosdb-jb-yyyyMMdd
    env_file:
      - ./config/.env
    ports:
      - "127.0.0.1:8081:8081"
      - "127.0.0.1:8080:8080"
      - "127.0.0.1:1234:1234"
    volumes:
      - ./cosmos-data:/data
      - ./config/account.key:/account.key:ro
    restart: unless-stopped
```
