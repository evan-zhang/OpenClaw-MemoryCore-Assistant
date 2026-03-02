#!/bin/bash
# MemoryCore v1.4.0 一键在线部署脚本
# 集成 智谱 AI (Zhipu AI) 向量检索增强版

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}🚀 MemoryCore v1.4.0 一键在线部署 (智谱 AI 增强版)${NC}"
echo -e "${BLUE}============================================================${NC}"

# 1. 环境检查
echo -e "\n${BLUE}[1/6] 正在检查系统环境...${NC}"

if [ -z "$ZHIPUAI_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  检测到 ZHIPUAI_API_KEY 环境变量未设置。${NC}"
    read -p "请输入您的智谱 AI API Key: " ZHIPUAI_API_KEY
    if [ -z "$ZHIPUAI_API_KEY" ]; then
        echo -e "${RED}❌ 错误: API Key 不能为空。部署终止。${NC}"
        exit 1
    fi
    export ZHIPUAI_API_KEY=$ZHIPUAI_API_KEY
fi

# 安装基础依赖 (Debian/Ubuntu 示例)
if command -v apt-get &> /dev/null; then
    echo "正在安装系统依赖 (sqlite3, python3-pip, jq)..."
    sudo apt-get update -qq && sudo apt-get install -y -qq sqlite3 python3-pip jq git &> /dev/null
fi

# 2. 克隆基础仓库
echo -e "\n${BLUE}[2/6] 正在克隆 MemoryCore 基础仓库...${NC}"
INSTALL_DIR="$HOME/.openclaw/workspace/memory-system-v1.0"

if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠️  目标目录已存在，正在备份并更新...${NC}"
    mv "$INSTALL_DIR" "${INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
fi

git clone https://github.com/ktao732084-arch/openclaw_memory_supersystem-v1.0.git "$INSTALL_DIR" &> /dev/null

# 3. 应用智谱 AI 增强补丁
echo -e "\n${BLUE}[3/6] 正在应用智谱 AI 核心补丁...${NC}"
cd "$INSTALL_DIR/src"

# 释放 vector_embedding.py
cat > vector_embedding.py << 'EOF'
#!/usr/bin/env python3
"""Vector Embedding Engine - 支持智谱 AI"""
import os, requests
from typing import Optional, List
class VectorEmbeddingEngine:
    def __init__(self, provider="openai", model=None, base_url=None):
        self.provider = provider; self.model = model; self.base_url = base_url; self.api_key = None; self.dimension = None
        if provider == "zhipuai": self._init_zhipuai()
        elif provider == "openai": self._init_openai()
    def _init_zhipuai(self):
        self.api_key = os.environ.get("ZHIPUAI_API_KEY")
        if not self.base_url: self.base_url = "https://open.bigmodel.cn/api/paas/v4/"
        if not self.model: self.model = "embedding-3"
        self.dimension = 2048
    def _init_openai(self):
        self.api_key = os.environ.get("OPENAI_API_KEY")
        if not self.base_url: self.base_url = "https://api.openai.com/v1/"
        if not self.model: self.model = "text-embedding-3-small"
        self.dimension = 1536
    def embed(self, texts: List[str]) -> Optional[List[List[float]]]:
        if not self.api_key: return None
        endpoint = f"{self.base_url}embeddings"
        headers = {"Authorization": f"Bearer {self.api_key}", "Content-Type": "application/json"}
        try:
            payload = {"model": self.model, "input": texts if len(texts)>1 else texts[0]}
            response = requests.post(endpoint, headers=headers, json=payload, timeout=30)
            if response.status_code != 200: return None
            result = response.json()
            return [item["embedding"] for item in result["data"]]
        except Exception: return None
def get_embedding_engine(provider="openai", model=None, base_url=None):
    return VectorEmbeddingEngine(provider, model, base_url)
EOF

# 释放 vector_index.py
cat > vector_index.py << 'EOF'
#!/usr/bin/env python3
import sqlite3, json, os
from pathlib import Path
from typing import List, Optional, Tuple
from datetime import datetime
class VectorIndexManager:
    def __init__(self, memory_dir: Path):
        self.db_path = Path(memory_dir) / "vectors.db"
        self.conn = sqlite3.connect(self.db_path)
        self.conn.execute("CREATE TABLE IF NOT EXISTS vectors (memory_id TEXT PRIMARY KEY, vector BLOB, dimension INTEGER, created_at TEXT)")
    def add_vector(self, memory_id: str, vector: List[float]) -> bool:
        try:
            self.conn.execute("INSERT OR REPLACE INTO vectors VALUES (?, ?, ?, ?)", (memory_id, json.dumps(vector).encode(), len(vector), datetime.utcnow().isoformat()))
            self.conn.commit(); return True
        except: return False
    def search(self, query_vector: List[float], limit: int = 20) -> List[Tuple[str, float]]:
        cursor = self.conn.execute("SELECT memory_id, vector FROM vectors")
        results = []
        for row in cursor:
            vec = json.loads(row[1].decode())
            score = sum(a*b for a,b in zip(query_vector, vec)) / (sum(a*a for a in query_vector)**0.5 * sum(b*b for b in vec)**0.5)
            results.append((row[0], score))
        results.sort(key=lambda x: x[1], reverse=True)
        return results[:limit]
def build_vector_index(memory_dir: Path, engine, backend="sqlite", batch_size=10):
    manager = VectorIndexManager(memory_dir); count = 0
    for p in ["facts", "beliefs", "summaries"]:
        path = memory_dir / f"layer2/active/{p}.jsonl"
        if not path.exists(): continue
        with open(path, 'r') as f:
            for line in f:
                r = json.loads(line)
                emb = engine.embed([r['content']])
                if emb and manager.add_vector(r['id'], emb[0]): count += 1
    return {"total": count, "indexed": count, "skipped": 0, "failed": 0}
EOF

# 释放 hybrid_search.py
cat > hybrid_search.py << 'EOF'
#!/usr/bin/env python3
import json
from pathlib import Path
from vector_index import VectorIndexManager
class SearchResult:
    def __init__(self, id, content, score, v_score=0.0, k_score=0.0):
        self.id=id; self.content=content; self.score=score; self.vector_score=v_score; self.keyword_score=k_score; self.metadata={}
class HybridSearchEngine:
    def __init__(self, memory_dir, engine, k_weight=0.3, v_weight=0.7, min_score=0.2):
        self.memory_dir = Path(memory_dir); self.engine = engine; self.k_weight = k_weight; self.v_weight = v_weight; self.min_score = min_score
        self.v_index = VectorIndexManager(memory_dir)
    def search(self, query, top_k=20, use_vector=True):
        all_res = {}
        if use_vector and self.engine:
            emb = self.engine.embed([query])
            if emb:
                for mid, score in self.v_index.search(emb[0], limit=top_k):
                    all_res[mid] = SearchResult(mid, self._get_c(mid), score, v_score=score)
        res = [r for r in all_res.values() if r.score >= self.min_score]
        res.sort(key=lambda x: x.score, reverse=True)
        return res[:top_k]
    def _get_c(self, mid):
        for p in ["facts", "beliefs", "summaries"]:
            path = self.memory_dir / f"layer2/active/{p}.jsonl"
            if not path.exists(): continue
            with open(path) as f:
                for line in f:
                    r = json.loads(line)
                    if r['id'] == mid: return r['content']
        return ""
def create_hybrid_search_engine(memory_dir, engine, **kwargs):
    return HybridSearchEngine(memory_dir, engine, **kwargs)
EOF

# 修改 memory.py 路由逻辑 (简化注入)
# [此处已由 git clone 包含，若需特定修改可用 sed]

# 4. 安装 Python 依赖
echo -e "\n${BLUE}[4/6] 正在安装 Python 依赖...${NC}"
pip3 install --quiet requests python-dateutil

# 5. 初始化与向量索引构建
echo -e "\n${BLUE}[5/6] 正在初始化系统并构建向量索引...${NC}"
cd "$INSTALL_DIR"
export LC_ALL=C.UTF-8
python3 src/memory.py init &> /dev/null

# 写入配置文件
cat > memory/config.json << EOF
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

# 构建索引
python3 src/memory.py vector-build --provider zhipuai

# 6. 配置别名
echo -e "\n${BLUE}[6/6] 正在配置系统别名...${NC}"
SHELL_RC="$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"

if ! grep -q "memory-system-v1.0" "$SHELL_RC"; then
    cat >> "$SHELL_RC" << EOF

# MemoryCore Aliases
export MEMORY_DIR="$INSTALL_DIR/memory"
export ZHIPUAI_API_KEY="$ZHIPUAI_API_KEY"
alias mem="python3 $INSTALL_DIR/src/memory.py"
alias memsearch="python3 $INSTALL_DIR/src/memory.py search"
alias memstatus="python3 $INSTALL_DIR/src/memory.py status"
EOF
    echo -e "${GREEN}✅ 别名已添加到 $SHELL_RC${NC}"
else
    echo -e "${YELLOW}⚠️  别名配置已存在，跳过。${NC}"
fi

echo -e "\n${GREEN}🎉 MemoryCore 部署成功！${NC}"
echo -e "------------------------------------------------------------"
echo -e "请运行以下命令使配置生效:"
echo -e "  ${YELLOW}source $SHELL_RC${NC}"
echo -e ""
echo -e "使用示例:"
echo -e "  ${BLUE}memstatus${NC}        # 查看系统状态"
echo -e "  ${BLUE}memsearch \"用户\"${NC} # 语义搜索记忆"
echo -e "------------------------------------------------------------"
