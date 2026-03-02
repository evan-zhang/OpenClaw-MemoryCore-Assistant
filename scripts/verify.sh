#!/bin/bash
# MemoryCore 验证脚本
# 验证 MemoryCore 安装和配置是否正确

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置变量
MEMORY_CORE_DIR="/root/.openclaw/workspace/memory-system-v1.0"
ZHIPUAI_API_KEY="${ZHIPUAI_API_KEY:-}"

# 统计变量
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

echo -e "${GREEN}✅ MemoryCore 验证脚本${NC}"
echo "="*80
echo ""

# 第 1 步：验证安装目录
echo -e "${BLUE}第 1 步：验证安装目录${NC}"
echo "-"*80

TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

if [ -d "$MEMORY_CORE_DIR" ]; then
    echo -e "${GREEN}✅ MemoryCore 目录存在${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}❌ MemoryCore 目录不存在${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

echo ""

# 第 2 步：验证核心文件
echo -e "${BLUE}第 2 步：验证核心文件${NC}"
echo "-"*80

CORE_FILES=(
    "$MEMORY_CORE_DIR/src/memory.py"
    "$MEMORY_CORE_DIR/src/vector_embedding.py"
    "$MEMORY_CORE_DIR/src/vector_index.py"
    "$MEMORY_CORE_DIR/src/hybrid_search.py"
    "$MEMORY_CORE_DIR/memory/config.json"
)

for file in "${CORE_FILES[@]}"; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $(basename $file)${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}❌ $(basename $file)${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
done

echo ""

# 第 3 步：验证智谱 AI API Key
echo -e "${BLUE}第 3 步：验证智谱 AI API Key${NC}"
echo "-"*80

TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

if [ -z "$ZHIPUAI_API_KEY" ]; then
    echo -e "${RED}❌ ZHIPUAI_API_KEY 环境变量未设置${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
else
    echo -e "${GREEN}✅ API Key 已设置: ${ZHIPUAI_API_KEY:0:20}...${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

echo ""

# 第 4 步：验证 Python 依赖
echo -e "${BLUE}第 4 步：验证 Python 依赖${NC}"
echo "-"*80

PYTHON_PACKAGES=(
    "requests"
    "python-dateutil"
)

for package in "${PYTHON_PACKAGES[@]}"; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if python3 -c "import $package" 2>/dev/null; then
        echo -e "${GREEN}✅ $package${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}❌ $package${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
done

echo ""

# 第 5 步：验证数据库
echo -e "${BLUE}第 5 步：验证数据库${NC}"
echo "-"*80

VECTOR_DB="$MEMORY_CORE_DIR/memory/vectors.db"

TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

if [ -f "$VECTOR_DB" ]; then
    echo -e "${GREEN}✅ 向量数据库存在${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    VECTOR_COUNT=$(sqlite3 "$VECTOR_DB" "SELECT COUNT(*) FROM vectors;" 2>/dev/null || echo "0")
    echo -e "${GREEN}✅ 向量索引数量: $VECTOR_COUNT${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}❌ 向量数据库不存在${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

echo ""

# 第 6 步：验证系统功能
echo -e "${BLUE}第 6 步：验证系统功能${NC}"
echo "-"*80

cd "$MEMORY_CORE_DIR"
export ZHIPUAI_API_KEY="$ZHIPUAI_API_KEY"
export LC_ALL=C.UTF-8

# 测试系统状态
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

if python3 src/memory.py status >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 系统状态命令正常${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}❌ 系统状态命令失败${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# 测试添加记忆
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

if python3 src/memory.py capture --type fact --importance 0.8 "验证测试" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 添加记忆功能正常${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}❌ 添加记忆功能失败${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# 测试搜索记忆
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

if python3 src/memory.py search "验证" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 搜索记忆功能正常${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}❌ 搜索记忆功能失败${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

echo ""

# 完成
echo "="*80
echo -e "${GREEN}📊 验证结果${NC}"
echo ""
echo -e "总检查数: $TOTAL_CHECKS"
echo -e "${GREEN}通过检查: $PASSED_CHECKS${NC}"
if [ $FAILED_CHECKS -gt 0 ]; then
    echo -e "${RED}失败检查: $FAILED_CHECKS${NC}"
else
    echo -e "${RED}失败检查: 0${NC}"
fi
echo ""

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}🎉 MemoryCore 验证完成，所有检查通过！${NC}"
    echo ""
    echo -e "${YELLOW}下一步操作:${NC}"
    echo "1. 重新加载配置: source ~/.bashrc"
    echo "2. 开始使用: memsearch '关键词'"
else
    echo -e "${RED}❌ MemoryCore 验证失败，请检查错误并重试${NC}"
    echo ""
    echo -e "${YELLOW}排查建议:${NC}"
    echo "1. 检查安装目录: $MEMORY_CORE_DIR"
    echo "2. 检查 API Key: echo \$ZHIPUAI_API_KEY"
    echo "3. 查看故障排查文档: docs/TROUBLESHOOTING.md"
fi

echo ""
echo -e "${GREEN}✅ 验证完成！${NC}"
