#!/bin/bash
# MemoryCore 部署包打包脚本
# 将完整的部署包打包为 .tar.gz 文件，方便分发

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置变量
PACKAGE_DIR="/root/.openclaw/workspace"
PACKAGE_NAME="memorycore-package-1.4.0-zhipuai"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${GREEN}📦 MemoryCore 部署包打包脚本${NC}"
echo "="*80

# 检查目标目录
TARGET_DIR="${PACKAGE_DIR}/${PACKAGE_NAME}"
echo -e "${GREEN}📍 目标目录:${NC} $TARGET_DIR"

if [ -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}⚠️ 目标目录已存在，清理中...${NC}"
    rm -rf "$TARGET_DIR"
fi

# 创建目录
mkdir -p "$TARGET_DIR"
echo -e "${GREEN}✅ 目录创建完成${NC}"

# 复制部署包内容
echo -e "${GREEN}📋 复制部署包内容...${NC}"

# 复制根目录文件
cp "${PACKAGE_DIR}/memorycore-package-1.4.0/"* "$TARGET_DIR/" 2>/dev/null || true

# 复制文档
cp -r "${PACKAGE_DIR}/memorycore-package-1.4.0/docs" "$TARGET_DIR/" 2>/dev/null || true

# 复制脚本
cp -r "${PACKAGE_DIR}/memorycore-package-1.4.0/scripts" "$TARGET_DIR/" 2>/dev/null || true

# 复制工具
cp -r "${PACKAGE_DIR}/memorycore-package-1.4.0/tools" "$TARGET_DIR/" 2>/dev/null || true

# 复制核心源码补丁
cp -r "${PACKAGE_DIR}/memorycore-package-1.4.0/core_src" "$TARGET_DIR/" 2>/dev/null || true

echo -e "${GREEN}✅ 部署包内容复制完成${NC}"

# 创建元数据文件
echo -e "${GREEN}📝 创建元数据文件...${NC}"

cat > "$TARGET_DIR/PACKAGE_METADATA.md" << 'EOF'
# MemoryCore 部署包元数据

**包名**：MemoryCore v1.4.0 + 智谱AI 集成  
**版本**：1.4.0  
**打包时间**：2026-03-02 16:12 GMT+8  
**目标受众**：开发人员、配置部署人员、架构人员、使用人员

---

## 📋 包内容

| 类型 | 文件数 | 说明 |
|------|--------|------|
| **根文档** | 2 | README.md, DEPLOYMENT_CHECKLIST.md |
| **详细文档** | 7 | docs/ 目录下的所有文档 |
| **脚本工具** | 7 | scripts/ 目录下的所有脚本 |
| **Python 工具** | 2 | tools/ 目录下的所有文件 |

---

## 🎯 使用方式

### 1. 解压部署包

```bash
tar -xzf memorycore-package-1.4.0-zhipuai-[timestamp].tar.gz
cd memorycore-package-1.4.0-zhipuai-[timestamp]
```

### 2. 自动化部署

```bash
# 设置环境变量
export ZHIPUAI_API_KEY="46c7ea42cdfe45b7b072288b6703ee8f.5XIR8I61NyJGZIjV"
export LC_ALL=C.UTF-8

# 运行安装脚本
chmod +x scripts/*.sh
./scripts/install.sh

# 运行配置脚本
./scripts/setup.sh

# 验证安装
./scripts/verify.sh
```

### 3. 手动部署

按照 `docs/INSTALL.md` 中的详细步骤手动安装。

---

## 📊 系统要求

### 最低要求

| 资源 | 要求 |
|------|------|
| **操作系统** | Linux (Ubuntu 20.04+, Debian 11+) |
| **CPU** | 2 核 |
| **内存** | 4 GB |
| **磁盘** | 10 GB |
| **Python** | 3.8+ |
| **网络** | 可访问智谱AI API |

### 推荐配置

| 资源 | 要求 |
|------|------|
| **操作系统** | Ubuntu 22.04 LTS |
| **CPU** | 4 核 |
| **内存** | 8 GB |
| **磁盘** | 50 GB (SSD) |
| **Python** | 3.10+ |

---

## 🔑 智谱 AI API Key

### 获取方式

1. 访问 [智谱 AI 官网](https://open.bigmodel.cn/)
2. 注册账号并登录
3. 进入 API Keys 页面
4. 创建新的 API Key
5. 复制 Key 值

### 配置方式

**方式 1：环境变量（推荐）**
```bash
export ZHIPUAI_API_KEY="your-api-key-here"
```

**方式 2：配置文件**
```bash
# 编辑配置文件
vi ~/.openclaw/workspace/memory-system-v1.0/memory/config.json

# 添加智谱 AI 配置
{
  "zhipuai": {
    "api_key": "your-api-key-here"
  }
}
```

---

## 📞 支持

### 文档支持

- 完整指南：`README.md`
- 快速开始：`docs/QUICKSTART.md`
- 安装指南：`docs/INSTALL.md`
- 系统架构：`docs/ARCHITECTURE.md`
- API 接口：`docs/API.md`
- 配置说明：`docs/CONFIG.md`
- 故障排查：`docs/TROUBLESHOOTING.md`
- 最佳实践：`docs/BEST_PRACTICES.md`

---

## 🎉 部署完成

**MemoryCore v1.4.0 + 智谱AI 集成部署包已准备就绪！**

**下一步**：
1. 解压部署包
2. 设置环境变量
3. 运行安装脚本
4. 开始使用

---

**MemoryCore - 你的智能记忆系统！** 🧠
EOF

echo -e "${GREEN}✅ 元数据文件创建完成${NC}"
echo ""

# 打包
echo -e "${BLUE}📦 正在打包...${NC}"

cd "$PACKAGE_DIR"
ARCHIVE_NAME="${PACKAGE_NAME}-${TIMESTAMP}.tar.gz"

tar -czf "$ARCHIVE_NAME" "$PACKAGE_NAME"

if [ -f "$ARCHIVE_NAME" ]; then
    ARCHIVE_SIZE=$(du -h "$ARCHIVE_NAME" | cut -f1)
    FILE_COUNT=$(find "$TARGET_DIR" -type f | wc -l)
    DIR_COUNT=$(find "$TARGET_DIR" -type d | wc -l)
    TOTAL_SIZE=$(du -sh "$TARGET_DIR" | cut -f1)
    
    echo ""
    echo "="*80
    echo -e "${GREEN}🎉 打包完成！${NC}"
    echo ""
    echo -e "${GREEN}📦 包文件:${NC} $ARCHIVE_NAME"
    echo -e "${GREEN}📊 包大小:${NC} $ARCHIVE_SIZE"
    echo ""
    echo -e "${GREEN}📋 部署包统计:${NC}"
    echo "   文件数: $FILE_COUNT"
    echo "   目录数: $DIR_COUNT"
    echo "   总大小: $TOTAL_SIZE"
    echo ""
    echo -e "${YELLOW}🚀 分发方式:${NC}"
    echo ""
    echo "1. 上传到服务器"
    echo "   scp $ARCHIVE_NAME user@server:/tmp/"
    echo ""
    echo "2. 在服务器上解压"
    echo "   cd /tmp"
    echo "   tar -xzf $ARCHIVE_NAME"
    echo "   cd memorycore-package-1.4.0-zhipuai-${TIMESTAMP}"
    echo ""
    echo "3. 运行安装脚本"
    echo "   chmod +x scripts/*.sh"
    echo "   ./scripts/install.sh"
    echo ""
    echo "4. 运行配置脚本"
    echo "   ./scripts/setup.sh"
    echo ""
    echo "5. 验证安装"
    echo "   ./scripts/verify.sh"
    echo ""
    echo "="*80
    
    # 创建分发说明
    cat > "${PACKAGE_DIR}/DISTRIBUTION.md" << 'EOF'
# MemoryCore 分发说明

## 📦 部署包信息

- **包名**: MemoryCore v1.4.0 + 智谱AI 集成
- **文件名**: `memorycore-package-1.4.0-zhipuai-[timestamp].tar.gz`
- **包大小**: `[archive_size]`

---

## 🚀 服务器部署步骤

### 1. 上传到服务器

```bash
# 使用 SCP 上传
scp memorycore-package-1.4.0-zhipuai-[timestamp].tar.gz user@server:/tmp/

# 使用 SFTP 上传
sftp user@server
put memorycore-package-1.4.0-zhipuai-[timestamp].tar.gz /tmp/
```

### 2. 解压部署包

```bash
# 登录服务器
ssh user@server

# 解压
cd /tmp
tar -xzf memorycore-package-1.4.0-zhipuai-[timestamp].tar.gz

# 进入目录
cd memorycore-package-1.4.0-zhipuai-[timestamp]
```

### 3. 设置环境变量

```bash
# 设置智谱 AI API Key
export ZHIPUAI_API_KEY="46c7ea42cdfe45b7b072288b6703ee8f.5XIR8I61NyJGZIjV"

# 设置 UTF-8 编码
export LC_ALL=C.UTF-8
```

### 4. 自动化部署

```bash
# 运行安装脚本
chmod +x scripts/*.sh
./scripts/install.sh

# 运行配置脚本
./scripts/setup.sh

# 验证安装
./scripts/verify.sh
```

---

## ✅ 验证部署

```bash
# 检查系统状态
cd ~/.openclaw/workspace/memory-system-v1.0
python3 src/memory.py status

# 测试搜索
python3 src/memory.py search "测试"

# 测试添加
python3 src/memory.py capture --type fact --importance 0.9 "测试内容"
```

---

## 📝 自定义配置

### 修改智谱 AI API Key

编辑 `~/.openclaw/workspace/memory-system-v1.0/memory/config.json`：

```json
{
  "vector": {
    "provider": "zhipuai",
    "model": "embedding-3",
    "base_url": "https://open.bigmodel.cn/api/paas/v4/",
    "dimension": 2048
  }
}
```

---

## 🎯 开始使用

**MemoryCore 已成功部署！**

快速开始：
```bash
cd ~/.openclaw/workspace/memory-system-v1.0

# 搜索记忆
python3 src/memory.py search "关键词"

# 添加记忆
python3 src/memory.py capture --type fact --importance 0.9 "内容"

# 查看状态
python3 src/memory.py status
```

---

**MemoryCore v1.4.0 - 你的智能记忆系统！** 🧠
EOF
    
    # 替换 [archive_size]
    sed -i "s/\[archive_size\]/$ARCHIVE_SIZE/g" "${PACKAGE_DIR}/DISTRIBUTION.md"
    
    echo -e "${GREEN}✅ 分发说明创建完成${NC}"
    
else
    echo -e "${RED}❌ 打包失败${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 MemoryCore 部署包打包完成！${NC}"
echo ""
echo -e "${GREEN}📍 包文件:${NC} $ARCHIVE_NAME"
echo -e "${GREEN}📊 包大小:${NC} $ARCHIVE_SIZE"
echo ""
echo -e "${YELLOW}📋 分发:${NC} scp $ARCHIVE_NAME user@server:/tmp/"
echo ""
echo -e "${GREEN}✅ 打包完成！${NC}"
