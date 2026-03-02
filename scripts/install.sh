#!/bin/bash
# MemoryCore 自动安装脚本
# 一键安装 MemoryCore v1.4.0 + 智谱AI 集成

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
INSTALL_DIR="/root/.openclaw/workspace"
MEMORY_CORE_DIR="${INSTALL_DIR}/memory-system-v1.0"
MEMORY_CORE_REPO="https://github.com/ktao732084-arch/openclaw_memory_supersystem-v1.0.git"
ZHIPUAI_API_KEY="${ZHIPUAI_API_KEY:-}"

echo -e "${GREEN}🚀 MemoryCore 自动安装脚本${NC}"
echo "="*80
echo ""

# 第 1 步：检查系统要求
echo -e "${BLUE}第 1 步：检查系统要求${NC}"
echo "-"*80

# 检查操作系统
if [ ! -f /etc/os-release ]; then
    echo -e "${RED}❌ 不支持的操作系统${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 操作系统检查通过${NC}"

# 检查 Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 未安装${NC}"
    echo -e "${YELLOW}请先安装 Python 3.8+${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | awk '{print $2}')
echo -e "${GREEN}✅ Python 版本: ${PYTHON_VERSION}${NC}"

# 检查内存
TOTAL_MEM=$(free -m | awk 'NR==2{print $2}')
if [ $TOTAL_MEM -lt 4096 ]; then
    echo -e "${YELLOW}⚠️ 内存不足（推荐 4GB+）${NC}"
else
    echo -e "${GREEN}✅ 内存检查通过: ${TOTAL_MEM}MB${NC}"
fi

# 检查磁盘
FREE_DISK=$(df -m "$INSTALL_DIR" | awk 'NR==2{print $4}')
if [ $FREE_DISK -lt 10240 ]; then
    echo -e "${YELLOW}⚠️ 磁盘空间不足（推荐 10GB+）${NC}"
else
    echo -e "${GREEN}✅ 磁盘检查通过: ${FREE_DISK}MB${NC}"
fi

echo ""

# 第 2 步：检查智谱 AI API Key
echo -e "${BLUE}第 2 步：检查智谱 AI API Key${NC}"
echo "-"*80

if [ -z "$ZHIPUAI_API_KEY" ]; then
    echo -e "${YELLOW}⚠️ ZHIPUAI_API_KEY 环境变量未设置${NC}"
    echo ""
    echo -e "${YELLOW}请设置 API Key:${NC}"
    echo "export ZHIPUAI_API_KEY=\"your-api-key-here\""
    echo ""
    echo -e "${YELLOW}或者从提示输入:${NC}"
    read -p "请输入智谱 AI API Key: " ZHIPUAI_API_KEY
    
    if [ -z "$ZHIPUAI_API_KEY" ]; then
        echo -e "${RED}❌ API Key 不能为空${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ API Key 已设置: ${ZHIPUAI_API_KEY:0:20}...${NC}"
echo ""

# 第 3 步：安装系统依赖
echo -e "${BLUE}第 3 步：安装系统依赖${NC}"
echo "-"*80

apt-get update -qq
apt-get install -y -qq python3-pip python3-venv sqlite3 jq

echo -e "${GREEN}✅ 系统依赖安装完成${NC}"
echo ""

# 第 4 步：克隆 MemoryCore 仓库
echo -e "${BLUE}第 4 步：克隆 MemoryCore 仓库${NC}"
echo "-"*80

if [ -d "$MEMORY_CORE_DIR" ]; then
    echo -e "${YELLOW}⚠️ MemoryCore 已存在，跳过克隆${NC}"
else
    git clone "$MEMORY_CORE_REPO" "$MEMORY_CORE_DIR"
    echo -e "${GREEN}✅ 仓库克隆完成${NC}"
fi

# 第 4.5 步：应用智谱 AI 增强补丁
echo -e "${BLUE}第 4.5 步：应用智谱 AI 增强补丁${NC}"
echo "-"*80

# 从部署包的 core_src 复制经过修改的文件到安装目录
PACKAGE_ROOT=$(dirname "$(cd "$(dirname "$0")"; pwd)")
if [ -d "$PACKAGE_ROOT/core_src" ]; then
    cp "$PACKAGE_ROOT/core_src/"*.py "$MEMORY_CORE_DIR/src/"
    echo -e "${GREEN}✅ 智谱 AI 核心逻辑补丁应用成功${NC}"
else
    echo -e "${RED}❌ 错误：未找到 core_src 目录，补丁应用失败${NC}"
    exit 1
fi

echo ""

# 第 5 步：安装 Python 依赖
echo -e "${BLUE}第 5 步：安装 Python 依赖${NC}"
echo "-"*80

cd "$MEMORY_CORE_DIR"
pip3 install --quiet requests python-dateutil

echo -e "${GREEN}✅ Python 依赖安装完成${NC}"
echo ""

# 第 6 步：初始化 MemoryCore
echo -e "${BLUE}第 6 步：初始化 MemoryCore${NC}"
echo "-"*80

export ZHIPUAI_API_KEY="$ZHIPUAI_API_KEY"
export LC_ALL=C.UTF-8

cd "$MEMORY_CORE_DIR"
python3 src/memory.py init

echo -e "${GREEN}✅ MemoryCore 初始化完成${NC}"
echo ""

# 第 7 步：配置智谱 AI
echo -e "${BLUE}第 7 步：配置智谱 AI 向量检索${NC}"
echo "-"*80

CONFIG_FILE="$MEMORY_CORE_DIR/memory/config.json"

# 创建配置
cat > "$CONFIG_FILE" << EOF
{
  "vector": {
    "enabled": true,
    "provider": "zhipuai",
    "model": "embedding-3",
    "base_url": "https://open.bigmodel.cn/api/paas/v4/",
    "dimension": 2048,
    "backend": "sqlite",
    "hybrid_search": {
      "keyword_weight": 0.3,
      "vector_weight": 0.7,
      "min_score": 0.2
    },
    "cache": {
      "enabled": true,
      "max_size": 10000
    }
  }
}
EOF

echo -e "${GREEN}✅ 智谱 AI 配置完成${NC}"
echo ""

# 第 8 步：构建向量索引
echo -e "${BLUE}第 8 步：构建向量索引${NC}"
echo "-"*80

python3 src/memory.py vector-build --provider zhipuai

echo -e "${GREEN}✅ 向量索引构建完成${NC}"
echo ""

# 完成
echo "="*80
echo -e "${GREEN}🎉 MemoryCore 安装完成！${NC}"
echo ""
echo -e "${GREEN}📍 安装目录:${NC} $MEMORY_CORE_DIR"
echo -e "${GREEN}🔑 智谱 AI Key:${NC} ${ZHIPUAI_API_KEY:0:20}..."
echo ""
echo -e "${YELLOW}下一步操作:${NC}"
echo "1. 运行验证脚本: ./verify.sh"
echo "2. 运行配置脚本: ./setup.sh"
echo "3. 开始使用: cd $MEMORY_CORE_DIR && python3 src/memory.py search '关键词'"
echo ""
echo -e "${GREEN}✅ 安装完成！${NC}"
