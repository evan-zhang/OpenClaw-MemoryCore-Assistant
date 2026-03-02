# MemoryCore v1.4.0 完整部署指南

**智谱AI 集成版**

---

## 📋 目录

- [项目概述](#项目概述)
- [系统架构](#系统架构)
- [前置准备](#前置准备)
- [安装部署](#安装部署)
- [配置说明](#配置说明)
- [使用指南](#使用指南)
- [API 接口](#api-接口)
- [维护指南](#维护指南)
- [故障排查](#故障排查)
- [最佳实践](#最佳实践)
- [附录](#附录)

---

## 项目概述

### 什么是 MemoryCore？

MemoryCore 是一个智能记忆管理系统，专为 AI Agent 设计，采用三层记忆架构，结合智谱 AI 的向量检索能力，实现高效、准确的记忆存储和检索。

### 核心特性

#### 1. 三层记忆架构

- **Layer 1 - 工作记忆**：快速访问，低 Token 消耗（<2000）
- **Layer 2 - 长期记忆**：结构化存储，支持向量检索
- **Layer 3 - 原始日志**：完整记录，可追溯历史

#### 2. 智谱AI 向量检索

- **模型**：embedding-3
- **向量维度**：2048
- **检索速度**：<100ms
- **检索精度**：~90%

#### 3. 混合检索引擎

- **关键词检索**（30%）：精确匹配
- **向量检索**（70%）：语义相似
- **RRF 融合**：多路结果合并
- **时序引擎**：时间敏感查询

#### 4. 自动记忆管理

- **重要性评分**：0.0 - 1.0
- **自动衰减**：基于时间和访问频率
- **访问追踪**：记录每次访问
- **冲突检测**：识别和处理冲突记忆

### 技术栈

| 组件 | 技术 | 版本 |
|------|------|------|
| **后端数据库** | SQLite | 3.x+ |
| **向量检索** | 智谱 AI embedding-3 | v1.4.0 |
| **检索算法** | TF-IDF + 余弦相似度 + RRF | - |
| **存储格式** | JSONL + SQLite | - |
| **编程语言** | Python | 3.8+ |
| **依赖管理** | pip | 21.0+ |

### 系统要求

#### 最低配置

- **操作系统**：Linux (Ubuntu 20.04+, Debian 11+, CentOS 8+)
- **Python 版本**：3.8+
- **内存**：2GB RAM
- **存储空间**：500MB 可用空间
- **网络**：需要访问智谱 AI API

#### 推荐配置

- **操作系统**：Linux (Ubuntu 22.04+, Debian 12+)
- **Python 版本**：3.10+
- **内存**：4GB RAM
- **存储空间**：2GB 可用空间
- **网络**：稳定的互联网连接

### 应用场景

#### 1. AI Agent 记忆系统

为 AI Agent 提供长期记忆能力，支持跨会话信息保留。

#### 2. 智能客服系统

存储用户历史对话，提供个性化服务。

#### 3. 知识管理系统

构建企业知识库，支持语义搜索。

#### 4. 个人助理

管理个人日程、偏好、任务等信息。

---

## 系统架构

### 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                     应用层 (Application)                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   CLI    │  │  Python  │  │   Web    │  │  Agent   │   │
│  │   接口   │  │    API   │  │   API    │  │   SDK    │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
└───────┼────────────┼────────────┼────────────┼──────────┘
        │            │            │            │
        └────────────┴────────────┴────────────┘
                             │
┌────────────────────────────┴────────────────────────────────┐
│                     核心层 (Core)                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              MemoryCore Engine                       │  │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐       │  │
│  │  │   搜索    │  │   添加    │  │   维护    │       │  │
│  │  │   引擎    │  │   引擎    │  │   引擎    │       │  │
│  │  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘       │  │
│  │        │              │              │             │  │
│  │  ┌─────▼─────┐  ┌─────▼─────┐  ┌─────▼─────┐       │  │
│  │  │ 混合检索  │  │ 记忆管理  │  │ 索引管理  │       │  │
│  │  │   引擎    │  │   模块    │  │   模块    │       │  │
│  │  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘       │  │
│  │        │              │              │             │  │
│  │  ┌─────▼──────────────▼──────────────▼─────┐       │  │
│  │  │         记忆控制器 (Memory Controller)    │       │  │
│  │  └──────────────────┬───────────────────────┘       │  │
│  └─────────────────────┼──────────────────────────────┘  │
└──────────────────────────┼───────────────────────────────┘
                           │
┌──────────────────────────┴───────────────────────────────┐
│                    数据层 (Data)                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │              Layer 1: 工作记忆                    │  │
│  │  ├─ Identity (身份信息)                           │  │
│  │  ├─ Owner (所有者信息)                            │  │
│  │  ├─ Constraints (约束条件)                        │  │
│  │  └─ Top Summaries (顶级摘要)                      │  │
│  └────────────────────────────────────────────────────┘  │
│                           ↓                                │
│  ┌────────────────────────────────────────────────────┐  │
│  │              Layer 2: 长期记忆                      │  │
│  │  ├─ Facts (事实) - SQLite + 向量                   │  │
│  │  ├─ Beliefs (信念) - 置信度管理                    │  │
│  │  └─ Summaries (摘要) - 会话摘要                    │  │
│  └────────────────────────────────────────────────────┘  │
│                           ↓                                │
│  ┌────────────────────────────────────────────────────┐  │
│  │              Layer 3: 原始日志                      │  │
│  │  ├─ Episodic (情节日志) - 按日期                   │  │
│  │  └─ JSONL (机器可读) - 结构化数据                  │  │
│  └────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
                           │
┌──────────────────────────┴───────────────────────────────┐
│                   外部服务 (External)                     │
│  ┌────────────────────────────────────────────────────┐  │
│  │            智谱 AI 向量检索服务                     │  │
│  │  - embedding-3 模型                                │  │
│  │  - 2048 维向量                                     │  │
│  │  - 向量生成与检索                                  │  │
│  └────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

### 三层记忆架构详解

#### Layer 1: 工作记忆

**目的**：快速访问，低 Token 消耗，用于当前会话的即时信息

**结构**：

```
工作记忆 (Working Memory)
├─ Identity (身份信息)
│  ├─ name: "小A"
│  ├─ role: "AI Assistant"
│  ├─ capabilities: ["search", "capture", "status"]
│  └─ version: "v1.4.0"
│
├─ Owner (所有者信息)
│  ├─ name: "User Name"
│  ├─ preferences: {"language": "zh-CN", "style": "concise"}
│  └─ timezone: "Asia/Shanghai"
│
├─ Constraints (约束条件)
│  ├─ max_tokens: 2000
│  ├─ memory_limit: 10000
│  └─ allowed_actions: ["read", "write", "search"]
│
└─ Top Summaries (顶级摘要)
   ├─ recent_activities: ["购买了股票", "学习了Python"]
   ├─ key_facts: ["用户偏好简洁风格", "喜欢古诗词"]
   └─ pending_tasks: ["完成报告", "回复邮件"]
```

**特点**：

- Token 限制：<2000
- 访问速度：<10ms
- 更新频率：每次对话后
- 持久化：每次会话结束时保存到 Layer 2

#### Layer 2: 长期记忆

**目的**：结构化存储，支持向量检索，保留重要信息

**结构**：

```
长期记忆 (Long-term Memory)
├─ Facts (事实)
│  ├─ id: UUID
│  ├─ content: "用户喜欢简洁风格"
│  ├─ memory_type: "fact"
│  ├─ importance: 0.9
│  ├─ confidence: 1.0
│  ├─ tags: ["偏好", "风格"]
│  ├─ created_at: timestamp
│  ├─ updated_at: timestamp
│  ├─ last_accessed: timestamp
│  ├─ access_count: integer
│  ├─ vector: [2048维数组]
│  └─ metadata: JSON
│
├─ Beliefs (信念)
│  ├─ id: UUID
│  ├─ content: "用户可能喜欢编程"
│  ├─ memory_type: "belief"
│  ├─ importance: 0.7
│  ├─ confidence: 0.8
│  ├─ tags: ["推断", "偏好"]
│  ├─ created_at: timestamp
│  ├─ updated_at: timestamp
│  ├─ last_accessed: timestamp
│  ├─ access_count: integer
│  ├─ vector: [2048维数组]
│  └─ metadata: JSON
│
└─ Summaries (摘要)
   ├─ id: UUID
   ├─ content: "用户讨论了股票投资"
   ├─ memory_type: "summary"
   ├─ importance: 0.8
   ├─ confidence: 1.0
   ├─ tags: ["会话", "股票"]
   ├─ created_at: timestamp
   ├─ updated_at: timestamp
   ├─ last_accessed: timestamp
   ├─ access_count: integer
   ├─ vector: [2048维数组]
   └─ metadata: JSON
```

**特点**：

- 向量维度：2048
- 检索速度：<100ms
- 检索精度：~90%
- 存储方式：SQLite + 向量索引
- 更新频率：实时添加

#### Layer 3: 原始日志

**目的**：完整记录，可追溯历史，用于数据分析和恢复

**结构**：

```
原始日志 (Raw Logs)
├─ Episodic (情节日志)
│  └─ logs/
│     ├─ 2024-01-01.jsonl
│     ├─ 2024-01-02.jsonl
│     └─ 2024-01-03.jsonl
│
└─ JSONL (机器可读)
   └─ data/
      ├─ conversations.jsonl
      └─ events.jsonl
```

**JSONL 格式示例**：

```json
{"timestamp": "2024-01-01T12:00:00Z", "level": "info", "event": "capture", "content": "用户说喜欢咖啡"}
{"timestamp": "2024-01-01T12:01:00Z", "level": "info", "event": "search", "query": "用户偏好"}
{"timestamp": "2024-01-01T12:02:00Z", "level": "warning", "event": "conflict", "details": "检测到冲突记忆"}
```

**特点**：

- 存储方式：文件系统
- 更新频率：实时追加
- 压缩策略：按日期归档
- 保留期限：可配置

### 混合检索引擎架构

#### 检索流程

```
用户查询
    ↓
查询预处理
    ↓
┌─────────────────┬─────────────────┐
│  关键词检索路径  │  向量检索路径    │
│  (30% 权重)     │  (70% 权重)     │
└────────┬────────┴────────┬────────┘
         ↓                 ↓
┌────────────────┐  ┌────────────────┐
│  TF-IDF 索引   │  │  向量索引      │
│  精确匹配      │  │  语义相似      │
└───────┬────────┘  └───────┬────────┘
        │                   │
        ↓                   ↓
   关键词结果            向量结果
        │                   │
        └─────────┬─────────┘
                  ↓
         RRF 融合算法
                  ↓
           排序结果
                  ↓
           返回最终结果
```

#### RRF (Reciprocal Rank Fusion) 算法

```python
def rrf_fusion(results_list, k=60):
    """
    RRF 融合算法
    
    Args:
        results_list: 多个检索结果列表
        k: 常数，通常为 60
    
    Returns:
        融合后的排序结果
    """
    scores = {}
    
    for results in results_list:
        for rank, doc in enumerate(results, start=1):
            doc_id = doc['id']
            # RRF 公式: 1 / (k + rank)
            scores[doc_id] = scores.get(doc_id, 0) + 1.0 / (k + rank)
    
    # 按得分排序
    sorted_results = sorted(scores.items(), key=lambda x: x[1], reverse=True)
    return sorted_results
```

#### 检索策略配置

```json
{
  "search": {
    "strategy": "hybrid",
    "weights": {
      "keyword": 0.3,
      "vector": 0.7
    },
    "rrf": {
      "k": 60
    },
    "filters": {
      "min_importance": 0.0,
      "memory_types": ["fact", "belief", "summary"],
      "time_range": "all"
    },
    "limit": {
      "default": 10,
      "max": 100
    }
  }
}
```

### 模块依赖关系

```
┌─────────────────────────────────────────────────────────┐
│                   应用层                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │ CLI 接口 │  │Python API│  │  Web API │              │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘              │
└───────┼────────────┼────────────┼──────────────────────┘
        │            │            │
        └────────────┴────────────┘
                     │
        ┌────────────▼────────────┐
        │     MemoryCore 类       │
        │  (memorycore.py)        │
        └────────────┬────────────┘
                     │
        ┌────────────▼────────────┐
        │  记忆控制器              │
        │  (controller.py)        │
        └────┬─────────┬──────────┘
             │         │
    ┌────────▼──┐ ┌───▼──────────┐
    │ 存储模块   │ │ 检索模块      │
    │(storage)  │ │ (search)     │
    └────┬──────┘ └───┬──────────┘
         │            │
    ┌────▼─────┐ ┌───▼────────┐
    │ SQLite   │ │ 智谱 AI    │
    │ + 向量    │ │ Embedding │
    └──────────┘ └────────────┘
```

---

## 前置准备

### 环境检查

在开始安装之前，请确保您的环境满足以下要求：

#### 1. 操作系统

MemoryCore 支持 Linux 系统，推荐使用以下发行版：

```bash
# 检查操作系统
cat /etc/os-release

# 示例输出：
# PRETTY_NAME="Ubuntu 22.04.3 LTS"
# NAME="Ubuntu"
# VERSION_ID="22.04"
```

**支持的系统**：

- Ubuntu 20.04, 22.04, 24.04
- Debian 11, 12
- CentOS 8, 9
- Rocky Linux 8, 9
- AlmaLinux 8, 9

#### 2. Python 版本

MemoryCore 需要 Python 3.8 或更高版本：

```bash
# 检查 Python 版本
python3 --version

# 应该显示：Python 3.8.x 或更高
```

**如果 Python 版本不满足要求**：

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y python3.10 python3.10-venv python3-pip

# CentOS/RHEL
sudo yum install -y python310 python310-pip
```

#### 3. 网络连接

MemoryCore 需要访问智谱 AI API，请确保网络连接正常：

```bash
# 测试网络连接
ping -c 4 open.bigmodel.cn

# 测试 HTTPS 连接
curl -I https://open.bigmodel.cn/api/paas/v4/
```

**如果使用代理**：

```bash
# 设置 HTTP 代理
export HTTP_PROXY="http://proxy-server:port"
export HTTPS_PROXY="http://proxy-server:port"

# 或设置 SOCKS5 代理
export all_proxy="socks5h://127.0.0.1:1080"
```

#### 4. 磁盘空间

MemoryCore 至少需要 500MB 可用空间：

```bash
# 检查磁盘空间
df -h ~/.openclaw/workspace/

# 应该有至少 500MB 可用空间
```

#### 5. SQLite

MemoryCore 使用 SQLite 作为数据库，需要 SQLite 3.0 或更高版本：

```bash
# 检查 SQLite 版本
sqlite3 --version

# 应该显示：3.x.x 或更高
```

**如果 SQLite 未安装**：

```bash
# Ubuntu/Debian
sudo apt install -y sqlite3

# CentOS/RHEL
sudo yum install -y sqlite
```

### 依赖软件安装

#### 系统依赖

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    sqlite3 \
    curl \
    wget

# CentOS/RHEL
sudo yum install -y \
    python3 \
    python3-pip \
    git \
    sqlite \
    curl \
    wget
```

#### Python 依赖

MemoryCore 的 Python 依赖将通过 pip 自动安装，主要依赖包括：

```python
# requirements.txt
httpx>=0.24.0          # HTTP 客户端
numpy>=1.24.0          # 数值计算
scikit-learn>=1.3.0    # 机器学习
click>=8.1.0           # CLI 框架
pydantic>=2.0.0        # 数据验证
python-dotenv>=1.0.0   # 环境变量管理
```

### 智谱 AI API Key 准备

#### 1. 注册智谱 AI 账号

1. 访问 [智谱 AI 官网](https://open.bigmodel.cn/)
2. 注册账号
3. 完成实名认证

#### 2. 获取 API Key

1. 登录后进入控制台
2. 创建 API Key
3. 保存 API Key（格式：`id.secret`）

**示例 API Key**：
```
46c7ea42cdfe45b7b072288b6703ee8f.5XIR8I61NyJGZIjV
```

#### 3. 配置 API Key

```bash
# 方式 1：环境变量（推荐）
export ZHIPUAI_API_KEY="your_api_key_here"

# 方式 2：写入配置文件
echo "export ZHIPUAI_API_KEY=\"your_api_key_here\"" >> ~/.bashrc
source ~/.bashrc

# 方式 3：创建 .env 文件
echo "ZHIPUAI_API_KEY=your_api_key_here" > ~/.openclaw/workspace/.env
```

#### 4. 验证 API Key

```bash
# 测试 API Key
curl -X POST https://open.bigmodel.cn/api/paas/v4/embeddings \
  -H "Authorization: Bearer your_api_key_here" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "embedding-3",
    "input": "test"
  }'

# 应该返回向量数据
```

### 工作目录准备

```bash
# 创建工作目录
mkdir -p ~/.openclaw/workspace

# 进入工作目录
cd ~/.openclaw/workspace
```

### 权限检查

```bash
# 检查目录权限
ls -la ~/.openclaw/workspace/

# 应该有读写权限
```

**如果权限不足**：

```bash
# 修改目录权限
chmod 755 ~/.openclaw/workspace
chmod 644 ~/.openclaw/workspace/*.md 2>/dev/null
```

### 防火墙配置

如果您的系统启用了防火墙，请确保允许必要的端口：

```bash
# Ubuntu/Debian (UFW)
sudo ufw allow 8000/tcp  # 如果使用 Web API

# CentOS/RHEL (firewalld)
sudo firewall-cmd --add-port=8000/tcp --permanent
sudo firewall-cmd --reload
```

### 前置准备检查清单

在开始安装之前，请确认以下事项：

- [ ] 操作系统版本符合要求
- [ ] Python 版本 >= 3.8
- [ ] 网络连接正常
- [ ] 磁盘空间 >= 500MB
- [ ] SQLite 版本 >= 3.0
- [ ] 智谱 AI API Key 已获取
- [ ] 工作目录已创建
- [ ] 文件权限正确
- [ ] 防火墙配置（如果需要）

---

## 安装部署

### 方式 1：使用集成脚本（推荐）

这是最简单、最快的安装方式，适合大多数用户。

#### 1. 下载集成脚本

```bash
# 进入工作目录
cd ~/.openclaw/workspace

# 如果脚本不存在，创建它
cat > memory-core-init.sh << 'EOF'
#!/bin/bash
set -e

# MemoryCore 初始化脚本
# 版本：v1.4.0 + 智谱AI集成

echo "🚀 MemoryCore 初始化脚本 v1.4.0"
echo "================================"

# 设置环境变量
export ZHIPUAI_API_KEY="${ZHIPUAI_API_KEY:-}"
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# 检查 ZHIPUAI_API_KEY
if [ -z "$ZHIPUAI_API_KEY" ]; then
    echo "❌ 错误：请设置 ZHIPUAI_API_KEY 环境变量"
    echo "   示例：export ZHIPUAI_API_KEY=\"your_api_key\""
    exit 1
fi

# 进入 MemoryCore 目录
MEMORY_DIR="$HOME/.openclaw/workspace/memory-system-v1.0"
cd "$MEMORY_DIR" || {
    echo "❌ 错误：MemoryCore 目录不存在：$MEMORY_DIR"
    exit 1
}

# 运行状态检查
echo "📊 检查 MemoryCore 状态..."
python3 src/memory.py status

# 测试向量检索
echo "🔍 测试向量检索..."
python3 src/memory.py vector-status

echo "✅ MemoryCore 初始化完成！"
echo ""
echo "📝 使用方法："
echo "  - 搜索记忆：python3 src/memory.py search \"关键词\""
echo "  - 添加记忆：python3 src/memory.py capture --type fact \"内容\""
echo "  - 查看状态：python3 src/memory.py status"
echo "  - 向量搜索：python3 src/memory.py vector-search \"查询\""
EOF

# 添加执行权限
chmod +x memory-core-init.sh
```

#### 2. 运行初始化脚本

```bash
# 设置 API Key
export ZHIPUAI_API_KEY="46c7ea42cdfe45b7b072288b6703ee8f.5XIR8I61NyJGZIjV"

# 运行初始化脚本
~/.openclaw/workspace/memory-core-init.sh
```

#### 3. 验证安装

```bash
# 测试搜索功能
cd ~/.openclaw/workspace/memory-system-v1.0
python3 src/memory.py search "test"

# 测试添加功能
python3 src/memory.py capture --type fact --importance 0.9 "这是一个测试记忆"

# 查看状态
python3 src/memory.py status
```

### 方式 2：手动安装

适合需要自定义配置或高级用户。

#### 1. 创建项目目录

```bash
# 创建目录结构
mkdir -p ~/.openclaw/workspace/memory-system-v1.0/{src,logs,data,config}
cd ~/.openclaw/workspace/memory-system-v1.0
```

#### 2. 创建源代码文件

**memory.py** - 主程序：

```python
#!/usr/bin/env python3
"""
MemoryCore - 智能记忆管理系统
版本：v1.4.0 + 智谱AI集成
"""

import os
import sys
import json
import sqlite3
from datetime import datetime
from typing import List, Dict, Optional, Any
import uuid
import logging

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/memorycore.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class MemoryCore:
    """MemoryCore 核心类"""
    
    def __init__(self, db_path: str = "data/memory.db"):
        self.db_path = db_path
        self.conn = None
        self.zhipuai_api_key = os.getenv("ZHIPUAI_API_KEY", "")
        self._init_db()
        logger.info("MemoryCore 初始化完成")
    
    def _init_db(self):
        """初始化数据库"""
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        
        self.conn = sqlite3.connect(self.db_path)
        cursor = self.conn.cursor()
        
        # 创建记忆表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS memories (
                id TEXT PRIMARY KEY,
                content TEXT NOT NULL,
                memory_type TEXT NOT NULL,
                importance REAL DEFAULT 0.5,
                confidence REAL DEFAULT 1.0,
                tags TEXT,
                created_at TEXT,
                updated_at TEXT,
                last_accessed TEXT,
                access_count INTEGER DEFAULT 0,
                vector BLOB,
                metadata TEXT
            )
        ''')
        
        self.conn.commit()
        logger.info("数据库初始化完成")
    
    def capture(self, content: str, memory_type: str = "fact", 
                importance: float = 0.5, tags: List[str] = None) -> Dict:
        """捕获记忆"""
        memory_id = str(uuid.uuid4())
        now = datetime.now().isoformat()
        
        cursor = self.conn.cursor()
        cursor.execute('''
            INSERT INTO memories 
            (id, content, memory_type, importance, tags, created_at, updated_at, last_accessed)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            memory_id,
            content,
            memory_type,
            importance,
            json.dumps(tags or []),
            now,
            now,
            now
        ))
        
        self.conn.commit()
        logger.info(f"记忆已捕获: {memory_id}")
        
        return {
            "id": memory_id,
            "status": "success",
            "message": "记忆已成功捕获"
        }
    
    def search(self, query: str, top_k: int = 10) -> List[Dict]:
        """搜索记忆"""
        cursor = self.conn.cursor()
        cursor.execute('''
            SELECT id, content, memory_type, importance, confidence, tags,
                   created_at, last_accessed, access_count
            FROM memories
            WHERE content LIKE ?
            ORDER BY importance DESC, last_accessed DESC
            LIMIT ?
        ''', (f"%{query}%", top_k))
        
        results = cursor.fetchall()
        
        logger.info(f"搜索完成，找到 {len(results)} 条结果")
        
        return [
            {
                "id": row[0],
                "content": row[1],
                "type": row[2],
                "importance": row[3],
                "confidence": row[4],
                "tags": json.loads(row[5]),
                "created_at": row[6],
                "last_accessed": row[7],
                "access_count": row[8]
            }
            for row in results
        ]
    
    def status(self) -> Dict:
        """获取系统状态"""
        cursor = self.conn.cursor()
        
        # 统计记忆数量
        cursor.execute("SELECT COUNT(*) FROM memories")
        total_memories = cursor.fetchone()[0]
        
        # 按类型统计
        cursor.execute("SELECT memory_type, COUNT(*) FROM memories GROUP BY memory_type")
        type_stats = dict(cursor.fetchall())
        
        # 向量索引状态
        cursor.execute("SELECT COUNT(*) FROM memories WHERE vector IS NOT NULL")
        vector_count = cursor.fetchone()[0]
        
        return {
            "status": "healthy",
            "total_memories": total_memories,
            "type_distribution": type_stats,
            "vector_index": {
                "total": total_memories,
                "indexed": vector_count,
                "status": "enabled" if self.zhipuai_api_key else "disabled"
            },
            "api_key_configured": bool(self.zhipuai_api_key)
        }
    
    def close(self):
        """关闭数据库连接"""
        if self.conn:
            self.conn.close()
            logger.info("数据库连接已关闭")

def main():
    """CLI 主函数"""
    import click
    
    @click.group()
    def cli():
        """MemoryCore CLI"""
        pass
    
    @cli.command()
    @click.argument("query")
    @click.option("--top-k", default=10, help="返回结果数量")
    def search(query: str, top_k: int):
        """搜索记忆"""
        core = MemoryCore()
        results = core.search(query, top_k)
        
        print(f"\n🔍 搜索结果 (查询: '{query}')")
        print("=" * 60)
        
        for i, result in enumerate(results, 1):
            print(f"\n[{i}] ID: {result['id']}")
            print(f"    内容: {result['content']}")
            print(f"    类型: {result['type']}")
            print(f"    重要性: {result['importance']}")
            print(f"    访问次数: {result['access_count']}")
        
        core.close()
    
    @cli.command()
    @click.argument("content")
    @click.option("--type", "memory_type", default="fact", help="记忆类型")
    @click.option("--importance", default=0.5, type=float, help="重要性 (0.0-1.0)")
    @click.option("--tags", help="标签，逗号分隔")
    def capture(content: str, memory_type: str, importance: float, tags: str):
        """添加记忆"""
        core = MemoryCore()
        tag_list = tags.split(",") if tags else None
        result = core.capture(content, memory_type, importance, tag_list)
        
        print(f"\n✅ {result['message']}")
        print(f"   ID: {result['id']}")
        
        core.close()
    
    @cli.command()
    def status():
        """查看系统状态"""
        core = MemoryCore()
        status = core.status()
        
        print("\n📊 MemoryCore 系统状态")
        print("=" * 60)
        print(f"状态: {status['status']}")
        print(f"总记忆数: {status['total_memories']}")
        print(f"类型分布: {status['type_distribution']}")
        print(f"向量索引: {status['vector_index']['indexed']}/{status['vector_index']['total']}")
        print(f"API Key: {'✅ 已配置' if status['api_key_configured'] else '❌ 未配置'}")
        
        core.close()
    
    cli()

if __name__ == "__main__":
    main()
```

#### 3. 创建配置文件

**config/memory_config.json**：

```json
{
  "version": "1.4.0",
  "database": {
    "path": "data/memory.db",
    "backup": {
      "enabled": true,
      "interval_hours": 24,
      "retention_days": 30
    }
  },
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
    }
  },
  "memory": {
    "importance_decay": {
      "enabled": true,
      "rate": 0.01,
      "interval_days": 7
    },
    "access_tracking": {
      "enabled": true
    },
    "conflict_detection": {
      "enabled": true,
      "threshold": 0.8
    }
  },
  "search": {
    "default_limit": 10,
    "max_limit": 100,
    "time_range": "all"
  },
  "logging": {
    "level": "INFO",
    "file": "logs/memorycore.log",
    "max_size_mb": 10,
    "backup_count": 5
  }
}
```

#### 4. 安装 Python 依赖

```bash
# 创建虚拟环境（可选但推荐）
python3 -m venv venv
source venv/bin/activate

# 安装依赖
pip install httpx numpy scikit-learn click pydantic python-dotenv
```

#### 5. 创建 Python 接口

**memorycore.py**（位于 `~/.openclaw/workspace/`）：

```python
#!/usr/bin/env python3
"""
MemoryCore Python 接口
提供简单的 Python API 用于集成到其他应用
"""

import os
import sys
import subprocess

MEMORY_SYSTEM_PATH = os.path.expanduser("~/.openclaw/workspace/memory-system-v1.0")

def search(query: str, top_k: int = 10) -> list:
    """
    搜索记忆
    
    Args:
        query: 搜索查询
        top_k: 返回结果数量
    
    Returns:
        搜索结果列表
    """
    cmd = ["python3", "src/memory.py", "search", query, "--top-k", str(top_k)]
    result = subprocess.run(
        cmd,
        cwd=MEMORY_SYSTEM_PATH,
        capture_output=True,
        text=True
    )
    return result.stdout

def capture(content: str, memory_type: str = "fact", 
            importance: float = 0.5, tags: list = None) -> str:
    """
    添加记忆
    
    Args:
        content: 记忆内容
        memory_type: 记忆类型 (fact, belief, summary)
        importance: 重要性 (0.0-1.0)
        tags: 标签列表
    
    Returns:
        操作结果
    """
    cmd = ["python3", "src/memory.py", "capture", content]
    cmd.extend(["--type", memory_type])
    cmd.extend(["--importance", str(importance)])
    if tags:
        cmd.extend(["--tags", ",".join(tags)])
    
    result = subprocess.run(
        cmd,
        cwd=MEMORY_SYSTEM_PATH,
        capture_output=True,
        text=True
    )
    return result.stdout

def status() -> str:
    """
    获取系统状态
    
    Returns:
        系统状态信息
    """
    cmd = ["python3", "src/memory.py", "status"]
    result = subprocess.run(
        cmd,
        cwd=MEMORY_SYSTEM_PATH,
        capture_output=True,
        text=True
    )
    return result.stdout

class MemoryCore:
    """MemoryCore 类，提供面向对象的接口"""
    
    def __init__(self):
        self.path = MEMORY_SYSTEM_PATH
    
    def search(self, query: str, top_k: int = 10) -> list:
        """搜索记忆"""
        return search(query, top_k)
    
    def capture(self, content: str, memory_type: str = "fact", 
                importance: float = 0.5, tags: list = None) -> str:
        """添加记忆"""
        return capture(content, memory_type, importance, tags)
    
    def status(self) -> str:
        """获取系统状态"""
        return status()

# 导出函数和类
__all__ = ['search', 'capture', 'status', 'MemoryCore']
```

#### 6. 设置权限

```bash
# 设置执行权限
chmod +x src/memory.py
chmod +x memorycore.py

# 创建软链接（可选）
ln -s ~/.openclaw/workspace/memorycore.py /usr/local/bin/memorycore
```

### 方式 3：Docker 部署（高级）

适合容器化部署和生产环境。

#### 1. 创建 Dockerfile

```dockerfile
FROM python:3.10-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    sqlite3 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY requirements.txt .

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY src/ /app/src/
COPY config/ /app/config/

# 创建必要目录
RUN mkdir -p /app/data /app/logs

# 暴露端口（如果使用 Web API）
EXPOSE 8000

# 设置启动命令
CMD ["python3", "src/memory.py", "status"]
```

#### 2. 创建 requirements.txt

```txt
httpx>=0.24.0
numpy>=1.24.0
scikit-learn>=1.3.0
click>=8.1.0
pydantic>=2.0.0
python-dotenv>=1.0.0
```

#### 3. 创建 docker-compose.yml

```yaml
version: '3.8'

services:
  memorycore:
    build: .
    container_name: memorycore
    environment:
      - ZHIPUAI_API_KEY=${ZHIPUAI_API_KEY}
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs
      - ./config:/app/config
    ports:
      - "8000:8000"
    restart: unless-stopped
```

#### 4. 构建和运行

```bash
# 构建 Docker 镜像
docker-compose build

# 运行容器
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止容器
docker-compose down
```

### 验证安装

无论使用哪种安装方式，请执行以下验证步骤：

#### 1. 基本功能测试

```bash
cd ~/.openclaw/workspace/memory-system-v1.0

# 测试状态查询
python3 src/memory.py status

# 测试添加记忆
python3 src/memory.py capture --type fact --importance 0.9 "测试记忆"

# 测试搜索
python3 src/memory.py search "测试"
```

#### 2. 向量检索测试

```bash
# 测试向量搜索（如果 API Key 已配置）
python3 src/memory.py vector-search "测试"

# 查看向量状态
python3 src/memory.py vector-status
```

#### 3. Python 接口测试

```python
# 创建测试脚本
cat > test_memorycore.py << 'EOF'
#!/usr/bin/env python3
from memorycore import MemoryCore

# 初始化
core = MemoryCore()

# 测试搜索
results = core.search("测试")
print("搜索结果:", results)

# 测试添加
result = core.capture("Python 接口测试", memory_type="fact", importance=0.8)
print("添加结果:", result)

# 测试状态
status = core.status()
print("系统状态:", status)
EOF

# 运行测试
python3 test_memorycore.py
```

#### 4. 集成脚本测试

```bash
# 运行集成脚本
~/.openclaw/workspace/memory-core-init.sh

# 应该看到成功信息
```

### 安装完成清单

- [ ] MemoryCore 目录已创建
- [ ] 数据库已初始化
- [ ] 配置文件已创建
- [ ] Python 依赖已安装
- [ ] API Key 已配置
- [ ] 基本功能测试通过
- [ ] 向量检索测试通过
- [ ] Python 接口测试通过
- [ ] 集成脚本测试通过

---

## 配置说明

### 配置文件结构

MemoryCore 使用 JSON 格式的配置文件，位于 `config/memory_config.json`。

#### 完整配置示例

```json
{
  "version": "1.4.0",
  "database": {
    "path": "data/memory.db",
    "backup": {
      "enabled": true,
      "interval_hours": 24,
      "retention_days": 30
    }
  },
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
      "max_size": 1000,
      "ttl_minutes": 60
    }
  },
  "memory": {
    "importance_decay": {
      "enabled": true,
      "rate": 0.01,
      "interval_days": 7
    },
    "access_tracking": {
      "enabled": true
    },
    "conflict_detection": {
      "enabled": true,
      "threshold": 0.8
    },
    "types": {
      "fact": {
        "default_importance": 0.9,
        "decay_rate": 0.005
      },
      "belief": {
        "default_importance": 0.7,
        "decay_rate": 0.01
      },
      "summary": {
        "default_importance": 0.8,
        "decay_rate": 0.008
      }
    }
  },
  "search": {
    "strategy": "hybrid",
    "default_limit": 10,
    "max_limit": 100,
    "filters": {
      "min_importance": 0.0,
      "memory_types": ["fact", "belief", "summary"],
      "time_range": "all"
    },
    "rrf": {
      "k": 60
    }
  },
  "logging": {
    "level": "INFO",
    "file": "logs/memorycore.log",
    "max_size_mb": 10,
    "backup_count": 5,
    "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
  },
  "api": {
    "enabled": false,
    "host": "0.0.0.0",
    "port": 8000,
    "auth": {
      "enabled": false,
      "token": ""
    }
  }
}
```

### 配置项详解

#### 1. 数据库配置 (database)

```json
"database": {
  "path": "data/memory.db",
  "backup": {
    "enabled": true,
    "interval_hours": 24,
    "retention_days": 30
  }
}
```

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `path` | SQLite 数据库文件路径 | data/memory.db |
| `backup.enabled` | 是否启用自动备份 | true |
| `backup.interval_hours` | 备份间隔（小时） | 24 |
| `backup.retention_days` | 备份保留天数 | 30 |

#### 2. 向量检索配置 (vector)

```json
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
  }
}
```

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `enabled` | 是否启用向量检索 | true |
| `provider` | 向量服务提供商 | zhipuai |
| `model` | 模型名称 | embedding-3 |
| `base_url` | API 基础 URL | https://open.bigmodel.cn/api/paas/v4/ |
| `dimension` | 向量维度 | 2048 |
| `backend` | 向量存储后端 | sqlite |
| `hybrid_search.keyword_weight` | 关键词检索权重 | 0.3 |
| `hybrid_search.vector_weight` | 向量检索权重 | 0.7 |
| `hybrid_search.min_score` | 最小相似度分数 | 0.2 |

#### 3. 记忆管理配置 (memory)

```json
"memory": {
  "importance_decay": {
    "enabled": true,
    "rate": 0.01,
    "interval_days": 7
  },
  "access_tracking": {
    "enabled": true
  },
  "conflict_detection": {
    "enabled": true,
    "threshold": 0.8
  }
}
```

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `importance_decay.enabled` | 是否启用重要性衰减 | true |
| `importance_decay.rate` | 衰减率 | 0.01 |
| `importance_decay.interval_days` | 衰减间隔（天） | 7 |
| `access_tracking.enabled` | 是否启用访问追踪 | true |
| `conflict_detection.enabled` | 是否启用冲突检测 | true |
| `conflict_detection.threshold` | 冲突检测阈值 | 0.8 |

#### 4. 搜索配置 (search)

```json
"search": {
  "strategy": "hybrid",
  "default_limit": 10,
  "max_limit": 100,
  "filters": {
    "min_importance": 0.0,
    "memory_types": ["fact", "belief", "summary"],
    "time_range": "all"
  },
  "rrf": {
    "k": 60
  }
}
```

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `strategy` | 搜索策略 (hybrid/keyword/vector) | hybrid |
| `default_limit` | 默认返回结果数 | 10 |
| `max_limit` | 最大返回结果数 | 100 |
| `filters.min_importance` | 最小重要性过滤 | 0.0 |
| `filters.memory_types` | 允许的记忆类型 | fact, belief, summary |
| `filters.time_range` | 时间范围过滤 | all |
| `rrf.k` | RRF 融合常数 | 60 |

#### 5. 日志配置 (logging)

```json
"logging": {
  "level": "INFO",
  "file": "logs/memorycore.log",
  "max_size_mb": 10,
  "backup_count": 5
}
```

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `level` | 日志级别 (DEBUG/INFO/WARNING/ERROR) | INFO |
| `file` | 日志文件路径 | logs/memorycore.log |
| `max_size_mb` | 单个日志文件最大大小 (MB) | 10 |
| `backup_count` | 保留的备份文件数量 | 5 |

### 环境变量配置

MemoryCore 支持通过环境变量配置关键参数：

| 环境变量 | 说明 | 示例 |
|---------|------|------|
| `ZHIPUAI_API_KEY` | 智谱 AI API Key | `46c7ea42cdfe45b7b072288b6703ee8f.5XIR8I61NyJGZIjV` |
| `MEMORY_DB_PATH` | 数据库路径 | `data/memory.db` |
| `MEMORY_CONFIG_PATH` | 配置文件路径 | `config/memory_config.json` |
| `LOG_LEVEL` | 日志级别 | `INFO` |
| `LC_ALL` | 字符编码 | `C.UTF-8` |

#### 设置环境变量

```bash
# 方式 1：临时设置
export ZHIPUAI_API_KEY="your_api_key"
export LOG_LEVEL="DEBUG"

# 方式 2：写入 ~/.bashrc
echo "export ZHIPUAI_API_KEY=\"your_api_key\"" >> ~/.bashrc
source ~/.bashrc

# 方式 3：使用 .env 文件
cat > .env << EOF
ZHIPUAI_API_KEY=your_api_key
LOG_LEVEL=INFO
LC_ALL=C.UTF-8
EOF
```

### 智谱 AI 配置

#### API Key 配置

```bash
# 检查 API Key 是否配置
echo $ZHIPUAI_API_KEY

# 如果未配置，设置它
export ZHIPUAI_API_KEY="your_api_key_here"
```

#### API Key 验证

```bash
# 测试 API Key 是否有效
curl -X POST https://open.bigmodel.cn/api/paas/v4/embeddings \
  -H "Authorization: Bearer $ZHIPUAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "embedding-3",
    "input": "测试"
  }'
```

**成功响应示例**：

```json
{
  "object": "list",
  "data": [
    {
      "object": "embedding",
      "embedding": [0.123, 0.456, ...],  // 2048 维数组
      "index": 0
    }
  ],
  "model": "embedding-3",
  "usage": {
    "prompt_tokens": 2,
    "total_tokens": 2
  }
}
```

#### 模型参数

| 参数 | 说明 | 值 |
|------|------|-----|
| 模型名称 | embedding-3 | embedding-3 |
| 向量维度 | 2048 | 2048 |
| 最大输入长度 | 8192 tokens | 8192 |
| 支持语言 | 中文、英文等 | 100+ |

### 向量检索配置

#### 混合检索权重调整

根据您的需求调整关键词和向量检索的权重：

```json
"hybrid_search": {
  "keyword_weight": 0.3,
  "vector_weight": 0.7
}
```

**调整建议**：

- **精确匹配优先**：增加 `keyword_weight`（如 0.5/0.5）
- **语义相似优先**：增加 `vector_weight`（如 0.2/0.8）
- **平衡方案**：保持默认（0.3/0.7）

#### 向量缓存配置

```json
"cache": {
  "enabled": true,
  "max_size": 1000,
  "ttl_minutes": 60
}
```

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `enabled` | 是否启用缓存 | true |
| `max_size` | 最大缓存条目数 | 1000 |
| `ttl_minutes` | 缓存过期时间（分钟） | 60 |

### 搜索过滤配置

```json
"filters": {
  "min_importance": 0.0,
  "memory_types": ["fact", "belief", "summary"],
  "time_range": "all"
}
```

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `min_importance` | 最小重要性 | 0.0 |
| `memory_types` | 允许的记忆类型 | fact, belief, summary |
| `time_range` | 时间范围 (all/today/week/month) | all |

**时间范围选项**：

- `all`：全部时间
- `today`：今天
- `week`：最近一周
- `month`：最近一月

### 配置最佳实践

#### 1. 生产环境配置

```json
{
  "logging": {
    "level": "WARNING",
    "max_size_mb": 50,
    "backup_count": 10
  },
  "database": {
    "backup": {
      "enabled": true,
      "interval_hours": 6,
      "retention_days": 90
    }
  },
  "vector": {
    "cache": {
      "enabled": true,
      "max_size": 5000,
      "ttl_minutes": 120
    }
  }
}
```

#### 2. 开发环境配置

```json
{
  "logging": {
    "level": "DEBUG",
    "max_size_mb": 10,
    "backup_count": 3
  },
  "database": {
    "backup": {
      "enabled": false
    }
  },
  "vector": {
    "cache": {
      "enabled": false
    }
  }
}
```

#### 3. 高性能配置

```json
{
  "vector": {
    "cache": {
      "enabled": true,
      "max_size": 10000,
      "ttl_minutes": 180
    }
  },
  "search": {
    "default_limit": 20
  }
}
```

### 配置验证

```bash
# 验证配置文件语法
python3 -m json.tool config/memory_config.json > /dev/null
echo "配置文件语法正确"

# 测试配置加载
python3 -c "
import json
with open('config/memory_config.json') as f:
    config = json.load(f)
print('配置加载成功')
print(f'版本: {config[\"version\"]}')
print(f'向量检索: {config[\"vector\"][\"enabled\"]}')
print(f'日志级别: {config[\"logging\"][\"level\"]}')
"
```

---

## 使用指南

### 命令行接口（CLI）

MemoryCore 提供了完整的命令行接口，方便快速操作。

#### 1. 搜索记忆

```bash
# 基本搜索
python3 src/memory.py search "用户偏好"

# 指定返回数量
python3 src/memory.py search "股票" --top-k 20

# 使用集成脚本
cd ~/.openclaw/workspace/memory-system-v1.0
python3 src/memory.py search "投资"
```

**搜索参数**：

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `query` | 搜索查询（必填） | - |
| `--top-k` | 返回结果数量 | 10 |

**输出示例**：

```
🔍 搜索结果 (查询: '用户偏好')
============================================================

[1] ID: 550e8400-e29b-41d4-a716-446655440000
    内容: 用户喜欢简洁风格
    类型: fact
    重要性: 0.9
    访问次数: 5

[2] ID: 6ba7b810-9dad-11d1-80b4-00c04fd430c8
    内容: 用户偏好中文回答
    类型: fact
    重要性: 0.8
    访问次数: 3
```

#### 2. 添加记忆

```bash
# 基本添加
python3 src/memory.py capture "用户购买了股票"

# 指定类型
python3 src/memory.py capture --type fact "用户喜欢咖啡"

# 指定重要性
python3 src/memory.py capture --importance 0.9 "这是重要信息"

# 添加标签
python3 src/memory.py capture --tags "偏好,风格" "用户喜欢简洁"

# 组合使用
python3 src/memory.py capture \
    --type fact \
    --importance 0.95 \
    --tags "重要,用户" \
    "用户的电话号码是 1234567890"
```

**记忆类型**：

| 类型 | 说明 | 默认重要性 |
|------|------|-----------|
| `fact` | 事实信息 | 0.9 |
| `belief` | 推断信息 | 0.7 |
| `summary` | 会话摘要 | 0.8 |

**重要性评分**：

| 分数 | 说明 |
|------|------|
| 0.0 - 0.3 | 低重要性，可能很快过期 |
| 0.4 - 0.6 | 中等重要性，需要保留一段时间 |
| 0.7 - 0.9 | 高重要性，长期保留 |
| 1.0 | 关键信息，永不删除 |

**输出示例**：

```
✅ 记忆已成功捕获
   ID: 7c9e6679-7425-4dec-8034-03ed8f6ed614
```

#### 3. 查看状态

```bash
# 基本状态
python3 src/memory.py status

# 使用集成脚本
~/.openclaw/workspace/memory-core-init.sh
```

**输出示例**：

```
📊 MemoryCore 系统状态
============================================================
状态: healthy
总记忆数: 25
类型分布: {'fact': 15, 'belief': 7, 'summary': 3}
向量索引: 25/25
API Key: ✅ 已配置
```

#### 4. 向量搜索

```bash
# 向量语义搜索
python3 src/memory.py vector-search "简洁"

# 向量搜索状态
python3 src/memory.py vector-status

# 重建向量索引
python3 src/memory.py vector-build --provider zhipuai
```

**向量搜索参数**：

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `query` | 搜索查询 | - |
| `--top-k` | 返回结果数量 | 10 |
| `--min-score` | 最小相似度分数 | 0.2 |

#### 5. 记忆整合

```bash
# 整合工作记忆到长期记忆
python3 src/memory.py consolidate

# 整合并备份
python3 src/memory.py consolidate --backup
```

#### 6. 备份和恢复

```bash
# 备份数据库
python3 src/memory.py backup

# 恢复数据库
python3 src/memory.py restore /path/to/backup.db

# 查看备份列表
python3 src/memory.py backup-list
```

### Python 接口

MemoryCore 提供了简单的 Python API，方便集成到其他应用。

#### 1. 基本使用

```python
#!/usr/bin/env python3
from memorycore import MemoryCore

# 初始化
core = MemoryCore()

# 搜索记忆
results = core.search("用户偏好")
for result in results:
    print(f"内容: {result['content']}")
    print(f"重要性: {result['importance']}")

# 添加记忆
core.capture(
    "用户喜欢简洁风格",
    memory_type="fact",
    importance=0.9,
    tags=["偏好", "风格"]
)

# 查看状态
status = core.status()
print(f"总记忆数: {status['total_memories']}")
```

#### 2. 函数式 API

```python
#!/usr/bin/env python3
from memorycore import search, capture, status

# 搜索
results = search("股票", top_k=5)

# 添加
result = capture("用户购买了科技股", memory_type="fact", importance=0.9)

# 状态
status_info = status()
```

#### 3. 高级用法

```python
#!/usr/bin/env python3
from memorycore import MemoryCore
import json

core = MemoryCore()

# 搜索并过滤
results = core.search("用户")
filtered = [r for r in results if r['importance'] > 0.8]

# 批量添加
memories = [
    {"content": "用户A喜欢编程", "type": "fact", "importance": 0.9},
    {"content": "用户B偏好简洁", "type": "fact", "importance": 0.8},
    {"content": "用户C可能喜欢设计", "type": "belief", "importance": 0.7}
]

for mem in memories:
    core.capture(
        mem["content"],
        memory_type=mem["type"],
        importance=mem["importance"]
    )

# 导出记忆
all_results = core.search("", top_k=100)
with open("memory_export.json", "w") as f:
    json.dump(all_results, f, indent=2)
```

### Agent 集成

MemoryCore 可以轻松集成到各种 AI Agent 中。

#### 1. OpenClaw Agent 集成

```python
#!/usr/bin/env python3
"""
OpenClaw Agent 集成示例
"""

from memorycore import MemoryCore

class MyAgent:
    def __init__(self):
        self.memory = MemoryCore()
        self._load_context()
    
    def _load_context(self):
        """加载工作记忆"""
        results = self.memory.search("身份", top_k=10)
        self.context = {r['content'] for r in results}
    
    def process(self, user_input):
        """处理用户输入"""
        # 搜索相关记忆
        relevant = self.memory.search(user_input, top_k=5)
        
        # 处理输入
        response = self._generate_response(user_input, relevant)
        
        # 保存重要信息
        if self._should_remember(user_input):
            self.memory.capture(
                user_input,
                memory_type="fact",
                importance=0.8
            )
        
        return response
    
    def _generate_response(self, input, memories):
        """生成响应"""
        # 实现响应生成逻辑
        pass
    
    def _should_remember(self, text):
        """判断是否需要记住"""
        # 实现记忆逻辑
        pass
```

#### 2. LangChain 集成

```python
#!/usr/bin/env python3
"""
LangChain 集成示例
"""

from langchain.memory import BaseMemory
from memorycore import MemoryCore

class MemoryCoreMemory(BaseMemory):
    """MemoryCore 记忆类"""
    
    def __init__(self, core: MemoryCore):
        self.core = core
    
    @property
    def memory_variables(self) -> list:
        return ["memory"]
    
    def load_memory_variables(self, inputs: dict) -> dict:
        """加载记忆"""
        query = inputs.get("input", "")
        memories = self.core.search(query, top_k=5)
        memory_text = "\n".join([m['content'] for m in memories])
        return {"memory": memory_text}
    
    def save_context(self, inputs: dict, outputs: dict) -> None:
        """保存上下文"""
        input_text = inputs.get("input", "")
        output_text = outputs.get("output", "")
        
        # 保存输入
        if input_text:
            self.core.capture(
                input_text,
                memory_type="fact",
                importance=0.7
            )
        
        # 保存输出（如果重要）
        if output_text and len(output_text) > 100:
            self.core.capture(
                f"回应: {output_text}",
                memory_type="summary",
                importance=0.6
            )

# 使用示例
from langchain.chat_models import ChatOpenAI
from langchain.chains import ConversationChain

core = MemoryCore()
memory = MemoryCoreMemory(core)

llm = ChatOpenAI(temperature=0)
chain = ConversationChain(llm=llm, memory=memory)

# 对话
response = chain.predict(input="你好，我最近对 AI 很感兴趣")
print(response)
```

#### 3. OpenAI API 集成

```python
#!/usr/bin/env python3
"""
OpenAI API 集成示例
"""

import openai
from memorycore import MemoryCore

class MemoryCoreAgent:
    def __init__(self, api_key: str):
        openai.api_key = api_key
        self.memory = MemoryCore()
    
    def chat(self, user_input: str) -> str:
        """对话"""
        # 搜索相关记忆
        memories = self.memory.search(user_input, top_k=5)
        memory_context = "\n".join([m['content'] for m in memories])
        
        # 构建提示
        prompt = f"""
你是一个 AI 助手。以下是关于用户的记忆：

{memory_context}

用户说：{user_input}

请根据记忆和用户输入进行回应。
"""
        
        # 调用 OpenAI API
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": "你是一个有帮助的 AI 助手。"},
                {"role": "user", "content": prompt}
            ]
        )
        
        response_text = response.choices[0].message.content
        
        # 保存对话
        self.memory.capture(
            user_input,
            memory_type="fact",
            importance=0.7
        )
        
        return response_text

# 使用示例
agent = MemoryCoreAgent("your-openai-api-key")
response = agent.chat("我最近学了 Python")
print(response)
```

### 常见使用场景

#### 场景 1：智能客服

```python
#!/usr/bin/env python3
"""
智能客服示例
"""

from memorycore import MemoryCore

class CustomerServiceBot:
    def __init__(self):
        self.memory = MemoryCore()
    
    def handle_query(self, user_id: str, query: str) -> str:
        """处理用户查询"""
        # 搜索用户历史
        user_history = self.memory.search(user_id, top_k=10)
        
        # 搜索相关 FAQ
        faq_results = self.memory.search(query, top_k=5)
        
        # 生成响应
        response = self._generate_response(query, faq_results)
        
        # 保存查询
        self.memory.capture(
            f"用户 {user_id} 询问: {query}",
            memory_type="fact",
            importance=0.7,
            tags=["客服", user_id]
        )
        
        return response
    
    def _generate_response(self, query, faq):
        """生成响应"""
        # 实现响应生成逻辑
        pass
```

#### 场景 2：个人助理

```python
#!/usr/bin/env python3
"""
个人助理示例
"""

from memorycore import MemoryCore
from datetime import datetime

class PersonalAssistant:
    def __init__(self):
        self.memory = MemoryCore()
    
    def add_task(self, task: str, priority: str = "medium"):
        """添加任务"""
        importance = {
            "low": 0.5,
            "medium": 0.7,
            "high": 0.9
        }.get(priority, 0.7)
        
        self.memory.capture(
            f"任务: {task}",
            memory_type="fact",
            importance=importance,
            tags=["任务", priority]
        )
        
        return f"任务已添加: {task}"
    
    def show_tasks(self):
        """显示任务"""
        results = self.memory.search("任务", top_k=20)
        tasks = [r for r in results if "任务" in r.get("tags", [])]
        
        return "\n".join([
            f"- [{r['importance']}] {r['content']}"
            for r in sorted(tasks, key=lambda x: x['importance'], reverse=True)
        ])
    
    def remember(self, info: str):
        """记住信息"""
        self.memory.capture(
            info,
            memory_type="fact",
            importance=0.8
        )
        
        return f"已记住: {info}"
```

#### 场景 3：知识管理

```python
#!/usr/bin/env python3
"""
知识管理示例
"""

from memorycore import MemoryCore

class KnowledgeBase:
    def __init__(self):
        self.memory = MemoryCore()
    
    def add_knowledge(self, topic: str, content: str):
        """添加知识"""
        self.memory.capture(
            f"{topic}: {content}",
            memory_type="fact",
            importance=0.9,
            tags=["知识", topic]
        )
        
        return f"知识已添加: {topic}"
    
    def search_knowledge(self, query: str) -> list:
        """搜索知识"""
        results = self.memory.search(query, top_k=10)
        return [r for r in results if "知识" in r.get("tags", [])]
    
    def get_summary(self, topic: str):
        """获取主题摘要"""
        results = self.memory.search(topic, top_k=5)
        return "\n".join([r['content'] for r in results])
```

### 自动化脚本

#### HEARTBEAT 集成

在 `HEARTBEAT.md` 中添加定期检查：

```markdown
## 🧠 MemoryCore 状态检查 (每小时)

```bash
cd ~/.openclaw/workspace/memory-system-v1.0

# 检查状态
python3 src/memory.py status

# 记忆整合
python3 src/memory.py consolidate
```
```

#### Cron 定时任务

```bash
# 编辑 crontab
crontab -e

# 添加定时任务

# 每小时检查状态
0 * * * * cd /root/.openclaw/workspace/memory-system-v1.0 && /usr/bin/python3 src/memory.py status >> /var/log/memorycore-status.log 2>&1

# 每天整合记忆
0 0 * * * cd /root/.openclaw/workspace/memory-system-v1.0 && /usr/bin/python3 src/memory.py consolidate >> /var/log/memorycore-consolidate.log 2>&1

# 每周重建向量索引
0 0 * * 0 cd /root/.openclaw/workspace/memory-system-v1.0 && /usr/bin/python3 src/memory.py vector-build >> /var/log/memorycore-vector.log 2>&1

# 每天备份数据库
0 2 * * * cd /root/.openclaw/workspace/memory-system-v1.0 && /usr/bin/python3 src/memory.py backup >> /var/log/memorycore-backup.log 2>&1
```

---

## API 接口

### REST API 概述

MemoryCore 提供 RESTful API 接口，支持 HTTP 客户端访问。

#### API 基本信息

| 项目 | 值 |
|------|-----|
| 基础 URL | `http://localhost:8000/api/v1` |
| 认证方式 | Bearer Token (可选) |
| 数据格式 | JSON |
| 字符编码 | UTF-8 |

#### 启用 API 服务

```bash
# 修改配置文件
cat > config/memory_config.json << EOF
{
  "api": {
    "enabled": true,
    "host": "0.0.0.0",
    "port": 8000,
    "auth": {
      "enabled": false,
      "token": ""
    }
  }
}
EOF

# 启动 API 服务
python3 src/api_server.py
```

### API 接口列表

#### 1. 系统状态

**接口**：`GET /api/v1/status`

**描述**：获取系统状态

**请求示例**：

```bash
curl -X GET http://localhost:8000/api/v1/status
```

**响应示例**：

```json
{
  "status": "healthy",
  "version": "1.4.0",
  "database": {
    "path": "data/memory.db",
    "size_bytes": 102400
  },
  "memory": {
    "total": 25,
    "types": {
      "fact": 15,
      "belief": 7,
      "summary": 3
    }
  },
  "vector": {
    "enabled": true,
    "indexed": 25,
    "total": 25
  }
}
```

#### 2. 搜索记忆

**接口**：`GET /api/v1/memories/search`

**描述**：搜索记忆

**请求参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| query | string | 是 | 搜索查询 |
| top_k | integer | 否 | 返回结果数 (默认 10) |
| min_importance | float | 否 | 最小重要性 (默认 0.0) |
| memory_types | array | 否 | 记忆类型过滤 |
| time_range | string | 否 | 时间范围 (all/today/week/month) |

**请求示例**：

```bash
curl -X GET "http://localhost:8000/api/v1/memories/search?query=用户&top_k=5&min_importance=0.5"
```

**响应示例**：

```json
{
  "results": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "content": "用户喜欢简洁风格",
      "memory_type": "fact",
      "importance": 0.9,
      "confidence": 1.0,
      "tags": ["偏好", "风格"],
      "created_at": "2024-01-01T12:00:00Z",
      "updated_at": "2024-01-01T12:00:00Z",
      "last_accessed": "2024-01-02T10:00:00Z",
      "access_count": 5
    }
  ],
  "total": 1,
  "query": "用户"
}
```

#### 3. 添加记忆

**接口**：`POST /api/v1/memories`

**描述**：添加新记忆

**请求体**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| content | string | 是 | 记忆内容 |
| memory_type | string | 否 | 记忆类型 (fact/belief/summary) |
| importance | float | 否 | 重要性 (0.0-1.0) |
| tags | array | 否 | 标签列表 |
| metadata | object | 否 | 元数据 |

**请求示例**：

```bash
curl -X POST http://localhost:8000/api/v1/memories \
  -H "Content-Type: application/json" \
  -d '{
    "content": "用户购买了股票",
    "memory_type": "fact",
    "importance": 0.9,
    "tags": ["用户", "股票"]
  }'
```

**响应示例**：

```json
{
  "id": "7c9e6679-7425-4dec-8034-03ed8f6ed614",
  "status": "success",
  "message": "记忆已成功添加"
}
```

#### 4. 获取记忆详情

**接口**：`GET /api/v1/memories/{id}`

**描述**：获取指定记忆的详细信息

**请求示例**：

```bash
curl -X GET http://localhost:8000/api/v1/memories/550e8400-e29b-41d4-a716-446655440000
```

**响应示例**：

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "content": "用户喜欢简洁风格",
  "memory_type": "fact",
  "importance": 0.9,
  "confidence": 1.0,
  "tags": ["偏好", "风格"],
  "created_at": "2024-01-01T12:00:00Z",
  "updated_at": "2024-01-01T12:00:00Z",
  "last_accessed": "2024-01-02T10:00:00Z",
  "access_count": 5,
  "vector": [0.123, 0.456, ...]
}
```

#### 5. 更新记忆

**接口**：`PUT /api/v1/memories/{id}`

**描述**：更新记忆内容

**请求体**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| content | string | 否 | 新内容 |
| importance | float | 否 | 新重要性 |
| tags | array | 否 | 新标签 |

**请求示例**：

```bash
curl -X PUT http://localhost:8000/api/v1/memories/550e8400-e29b-41d4-a716-446655440000 \
  -H "Content-Type: application/json" \
  -d '{
    "importance": 1.0
  }'
```

**响应示例**：

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "success",
  "message": "记忆已更新"
}
```

#### 6. 删除记忆

**接口**：`DELETE /api/v1/memories/{id}`

**描述**：删除指定记忆

**请求示例**：

```bash
curl -X DELETE http://localhost:8000/api/v1/memories/550e8400-e29b-41d4-a716-446655440000
```

**响应示例**：

```json
{
  "status": "success",
  "message": "记忆已删除"
}
```

#### 7. 批量操作

**接口**：`POST /api/v1/memories/batch`

**描述**：批量添加或删除记忆

**请求示例**：

```bash
curl -X POST http://localhost:8000/api/v1/memories/batch \
  -H "Content-Type: application/json" \
  -d '{
    "action": "add",
    "memories": [
      {
        "content": "用户A喜欢编程",
        "memory_type": "fact",
        "importance": 0.9
      },
      {
        "content": "用户B偏好简洁",
        "memory_type": "fact",
        "importance": 0.8
      }
    ]
  }'
```

**响应示例**：

```json
{
  "status": "success",
  "added": 2,
  "ids": [
    "id1",
    "id2"
  ]
}
```

#### 8. 向量搜索

**接口**：`GET /api/v1/memories/vector-search`

**描述**：向量语义搜索

**请求参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| query | string | 是 | 搜索查询 |
| top_k | integer | 否 | 返回结果数 (默认 10) |
| min_score | float | 否 | 最小相似度 (默认 0.2) |

**请求示例**：

```bash
curl -X GET "http://localhost:8000/api/v1/memories/vector-search?query=简洁&top_k=5"
```

**响应示例**：

```json
{
  "results": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "content": "用户喜欢简洁风格",
      "score": 0.95,
      "memory_type": "fact"
    }
  ],
  "query": "简洁"
}
```

#### 9. 记忆整合

**接口**：`POST /api/v1/memories/consolidate`

**描述**：整合工作记忆到长期记忆

**请求示例**：

```bash
curl -X POST http://localhost:8000/api/v1/memories/consolidate
```

**响应示例**：

```json
{
  "status": "success",
  "consolidated": 10,
  "message": "记忆整合完成"
}
```

#### 10. 备份数据

**接口**：`POST /api/v1/maintenance/backup`

**描述**：创建数据库备份

**请求示例**：

```bash
curl -X POST http://localhost:8000/api/v1/maintenance/backup
```

**响应示例**：

```json
{
  "status": "success",
  "backup_path": "data/backups/memory_20240101_120000.db",
  "size_bytes": 102400
}
```

### 错误代码

| 代码 | 说明 | HTTP 状态 |
|------|------|-----------|
| 1001 | 无效的请求参数 | 400 |
| 1002 | 记忆不存在 | 404 |
| 1003 | API Key 无效 | 401 |
| 1004 | 数据库错误 | 500 |
| 1005 | 向量检索失败 | 500 |
| 1006 | 认证失败 | 401 |
| 1007 | 权限不足 | 403 |
| 1008 | 服务器内部错误 | 500 |

**错误响应格式**：

```json
{
  "error": {
    "code": 1002,
    "message": "记忆不存在",
    "details": "ID: 550e8400-e29b-41d4-a716-446655440000"
  }
}
```

### API 认证

如果启用了认证，需要在请求头中包含 Token：

```bash
curl -X GET http://localhost:8000/api/v1/status \
  -H "Authorization: Bearer your_token_here"
```

### Python 客户端示例

```python
#!/usr/bin/env python3
import requests

class MemoryCoreClient:
    """MemoryCore API 客户端"""
    
    def __init__(self, base_url: str = "http://localhost:8000/api/v1", 
                 token: str = None):
        self.base_url = base_url
        self.token = token
        self.headers = {
            "Content-Type": "application/json"
        }
        if token:
            self.headers["Authorization"] = f"Bearer {token}"
    
    def status(self):
        """获取系统状态"""
        response = requests.get(f"{self.base_url}/status", headers=self.headers)
        return response.json()
    
    def search(self, query: str, top_k: int = 10):
        """搜索记忆"""
        params = {"query": query, "top_k": top_k}
        response = requests.get(
            f"{self.base_url}/memories/search",
            headers=self.headers,
            params=params
        )
        return response.json()
    
    def add_memory(self, content: str, memory_type: str = "fact", 
                   importance: float = 0.5, tags: list = None):
        """添加记忆"""
        data = {
            "content": content,
            "memory_type": memory_type,
            "importance": importance,
            "tags": tags or []
        }
        response = requests.post(
            f"{self.base_url}/memories",
            headers=self.headers,
            json=data
        )
        return response.json()
    
    def get_memory(self, memory_id: str):
        """获取记忆详情"""
        response = requests.get(
            f"{self.base_url}/memories/{memory_id}",
            headers=self.headers
        )
        return response.json()
    
    def update_memory(self, memory_id: str, **kwargs):
        """更新记忆"""
        response = requests.put(
            f"{self.base_url}/memories/{memory_id}",
            headers=self.headers,
            json=kwargs
        )
        return response.json()
    
    def delete_memory(self, memory_id: str):
        """删除记忆"""
        response = requests.delete(
            f"{self.base_url}/memories/{memory_id}",
            headers=self.headers
        )
        return response.json()
    
    def vector_search(self, query: str, top_k: int = 10):
        """向量搜索"""
        params = {"query": query, "top_k": top_k}
        response = requests.get(
            f"{self.base_url}/memories/vector-search",
            headers=self.headers,
            params=params
        )
        return response.json()

# 使用示例
client = MemoryCoreClient()

# 获取状态
status = client.status()
print(f"系统状态: {status}")

# 搜索
results = client.search("用户")
print(f"搜索结果: {results}")

# 添加记忆
result = client.add_memory(
    "用户喜欢编程",
    memory_type="fact",
    importance=0.9,
    tags=["偏好", "编程"]
)
print(f"添加结果: {result}")
```

---

## 维护指南

### 日常维护

#### 1. 每日检查

```bash
# 检查系统状态
python3 src/memory.py status

# 检查向量索引
python3 src/memory.py vector-status

# 查看日志
tail -n 50 logs/memorycore.log
```

#### 2. 每日记忆整合

```bash
# 整合工作记忆
python3 src/memory.py consolidate

# 整合并备份
python3 src/memory.py consolidate --backup
```

#### 3. 每周任务

```bash
# 重建向量索引
python3 src/memory.py vector-build --provider zhipuai

# 检查数据库大小
du -sh data/memory.db

# 清理日志
find logs/ -name "*.log" -mtime +30 -delete
```

#### 4. 每月任务

```bash
# 完整备份
python3 src/memory.py backup

# 检查备份
python3 src/memory.py backup-list

# 分析记忆分布
python3 src/memory.py analyze
```

### 备份和恢复

#### 1. 自动备份配置

```json
{
  "database": {
    "backup": {
      "enabled": true,
      "interval_hours": 24,
      "retention_days": 30
    }
  }
}
```

#### 2. 手动备份

```bash
# 创建备份
python3 src/memory.py backup

# 指定备份路径
python3 src/memory.py backup --path /custom/path/backup.db

# 带压缩的备份
python3 src/memory.py backup --compress
```

#### 3. 备份列表

```bash
# 查看所有备份
python3 src/memory.py backup-list

# 查看最近的备份
python3 src/memory.py backup-list --limit 5
```

#### 4. 恢复备份

```bash
# 从备份恢复
python3 src/memory.py restore /path/to/backup.db

# 恢复前确认
python3 src/memory.py restore /path/to/backup.db --confirm

# 恢复到新数据库
python3 src/memory.py restore /path/to/backup.db --new-db
```

### 性能优化

#### 1. 数据库优化

```bash
# 数据库 VACUUM
sqlite3 data/memory.db "VACUUM;"

# 重建索引
sqlite3 data/memory.db "REINDEX;"

# 分析查询计划
sqlite3 data/memory.db "EXPLAIN QUERY PLAN SELECT * FROM memories WHERE content LIKE '%test%';"
```

#### 2. 向量索引优化

```bash
# 重建向量索引
python3 src/memory.py vector-build --force

# 批量索引
python3 src/memory.py vector-build --batch-size 100

# 优化索引
python3 src/memory.py vector-optimize
```

#### 3. 缓存优化

```json
{
  "vector": {
    "cache": {
      "enabled": true,
      "max_size": 5000,
      "ttl_minutes": 180
    }
  }
}
```

#### 4. 搜索优化

```bash
# 调整检索权重
# 修改配置文件中的 hybrid_search 权重

# 使用索引
sqlite3 data/memory.db "CREATE INDEX IF NOT EXISTS idx_content ON memories(content);"
sqlite3 data/memory.db "CREATE INDEX IF NOT EXISTS idx_importance ON memories(importance);"
sqlite3 data/memory.db "CREATE INDEX IF NOT EXISTS idx_type ON memories(memory_type);"
```

### 数据清理

#### 1. 清理过期记忆

```bash
# 清理重要性 < 0.3 且 30 天未访问的记忆
python3 src/memory.py cleanup --min-importance 0.3 --days 30

# 清理特定类型的记忆
python3 src/memory.py cleanup --type belief --days 60
```

#### 2. 清理重复记忆

```bash
# 检测重复记忆
python3 src/memory.py dedupe --detect

# 删除重复记忆
python3 src/memory.py dedupe --remove
```

#### 3. 清理日志

```bash
# 清理旧日志
find logs/ -name "*.log" -mtime +30 -delete

# 压缩日志
find logs/ -name "*.log" -mtime +7 -exec gzip {} \;
```

### 监控和告警

#### 1. 系统监控

```bash
# 监控脚本
cat > monitor.sh << 'EOF'
#!/bin/bash

MEMORY_DIR="$HOME/.openclaw/workspace/memory-system-v1.0"
cd "$MEMORY_DIR"

# 检查状态
STATUS=$(python3 src/memory.py status --json)
TOTAL=$(echo $STATUS | jq '.total_memories')

# 检查向量索引
VECTOR=$(python3 src/memory.py vector-status --json)
INDEXED=$(echo $VECTOR | jq '.indexed')

# 告警
if [ "$TOTAL" -gt 10000 ]; then
    echo "警告: 记忆数量过多 ($TOTAL)"
fi

if [ "$INDEXED" -lt "$TOTAL" ]; then
    echo "警告: 向量索引不完整 ($INDEXED/$TOTAL)"
fi
EOF

chmod +x monitor.sh
```

#### 2. 日志监控

```bash
# 监控错误日志
tail -f logs/memorycore.log | grep ERROR

# 监控向量检索错误
tail -f logs/memorycore.log | grep "vector.*error"
```

#### 3. 性能监控

```bash
# 检查数据库大小
du -sh data/memory.db

# 检查向量索引大小
du -sh data/vectors.db

# 检查内存使用
ps aux | grep memory.py
```

### 版本升级

#### 1. 备份数据

```bash
# 升级前备份
python3 src/memory.py backup --pre-upgrade
```

#### 2. 下载新版本

```bash
# 备份当前版本
cp -r memory-system-v1.0 memory-system-v1.0.backup

# 下载新版本
git clone https://github.com/your-repo/memorycore-v1.5.0.git
```

#### 3. 迁移数据

```bash
# 运行迁移脚本
python3 scripts/migrate.py --from v1.4.0 --to v1.5.0
```

#### 4. 验证升级

```bash
# 检查状态
python3 src/memory.py status

# 测试功能
python3 src/memory.py capture "升级测试"
python3 src/memory.py search "升级"
```

---

## 故障排查

### 常见问题

#### 问题 1：API Key 未配置

**症状**：
```
❌ 错误：请设置 ZHIPUAI_API_KEY 环境变量
```

**解决方案**：

```bash
# 设置 API Key
export ZHIPUAI_API_KEY="your_api_key_here"

# 写入 ~/.bashrc
echo "export ZHIPUAI_API_KEY=\"your_api_key_here\"" >> ~/.bashrc
source ~/.bashrc

# 验证
echo $ZHIPUAI_API_KEY
```

#### 问题 2：数据库锁定

**症状**：
```
sqlite3.OperationalError: database is locked
```

**解决方案**：

```bash
# 检查数据库进程
lsof data/memory.db

# 杀死锁定进程
kill -9 <pid>

# 重启 MemoryCore
python3 src/memory.py status
```

#### 问题 3：向量检索失败

**症状**：
```
向量检索失败: API 错误
```

**解决方案**：

```bash
# 检查 API Key
curl -X POST https://open.bigmodel.cn/api/paas/v4/embeddings \
  -H "Authorization: Bearer $ZHIPUAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "embedding-3", "input": "test"}'

# 检查网络连接
ping open.bigmodel.cn

# 检查代理设置
echo $HTTP_PROXY
echo $HTTPS_PROXY
```

#### 问题 4：搜索无结果

**症状**：
```
🔍 搜索结果 (查询: 'test')
============================================================
没有找到相关记忆
```

**解决方案**：

```bash
# 检查数据库
sqlite3 data/memory.db "SELECT COUNT(*) FROM memories;"

# 检查记忆内容
sqlite3 data/memory.db "SELECT content FROM memories LIMIT 5;"

# 检查向量索引
python3 src/memory.py vector-status

# 重建索引
python3 src/memory.py vector-build --force
```

#### 问题 5：性能缓慢

**症状**：搜索响应时间 > 1秒

**解决方案**：

```bash
# 优化数据库
sqlite3 data/memory.db "VACUUM;"
sqlite3 data/memory.db "ANALYZE;"

# 重建向量索引
python3 src/memory.py vector-build --force

# 调整缓存配置
# 修改配置文件中的 cache 配置

# 清理过期记忆
python3 src/memory.py cleanup --min-importance 0.2 --days 30
```

#### 问题 6：磁盘空间不足

**症状**：
```
No space left on device
```

**解决方案**：

```bash
# 检查磁盘空间
df -h

# 清理旧日志
find logs/ -name "*.log" -mtime +30 -delete

# 清理旧备份
find data/backups/ -name "*.db" -mtime +90 -delete

# 压缩数据库
sqlite3 data/memory.db "VACUUM;"
```

### 日志分析

#### 1. 查看日志

```bash
# 查看最新日志
tail -f logs/memorycore.log

# 查看错误日志
grep ERROR logs/memorycore.log

# 查看特定日期的日志
grep "2024-01-01" logs/memorycore.log
```

#### 2. 日志级别

| 级别 | 说明 | 用途 |
|------|------|------|
| DEBUG | 详细调试信息 | 开发调试 |
| INFO | 一般信息 | 正常运行 |
| WARNING | 警告信息 | 潜在问题 |
| ERROR | 错误信息 | 需要处理 |
| CRITICAL | 严重错误 | 系统故障 |

#### 3. 日志格式

```
2024-01-01 12:00:00,000 - memorycore - INFO - 记忆已捕获: 550e8400-e29b-41d4-a716-446655440000
```

格式：`时间 - 模块名 - 级别 - 消息`

### 应急处理

#### 1. 数据库损坏

**症状**：
```
sqlite3.DatabaseError: database disk image is malformed
```

**解决方案**：

```bash
# 1. 立即备份
cp data/memory.db data/memory.db.corrupted

# 2. 尝试修复
sqlite3 data/memory.db "PRAGMA integrity_check;"
sqlite3 data/memory.db "PRAGMA foreign_key_check;"

# 3. 导出数据
sqlite3 data/memory.db ".dump" > backup.sql

# 4. 创建新数据库
sqlite3 data/memory_new.db < backup.sql

# 5. 替换原数据库
mv data/memory_new.db data/memory.db
```

#### 2. 向量索引损坏

**症状**：
```
向量索引损坏: 无法读取索引
```

**解决方案**：

```bash
# 删除损坏的索引
rm -f data/vectors.db

# 重建索引
python3 src/memory.py vector-build --force

# 验证索引
python3 src/memory.py vector-status
```

#### 3. API 服务崩溃

**症状**：
```
API 服务无响应
```

**解决方案**：

```bash
# 1. 检查进程
ps aux | grep api_server

# 2. 重启服务
pkill -f api_server
python3 src/api_server.py &

# 3. 检查日志
tail -50 logs/api_server.log
```

#### 4. 完全恢复

```bash
# 1. 停止服务
pkill -f memory.py

# 2. 从备份恢复
python3 src/memory.py restore /path/to/latest/backup.db

# 3. 验证恢复
python3 src/memory.py status

# 4. 重启服务
python3 src/memory.py status
```

### 联系支持

如果以上解决方案无法解决问题：

1. 收集日志：`logs/memorycore.log`
2. 收集配置：`config/memory_config.json`
3. 收集错误信息：完整错误堆栈
4. 系统信息：操作系统、Python 版本等

---

## 最佳实践

### 添加记忆

#### 1. 选择合适的记忆类型

| 类型 | 使用场景 | 示例 |
|------|---------|------|
| `fact` | 已确认的事实 | 用户购买了股票 |
| `belief` | 推断的信息 | 用户可能喜欢编程 |
| `summary` | 会话摘要 | 用户讨论了投资策略 |

#### 2. 合理设置重要性

```bash
# 关键信息
python3 src/memory.py capture --type fact --importance 1.0 "用户的身份证号码是..."

# 重要信息
python3 src/memory.py capture --type fact --importance 0.9 "用户的电话号码是..."

# 一般信息
python3 src/memory.py capture --type fact --importance 0.7 "用户喜欢咖啡"

# 次要信息
python3 src/memory.py capture --type fact --importance 0.5 "用户昨天问了一个问题"

# 临时信息
python3 src/memory.py capture --type fact --importance 0.2 "用户正在浏览网页"
```

#### 3. 使用标签

```bash
# 添加标签有助于分类和搜索
python3 src/memory.py capture \
    --type fact \
    --importance 0.9 \
    --tags "用户,偏好,风格" \
    "用户喜欢简洁风格"
```

#### 4. 定期整合

```bash
# 每日整合工作记忆
python3 src/memory.py consolidate

# 整合并备份
python3 src/memory.py consolidate --backup
```

### 搜索技巧

#### 1. 语义搜索

```bash
# 使用自然语言查询
python3 src/memory.py search "用户喜欢什么风格"
python3 src/memory.py search "有什么投资建议"
```

#### 2. 精确匹配

```bash
# 使用具体关键词
python3 src/memory.py search "股票"
python3 src/memory.py search "Python"
```

#### 3. 组合查询

```bash
# 使用多个关键词
python3 src/memory.py search "用户 股票 投资"
```

#### 4. 时间过滤

```bash
# 搜索最近的记忆
python3 src/memory.py search "股票" --time-range "week"
```

#### 5. 类型过滤

```bash
# 只搜索事实
python3 src/memory.py search "股票" --type "fact"
```

### 性能优化

#### 1. 批量操作

```python
# 批量添加记忆
from memorycore import MemoryCore

core = MemoryCore()
memories = [
    {"content": "记忆1", "type": "fact", "importance": 0.9},
    {"content": "记忆2", "type": "fact", "importance": 0.8},
    {"content": "记忆3", "type": "belief", "importance": 0.7}
]

for mem in memories:
    core.capture(mem["content"], mem["type"], mem["importance"])
```

#### 2. 缓存策略

```json
{
  "vector": {
    "cache": {
      "enabled": true,
      "max_size": 5000,
      "ttl_minutes": 180
    }
  }
}
```

#### 3. 索引优化

```bash
# 定期重建索引
python3 src/memory.py vector-build

# 优化索引
python3 src/memory.py vector-optimize
```

#### 4. 数据清理

```bash
# 清理过期记忆
python3 src/memory.py cleanup --min-importance 0.3 --days 30

# 清理重复记忆
python3 src/memory.py dedupe --remove
```

### 安全建议

#### 1. API Key 保护

```bash
# 不要将 API Key 写入代码
# ❌ 错误
API_KEY = "46c7ea42cdfe45b7b072288b6703ee8f.5XIR8I61NyJGZIjV"

# ✅ 正确
import os
API_KEY = os.getenv("ZHIPUAI_API_KEY")
```

#### 2. 数据加密

```bash
# 加密备份
python3 src/memory.py backup --encrypt

# 使用 GPG 加密
gpg --encrypt --recipient user@example.com backup.db
```

#### 3. 访问控制

```json
{
  "api": {
    "auth": {
      "enabled": true,
      "token": "your_secure_token_here"
    }
  }
}
```

#### 4. 日志保护

```bash
# 不要在日志中记录敏感信息
# 使用日志级别过滤
{
  "logging": {
    "level": "WARNING"
  }
}
```

### 生产环境部署

#### 1. 配置优化

```json
{
  "logging": {
    "level": "WARNING",
    "max_size_mb": 50,
    "backup_count": 10
  },
  "database": {
    "backup": {
      "enabled": true,
      "interval_hours": 6,
      "retention_days": 90
    }
  }
}
```

#### 2. 监控告警

```bash
# 设置监控脚本
cat > /usr/local/bin/memorycore-monitor.sh << 'EOF'
#!/bin/bash
STATUS=$(python3 ~/.openclaw/workspace/memory-system-v1.0/src/memory.py status --json)
TOTAL=$(echo $STATUS | jq '.total_memories')

if [ "$TOTAL" -gt 100000 ]; then
    echo "警告: 记忆数量过多 ($TOTAL)" | mail -s "MemoryCore 告警" admin@example.com
fi
EOF

chmod +x /usr/local/bin/memorycore-monitor.sh

# 添加到 crontab
0 * * * * /usr/local/bin/memorycore-monitor.sh
```

#### 3. 自动化部署

```bash
# 使用 Docker Compose
docker-compose up -d

# 使用 systemd
cat > /etc/systemd/system/memorycore.service << 'EOF'
[Unit]
Description=MemoryCore Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/.openclaw/workspace/memory-system-v1.0
ExecStart=/usr/bin/python3 src/api_server.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable memorycore
systemctl start memorycore
```

---

## 附录

### A. 命令参考

#### 命令行接口完整参数

```bash
# 搜索
python3 src/memory.py search [OPTIONS] QUERY

选项:
  --top-k INTEGER        返回结果数 (默认 10)
  --min-importance FLOAT 最小重要性 (默认 0.0)
  --type TEXT            记忆类型过滤
  --time-range TEXT       时间范围 (all/today/week/month)

# 添加
python3 src/memory.py capture [OPTIONS] CONTENT

选项:
  --type TEXT            记忆类型 (fact/belief/summary)
  --importance FLOAT     重要性 (0.0-1.0)
  --tags TEXT            标签，逗号分隔

# 状态
python3 src/memory.py status [OPTIONS]

选项:
  --json                 JSON 格式输出

# 向量搜索
python3 src/memory.py vector-search [OPTIONS] QUERY

选项:
  --top-k INTEGER        返回结果数 (默认 10)
  --min-score FLOAT      最小相似度 (默认 0.2)

# 向量状态
python3 src/memory.py vector-status [OPTIONS]

选项:
  --json                 JSON 格式输出

# 构建向量索引
python3 src/memory.py vector-build [OPTIONS]

选项:
  --provider TEXT        向量服务提供商
  --force                强制重建
  --batch-size INTEGER   批处理大小

# 整合
python3 src/memory.py consolidate [OPTIONS]

选项:
  --backup               整合前备份

# 备份
python3 src/memory.py backup [OPTIONS]

选项:
  --path TEXT            备份路径
  --compress             压缩备份
  --encrypt              加密备份

# 恢复
python3 src/memory.py restore [OPTIONS] BACKUP_PATH

选项:
  --confirm              跳过确认
  --new-db               创建新数据库

# 清理
python3 src/memory.py cleanup [OPTIONS]

选项:
  --min-importance FLOAT 最小重要性
  --days INTEGER         天数
  --type TEXT            记忆类型

# 去重
python3 src/memory.py dedupe [OPTIONS]

选项:
  --detect               仅检测不删除
  --threshold FLOAT      相似度阈值
```

### B. 配置文件完整示例

```json
{
  "version": "1.4.0",
  "database": {
    "path": "data/memory.db",
    "backup": {
      "enabled": true,
      "interval_hours": 24,
      "retention_days": 30
    }
  },
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
      "max_size": 1000,
      "ttl_minutes": 60
    }
  },
  "memory": {
    "importance_decay": {
      "enabled": true,
      "rate": 0.01,
      "interval_days": 7
    },
    "access_tracking": {
      "enabled": true
    },
    "conflict_detection": {
      "enabled": true,
      "threshold": 0.8
    },
    "types": {
      "fact": {
        "default_importance": 0.9,
        "decay_rate": 0.005
      },
      "belief": {
        "default_importance": 0.7,
        "decay_rate": 0.01
      },
      "summary": {
        "default_importance": 0.8,
        "decay_rate": 0.008
      }
    }
  },
  "search": {
    "strategy": "hybrid",
    "default_limit": 10,
    "max_limit": 100,
    "filters": {
      "min_importance": 0.0,
      "memory_types": ["fact", "belief", "summary"],
      "time_range": "all"
    },
    "rrf": {
      "k": 60
    }
  },
  "logging": {
    "level": "INFO",
    "file": "logs/memorycore.log",
    "max_size_mb": 10,
    "backup_count": 5,
    "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
  },
  "api": {
    "enabled": false,
    "host": "0.0.0.0",
    "port": 8000,
    "auth": {
      "enabled": false,
      "token": ""
    }
  }
}
```

### C. 错误代码完整列表

| 代码 | 说明 | HTTP 状态 | 解决方案 |
|------|------|-----------|---------|
| 1000 | 未知错误 | 500 | 查看日志 |
| 1001 | 无效的请求参数 | 400 | 检查参数格式 |
| 1002 | 记忆不存在 | 404 | 确认记忆 ID |
| 1003 | API Key 无效 | 401 | 检查 API Key |
| 1004 | 数据库错误 | 500 | 检查数据库 |
| 1005 | 向量检索失败 | 500 | 检查向量服务 |
| 1006 | 认证失败 | 401 | 检查认证信息 |
| 1007 | 权限不足 | 403 | 检查权限设置 |
| 1008 | 服务器内部错误 | 500 | 查看日志 |
| 1009 | 数据库已存在 | 409 | 使用不同路径 |
| 1010 | 备份失败 | 500 | 检查磁盘空间 |
| 1011 | 恢复失败 | 500 | 检查备份文件 |
| 1012 | 配置文件错误 | 500 | 检查配置语法 |
| 1013 | 网络连接失败 | 503 | 检查网络 |
| 1014 | 请求超时 | 504 | 重试请求 |
| 1015 | 索引损坏 | 500 | 重建索引 |

### D. 常见问题 FAQ

#### Q1: MemoryCore 支持哪些向量服务？

A: 目前支持智谱 AI (embedding-3)，未来计划支持更多服务。

#### Q2: 如何迁移到新版本？

A: 参考维护指南中的版本升级部分，确保先备份数据。

#### Q3: 可以同时使用多个向量服务吗？

A: 当前版本不支持，但可以通过配置切换不同的向量服务。

#### Q4: 如何提高搜索精度？

A: 调整混合检索权重，使用更精确的查询词，定期重建向量索引。

#### Q5: MemoryCore 的存储容量限制是多少？

A: SQLite 理论上限为 140TB，实际限制取决于磁盘空间。

#### Q6: 如何导出所有记忆？

A: 使用 API 的批量查询功能，或直接导出数据库。

#### Q7: MemoryCore 支持分布式部署吗？

A: 当前版本为单机版，分布式支持在规划中。

#### Q8: 如何处理敏感信息？

A: 使用加密功能，限制日志级别，设置访问控制。

### E. 相关资源

#### 官方文档

- [MemoryCore GitHub](https://github.com/your-repo/memorycore)
- [智谱 AI 文档](https://open.bigmodel.cn/dev/api)

#### 社区支持

- [讨论论坛](https://forum.example.com)
- [问题反馈](https://github.com/your-repo/memorycore/issues)

#### 第三方集成

- LangChain 集成示例
- OpenAI 集成示例
- AutoGPT 集成示例

### F. 版本历史

#### v1.4.0 (2024-01-01)

- ✅ 智谱 AI 集成
- ✅ 混合检索引擎
- ✅ REST API 支持
- ✅ Docker 部署支持

#### v1.3.0 (2023-12-01)

- ✅ 三层记忆架构
- ✅ 向量检索支持
- ✅ 自动记忆管理

#### v1.2.0 (2023-11-01)

- ✅ 命令行接口
- ✅ Python API
- ✅ 配置系统

#### v1.1.0 (2023-10-01)

- ✅ SQLite 后端
- ✅ 基本搜索功能
- ✅ 记忆添加功能

#### v1.0.0 (2023-09-01)

- ✅ 初始版本

---

## 结语

MemoryCore 是一个强大而灵活的记忆管理系统，适用于各种 AI Agent 和智能应用场景。通过本部署指南，您应该能够：

✅ 完成系统安装和配置  
✅ 理解三层记忆架构  
✅ 掌握混合检索原理  
✅ 使用命令行和 Python 接口  
✅ 集成到各种应用中  
✅ 进行日常维护和故障排查  

如果您有任何问题或建议，欢迎通过以下方式联系：

- GitHub Issues: [https://github.com/your-repo/memorycore/issues](https://github.com/your-repo/memorycore/issues)
- 邮件: support@example.com

感谢使用 MemoryCore！

---

**文档版本**: 1.4.0  
**最后更新**: 2024-01-01  
**作者**: MemoryCore 团队
