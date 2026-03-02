#!/bin/bash
# MemoryCore 备份脚本
# 备份 MemoryCore 数据和配置

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 配置变量
MEMORY_CORE_DIR="${MEMORY_CORE_DIR:-/root/.openclaw/workspace/memory-system-v1.0}"
BACKUP_DIR="/tmp/memorycore-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${GREEN}💾 MemoryCore 备份脚本${NC}"
echo "="*80
echo ""

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 备份 1: 备份数据库
echo -e "${GREEN}备份数据库...${NC}"

VECTOR_DB="$MEMORY_CORE_DIR/memory/vectors.db"
FACTS_FILE="$MEMORY_CORE_DIR/memory/layer2/active/facts.jsonl"
BELIEFS_FILE="$MEMORY_CORE_DIR/memory/layer2/active/beliefs.jsonl"
SUMMARIES_FILE="$MEMORY_CORE_DIR/memory/layer2/active/summaries.jsonl"

BACKUP_NAME="memorycore-backup-$TIMESTAMP.tar.gz"

cd "$MEMORY_CORE_DIR"
tar -czf "$BACKUP_DIR/$BACKUP_NAME" \
    memory/vectors.db \
    memory/layer2/active/*.jsonl \
    memory/config.json \
    2>/dev/null

if [ -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)
    echo -e "${GREEN}✅ 备份完成: $BACKUP_NAME ($BACKUP_SIZE)${NC}"
    echo "   位置: $BACKUP_DIR/$BACKUP_NAME"
else
    echo -e "${RED}❌ 备份失败${NC}"
    exit 1
fi

# 备份 2: 清理旧备份（保留最近 7 天）
echo -e "\n${GREEN}清理旧备份...${NC}"

find "$BACKUP_DIR" -name "memorycore-backup-*.tar.gz" -mtime +7 -delete
echo -e "${GREEN}✅ 旧备份已清理（保留最近 7 天）${NC}"

# 完成
echo ""
echo "="*80
echo -e "${GREEN}🎉 备份完成！${NC}"
echo ""
echo -e "${YELLOW}恢复备份:${NC}"
echo "tar -xzf $BACKUP_DIR/$BACKUP_NAME -C $MEMORY_CORE_DIR"
echo ""
echo -e "${GREEN}✅ 备份完成！${NC}"
