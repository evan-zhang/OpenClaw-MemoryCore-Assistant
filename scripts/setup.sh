#!/bin/bash
# MemoryCore ç³»ç»éç½®èæ¬
# éç½®ç¯å¢åéãç³»ç»å«åãèªå¨åä»»å¡

set -e

# é¢è²è¾åº
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# éç½®åé
INSTALL_DIR="/root/.openclaw/workspace"
MEMORY_CORE_DIR="${INSTALL_DIR}/memory-system-v1.0"
ZHIPUAI_API_KEY="${ZHIPUAI_API_KEY:-}"

echo -e "${GREEN}ð§ MemoryCore ç³»ç»éç½®èæ¬${NC}"
echo "="*80
echo ""

# æ£æ¥æºè°± AI API Key
if [ -z "$ZHIPUAI_API_KEY" ]; then
    echo -e "${YELLOW}â ï¸ ZHIPUAI_API_KEY ç¯å¢åéæªè®¾ç½®${NC}"
    echo -e "${YELLOW}è¯·è®¾ç½®åéè¯${NC}"
    exit 1
fi

# ç¬¬ 1 æ­¥ï¼éç½® .bashrc
echo -e "${BLUE}ç¬¬ 1 æ­¥ï¼éç½® .bashrc${NC}"
echo "-"*80

# å¤ä»½åæä»¶
if [ -f ~/.bashrc ]; then
    cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d)
    echo -e "${GREEN}â å·²å¤ä»½ .bashrc${NC}"
fi

# æ·»å ç¯å¢åé
cat >> ~/.bashrc << 'EOF'

# MemoryCore ç¯å¢åé (2026-03-02)
export ZHIPUAI_API_KEY="__ZHIPUAI_API_KEY_PLACEHOLDER__"
export LC_ALL=C.UTF-8

# MemoryCore å«å
export MEMORY_CORE_DIR="$HOME/.openclaw/workspace/memory-system-v1.0"
alias mem="cd \$MEMORY_CORE_DIR && python3 src/memory.py"
alias memsearch="\$MEMORY_CORE_DIR/python3 src/memory.py search"
alias memcapture="\$MEMORY_CORE_DIR/python3 src/memory.py capture --type fact --importance 0.9"
alias memstatus="\$MEMORY_CORE_DIR/python3 src/memory.py status"
alias membuild="\$MEMORY_CORE_DIR/python3 src/memory.py vector-build --provider zhipuai"

EOF

# æ¿æ¢ API Key å ä½ç¬¦
$SED_I "s/__ZHIPUAI_API_KEY_PLACEHOLDER__/$ZHIPUAI_API_KEY/g" ~/.bashrc

echo -e "${GREEN}â .bashrc éç½®å®æ${NC}"
echo ""

# ç¬¬ 2 æ­¥ï¼éç½® HEARTBEAT
echo -e "${BLUE}ç¬¬ 2 æ­¥ï¼éç½® HEARTBEAT.md${NC}"
echo "-"*80

HEARTBEAT_FILE="$INSTALL_DIR/HEARTBEAT.md"

if [ -f "$HEARTBEAT_FILE" ]; then
    cp "$HEARTBEAT_FILE" "$HEARTBEAT_FILE.backup.$(date +%Y%m%d)"
fi

cat > "$HEARTBEAT_FILE" << 'EOF'
# HEARTBEAT.md - MemoryCore éæ

## ð§  MemoryCore ç¶ææ£æ¥ (æ¯å°æ¶)

### 1. è®°å¿ç³»ç»æ£æ¥
```bash
cd ~/.openclaw/workspace/memory-system-v1.0
export ZHIPUAI_API_KEY="__ZHIPUAI_API_KEY_PLACEHOLDER__"
export LC_ALL=C.UTF-8

# æ¥çç¶æ
python3 src/memory.py status

# å¦æåéç´¢å¼æååï¼éå»º
python3 src/memory.py vector-build --provider zhipuai
```

### 2. æ¯æ¥æ´å
```bash
cd ~/.openclaw/workspace/memory-system-v1.0
export ZHIPUAI_API_KEY="__ZHIPUAI_API_KEY_PLACEHOLDER__"
export LC_ALL=C.UTF-8

# è®°å¿æ´å
python3 src/memory.py consolidate
```

### 3. å¥åº·æ£æ¥
```bash
# æ£æ¥åéç´¢å¼å¤§å°
ls -lh ~/.openclaw/workspace/memory-system-v1.0/memory/vectors.db

# æ£æ¥æ´»è·è®°å¿æ°é
cat ~/.openclaw/workspace/memory-system-v1.0/memory/layer2/active/facts.jsonl | wc -l

# æ£æ¥åéç´¢å¼ç¶æ
sqlite3 ~/.openclaw/workspace/memory-system-v1.0/memory/vectors.db "SELECT COUNT(*) as total FROM vectors;"
```

---

## ð¯ é¢è­¦è§å

### æ£æ¥é¡¹
- **æ´»è·è®°å¿æ° > 10000**: å»ºè®®æ´å
- **åéç´¢å¼æä»¶ > 1GB**: å»ºè®®éå»º
- **åéç´¢å¼æ° â  æ´»è·è®°å¿æ°**: éè¦éå»º
- **API è°ç¨å¤±è´¥**: æ£æ¥æºè°± AI Key

---

## ð§ èªå¨åèæ¬

### æ¯å°æ¶æ§è¡
```bash
#!/bin/bash
# memory-core-health-check.sh

cd ~/.openclaw/workspace/memory-system-v1.0
export ZHIPUAI_API_KEY="__ZHIPUAI_API_KEY_PLACEHOLDER__"
export LC_ALL=C.UTF-8

# ç¶ææ£æ¥
python3 src/memory.py status | head -30

# åéç´¢å¼æ£æ¥
VECTOR_COUNT=$(sqlite3 memory/vectors.db "SELECT COUNT(*) FROM vectors;" 2>/dev/null || echo "0")
ACTIVE_COUNT=$(cat memory/layer2/active/facts.jsonl | wc -l)

if [ "$VECTOR_COUNT" != "$ACTIVE_COUNT" ]; then
    echo "â ï¸ åéç´¢å¼ä¸å¹éï¼éå»ºä¸­..."
    python3 src/memory.py vector-build --provider zhipuai
fi
```
EOF

# æ¿æ¢ API Key å ä½ç¬¦
$SED_I "s/__ZHIPUAI_API_KEY_PLACEHOLDER__/$ZHIPUAI_API_KEY/g" "$HEARTBEAT_FILE"

echo -e "${GREEN}â HEARTBEAT.md éç½®å®æ${NC}"
echo ""

# ç¬¬ 3 æ­¥ï¼éç½® crontabï¼å¯éï¼
echo -e "${BLUE}ç¬¬ 3 æ­¥ï¼éç½® crontabï¼å¯éï¼${NC}"
echo "-"*80

read -p "æ¯å¦éç½® crontab èªå¨åä»»å¡ï¼(y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # å¤ä»½å crontab
    crontab -l > /tmp/crontab.backup.$(date +%Y%m%d) 2>/dev/null || true
    
    # æ·»å  MemoryCore å®æ¶ä»»å¡
    (crontab -l 2>/dev/null; cat << EOF

# MemoryCore å¥åº·æ£æ¥ï¼æ¯å°æ¶ï¼
0 * * * * cd ~/.openclaw/workspace/memory-system-v1.0 && export ZHIPUAI_API_KEY="$ZHIPUAI_API_KEY" && export LC_ALL=C.UTF-8 && python3 src/memory.py status >> /tmp/memorycore-status.log 2>&1

# MemoryCore è®°å¿æ´åï¼æ¯å¤©åæ¨ 2 ç¹ï¼
0 2 * * * cd ~/.openclaw/workspace/memory-system-v1.0 && export ZHIPUAI_API_KEY="$ZHIPUAI_API_KEY" && export LC_ALL=C.UTF-8 && python3 src/memory.py consolidate >> /tmp/memorycore-consolidate.log 2>&1
EOF
) | crontab -
    
    echo -e "${GREEN}â crontab éç½®å®æ${NC}"
else
    echo -e "${YELLOW}â­ è·³è¿ crontab éç½®${NC}"
fi

echo ""

# å®æ
echo "="*80
echo -e "${GREEN}ð MemoryCore ç³»ç»éç½®å®æï¼${NC}"
echo ""
echo -e "${GREEN}ð éç½®åå®¹:${NC}"
echo "1. â .bashrc å·²æ·»å  MemoryCore å«å"
echo "2. â HEARTBEAT.md å·²æ·»å  MemoryCore æ£æ¥"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "3. â crontab å·²æ·»å èªå¨åä»»å¡"
fi
echo ""
echo -e "${YELLOW}ä¸ä¸æ­¥æä½:${NC}"
echo "1. éæ°å è½½éç½®: source ~/.bashrc"
echo "2. è¿è¡éªè¯èæ¬: ./verify.sh"
echo "3. å¼å§ä½¿ç¨: memsearch 'å³é®è¯'"
echo ""
echo -e "${GREEN}â éç½®å®æï¼${NC}"
