# ECS Init Scripts

Minimal bootstrap scripts for a fresh Linux server.

## What It Does

- Installs common tooling for Ubuntu/Debian and CentOS
- Sets up `zsh` with `oh-my-zsh`
- Configures `vim`, `bash`, `git`, and `ssh`
- Uses Gitee mirrors where possible, with GitHub fallback for broken downloads

## Highlights

- Fast setup for disposable cloud instances
- Works with both `apt-get` and `yum`
- Keeps the environment consistent across new machines
- Fails over cleanly when a mirror returns an empty file

## Usage

```bash
git clone https://github.com/chfeng-cs/ecs-init-scripts.git
cd ecs-init-scripts
bash init_env.sh
```

## Notes

- The script assumes `sudo` access.
- Some downloads prefer Gitee to reduce latency in mainland China.
- If a Gitee download returns a zero-byte file, the script retries from GitHub.

## Files

- `init_env.sh` - main bootstrap script
- `README.md` - project overview

