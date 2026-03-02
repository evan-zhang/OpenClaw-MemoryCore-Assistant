# OpenClaw-MemoryCore-Assistant

This repository packages MemoryCore v1.4.0 enhancements and deployment tooling.

## One-line install (recommended)

```bash
curl -sSL https://raw.githubusercontent.com/evan-zhang/OpenClaw-MemoryCore-Assistant/main/online-deploy.sh | bash
```

If you run into pip errors on macOS (PEP 668 / Homebrew-managed Python), please use a virtualenv:

```bash
python3 -m venv ~/memcore-venv
source ~/memcore-venv/bin/activate
curl -sSL https://raw.githubusercontent.com/evan-zhang/OpenClaw-MemoryCore-Assistant/main/online-deploy.sh | bash
```

Or export your ZHIPUAI_API_KEY ahead of time:

```bash
export ZHIPUAI_API_KEY="your-key"
curl -sSL https://raw.githubusercontent.com/evan-zhang/OpenClaw-MemoryCore-Assistant/main/online-deploy.sh | bash
```

## Troubleshooting

- PEP 668 (macOS/Homebrew): use virtualenv or `pip --user`. See scripts/check_env.sh for diagnostics.
- If `vector-build` command missing from help: ensure the deploy script applied `core_src` patches into `memory-system-v1.0/src`.

