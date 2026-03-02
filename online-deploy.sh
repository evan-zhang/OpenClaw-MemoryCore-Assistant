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

# 1. 环境检查与 API Key 获取
echo -e "\n${BLUE}[1/6] 正在检查系统环境...${NC}"

# 修复 curl | bash 模式下的交互式输入
if [ -z "$ZHIPUAI_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  检测到 ZHIPUAI_API_KEY 环境变量未设置。${NC}"
    # 强制从终端读取输入
    printf "${BLUE}请输入您的智谱 AI API Key: ${NC}"
    read ZHIPUAI_API_KEY < /dev/tty
    if [ -z "$ZHIPUAI_API_KEY" ]; then
        echo -e "${RED}❌ 错误: API Key 不能为空。部署终止。${NC}"
        exit 1
    fi
    export ZHIPUAI_API_KEY=$ZHIPUAI_API_KEY
fi

# 操作系统兼容性判断
OS_TYPE=$(uname -s)
if [ "$OS_TYPE" = "Darwin" ]; then
    echo -e "${YELLOW}检测到 macOS 系统，请确保已安装 python3, sqlite3 和 git。${NC}"
elif command -v apt-get &> /dev/null; then
    echo "正在安装系统依赖 (sqlite3, python3-pip, jq, git)..."
    sudo apt-get update -qq && sudo apt-get install -y -qq sqlite3 python3-pip jq git &> /dev/null
else
    echo -e "${YELLOW}⚠️  未检测到 apt-get，请确保手动安装了 sqlite3, python3-pip, jq 和 git。${NC}"
fi

# 2. 克隆基础仓库
echo -e "\n${BLUE}[2/6] 正在克隆 MemoryCore 基础仓库...${NC}"
INSTALL_DIR="$HOME/.openclaw/workspace/memory-system-v1.0"
MEMORY_CORE_DIR="$INSTALL_DIR"

if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠️  目标目录已存在，正在备份并更新...${NC}"
    mv "$INSTALL_DIR" "${INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
fi

git clone https://github.com/ktao732084-arch/openclaw_memory_supersystem-v1.0.git "$INSTALL_DIR" &> /dev/null

# 3. 获取智谱 AI 增强补丁
echo -e "\n${BLUE}[3/6] 正在从 GitHub 获取智谱 AI 增强补丁...${NC}"

RAW_URL="https://raw.githubusercontent.com/evan-zhang/OpenClaw-MemoryCore-Assistant/main/core_src"

# 依次下载补丁文件
for patch_file in memory.py vector_embedding.py vector_index.py hybrid_search.py; do
    echo "正在下载 $patch_file..."
    curl -sSL "$RAW_URL/$patch_file" -o "$MEMORY_CORE_DIR/src/$patch_file"
done

echo -e "${GREEN}✅ 智谱 AI 核心逻辑补丁应用成功${NC}"

# 4. 安装 Python 依赖
echo -e "\n${BLUE}[4/6] 正在安装 Python 依赖...${NC}"
# 使用 --user 避免权限问题，尤其是 macOS
pip3 install --quiet --user requests python-dateutil || pip3 install --quiet requests python-dateutil

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
if [ "$OS_TYPE" = "Darwin" ]; then
    # macOS 默认使用 zsh
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
fi

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
