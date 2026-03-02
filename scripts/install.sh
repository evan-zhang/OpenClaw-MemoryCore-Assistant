#!/bin/bash
# Robust install script for MemoryCore (ensures venv, installs deps, applies patches)
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

INSTALL_DIR="${INSTALL_DIR:-$HOME/.openclaw/workspace/memory-system-v1.0}"
REPO_URL="https://github.com/ktao732084-arch/openclaw_memory_supersystem-v1.0.git"
CORE_SRC_URL_BASE="https://raw.githubusercontent.com/evan-zhang/OpenClaw-MemoryCore-Assistant/main/core_src"

echo -e "${GREEN}🚀 Robust MemoryCore install${NC}"

# 1. Ensure python3 exists
if ! command -v python3 &> /dev/null; then
  echo -e "${RED}Python3 not found. Install Python 3.8+ and rerun.${NC}"
  exit 1
fi

# 2. Clone repo if missing
if [ -d "$INSTALL_DIR" ]; then
  echo -e "${YELLOW}Target exists; backing up and re-cloning${NC}"
  mv "$INSTALL_DIR" "${INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
fi

echo "Cloning base repo..."
git clone "$REPO_URL" "$INSTALL_DIR"

# 3. Create and activate venv
VENV_DIR="$HOME/.memcore_venv"
if [ ! -d "$VENV_DIR" ]; then
  echo "Creating virtualenv at $VENV_DIR"
  python3 -m venv "$VENV_DIR"
fi
# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"
python3 -m pip install --upgrade pip

# 4. Install python deps into venv
echo "Installing python dependencies into venv..."
pip install --no-cache-dir requests python-dateutil || { echo -e "${RED}pip install failed${NC}"; exit 1; }

# 5. Apply core patches (download from our GitHub)
echo "Applying core patches..."
mkdir -p "$INSTALL_DIR/src"
for f in vector_embedding.py vector_index.py hybrid_search.py memory.py; do
  echo "Downloading $f"
  curl -sSL "$CORE_SRC_URL_BASE/$f" -o "$INSTALL_DIR/src/$f" || { echo "Failed to download $f"; exit 1; }
done

# 6. Test imports
echo "Testing imports in venv..."
python3 - <<'PY'
import sys
sys.path.insert(0, '$INSTALL_DIR/src')
errs = []
for mod in ('vector_embedding','vector_index','hybrid_search'):
    try:
        __import__(mod)
    except Exception as e:
        errs.append((mod, str(e)))
if errs:
    print('Import errors:')
    for m,e in errs:
        print(m, e)
    sys.exit(2)
print('Imports OK')
PY

# 7. Initialize system and save config
export ZHIPUAI_API_KEY="${ZHIPUAI_API_KEY:-}"
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

# 8. Run vector-build (optional: user can skip)
echo "Building vector index (this may take time)..."
python3 src/memory.py vector-build --provider zhipuai || echo "vector-build failed; check imports/logs"

# 9. Finish
echo -e "${GREEN}Installation complete. Activate venv: source $VENV_DIR/bin/activate${NC}"
