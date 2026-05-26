# Continuous Migration with Concourse and Spring Application Advisor

Runs Spring Application Advisor (SAA) upgrade pipelines on Concourse CI. The spawner pipeline discovers Java/Spring Boot repos across GitHub orgs and GitLab groups and creates a per-repo pipeline that opens upgrade pull/merge requests.

Works on both **macOS** and **Linux**. `demo.sh` detects the host platform and selects the right `sed` flavor and `fly` binary automatically.

## Prerequisites

- Docker (Docker Desktop on macOS, Docker Engine on Linux)
- [vendir](https://carvel.dev/vendir/)
- [httpie](https://github.com/jkbrzt/httpie) (or `curl`)
- [Bitwarden CLI](https://bitwarden.com/help/cli/) (`bw`) — `.envrc` reads secrets from it

Install via Homebrew (macOS or Linuxbrew):
```bash
brew install vendir httpie bitwarden-cli
```

## Setup

1. Configure environment variables in `.envrc` (see the file for the Bitwarden item names it expects).
2. Source the env and start the demo:
   ```bash
   source .envrc
   ./demo.sh
   ```

Concourse lands on `http://localhost:8080` (login `test`/`test`); Nexus on `http://localhost:9081` (`admin`/`admin123`).

## Cross-platform notes

- `sed -i`: BSD on macOS (`sed -i ''`), GNU on Linux (`sed -i`). `demo.sh` picks the right form via `OSTYPE`.
- `fly` binary: downloaded from the running Concourse to match `darwin` or `linux`.
- Docker Compose on macOS: `cgroup: host` is stripped from the downloaded compose file at runtime (Docker Desktop doesn't support it); `privileged: true` is kept because the containerd worker needs it for iptables.

## Troubleshooting

### Docker Compose errors
If you see errors mentioning `privileged` or `cgroup`, confirm Docker is running and that your user can run `docker ps` without sudo.

### `sed: 1: ...: invalid command code`
You're running a GNU-`sed` flag against BSD `sed`. `demo.sh` handles this for itself, but if you've added new `sed -i` calls, follow the `SED_INPLACE` pattern in `demo.sh` rather than hard-coding either flavor.

### Command not found
Install the missing tool with your package manager (`brew install <tool>` or `apt install <tool>`).
