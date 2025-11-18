FROM ubuntu:22.04

# Author / Maintainer: luongnv89
LABEL maintainer="luongnv89"

ENV DEBIAN_FRONTEND=noninteractive

# Update and install baseline CLI/dev tooling
RUN set -eux; \
    echo "[Base] Updating apt cache and installing CLI tools"; \
    apt-get update; \
    apt-get install -y \
        git vim wget curl zsh \
        ca-certificates gnupg lsb-release \
        software-properties-common \
        build-essential \
        locales \
        unzip \
        fontconfig \
        # Monitoring and utilities
        btop ripgrep bat \
        # Extra build tooling for editor/plugins
        ninja-build gettext cmake unzip curl; \
    echo "[Base] Cleaning apt metadata"; \
    rm -rf /var/lib/apt/lists/*

# Configure UTF-8 locale for consistent tooling behavior
RUN set -eux; \
    echo "[Locale] Generating en_US.UTF-8 locale"; \
    locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install Node.js (LTS) and npm
RUN set -eux; \
    echo "[Node] Preparing NodeSource repository"; \
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -; \
    echo "[Node] Installing Node.js and npm"; \
    apt-get update; \
    apt-get install -y nodejs; \
    npm install -g npm@latest

# Install Python 3.12 and pip, set as default
RUN set -eux; \
    echo "[Python] Adding deadsnakes PPA"; \
    add-apt-repository ppa:deadsnakes/ppa -y; \
    apt-get update; \
    echo "[Python] Installing Python 3.12 toolchain"; \
    apt-get install -y python3.12 python3.12-venv; \
    echo "[Python] Bootstrapping pip for Python 3.12"; \
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12; \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1; \
    update-alternatives --install /usr/bin/pip3 pip3 /usr/local/bin/pip3.12 1

# Install Oh My Zsh for a richer shell experience
RUN set -eux; \
    echo "[Zsh] Installing Oh My Zsh"; \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Oh My Zsh plugins
RUN set -eux; \
    echo "[Zsh] Fetching zsh plugins"; \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting; \
    git clone https://github.com/zsh-users/zsh-autosuggestions.git /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions; \
    git clone https://github.com/zsh-users/zsh-completions.git /root/.oh-my-zsh/custom/plugins/zsh-completions

# Copy custom theme into Oh My Zsh
COPY wedisagree.zsh-theme /root/.oh-my-zsh/themes/wedisagree.zsh-theme

# Configure Vim with useful plugins
COPY .vimrc /root/.vimrc
RUN set -eux; \
    echo "[Vim] Installing vim-plug and plugins"; \
    curl -fLo /root/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim; \
    TERM=xterm-256color vim +'PlugInstall --sync' +qa

# Install JetBrains Mono Nerd Font for improved terminal typography
RUN set -eux; \
    echo "[Fonts] Installing JetBrainsMono Nerd Font"; \
    mkdir -p /usr/share/fonts/nerd-fonts; \
    wget -O /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip; \
    unzip /tmp/JetBrainsMono.zip -d /usr/share/fonts/nerd-fonts/; \
    fc-cache -fv; \
    rm /tmp/JetBrainsMono.zip

# Set up zsh as default shell
RUN set -eux; \
    echo "[Shell] Setting default shell to zsh"; \
    chsh -s $(which zsh)

# Configure Oh My Zsh theme and plugins
RUN sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="wedisagree"/' /root/.zshrc; \
    sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)/' /root/.zshrc

# Display a friendly welcome message on login
RUN cat <<'EOF' >> /root/.zshrc

echo ""
echo "Welcome to the u2204dev container!"
if command -v python3 >/dev/null 2>&1; then
  PY_VER="$(python3 --version 2>/dev/null)"
else
  PY_VER="Python: not installed"
fi
if command -v node >/dev/null 2>&1; then
  NODE_VER="Node.js $(node --version 2>/dev/null)"
else
  NODE_VER="Node.js: not installed"
fi
if command -v npm >/dev/null 2>&1; then
  NPM_VER="npm $(npm --version 2>/dev/null)"
else
  NPM_VER="npm: not installed"
fi
echo "Shell: Oh My Zsh + wedisagree theme"
echo "Editor: Vim with plugins"
echo "$PY_VER"
echo "$NODE_VER"
echo "$NPM_VER"
echo ""

EOF

# Drop into zsh by default for interactive containers
CMD [ "zsh" ]
