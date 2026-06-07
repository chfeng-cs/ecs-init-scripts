#!/bin/bash
# Sync dotfiles from gitee (primary) / github (fallback)
# Install to: ~/.local/bin/sync-dotfiles

GITEE_SCRIPTS="https://gitee.com/chfeng-cs/scripts/raw/master"
GITHUB_SCRIPTS="https://raw.githubusercontent.com/chfeng-cs/ecs-init-scripts/master"

download_with_fallback() {
    local primary_url="$1"
    local fallback_url="$2"
    local target_file="$3"
    local name
    name=$(basename "$target_file")

    wget -q "$primary_url" -O "$target_file" || true
    if [ ! -s "$target_file" ]; then
        wget -q "$fallback_url" -O "$target_file"
    fi
    if [ ! -s "$target_file" ]; then
        echo "  [FAIL] $name"
        return 1
    fi
    echo "  [OK]   $name"
}

sync_all() {
    echo "==> syncing dotfiles"
    download_with_fallback \
        "$GITEE_SCRIPTS/.zshrc"            "$GITHUB_SCRIPTS/.zshrc"            "$HOME/.zshrc"
    download_with_fallback \
        "$GITEE_SCRIPTS/.bashrc"           "$GITHUB_SCRIPTS/.bashrc"           "$HOME/.bashrc"
    download_with_fallback \
        "$GITEE_SCRIPTS/.profile"          "$GITHUB_SCRIPTS/.profile"          "$HOME/.profile"
    download_with_fallback \
        "$GITEE_SCRIPTS/.p10k-vscode.zsh"  "$GITHUB_SCRIPTS/.p10k-vscode.zsh"  "$HOME/.p10k-vscode.zsh"
    download_with_fallback \
        "$GITEE_SCRIPTS/.p10k.zsh"         "$GITHUB_SCRIPTS/.p10k.zsh"         "$HOME/.p10k.zsh"
    download_with_fallback \
        "https://gitee.com/chfeng-cs/simple-scripts/raw/master/.vimrc" \
        "https://raw.githubusercontent.com/chfeng-cs/simple-scripts/master/.vimrc" \
        "$HOME/.vimrc"
    echo "==> done"
}

# Run sync_all when executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    sync_all
fi
