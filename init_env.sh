#!/bin/bash

EMAIL="ethan.fengch@gmail.com"
FULL_NAME="Ethan Feng"

MIHOMO_VERSION="v1.19.30"
MIHOMO_ARCHIVE="mihomo-linux-amd64-v1-go120-${MIHOMO_VERSION}.gz"
MIHOMO_DIR="$HOME/.bin/mihomo"
MIHOMO_RELEASE_URL="https://github.com/MetaCubeX/mihomo/releases/download/${MIHOMO_VERSION}/${MIHOMO_ARCHIVE}"
MIHOMO_GITEE_URL="https://gitee.com/chfeng-cs/scripts/raw/master/${MIHOMO_ARCHIVE}"
MIHOMO_GITHUB_URL="https://raw.githubusercontent.com/chfeng-cs/ecs-init-scripts/master/${MIHOMO_ARCHIVE}"

CMD=""
if command -v nala >/dev/null 2>&1; then
    CMD="nala"
elif command -v apt-get >/dev/null 2>&1; then
    CMD="apt-get"
elif command -v yum >/dev/null 2>&1; then
    CMD="yum"
else
    echo "Unsupported System:"
    lsb_release -a
fi

bootstrap_sync() {
    local SYNC_DIR="$HOME/.local/bin"
    local SYNC_SCRIPT="$SYNC_DIR/sync-dotfiles"
    mkdir -p "$SYNC_DIR"
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

ensure_nala() {
    if [[ "$CMD" == "apt-get" ]] && ! command -v nala >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y nala
        if command -v nala >/dev/null 2>&1; then
            CMD="nala"
        fi
    fi
}

intsall_sw() {
    SW_LIST="build-essential curl git vim wget zsh"
    ensure_nala
    sudo $CMD update
    if [[ "$CMD" == "nala" ]]; then
        # Ubuntu or Debian
        sudo $CMD install -y $SW_LIST
    elif [[ "$CMD" == "apt-get" ]]; then
        # Ubuntu or Debian
        sudo $CMD -y install $SW_LIST
    else
        # CentOS
        sudo $CMD -y install $SW_LIST
    fi
}

init_zsh() {
    INSTALL_SH=~/ohmyzsh/tools/install.sh

    # check if zsh is installed
    if [ ! `which zsh` ]; then
        sudo $CMD -y install zsh
    fi

    cd ~
    # install zsh via gitee instead of github
    git clone https://gitee.com/whisky-root/ohmyzsh.git
    sed -i 's/github.com\/\${REPO}/gitee.com\/\${REPO}/' $INSTALL_SH
    sed -i 's/REPO:-ohmyzsh\/ohmyzsh/REPO:-whisky-root\/ohmyzsh/' $INSTALL_SH
    sh "$INSTALL_SH" --unattended
    TARGET_USER=${SUDO_USER:-${USER}}
    if [ "$TARGET_USER" != "root" ]; then
        sudo chsh -s "$(command -v zsh)" "$TARGET_USER"
    fi

    # plugins
    AUTO_SUG_DIR=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    if [ ! -f $AUTO_SUG_DIR ];then
        mkdir $AUTO_SUG_DIR
    fi
    git clone https://gitee.com/keman5/zsh-autosuggestions.git $AUTO_SUG_DIR

    # powerlevel10k theme
    POWER_LEVEL_10K_DIR=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    if [ ! -d $POWER_LEVEL_10K_DIR ];then
        git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git $POWER_LEVEL_10K_DIR
    fi
    download_with_fallback \
        https://gitee.com/chfeng-cs/scripts/raw/master/.p10k-vscode.zsh \
        https://raw.githubusercontent.com/chfeng-cs/ecs-init-scripts/master/.p10k-vscode.zsh \
        ~/.p10k-vscode.zsh
    download_with_fallback \
        https://gitee.com/chfeng-cs/scripts/raw/master/.p10k.zsh \
        https://raw.githubusercontent.com/chfeng-cs/ecs-init-scripts/master/.p10k.zsh \
        ~/.p10k.zsh
    download_with_fallback \
        https://gitee.com/chfeng-cs/scripts/raw/master/.zshrc \
        https://raw.githubusercontent.com/chfeng-cs/ecs-init-scripts/master/.zshrc \
        ~/.zshrc

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
    if [ ! -d .ssh ]; then
        mkdir -m 700 .ssh
    fi
    cd .ssh
    if [ ! -f authorized_keys ]; then 
		touch authorized_keys
		chmod 600 authorized_keys
	fi
    guarantee_pk ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDBf5jaDI4zVycmTJNzBbV46xwyudolNQYpxYkdRkURvDIX3NGzzM34kjWX6gKjze7p75tCyQpHL/mIZMyp05jD7QiAzgmx8OGdz7eKKSx2W5msdqxT+7rnTtGZSLlLeOs4hJqT5FGx+0BvIla+JlhiWzbl1hAp1gXyFcvFd8jEX6V3Ry1fZGJ5dcWrh3ZOwHts6a5aRHXKMhvO+Jtt6DY2CyCiLzJprtQ65mLs1l7O0geLRINDgjoZUzLA+uPjvEn2Ka9CT+URPV6Dzohh1WZUFn+l0H9rBto9ZfIkuGO+kG/wZ3h12dhXz6YeKK4SaPBkCkCOF/l4lGwC0iGT7EB dande@fch-pc # My PC public key
    guarantee_pk ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/FDGrk167CNnOxTu+IB2zelSBjaHntL5pa9nhd/JVsqURcRH64dWvxsDbDUrdp3g/uoRqBDorCuZiNeL/JOhqpkw7K/Mm9J6TC+VybhiiMXG/0ca482ek6vY1xXvfmwjo/jyMTlHUNIohFbyrI4DOK968hM2bWsl0rV5hAkmjSXRaSLwjUbOWYbuZYeYeS6UX5JcQlWE4E02hit8VGtyW+ArIbcHBoFnoERAPh7LwfgQKqBmU3DKCewgJJ98F6GRhHHcUZtSCYBj1TCKPgJ304lPlfnwVvwAkiUbHn8k/7XRq+GFU4zMOw1YNh/rn28AZM+HNHCa8/uLugBLqADh+915vrjqvo+6OMHrDmpXyAoixZYpq7lgTjc1Sbuv/oSO/kiuU89uJpm95EiS84Xg9+j2zj4SS8b+DEe06/QTaz76BhkygWLQJqtJAV+3BJU4IgijKuna4aXh23OIwT/VQ8EBm7e7oP3c49lk5+uR1jFzLYC39lpC1pWaYc8odPbM= feng@DESKTOP-4BCF5JK # Add work pk

    cd ~
}

# vim
init_vim() {
    cd ~
    if [ ! -d ~/.vim/bundle/Vundle.vim ]; then
        git clone https://gitee.com/mirrors/Vundle.git ~/.vim/bundle/Vundle.vim
    fi
    download_with_fallback \
        https://gitee.com/chfeng-cs/simple-scripts/raw/master/.vimrc \
        https://raw.githubusercontent.com/chfeng-cs/simple-scripts/master/.vimrc \
        ~/.vimrc
}

# bash
init_bash() {
    cd ~
    download_with_fallback \
        https://gitee.com/chfeng-cs/scripts/raw/master/.bashrc \
        https://raw.githubusercontent.com/chfeng-cs/ecs-init-scripts/master/.bashrc \
        ~/.bashrc
    download_with_fallback \
        https://gitee.com/chfeng-cs/scripts/raw/master/.profile \
        https://raw.githubusercontent.com/chfeng-cs/ecs-init-scripts/master/.profile \
        ~/.profile
}

# git
init_git() {
    if [ `which git` ]; then
        git config --global user.name $FULL_NAME
        git config --global user.email $EMAIL
        git config --global alias.co checkout
        git config --global alias.br branch
        git config --global alias.ci commit
        git config --global alias.st status
        git config --global alias.mg merge
        git config --global alias.md commit --amend
        git config --global alias.dt difftool
        git config --global alias.mt mergetool
        git config --global alias.cf config
        git config --global alias.last log -1 HEAD 2>/dev/null
        git config --global alias.line log --oneline 2>/dev/null
        git config --global alias.latest for-each-ref --sort=-committerdate --format='%(committerdate:short) %(refname:short) [%(committername)]' 2>/dev/null
    else
        echo "git is not installed on you system."
    fi
}

download_mihomo() {
    local archive_file="$1"
    local url

    for url in "$MIHOMO_RELEASE_URL" "$MIHOMO_GITEE_URL" "$MIHOMO_GITHUB_URL"; do
        echo "==> downloading mihomo from $url"
        if curl -fL --progress-bar --connect-timeout 10 --speed-limit 1 --speed-time 10 \
            --output "$archive_file" "$url"; then
            return 0
        fi
        echo "  download failed, trying the next source"
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
    local mixed_port

    read -r -p "Clash subscription URL (press Enter to skip): " subscription_url
    if [ -z "$subscription_url" ]; then
        echo "Skipped Clash config download. Add it later as $MIHOMO_DIR/clash.yaml"
        return 0
    fi

    if ! curl -fsSL --connect-timeout 15 --speed-limit 1 --speed-time 15 \
        --user-agent mihomo --output "$MIHOMO_DIR/clash.yaml" "$subscription_url"; then
        rm -f "$MIHOMO_DIR/clash.yaml"
        echo "Failed to download Clash config. The mihomo installation is still available."
        return 1
    fi

    chmod 600 "$MIHOMO_DIR/clash.yaml"
    echo "Clash config saved to $MIHOMO_DIR/clash.yaml"

    mixed_port=$(awk '/^[[:space:]]*mixed-port:[[:space:]]*[0-9]+/ {print $2; exit}' \
        "$MIHOMO_DIR/clash.yaml")
    if [ -n "$mixed_port" ] && [ "$mixed_port" != "7897" ]; then
        echo "Note: config mixed-port is $mixed_port, but ~/.zshrc currently uses proxy port 7897."
    fi
}

install_mihomo() {
    local answer
    local archive_file="$MIHOMO_DIR/mihomo.gz"

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

    mkdir -p "$MIHOMO_DIR"
    if ! download_mihomo "$archive_file"; then
        echo "Failed to download mihomo from all sources."
        return 1
    fi

    if ! gzip -df "$archive_file"; then
        echo "Failed to extract mihomo."
        return 1
    fi
    chmod +x "$MIHOMO_DIR/mihomo"

    write_start_mihomo
    add_mihomo_to_path
    echo "mihomo installed in $MIHOMO_DIR"
    download_clash_config || true
    echo "Run 'source ~/.zshrc', then use start_mihomo."
}

main() {
    bootstrap_sync
    intsall_sw
    init_ssh
    init_bash
    init_git
    init_vim
    init_zsh
    install_mihomo
}

main
