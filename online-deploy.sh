#!/bin/bash
# Robust online deploy script (uses venv, downloads patches, init + build)
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}MemoryCore Robust Online Deploy (venv-enabled)${NC}"

# get API key from env or prompt (supports curl|bash)
if [ -z "$ZHIPUAI_API_KEY" ]; then
  printf "Enter ZHIPUAI_API_KEY: "
  read ZHIPUAI_API_KEY < /dev/tty || { echo "No tty available; export ZHIPUAI_API_KEY and retry"; exit 1; }
  export ZHIPUAI_API_KEY
fi

# Clone base repo
INSTALL_DIR="$HOME/.openclaw/workspace/memory-system-v1.0"
REPO_URL="https://github.com/ktao732084-arch/openclaw_memory_supersystem-v1.0.git"
CORE_SRC_URL_BASE="https://raw.githubusercontent.com/evan-zhang/OpenClaw-MemoryCore-Assistant/main/core_src"

if [ -d "$INSTALL_DIR" ]; then
  mv "$INSTALL_DIR" "${INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
fi

echo "Cloning base repo..."
git clone "$REPO_URL" "$INSTALL_DIR"

# try to create venv; if unavailable fall back to --user installs
VENV_DIR="$HOME/.memcore_venv"
FALLBACK_USER=0
if python3 -m venv "$VENV_DIR" 2>/dev/null; then
  # shellcheck disable=SC1090
  source "$VENV_DIR/bin/activate"
  python3 -m pip install --upgrade pip
  pip install --no-cache-dir requests python-dateutil || { echo "pip install failed inside venv"; exit 1; }
else
  echo "${YELLOW}python3-venv not available; falling back to user-level pip installs${NC}"
  FALLBACK_USER=1
  python3 -m pip install --user --upgrade pip
  python3 -m pip install --user requests python-dateutil || { echo "pip --user install failed"; exit 1; }
  # ensure ~/.local/bin is on PATH for this session
  export PATH="$HOME/.local/bin:$PATH"
fi

# download core patches
mkdir -p "$INSTALL_DIR/src"
for f in vector_embedding.py vector_index.py hybrid_search.py memory.py; do
  curl -sSL "$CORE_SRC_URL_BASE/$f" -o "$INSTALL_DIR/src/$f" || { echo "Failed to fetch $f"; exit 1; }
done

# test imports
python3 - <<'PY'
import sys
sys.path.insert(0, '$INSTALL_DIR/src')
for mod in ('vector_embedding','vector_index','hybrid_search'):
    try:
        __import__(mod)
    except Exception as e:
        print('Import failed:', mod, e)
        sys.exit(2)
print('Imports OK')
PY

# init and config
export LC_ALL=C.UTF-8
cd "$INSTALL_DIR"
python3 src/memory.py init
cat > memory/config.json <<'EOF'
{
  "vector": {
    "enabled": true,
    "provider": "zhipuai",
    "model": "embedding-3",
    "dimension": 2048,
    "backend": "sqlite",
    "hybrid_search": { "keyword_weight": 0.3, "vector_weight": 0.7, "min_score": 0.2 }
  }
}
EOF

# attempt vector-build
python3 src/memory.py vector-build --provider zhipuai || echo "vector-build failed (check logs)"

echo -e "${GREEN}Deploy complete. Activate venv: source $VENV_DIR/bin/activate${NC}"
