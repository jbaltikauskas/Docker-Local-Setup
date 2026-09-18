# Local Docker Stack Installers

This repo creates self-contained local Docker stacks on Windows 11 with Docker
Desktop. Each installer creates a dated install folder under the configured
`INSTALL_ROOT_FOLDER`. The checked-in config files default to
`..\Docker-Local-Setup--Installs`, which is a folder beside this repo. Each install
folder has its own `docker-compose.yml`, generated management scripts,
configuration, and install-folder `README.md`.

## Available Installers

```powershell
pwsh -File .\Install-SonarCube.ps1 -ServerNamePrefix JB
pwsh -File .\Install-MSSql.ps1 -ServerNamePrefix JB
pwsh -File .\Install-AspireDashboard.ps1 -ServerNamePrefix JB
pwsh -File .\Install-PostgreSql.ps1 -ServerNamePrefix JB
pwsh -File .\Install-Snowflake.ps1 -ServerNamePrefix JB
```

Each installer reads runtime settings from its matching required config file:

- `config-sonarcube.json`
- `config-mssql.json`
- `config-aspire-dashboard.json`
- `config-postgresql.json`
- `config-snowflake.json`

`ServerNamePrefix` is always supplied directly to the installer. It is not read
from config files. Install folders use the pattern
`<ServerNamePrefix>-<StackName>-yyyyMMdd`.

Each config file sets `INSTALL_ROOT_FOLDER` to control where the dated install
folder is created. Relative paths are resolved from the installer script
folder. Leave it empty to use the installer script folder. If the configured
root folder does not exist, the installer creates it.

```json
"INSTALL_ROOT_FOLDER": "..\\Docker-Local-Setup--Installs"
```

## Generated Files

Generated install folders include stack-specific files such as:

- `docker-compose.yml`
- stack-specific start and stop scripts
- `config\.env`
- `config\.env.secrets` when the stack needs secrets
- `README.md`

Installer-managed non-secret files and generated management scripts are
overwritten when their writers run. Existing `.env.secrets` files are preserved
when the installer creates secrets.

## Data Persistence

SonarCube and PostgreSQL use Docker named volumes for persistent database and
application data. PostgreSQL uses a single generated `config\.env` file and
Windows batch start/stop scripts. Snowflake uses one `config\.env` file and
stores emulator data in an install-local `snowflake-dat` folder. MSSQL
currently uses an install-local `mssql_dev_data` folder beside its generated
compose file. Aspire Dashboard does not create persistent data storage.

Do not run `docker compose down -v` or `docker volume prune` unless you intend
to delete persistent data.

## Defaults

- SonarCube Web UI defaults to `http://localhost:9000`; login uses the
  configured `SONAR_ADMIN_USERNAME` and `SONAR_ADMIN_PASSWORD`. The password
  must be at least 12 characters and include uppercase, lowercase, number, and
  special-character content. SonarCube PostgreSQL credentials come from
  `POSTGRES_USER`, `POSTGRES_PASSWORD`, and `POSTGRES_DB` in
  `config-sonarcube.json`. The installer repairs the configured PostgreSQL
  user's password in existing named volumes before SonarCube starts. After the
  Web API is ready it appends global `sonar.exclusions`
  (`**/Scan-SonarCube.ps1,.ps1/**,.claude/**,.cursor/**,docs/**`), installs or
  updates the global `dotnet-sonarscanner` tool (requires the .NET SDK) with
  `dotnet tool install --global dotnet-sonarscanner` or
  `dotnet tool update --global dotnet-sonarscanner`, verifies with
  `dotnet sonarscanner --version`, then generates a no-expiration Global
  Analysis Token and writes `SONAR_TOKEN` to the install folder
  `config\.env.secrets`. It also writes `Scan-SonarCube.ps1` with the host URL
  and analysis token embedded so the script can be copied into application
  projects (treat that file as secret). The script resolves a solution from the
  first `*.slnx` in the current directory, then the first `*.sln`, and prompts
  only when neither is found. The SonarQube project key is computed at scan
  time as `<solution-name>` or `<solution-name>--<git-branch>`. It passes the
  same `sonar.exclusions` list on begin and runs `dotnet sonarscanner begin`,
  `dotnet build`, and `dotnet sonarscanner end`.
- MSSQL defaults to SQL Server Developer Edition on port `1433`.
- Aspire Dashboard defaults to UI port `18888` and OTLP ports `4317` / `4318`.
- PostgreSQL defaults to `postgres:16-alpine` on port `5432` with database
  credentials from `config-postgresql.json`.
- Snowflake defaults to `ghcr.io/nnnkkk7/snowflake-emulator:latest` on port `8080`
  with local account settings from `config-snowflake.json`.

## Snowflake Connection

You can connect to the Snowflake emulator using the standard gosnowflake driver
or REST API. The default connection string/DSN is:

```text
user:pass@localhost:8080/TEST_DB/PUBLIC?account=test&protocol=http
```

## Snowflake Compose Example

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
