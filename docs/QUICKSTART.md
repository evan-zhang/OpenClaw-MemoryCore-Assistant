# MemoryCore 快速参考

**版本**：v1.4.0 + 智谱AI 集成  
**最后更新**：2026-03-02 16:12 GMT+8

---

## 🚀 快速命令

### 系统状态
```bash
cd ~/.openclaw/workspace/memory-system-v1.0
export ZHIPUAI_API_KEY="46c7ea42cdfe45b7b072288b6703ee8f.5XIR8I61NyJGZIjV"
export LC_ALL=C.UTF-8

# 查看状态
python3 src/memory.py status
```

### 搜索记忆
```bash
# 关键词搜索
python3 src/memory.py search "用户"

# 语义搜索（使用向量）
python3 src/memory.py vector-search "用户偏好"

# 混合搜索（关键词 + 向量）
python3 src/memory.py search "简洁风格"
```

### 添加记忆
```bash
# 添加事实
python3 src/memory.py capture --type fact --importance 0.9 "内容"

# 添加推断
python3 src/memory.py capture --type belief --importance 0.7 "内容"

# 添加摘要
python3 src/memory.py capture --type summary --importance 0.8 "内容"
```

### 维护操作
```bash
# 记忆整合
python3 src/memory.py consolidate

# 构建向量索引
python3 src/memory.py vector-build --provider zhipuai

# 系统验证
python3 src/memory.py validate
```

---

## 📊 记忆类型

| 类型 | 说明 | 示例 |
|------|------|------|
| `fact` | 事实 | "用户名是 Evan" |
| `belief` | 推断 | "用户可能喜欢简洁风格" |
| `summary` | 摘要 | "用户最近讨论了股票交易" |

---

## 🎯 重要性评分

| 分数 | 说明 | 使用场景 |
|------|------|----------|
| 1.0 | 关键信息 | 用户名、密码、重要决策 |
| 0.9 | 重要信息 | 用户偏好、常用命令 |
| 0.7 | 一般信息 | 兴趣爱好、工作项目 |
| 0.5 | 临时信息 | 当前任务、短期计划 |
| 0.3 | 低重要性 | 随意想法、临时想法 |

---

## 🔧 环境变量

```bash
# 智谱 AI API Key
export ZHIPUAI_API_KEY="46c7ea42cdfe45b7b072288b6703ee8f.5XIR8I61NyJGZIjV"

# UTF-8 编码
export LC_ALL=C.UTF-8

# 记忆系统目录（可选）
export MEMORY_SYSTEM_DIR="/root/.openclaw/workspace/memory-system-v1.0"
```

---

## 📝 别名配置

添加到 `~/.bashrc`：

```bash
# 记忆系统目录
export MEMORY_SYSTEM_DIR="$HOME/.openclaw/workspace/memory-system-v1.0"

# 智谱 AI API Key
export ZHIPUAI_API_KEY="46c7ea42cdfe45b7b072288b6703ee8f.5XIR8I61NyJGZIjV"

# UTF-8 编码
export LC_ALL=C.UTF-8

# 别名
alias mem="cd \$MEMORY_SYSTEM_DIR && python3 src/memory.py"
alias memsearch="\$MEMORY_SYSTEM_DIR/python3 src/memory.py search"
alias memcapture="\$MEMORY_SYSTEM_DIR/python3 src/memory.py capture --type fact --importance 0.9"
alias memstatus="\$MEMORY_SYSTEM_DIR/python3 src/memory.py status"
alias membuild="\$MEMORY_SYSTEM_DIR/python3 src/memory.py vector-build --provider zhipuai"
```

重新加载：
```bash
source ~/.bashrc
```

使用：
```bash
# 搜索
memsearch "关键词"

# 添加
memcapture "内容"

# 状态
memstatus
```

---

## 🎯 使用场景

### 场景 1：用户偏好存储

```bash
# 添加偏好
python3 src/memory.py capture --type fact --importance 0.9 "用户偏好简洁风格"

# 搜索偏好
python3 src/memory.py search "简洁"
```

### 场景 2：知识库管理

```bash
# 添加知识点
python3 src/memory.py capture --type fact --importance 0.7 "股票 NVDA 主要业务是 GPU"

# 搜索知识点
python3 src/memory.py search "GPU"
```

### 场景 3：工作流程记录

```bash
# 记录流程
python3 src/memory.py capture --type summary --importance 0.8 "部署 MemoryCore 的步骤：1. 系统准备 2. 安装依赖..."

# 搜索流程
python3 src/memory.py search "部署步骤"
```

---

## 🔍 搜索技巧

### 技巧 1：语义搜索

使用自然语言查询，向量检索会找到语义相关的记忆。

**示例**：
```
"用户偏好" → 找到所有关于用户偏好的记忆
"股票交易" → 找到所有关于股票交易的记忆
```

### 技巧 2：关键词搜索

使用具体关键词进行精确匹配。

**示例**：
```
"Evan" → 找到所有包含 Evan 的记忆
"NVDA" → 找到所有包含 NVDA 的记忆
```

### 技巧 3：组合搜索

结合多个关键词进行更精准的搜索。

**示例**：
```
"用户 股票 买入" → 找到用户买入股票的记忆
"偏好 古诗" → 找到用户喜欢古诗的记忆
```

---

## 📝 维护任务

### 每日任务

- [ ] 记忆整合 `consolidate`
- [ ] 检查系统状态 `status`
- [ ] 清理过期记忆

### 每周任务

- [ ] 重建向量索引 `vector-build`
- [ ] 检查系统性能
- [ ] 备份重要记忆

### 每月任务

- [ ] 归档旧记忆
- [ ] 清理过时记忆
- [ ] 优化系统配置

---

## 🎯 最佳实践

### 1. 添加记忆

- ✅ 使用合适的重要性分数
- ✅ 选择正确的记忆类型
- ✅ 定期整合记忆

### 2. 搜索记忆

- ✅ 使用语义搜索（自然语言）
- ✅ 使用关键词搜索（精确匹配）
- ✅ 使用组合搜索（更精准）

### 3. 维护系统

- ✅ 定期整合记忆
- ✅ 定期重建向量索引
- ✅ 定期备份重要记忆

---

**MemoryCore v1.4.0 - 你的智能记忆系统！** 🧠
