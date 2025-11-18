# u2204dev – Ubuntu 22.04 Development Image

This image bundles a productive CLI environment for day-to-day development on Ubuntu 22.04.

## Features

- **Shell:** Oh My Zsh with the custom `wedisagree` theme and syntax/auto-suggestion plugins.
- **Editor:** Vim configured with vim-plug plus plugins (fzf, NERDTree, GitGutter, vim-surround, auto-pairs, etc.).
- **Languages/Tooling:** Node.js (LTS) + npm, Python 3.12 + pip, build-essential, ripgrep, bat, btop, git, and more.
- **Fonts:** JetBrains Mono Nerd Font pre-installed for consistent terminal appearance.
- **Welcome prompt:** Displays the shell/editor plus detected Python/Node/npm versions when you start a shell.

## Build

```bash
docker build -t luongnv89/u2204dev -f u2204dev/Dockerfile u2204dev
```

## Run

```bash
docker run --rm -it -v "$PWD":/workspace luongnv89/u2204dev zsh
```

## CI/CD

The repository includes a GitHub Actions workflow (`.github/workflows/build-u2204dev.yml`) that builds and pushes this image to GitHub Container Registry (`ghcr.io/<owner>/u2204dev`) whenever `main` changes.
