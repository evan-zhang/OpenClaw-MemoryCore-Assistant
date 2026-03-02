#!/bin/bash
# MemoryCore 系统配置脚本
# 配置环境变量、系统别名、自动化任务

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置变量
INSTALL_DIR="/root/.openclaw/workspace"
MEMORY_CORE_DIR="${INSTALL_DIR}/memory-system-v1.0"
ZHIPUAI_API_KEY="${ZHIPUAI_API_KEY:-}"

echo -e "${GREEN}🔧 MemoryCore 系统配置脚本${NC}"
echo "="*80
echo ""

# 检查智谱 AI API Key
if [ -z "$ZHIPUAI_API_KEY" ]; then
    echo -e "${YELLOW}⚠️ ZHIPUAI_API_KEY 环境变量未设置${NC}"
    echo -e "${YELLOW}请设置后重试${NC}"
    exit 1
fi

# 第 1 步：配置 .bashrc
echo -e "${BLUE}第 1 步：配置 .bashrc${NC}"
echo "-"*80

# 备份原文件
if [ -f ~/.bashrc ]; then
    cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d)
    echo -e "${GREEN}✅ 已备份 .bashrc${NC}"
fi

# 添加环境变量
cat >> ~/.bashrc << 'EOF'

# MemoryCore 环境变量 (2026-03-02)
export ZHIPUAI_API_KEY="__ZHIPUAI_API_KEY_PLACEHOLDER__"
export LC_ALL=C.UTF-8

# MemoryCore 别名
export MEMORY_CORE_DIR="$HOME/.openclaw/workspace/memory-system-v1.0"
alias mem="cd \$MEMORY_CORE_DIR && python3 src/memory.py"
alias memsearch="\$MEMORY_CORE_DIR/python3 src/memory.py search"
alias memcapture="\$MEMORY_CORE_DIR/python3 src/memory.py capture --type fact --importance 0.9"
alias memstatus="\$MEMORY_CORE_DIR/python3 src/memory.py status"
alias membuild="\$MEMORY_CORE_DIR/python3 src/memory.py vector-build --provider zhipuai"

EOF

# 替换 API Key 占位符
sed -i "s/__ZHIPUAI_API_KEY_PLACEHOLDER__/$ZHIPUAI_API_KEY/g" ~/.bashrc

echo -e "${GREEN}✅ .bashrc 配置完成${NC}"
echo ""

# 第 2 步：配置 HEARTBEAT
echo -e "${BLUE}第 2 步：配置 HEARTBEAT.md${NC}"
echo "-"*80

HEARTBEAT_FILE="$INSTALL_DIR/HEARTBEAT.md"

if [ -f "$HEARTBEAT_FILE" ]; then
    cp "$HEARTBEAT_FILE" "$HEARTBEAT_FILE.backup.$(date +%Y%m%d)"
fi

cat > "$HEARTBEAT_FILE" << 'EOF'
# HEARTBEAT.md - MemoryCore 集成

## 🧠 MemoryCore 状态检查 (每小时)

### 1. 记忆系统检查
```bash
cd ~/.openclaw/workspace/memory-system-v1.0
export ZHIPUAI_API_KEY="__ZHIPUAI_API_KEY_PLACEHOLDER__"
export LC_ALL=C.UTF-8

# 查看状态
python3 src/memory.py status

# 如果向量索引有变化，重建
python3 src/memory.py vector-build --provider zhipuai
```

### 2. 每日整合
```bash
cd ~/.openclaw/workspace/memory-system-v1.0
export ZHIPUAI_API_KEY="__ZHIPUAI_API_KEY_PLACEHOLDER__"
export LC_ALL=C.UTF-8

# 记忆整合
python3 src/memory.py consolidate
```

### 3. 健康检查
```bash
# 检查向量索引大小
ls -lh ~/.openclaw/workspace/memory-system-v1.0/memory/vectors.db

# 检查活跃记忆数量
cat ~/.openclaw/workspace/memory-system-v1.0/memory/layer2/active/facts.jsonl | wc -l

# 检查向量索引状态
sqlite3 ~/.openclaw/workspace/memory-system-v1.0/memory/vectors.db "SELECT COUNT(*) as total FROM vectors;"
```

---

## 🎯 预警规则

### 检查项
- **活跃记忆数 > 10000**: 建议整合
- **向量索引文件 > 1GB**: 建议重建
- **向量索引数 ≠ 活跃记忆数**: 需要重建
- **API 调用失败**: 检查智谱 AI Key

---

## 🔧 自动化脚本

### 每小时执行
```bash
#!/bin/bash
# memory-core-health-check.sh

cd ~/.openclaw/workspace/memory-system-v1.0
export ZHIPUAI_API_KEY="__ZHIPUAI_API_KEY_PLACEHOLDER__"
export LC_ALL=C.UTF-8

# 状态检查
python3 src/memory.py status | head -30

# 向量索引检查
VECTOR_COUNT=$(sqlite3 memory/vectors.db "SELECT COUNT(*) FROM vectors;" 2>/dev/null || echo "0")
ACTIVE_COUNT=$(cat memory/layer2/active/facts.jsonl | wc -l)

if [ "$VECTOR_COUNT" != "$ACTIVE_COUNT" ]; then
    echo "⚠️ 向量索引不匹配，重建中..."
    python3 src/memory.py vector-build --provider zhipuai
fi
```
EOF

# 替换 API Key 占位符
sed -i "s/__ZHIPUAI_API_KEY_PLACEHOLDER__/$ZHIPUAI_API_KEY/g" "$HEARTBEAT_FILE"

echo -e "${GREEN}✅ HEARTBEAT.md 配置完成${NC}"
echo ""

# 第 3 步：配置 crontab（可选）
echo -e "${BLUE}第 3 步：配置 crontab（可选）${NC}"
echo "-"*80

read -p "是否配置 crontab 自动化任务？(y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 备份原 crontab
    crontab -l > /tmp/crontab.backup.$(date +%Y%m%d) 2>/dev/null || true
    
    # 添加 MemoryCore 定时任务
    (crontab -l 2>/dev/null; cat << EOF

# MemoryCore 健康检查（每小时）
0 * * * * cd ~/.openclaw/workspace/memory-system-v1.0 && export ZHIPUAI_API_KEY="$ZHIPUAI_API_KEY" && export LC_ALL=C.UTF-8 && python3 src/memory.py status >> /tmp/memorycore-status.log 2>&1

# MemoryCore 记忆整合（每天凌晨 2 点）
0 2 * * * cd ~/.openclaw/workspace/memory-system-v1.0 && export ZHIPUAI_API_KEY="$ZHIPUAI_API_KEY" && export LC_ALL=C.UTF-8 && python3 src/memory.py consolidate >> /tmp/memorycore-consolidate.log 2>&1
EOF
) | crontab -
    
    echo -e "${GREEN}✅ crontab 配置完成${NC}"
else
    echo -e "${YELLOW}⏭ 跳过 crontab 配置${NC}"
fi

echo ""

# 完成
echo "="*80
echo -e "${GREEN}🎉 MemoryCore 系统配置完成！${NC}"
echo ""
echo -e "${GREEN}📝 配置内容:${NC}"
echo "1. ✅ .bashrc 已添加 MemoryCore 别名"
echo "2. ✅ HEARTBEAT.md 已添加 MemoryCore 检查"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "3. ✅ crontab 已添加自动化任务"
fi
echo ""
echo -e "${YELLOW}下一步操作:${NC}"
echo "1. 重新加载配置: source ~/.bashrc"
echo "2. 运行验证脚本: ./verify.sh"
echo "3. 开始使用: memsearch '关键词'"
echo ""
echo -e "${GREEN}✅ 配置完成！${NC}"
