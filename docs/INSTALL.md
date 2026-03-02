# MemoryCore 安装指南

**版本**：v1.4.0 + 智谱AI 集成  
**部署方式**：自动化脚本

---

## 🚀 快速开始

### 1. 设置环境变量

```bash
# 设置智谱 AI API Key
export ZHIPUAI_API_KEY="46c7ea42cdfe45b7b072288b6703ee8f.5XIR8I61NyJGZIjV"

# 设置 UTF-8 编码
export LC_ALL=C.UTF-8
```

### 2. 进入系统目录

```bash
# MemoryCore 系统
cd ~/.openclaw/workspace/memory-system-v1.0
```

### 3. 验证系统

```bash
# 查看系统状态
python3 src/memory.py status

# 测试搜索
python3 src/memory.py search "智谱AI"

# 测试添加
python3 src/memory.py capture --type fact --importance 0.9 "测试内容"
```

---

## 📋 安装步骤

### 第 1 步：系统准备

#### 检查操作系统
```bash
cat /etc/os-release
```

应该显示 Linux 发行版信息（如 Ubuntu 20.04+, Debian 11+）

#### 检查 Python 版本
```bash
python3 --version
```

应该显示 Python 3.8+ 版本

#### 检查内存
```bash
free -m
```

推荐至少 4GB 可用内存

---

### 第 2 步：安装依赖

```bash
# 更新包列表
sudo apt-get update

# 安装系统依赖
sudo apt-get install -y python3-pip python3-venv sqlite3 jq

# 安装 Python 依赖
pip3 install --upgrade pip
pip3 install requests python-dateutil
```

---

### 第 3 步：初始化系统

```bash
# 设置环境变量
export ZHIPUAI_API_KEY="46c7ea42cdfe45b7b072288b6703ee8f.5XIR8I61NyJGZIjV"
export LC_ALL=C.UTF-8

# 初始化系统
cd ~/.openclaw/workspace/memory-system-v1.0
python3 src/memory.py init
```

---

### 第 4 步：配置智谱 AI

#### 方式 1：环境变量（推荐）
```bash
# 永久配置：添加到 ~/.bashrc
echo 'export ZHIPUAI_API_KEY="46c7ea42cdfe45b7b072288b6703ee8f.5XIR8I61NyJGZIjV"' >> ~/.bashrc
echo 'export LC_ALL=C.UTF-8' >> ~/.bashrc

# 重新加载配置
source ~/.bashrc
```

#### 方式 2：配置文件
```bash
# 创建配置文件
cat > ~/.openclaw/workspace/memory-system-v1.0/memory/config.json << 'EOF'
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
```

---

### 第 5 步：构建向量索引

```bash
# 设置环境变量
export ZHIPUAI_API_KEY="46c7ea42cdfe45b7b072288b6703ee8f.5XIR8I61NyJGZIjV"
export LC_ALL=C.UTF-8

# 构建向量索引
cd ~/.openclaw/workspace/memory-system-v1.0
python3 src/memory.py vector-build --provider zhipuai
```

---

### 第 6 步：验证安装

```bash
# 查看系统状态
python3 src/memory.py status

# 测试搜索
python3 src/memory.py search "智谱AI"

# 测试添加
python3 src/memory.py capture --type fact --importance 0.9 "MemoryCore 安装测试"

# 查看向量状态
python3 src/memory.py vector-status
```

---

## 🎯 验证清单

### 系统检查

- [ ] 操作系统兼容
- [ ] Python 版本正确
- [ ] 内存充足
- [ ] 磁盘空间充足

### 功能检查

- [ ] `init` 命令成功
- [ ] `status` 命令成功
- [ ] `search` 命令成功
- [ ] `capture` 命令成功
- [ ] `vector-build` 命令成功

### 智谱 AI 检查

- [ ] API Key 已设置
- [ ] API Key 有效
- [ ] 向量模型正确
- [ ] 向量维度正确
- [ ] 向量检索工作

---

## 🔧 故障排查

### 问题 1：API 调用失败

**症状**：`智谱AI 请求失败`  
**原因**：API Key 无效或网络问题  
**解决方案**：
```bash
# 验证 API Key
echo $ZHIPUAI_API_KEY

# 测试连接
curl -X POST "https://open.bigmodel.cn/api/paas/v4/embeddings" \
  -H "Authorization: Bearer $ZHIPUAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"embedding-3","input":"测试"}'
```

### 问题 2：中文乱码

**症状**：搜索结果显示乱码  
**原因**：环境变量未设置  
**解决方案**：
```bash
export LC_ALL=C.UTF-8
export ZHIPUAI_API_KEY="46c7ea42cdfe45b7b072288b6703ee8f.5XIR8I61NyJGZIjV"
```

### 问题 3：向量索引未更新

**症状**：添加新记忆后向量索引不变  
**原因**：未运行 `vector-build`  
**解决方案**：
```bash
# 强制重建向量索引
cd ~/.openclaw/workspace/memory-system-v1.0
python3 src/memory.py vector-build --provider zhipuai
```

---

## 📝 下一步

### 开始使用

```bash
# 设置环境变量
export ZHIPUAI_API_KEY="46c7ea42cdfe45b7b072288b6703ee8f.5XIR8I61NyJGZIjV"
export LC_ALL=C.UTF-8

# 开始使用
cd ~/.openclaw/workspace/memory-system-v1.0

# 搜索记忆
python3 src/memory.py search "关键词"

# 添加记忆
python3 src/memory.py capture --type fact --importance 0.9 "内容"

# 查看状态
python3 src/memory.py status
```

---

**安装完成！MemoryCore 已准备就绪。** 🧠
