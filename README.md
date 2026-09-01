# ECS Init Scripts

Minimal bootstrap scripts for a fresh Linux server.

## What It Does

- Installs common tooling for Debian/Ubuntu and common RHEL/Fedora systems
- Sets up `zsh` with `oh-my-zsh`
- Configures `vim`, `bash`, `git`, and `ssh`
- Optionally installs mihomo with Clash subscription support
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
- Git 2.20.0+ and Zsh 5.1.0+ are required.
- Some downloads prefer Gitee to reduce latency in mainland China.
- If a Gitee download returns a zero-byte file, the script retries from GitHub.
- The optional mihomo setup installs `start_mihomo` under `~/.bin/mihomo`.
- GEOIP/GEOSITE rules are removed so mihomo does not require GEO databases.

## Files

- `init_env.sh` - main bootstrap script
- `README.md` - project overview
