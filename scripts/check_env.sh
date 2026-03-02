#!/bin/bash
# check_env.sh - 环境自检脚本 (MemoryCore)
set -e

echo "🔎 MemoryCore 环境自检"
PYTHON_BIN=$(which python3 || true)
if [ -z "$PYTHON_BIN" ]; then
  echo "❌ 未检测到 python3，请先安装 Python 3.8+"
  exit 1
fi
echo "Python: $($PYTHON_BIN --version)" || true

# 建议使用虚拟环境
if [ -z "$VIRTUAL_ENV" ]; then
  echo "⚠️ 未在虚拟环境中运行，推荐使用: python3 -m venv ~/memcore-venv && source ~/memcore-venv/bin/activate"
fi

# pip 可用性
if ! command -v pip3 &> /dev/null; then
  echo "❌ pip3 未找到，请先安装 pip"
  exit 1
fi

# 检查依赖
echo "检查 Python 包: requests, python-dateutil"
python3 - <<'PY'
import sys
missing=[]
for pkg in ('requests','dateutil'):
    try:
        __import__(pkg)
    except Exception:
        missing.append(pkg)
if missing:
    print('缺少包:', missing)
    sys.exit(2)
print('依赖 OK')
PY

# 检查核心补丁文件
ROOT_DIR="$HOME/.openclaw/workspace/memory-system-v1.0/src"
for f in vector_embedding.py vector_index.py hybrid_search.py memory.py; do
  if [ ! -f "$ROOT_DIR/$f" ]; then
    echo "❌ 缺少核心文件: $ROOT_DIR/$f"
    echo "请确保 core_src 中的文件已复制到 $ROOT_DIR"
    exit 1
  fi
done

echo "✅ 环境检查通过"
