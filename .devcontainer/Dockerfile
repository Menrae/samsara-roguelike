# syntax=docker/dockerfile:1
FROM debian:bookworm-slim

# Bump this to update Godot. Asset names follow:
#   https://github.com/godotengine/godot/releases/download/{GODOT_VERSION}-stable/Godot_v{GODOT_VERSION}-stable_linux.x86_64.zip
ARG GODOT_VERSION=4.7.1
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

ENV DEBIAN_FRONTEND=noninteractive

# Runtime libs Godot links against even in --headless mode, plus fetch/build tooling.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libx11-6 \
    libxcursor1 \
    libxinerama1 \
    libxrandr2 \
    libxi6 \
    libgl1 \
    libasound2 \
    libfontconfig1 \
    libudev1 \
    libxkbcommon0 \
    libxkbcommon-x11-0 \
    libdbus-1-3 \
    libpulse0 \
    libxext6 \
    libxrender1 \
    unzip \
    wget \
    ca-certificates \
    git \
    python3 \
    python3-pip \
    python3-venv \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Non-root user matching the WSL host UID/GID so bind-mounted files never come back root-owned.
RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# Godot editor binary.
RUN wget -q -O /tmp/godot.zip \
    "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
    && unzip -q /tmp/godot.zip -d /tmp/godot-extract \
    && mv /tmp/godot-extract/Godot_v${GODOT_VERSION}-stable_linux.x86_64 /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm -rf /tmp/godot.zip /tmp/godot-extract

# Export templates, installed to the path Godot 4 expects under the non-root user's home.
RUN wget -q -O /tmp/templates.tpz \
    "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" \
    && mkdir -p /home/${USERNAME}/.local/share/godot/export_templates \
    && unzip -q /tmp/templates.tpz -d /tmp/templates-extract \
    && mv /tmp/templates-extract/templates "/home/${USERNAME}/.local/share/godot/export_templates/${GODOT_VERSION}.stable" \
    && rm -rf /tmp/templates.tpz /tmp/templates-extract \
    && chown -R ${USER_UID}:${USER_GID} /home/${USERNAME}/.local

# Fail the build loudly if the editor binary is broken.
RUN godot --headless --version

# gdtoolkit 4.x is the line compatible with Godot 4 GDScript.
RUN pip3 install --no-cache-dir --break-system-packages "gdtoolkit==4.*"

RUN gdformat --version && gdlint --version || true

USER ${USERNAME}
WORKDIR /workspaces/samsara-roguelike

# Pre-create config/cache dirs so named volumes mounted here inherit correct
# ownership from the image instead of being created root-owned by Docker.
RUN mkdir -p /home/${USERNAME}/.config/godot \
             /home/${USERNAME}/.cache/godot \
             /home/${USERNAME}/.local/share/godot \
    && chown -R ${USER_UID}:${USER_GID} \
             /home/${USERNAME}/.config \
             /home/${USERNAME}/.cache \
             /home/${USERNAME}/.local
