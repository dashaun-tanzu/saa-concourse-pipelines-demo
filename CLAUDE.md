# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

macOS-compatible demo for running **Spring Application Advisor (SAA)** upgrade pipelines on **Concourse CI**. It discovers Java/Spring Boot repos across GitHub orgs and GitLab groups, runs SAA against each, and opens pull/merge requests with version upgrades. A local Nexus proxies the Broadcom Spring Enterprise Maven repo so pipelines don't need direct credentials per build.

## Running the Demo

```bash
# Prerequisites
brew install vendir httpie   # also needs Docker Desktop and Bitwarden CLI (`bw`)

# Configure secrets (sources from Bitwarden via `bw get`)
source .envrc

# Run the full demo
./demo.sh
```

`demo.sh` is destructive on each run: it wipes `upgrade-example/`, runs `docker compose down --remove-orphans` + `docker volume prune -f`, then re-stages Concourse, Nexus, and pipelines from scratch.

## Key Commands

- **Start the stack**: `./demo.sh` (Concourse → `localhost:8080`, Nexus → `localhost:9081`, login `test`/`test` for Concourse, `admin`/`admin123` for Nexus)
- **Reset demo repos**: `./repo-management.sh` — DANGEROUS: deletes every repo in `TARGET_ORG` (default `dashaun-demo`), then re-forks `SOURCE_REPOS` into it. Always confirm `TARGET_ORG` before running.
- **Sync vendored deps**: `vendir sync` (pulls `paxtonhare/demo-magic` into `vendir/demo-magic/`)
- **Fly CLI** (after demo starts): `./upgrade-example/fly -t advisor-demo <command>` — the binary is downloaded from the running Concourse at `install_fly` time and matches the host platform.

There are no tests or a build step for this repo itself — it is a shell-script orchestrator for external pipelines.

## Architecture

### Two-tier Concourse design

1. **Spawner pipeline** (`pipelines/spawner-pipeline.yml`): Runs every 15 minutes on the `main` team. Two crawl tasks (`crawl-github`, `crawl-gitlab`) page the respective APIs for each org/group in `GITHUB_ORGS` / `GITLAB_GROUPS`, skip archived/disabled repos, and keep only those with a `pom.xml` or `build.gradle` in the root. Two `across` steps then call `set_pipeline` once per discovered repo, **targeting a Concourse team named after the org/group** (created earlier by `install_fly` in `demo.sh`).

2. **Per-repo pipelines** — the spawner instantiates one of:
   - `pipelines/github-pipeline.yml` for each GitHub repo
   - `pipelines/gitlab-pipeline.yml` for each GitLab project
   - `pipelines/repo-pipeline.yml` is an older single-repo template (30-minute trigger). Not invoked by the spawner; kept for manual `fly set-pipeline` use.

   Each per-repo pipeline runs on the `ghcr.io/dashaun/scpd-runner:latest` image, checks for any open PR first (skips the run if one exists), runs SAA (`advisor build-config get` → `advisor upgrade-plan get/apply --push`), and **falls back to an OpenRewrite recipe** (`MavenUpgradeSpringBootToLatestPatch` from `dashaun-tanzu/openrewrite-recipes`) when SAA reports "No upgrade plans available" — that path opens a fresh branch + PR via `gh`.

### Runner image

The runner is **not built in this repo**. It lives at `ghcr.io/dashaun/scpd-runner` (managed in a separate repository — see the `publish_runner` stub in `demo.sh`). The image provides Ubuntu + SDKMAN (Java 21) + `gh` CLI + Maven; per-pipeline tasks write a transient `~/.m2/settings.xml` pointing at the in-cluster Nexus.

### Nexus side-car

`install_concourse` in `demo.sh` appends two services to the downloaded Concourse `docker-compose.yml`:
- `saa-nexus` (Sonatype Nexus 3, host-published on `9081` → container `8081`)
- `nexus-config` — a one-shot `curlimages/curl` container that waits for Nexus, accepts the EULA, enables anonymous read, creates a `spring-enterprise` proxy of `packages.broadcom.com/artifactory/spring-enterprise` using `MAVEN_USERNAME`/`MAVEN_PASSWORD`, and adds it to the `maven-public` group.

Pipelines reach Nexus via its **container IP** (resolved via `docker inspect` in `install_fly` and passed in as the `nexus_url` fly variable) — not via `host.docker.internal`. This means the URL changes if you re-create the Nexus container, so re-running `demo.sh` is the supported way to refresh it.

### Secrets

All secrets come from **Bitwarden CLI** (`bw`) via `.envrc`. Required Bitwarden items:
- `dockerhub-access-token` (registry pulls — Concourse uses it for `concourse/time-resource` and `alpine`)
- `SAA_CONCOURSE_DEMO` (Git PR author email + GitHub PAT for PR creation)
- `spring-enterprise-mvn-remote` (Broadcom Maven creds, used by Nexus proxy)

`.envrc` also sets `GITHUB_ORGS` (JSON array) and `ADVISOR_VERSION`. `GITLAB_TOKEN` / `GITLAB_GROUPS` / `GITLAB_HOST` are optional and default to empty/`gitlab.com`.

## macOS / cross-platform gotchas

- All in-place `sed` uses BSD syntax: `sed -i ''` with an empty backup arg. `demo.sh` picks the right form via `OSTYPE` (`SED_INPLACE` array). When editing scripts, follow the same pattern instead of hard-coding GNU `sed -i`.
- Prefer `grep -oE` (POSIX ERE), not `grep -oP` (GNU-only).
- `demo.sh` strips `cgroup: host` from the downloaded Concourse compose file on macOS (Docker Desktop doesn't support it); `privileged: true` is intentionally kept — the containerd worker needs it for iptables.
- The fly binary is fetched per-platform: `darwin` on macOS, `linux` elsewhere (`FLY_PLATFORM` in `demo.sh`).
- Local Java (`.sdkmanrc`) is pinned to `8.0.482-librca` so the shell prompt in the demo recording matches; the pipeline runner uses Java 21 inside the container.
