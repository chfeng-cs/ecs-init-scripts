#!/bin/bash

EMAIL_ESCAPED='\x65\x74\x68\x61\x6e\x2e\x66\x65\x6e\x67\x63\x68\x40\x67\x6d\x61\x69\x6c\x2e\x63\x6f\x6d'
EMAIL=$(printf '%b' "$EMAIL_ESCAPED")
FULL_NAME="Ethan Feng"
MIN_ZSH_VERSION="5.1.0"
MIN_GIT_VERSION="2.20.0"

MIHOMO_VERSION="v1.19.30"
MIHOMO_ARCHIVE="mihomo-linux-amd64-v1-go120-${MIHOMO_VERSION}.gz"
MIHOMO_MD5="25f60e0d0b91d0e414806a269a7e3800"
MIHOMO_DIR="$HOME/.bin/mihomo"
MIHOMO_CACHE_DIR="$HOME/.cache/ecs-init-scripts"
MIHOMO_RELEASE_URL="https://github.com/MetaCubeX/mihomo/releases/download/${MIHOMO_VERSION}/${MIHOMO_ARCHIVE}"
MIHOMO_GITEE_URL="https://gitee.com/chfeng-cs/scripts/raw/master/${MIHOMO_ARCHIVE}"
MIHOMO_GITHUB_URL="https://raw.githubusercontent.com/chfeng-cs/ecs-init-scripts/master/${MIHOMO_ARCHIVE}"

PKG_FAMILY=""
CMD=""

detect_os() {
    local ID
    local PRETTY_NAME

    [ -r /etc/os-release ] || return 1
    . /etc/os-release
    case "${ID:-}" in
        debian|ubuntu)
            PKG_FAMILY="debian"
            command -v nala >/dev/null 2>&1 && CMD="nala" || CMD="apt-get"
            ;;
        rhel|centos|rocky|almalinux|fedora|amzn)
            PKG_FAMILY="rhel"
            command -v dnf >/dev/null 2>&1 && CMD="dnf" || CMD="yum"
            ;;
        *)
            echo "Unsupported system: ${PRETTY_NAME:-unknown}"
            return 1
            ;;
    esac

    command -v "$CMD" >/dev/null 2>&1 || return 1
    echo "==> ${PRETTY_NAME:-$ID} ($CMD)"
}

bootstrap_sync() {
    local SYNC_DIR="$HOME/.local/bin"
    local SYNC_SCRIPT="$SYNC_DIR/sync-dotfiles"

    mkdir -p "$SYNC_DIR"
    if [ -x "$SYNC_SCRIPT" ]; then
        echo "[SKIP] sync-dotfiles already installed"
        source "$SYNC_SCRIPT"
        return 0
    fi

    wget -q "https://gitee.com/chfeng-cs/ecs-init-scripts/raw/master/sync-dotfiles.sh" -O "$SYNC_SCRIPT" || true
    if [ ! -s "$SYNC_SCRIPT" ]; then
        wget -q "https://raw.githubusercontent.com/chfeng-cs/ecs-init-scripts/master/sync-dotfiles.sh" -O "$SYNC_SCRIPT"
    fi
    if [ ! -s "$SYNC_SCRIPT" ]; then
        echo "Failed to download sync-dotfiles"
        exit 1
    fi
    chmod +x "$SYNC_SCRIPT"
    source "$SYNC_SCRIPT"
}

version_ge() {
    [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

zsh_version_ok() {
    command -v zsh >/dev/null 2>&1 &&
        version_ge "$(zsh --version | awk '{print $2}')" "$MIN_ZSH_VERSION"
}

git_version_ok() {
    command -v git >/dev/null 2>&1 &&
        version_ge "$(git --version | awk '{print $3}')" "$MIN_GIT_VERSION"
}

ensure_nala() {
    if [[ "$CMD" == "apt-get" ]] && ! command -v nala >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y nala
        if command -v nala >/dev/null 2>&1; then
            CMD="nala"
        fi
    fi
}

install_sw() {
    local packages=()
    local command_name

    for command_name in curl vim wget; do
        command -v "$command_name" >/dev/null 2>&1 || packages+=("$command_name")
    done
    command -v gcc >/dev/null 2>&1 && command -v make >/dev/null 2>&1 || {
        if [[ "$PKG_FAMILY" == "rhel" ]]; then
            packages+=(gcc gcc-c++ make)
        else
            packages+=(build-essential)
        fi
    }
    git_version_ok || packages+=(git)
    zsh_version_ok || packages+=(zsh)

    if [ "${#packages[@]}" -eq 0 ]; then
        echo "[SKIP] required software already installed"
        return 0
    fi

    ensure_nala
    if [[ "$PKG_FAMILY" == "rhel" ]]; then
        sudo "$CMD" makecache
    else
        sudo "$CMD" update
    fi
    sudo "$CMD" install -y "${packages[@]}"

    if ! git_version_ok; then
        echo "Git $MIN_GIT_VERSION or newer is required."
        return 1
    fi
    if ! zsh_version_ok; then
        echo "Zsh $MIN_ZSH_VERSION or newer is required."
        return 1
    fi
}

download_if_missing() {
    local primary_url="$1"
    local fallback_url="$2"
    local target_file="$3"

    if [ -s "$target_file" ]; then
        echo "[SKIP] $(basename "$target_file") already exists"
        return 0
    fi
    download_with_fallback "$primary_url" "$fallback_url" "$target_file"
}

init_zsh() {
    local INSTALL_DIR="$HOME/ohmyzsh"
    local INSTALL_SH="$INSTALL_DIR/tools/install.sh"
    local TARGET_USER=${SUDO_USER:-${USER}}
    local ZSH_PATH
    local CURRENT_SHELL
    local AUTO_SUG_DIR
    local POWER_LEVEL_10K_DIR
    local ZSHRC_EXISTED=0

    cd ~
    [ -s "$HOME/.zshrc" ] && ZSHRC_EXISTED=1
    if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
        echo "[SKIP] oh-my-zsh already installed"
    else
        if [ ! -f "$INSTALL_SH" ]; then
            if [ -e "$INSTALL_DIR" ]; then
                echo "Incomplete oh-my-zsh installer directory: $INSTALL_DIR"
                return 1
            fi
            git clone https://gitee.com/whisky-root/ohmyzsh.git "$INSTALL_DIR"
        fi
        sed -i 's/github.com\/\${REPO}/gitee.com\/\${REPO}/' "$INSTALL_SH"
        sed -i 's/REPO:-ohmyzsh\/ohmyzsh/REPO:-whisky-root\/ohmyzsh/' "$INSTALL_SH"
        sh "$INSTALL_SH" --unattended
    fi

    ZSH_PATH=$(command -v zsh)
    CURRENT_SHELL=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f7)
    if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
        echo "[SKIP] login shell is already zsh"
    elif [ "$TARGET_USER" = "root" ]; then
        chsh -s "$ZSH_PATH" "$TARGET_USER"
    else
        sudo chsh -s "$ZSH_PATH" "$TARGET_USER"
    fi

    # plugins
    AUTO_SUG_DIR=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    if [ -f "$AUTO_SUG_DIR/zsh-autosuggestions.zsh" ]; then
        echo "[SKIP] zsh-autosuggestions already installed"
    elif [ -e "$AUTO_SUG_DIR" ]; then
        echo "Incomplete zsh-autosuggestions directory: $AUTO_SUG_DIR"
        return 1
    else
        mkdir -p "$(dirname "$AUTO_SUG_DIR")"
        git clone https://gitee.com/keman5/zsh-autosuggestions.git "$AUTO_SUG_DIR"
    fi

    # powerlevel10k theme
    POWER_LEVEL_10K_DIR=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    if [ -f "$POWER_LEVEL_10K_DIR/powerlevel10k.zsh-theme" ]; then
        echo "[SKIP] powerlevel10k already installed"
    elif [ -e "$POWER_LEVEL_10K_DIR" ]; then
        echo "Incomplete powerlevel10k directory: $POWER_LEVEL_10K_DIR"
        return 1
    else
        mkdir -p "$(dirname "$POWER_LEVEL_10K_DIR")"
        git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git "$POWER_LEVEL_10K_DIR"
    fi
    download_if_missing \
        https://gitee.com/chfeng-cs/scripts/raw/master/.p10k-vscode.zsh \
        https://raw.githubusercontent.com/chfeng-cs/ecs-init-scripts/master/.p10k-vscode.zsh \
        "$HOME/.p10k-vscode.zsh"
    download_if_missing \
        https://gitee.com/chfeng-cs/scripts/raw/master/.p10k.zsh \
        https://raw.githubusercontent.com/chfeng-cs/ecs-init-scripts/master/.p10k.zsh \
        "$HOME/.p10k.zsh"
    if [ "$ZSHRC_EXISTED" -eq 1 ]; then
        echo "[SKIP] .zshrc already exists"
    else
        download_with_fallback \
            https://gitee.com/chfeng-cs/scripts/raw/master/.zshrc \
            https://raw.githubusercontent.com/chfeng-cs/ecs-init-scripts/master/.zshrc \
            "$HOME/.zshrc"
    fi

}

guarantee_pk() {
    if [ "$#" -ne 3 ]; then
        return 1
    fi

    local key_type="$1"
    local public_key="$2"
    local comment="$3"

    if awk -v key="$public_key" '$2 == key { found = 1; exit } END { exit !found }' authorized_keys; then
        echo "$comment already exists"
        return 0
    fi

    printf '%s %s %s\n' "$key_type" "$public_key" "$comment" >> authorized_keys
    echo "$comment added"
}

init_ssh() {
    cd ~
    mkdir -p .ssh
    chmod 700 .ssh
    cd .ssh
    touch authorized_keys
    chmod 600 authorized_keys
    guarantee_pk ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDBf5jaDI4zVycmTJNzBbV46xwyudolNQYpxYkdRkURvDIX3NGzzM34kjWX6gKjze7p75tCyQpHL/mIZMyp05jD7QiAzgmx8OGdz7eKKSx2W5msdqxT+7rnTtGZSLlLeOs4hJqT5FGx+0BvIla+JlhiWzbl1hAp1gXyFcvFd8jEX6V3Ry1fZGJ5dcWrh3ZOwHts6a5aRHXKMhvO+Jtt6DY2CyCiLzJprtQ65mLs1l7O0geLRINDgjoZUzLA+uPjvEn2Ka9CT+URPV6Dzohh1WZUFn+l0H9rBto9ZfIkuGO+kG/wZ3h12dhXz6YeKK4SaPBkCkCOF/l4lGwC0iGT7EB dande@fch-pc # My PC public key
    guarantee_pk ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/FDGrk167CNnOxTu+IB2zelSBjaHntL5pa9nhd/JVsqURcRH64dWvxsDbDUrdp3g/uoRqBDorCuZiNeL/JOhqpkw7K/Mm9J6TC+VybhiiMXG/0ca482ek6vY1xXvfmwjo/jyMTlHUNIohFbyrI4DOK968hM2bWsl0rV5hAkmjSXRaSLwjUbOWYbuZYeYeS6UX5JcQlWE4E02hit8VGtyW+ArIbcHBoFnoERAPh7LwfgQKqBmU3DKCewgJJ98F6GRhHHcUZtSCYBj1TCKPgJ304lPlfnwVvwAkiUbHn8k/7XRq+GFU4zMOw1YNh/rn28AZM+HNHCa8/uLugBLqADh+915vrjqvo+6OMHrDmpXyAoixZYpq7lgTjc1Sbuv/oSO/kiuU89uJpm95EiS84Xg9+j2zj4SS8b+DEe06/QTaz76BhkygWLQJqtJAV+3BJU4IgijKuna4aXh23OIwT/VQ8EBm7e7oP3c49lk5+uR1jFzLYC39lpC1pWaYc8odPbM= feng@DESKTOP-4BCF5JK # Add work pk

    cd ~
}

# vim
init_vim() {
    cd ~
    if [ -d "$HOME/.vim/bundle/Vundle.vim/.git" ]; then
        echo "[SKIP] Vundle already installed"
    elif [ -e "$HOME/.vim/bundle/Vundle.vim" ]; then
        echo "Incomplete Vundle directory: $HOME/.vim/bundle/Vundle.vim"
        return 1
    else
        git clone https://gitee.com/mirrors/Vundle.git "$HOME/.vim/bundle/Vundle.vim"
    fi
    download_if_missing \
        https://gitee.com/chfeng-cs/simple-scripts/raw/master/.vimrc \
        https://raw.githubusercontent.com/chfeng-cs/simple-scripts/master/.vimrc \
        "$HOME/.vimrc"
}

# bash
init_bash() {
    cd ~
    download_if_missing \
        https://gitee.com/chfeng-cs/scripts/raw/master/.bashrc \
        https://raw.githubusercontent.com/chfeng-cs/ecs-init-scripts/master/.bashrc \
        "$HOME/.bashrc"
    download_if_missing \
        https://gitee.com/chfeng-cs/scripts/raw/master/.profile \
        https://raw.githubusercontent.com/chfeng-cs/ecs-init-scripts/master/.profile \
        "$HOME/.profile"
}

# git
init_git() {
    if command -v git >/dev/null 2>&1; then
        git config --global user.name "$FULL_NAME"
        git config --global user.email "$EMAIL"
        git config --global alias.co checkout
        git config --global alias.br branch
        git config --global alias.ci commit
        git config --global alias.st status
        git config --global alias.mg merge
        git config --global alias.md 'commit --amend'
        git config --global alias.dt difftool
        git config --global alias.mt mergetool
        git config --global alias.cf config
        git config --global alias.last 'log -1 HEAD'
        git config --global alias.line 'log --oneline'
        git config --global alias.latest "for-each-ref --sort=-committerdate --format='%(committerdate:short) %(refname:short) [%(committername)]'"
    else
        echo "git is not installed on you system."
    fi
}

download_mihomo() {
    local archive_file="$1"
    local url
    local actual_md5

    if [ -s "$archive_file" ]; then
        actual_md5=$(md5sum "$archive_file" | awk '{print $1}')
        if [ "$actual_md5" = "$MIHOMO_MD5" ]; then
            echo "[SKIP] using cached $MIHOMO_ARCHIVE"
            return 0
        fi
        rm -f "$archive_file"
    fi

    for url in "$MIHOMO_GITHUB_URL" "$MIHOMO_RELEASE_URL" "$MIHOMO_GITEE_URL"; do
        echo "==> downloading $MIHOMO_ARCHIVE from $url"
        if curl -fL --progress-bar --connect-timeout 10 --speed-limit 1 --speed-time 10 \
            --output "$archive_file" "$url"; then
            actual_md5=$(md5sum "$archive_file" | awk '{print $1}')
            if [ "$actual_md5" = "$MIHOMO_MD5" ]; then
                return 0
            fi
            echo "  MD5 mismatch, trying the next source"
        else
            echo "  download failed, trying the next source"
        fi
        rm -f "$archive_file"
    done

    rm -f "$archive_file"
    return 1
}

write_start_mihomo() {
    cat > "$MIHOMO_DIR/start_mihomo" <<'EOF'
#!/bin/bash

MIHOMO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MIHOMO_BIN="$MIHOMO_DIR/mihomo"
MIHOMO_CONFIG="$MIHOMO_DIR/clash.yaml"
MIHOMO_LOG="$MIHOMO_DIR/mihomo.log"

if [ ! -x "$MIHOMO_BIN" ]; then
    echo "mihomo executable not found: $MIHOMO_BIN"
    exit 1
fi
if [ ! -s "$MIHOMO_CONFIG" ]; then
    echo "mihomo config not found: $MIHOMO_CONFIG"
    exit 1
fi
if pgrep -x mihomo >/dev/null 2>&1; then
    echo "mihomo is already running"
    exit 0
fi

nohup "$MIHOMO_BIN" -d "$MIHOMO_DIR" -f "$MIHOMO_CONFIG" \
    > "$MIHOMO_LOG" 2>&1 &
echo "mihomo started (PID $!), log: $MIHOMO_LOG"
EOF

    chmod +x "$MIHOMO_DIR/start_mihomo"
}

add_mihomo_to_path() {
    local path_line='export PATH="$HOME/.bin/mihomo:$PATH"'

    if ! grep -Fqx "$path_line" "$HOME/.zshrc" 2>/dev/null; then
        {
            echo
            echo '# mihomo commands'
            echo "$path_line"
        } >> "$HOME/.zshrc"
    fi
}

download_clash_config() {
    local subscription_url
    local config_tmp="$MIHOMO_DIR/.clash.yaml.new"
    local sanitized_tmp="$MIHOMO_DIR/.clash.yaml.sanitized"
    local mixed_port

    read -r -p "Clash subscription URL (press Enter to keep current config): " subscription_url
    if [ -z "$subscription_url" ]; then
        if [ -s "$MIHOMO_DIR/clash.yaml" ]; then
            echo "[SKIP] keeping existing Clash config"
        else
            echo "No Clash config was provided."
        fi
        return 0
    fi

    rm -f "$config_tmp"
    if ! curl -fsSL --connect-timeout 15 --speed-limit 1 --speed-time 15 \
        --user-agent mihomo --output "$config_tmp" "$subscription_url"; then
        rm -f "$config_tmp"
        echo "Failed to download Clash config. The existing config was not changed."
        return 1
    fi

    sed -i \
        -e '/^[[:space:]]*-[[:space:]].*GEOIP,/d' \
        -e '/^[[:space:]]*-[[:space:]].*GEOSITE,/d' \
        -e '/^[[:space:]]*-[[:space:]]*[Gg][Ee][Oo][Ss][Ii][Tt][Ee]:/d' \
        -e 's/^\([[:space:]]*geoip:[[:space:]]*\)true[[:space:]]*$/\1false/' \
        "$config_tmp"
    awk '
        /^[[:space:]]+geosite:/ {
            skip_indent = match($0, /[^ ]/) - 1
            next
        }
        skip_indent && /^[[:space:]]*$/ { next }
        skip_indent && match($0, /[^ ]/) - 1 > skip_indent { next }
        { skip_indent = 0; print }
    ' "$config_tmp" > "$sanitized_tmp"
    mv "$sanitized_tmp" "$config_tmp"
    if grep -q '^geo-auto-update:' "$config_tmp"; then
        sed -i 's/^geo-auto-update:.*/geo-auto-update: false/' "$config_tmp"
    else
        sed -i '1i geo-auto-update: false' "$config_tmp"
    fi
    chmod 600 "$config_tmp"
    mv "$config_tmp" "$MIHOMO_DIR/clash.yaml"
    echo "Clash config saved to $MIHOMO_DIR/clash.yaml"

    mixed_port=$(awk '/^[[:space:]]*mixed-port:[[:space:]]*[0-9]+/ {print $2; exit}' \
        "$MIHOMO_DIR/clash.yaml")
    if [ -n "$mixed_port" ] && [ "$mixed_port" != "7897" ]; then
        echo "Note: config mixed-port is $mixed_port, but ~/.zshrc currently uses proxy port 7897."
    fi
}

install_mihomo() {
    local answer
    local archive_file="$MIHOMO_CACHE_DIR/$MIHOMO_ARCHIVE"
    local version_file="$MIHOMO_DIR/.version"

    if [ -x "$MIHOMO_DIR/mihomo" ] && [ "$(cat "$version_file" 2>/dev/null)" = "$MIHOMO_VERSION" ]; then
        echo "[SKIP] mihomo $MIHOMO_VERSION already installed"
    else
        read -r -p "Install mihomo ${MIHOMO_VERSION}? [y/N] " answer
        if [[ ! "$answer" =~ ^[Yy]$ ]]; then
            echo "Skipping mihomo installation."
            return 0
        fi

        case "$(uname -m)" in
            x86_64|amd64) ;;
            *)
                echo "Unsupported architecture: $(uname -m). This package is for amd64 only."
                return 1
                ;;
        esac

        mkdir -p "$MIHOMO_DIR" "$MIHOMO_CACHE_DIR"
        if ! download_mihomo "$archive_file"; then
            echo "Failed to download mihomo from all sources."
            return 1
        fi

        if ! gzip -dc "$archive_file" > "$MIHOMO_DIR/mihomo"; then
            rm -f "$MIHOMO_DIR/mihomo"
            echo "Failed to extract mihomo."
            return 1
        fi
        chmod +x "$MIHOMO_DIR/mihomo"
        printf '%s\n' "$MIHOMO_VERSION" > "$version_file"
        echo "mihomo installed in $MIHOMO_DIR"
    fi

    write_start_mihomo
    add_mihomo_to_path
    download_clash_config || true
    echo "Run 'source ~/.zshrc', then use start_mihomo."
}

main() {
    detect_os || return 1
    bootstrap_sync || return 1
    install_sw || return 1
    init_ssh || return 1
    init_bash || return 1
    init_git || return 1
    init_vim || return 1
    init_zsh || return 1
    install_mihomo || return 1
}

main
