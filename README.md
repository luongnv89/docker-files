# docker-files

Curated Docker images for different development environments. Each image lives in its own directory (e.g., `u2204dev/`) with a dedicated Dockerfile and per-image README describing that environment.

## Available Images

| Folder    | Description                                    | Docs                      |
|-----------|------------------------------------------------|---------------------------|
| `u2204dev/` | Ubuntu 22.04 CLI/dev environment with Oh My Zsh, wedisagree theme, Vim plugins, Node.js, Python 3.12, etc. | [`u2204dev/README.md`](u2204dev/README.md) |

> As new images are added, follow the same pattern: create `<image-name>/Dockerfile`, add a `<image-name>/README.md`, and update this table.

## Global CI/CD (GitHub Container Registry)

The repository uses GitHub Actions to build/publish images to GHCR:

- `.github/workflows/build-u2204dev.yml` builds `u2204dev` and pushes `ghcr.io/<owner>/u2204dev`.
- Workflows authenticate with the built-in `GITHUB_TOKEN`; ensure the repo has package publishing permissions and adjust package visibility in GitHub Packages as needed.
- Each build publishes a `latest` tag plus an immutable commit `sha` tag, and produces a multi-architecture manifest (linux/amd64 + linux/arm64) so M-series Macs/ARM servers can pull without a fallback.

Use **Actions → Build and Publish u2204dev** to trigger the workflow manually.

### Consume the published image

1. Authenticate against GitHub Container Registry (requires a PAT with at least the `read:packages` scope):

   ```bash
   echo "${GH_PAT:?}" | docker login ghcr.io -u <your-github-username> --password-stdin
   ```

2. Pull the image that Actions publishes (`latest` or a specific commit SHA tag). The repo currently builds `ghcr.io/luongnv89/u2204dev`:

   ```bash
   docker pull ghcr.io/luongnv89/u2204dev:latest
   # or for a reproducible version:
   docker pull ghcr.io/luongnv89/u2204dev:<git-sha>
   ```

3. Run the container the same way you would if you built it locally:

   ```bash
   docker run --rm -it ghcr.io/luongnv89/u2204dev:latest zsh
   ```

> Tip: once authenticated, `docker compose` services can reference the GHCR image directly via `ghcr.io/luongnv89/u2204dev:<tag>`.

## Development Workflow

- Install the repo’s pre-commit hook so every commit runs formatting, linting, Docker build tests, and cleanup:

  ```bash
  ln -sf ../../scripts/pre-commit.sh .git/hooks/pre-commit
  ```

- You can also run the checks ad-hoc with `./scripts/pre-commit.sh`. The script:
  1. Formats shell scripts via `shfmt` (local install or Docker fallback).
  2. Lints shell scripts with ShellCheck and Dockerfiles with Hadolint.
  3. Builds the `u2204dev` image to ensure the Dockerfile stays healthy.
  4. Cleans Python caches and removes the temporary build image.
