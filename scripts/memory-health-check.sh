#!/bin/bash
# MemoryCore 健康检查脚本
# 定期检查 MemoryCore 系统健康状态

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 配置变量
MEMORY_CORE_DIR="${MEMORY_CORE_DIR:-/root/.openclaw/workspace/memory-system-v1.0}"
ZHIPUAI_API_KEY="${ZHIPUAI_API_KEY:-}"
LOG_FILE="/tmp/memorycore-health-check.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') - MemoryCore 健康检查" >> "$LOG_FILE"
echo "="*80 >> "$LOG_FILE"

# 检查 1: 系统状态
echo "检查 1: 系统状态" | tee -a "$LOG_FILE"
cd "$MEMORY_CORE_DIR" 2>/dev/null || {
    echo "❌ MemoryCore 目录不存在" | tee -a "$LOG_FILE"
    exit 1
}

export ZHIPUAI_API_KEY="$ZHIPUAI_API_KEY"
export LC_ALL=C.UTF-8

STATUS_OUTPUT=$(python3 src/memory.py status 2>&1)
echo "$STATUS_OUTPUT" | tee -a "$LOG_FILE"

# 检查 2: 向量索引状态
echo -e "\n检查 2: 向量索引状态" | tee -a "$LOG_FILE"

VECTOR_DB="$MEMORY_CORE_DIR/memory/vectors.db"
if [ -f "$VECTOR_DB" ]; then
    VECTOR_COUNT=$(sqlite3 "$VECTOR_DB" "SELECT COUNT(*) FROM vectors;" 2>/dev/null || echo "0")
    VECTOR_SIZE=$(du -h "$VECTOR_DB" | cut -f1)
    
    echo "向量索引数: $VECTOR_COUNT" | tee -a "$LOG_FILE"
    echo "向量索引大小: $VECTOR_SIZE" | tee -a "$LOG_FILE"
    
    # 检查是否需要重建
    FACTS_COUNT=$(cat "$MEMORY_CORE_DIR/memory/layer2/active/facts.jsonl" 2>/dev/null | wc -l)
    
    if [ "$VECTOR_COUNT" != "$FACTS_COUNT" ]; then
        echo -e "${YELLOW}⚠️ 向量索引不匹配（向量: $VECTOR_COUNT, 记忆: $FACTS_COUNT）${NC}" | tee -a "$LOG_FILE"
        echo "建议: 运行 python3 src/memory.py vector-build --provider zhipuai"
    else
        echo -e "${GREEN}✅ 向量索引正常${NC}" | tee -a "$LOG_FILE"
    fi
else
    echo "❌ 向量数据库不存在" | tee -a "$LOG_FILE"
fi

# 检查 3: 活跃记忆数量
echo -e "\n检查 3: 活跃记忆数量" | tee -a "$LOG_FILE"

ACTIVE_COUNT=$(cat "$MEMORY_CORE_DIR/memory/layer2/active/facts.jsonl" 2>/dev/null | wc -l)
echo "活跃记忆数: $ACTIVE_COUNT" | tee -a "$LOG_FILE"

if [ $ACTIVE_COUNT -gt 10000 ]; then
    echo -e "${YELLOW}⚠️ 活跃记忆数 > 10000，建议整合${NC}" | tee -a "$LOG_FILE"
else
    echo -e "${GREEN}✅ 活跃记忆数正常${NC}" | tee -a "$LOG_FILE"
fi

# 检查 4: API 连接测试
echo -e "\n检查 4: 智谱 AI API 连接" | tee -a "$LOG_FILE"

if [ -z "$ZHIPUAI_API_KEY" ]; then
    echo "❌ API Key 未设置" | tee -a "$LOG_FILE"
else
    echo "API Key: ${ZHIPUAI_API_KEY:0:20}..." | tee -a "$LOG_FILE"
    # 这里可以添加实际的 API 测试
    echo -e "${GREEN}✅ API Key 已配置${NC}" | tee -a "$LOG_FILE"
fi

# 检查 5: 磁盘空间
echo -e "\n检查 5: 磁盘空间" | tee -a "$LOG_FILE"

DISK_USAGE=$(du -sh "$MEMORY_CORE_DIR" | cut -f1)
FREE_DISK=$(df -h "$MEMORY_CORE_DIR" | awk 'NR==2{print $4}')

echo "MemoryCore 目录大小: $DISK_USAGE" | tee -a "$LOG_FILE"
echo "可用磁盘空间: $FREE_DISK" | tee -a "$LOG_FILE"

if [ "$FREE_DISK" -lt 1024 ]; then
    echo -e "${YELLOW}⚠️ 可用磁盘空间不足 1GB${NC}" | tee -a "$LOG_FILE"
else
    echo -e "${GREEN}✅ 磁盘空间正常${NC}" | tee -a "$LOG_FILE"
fi

# 完成
echo -e "\n${GREEN}✅ 健康检查完成${NC}"
echo "="*80
