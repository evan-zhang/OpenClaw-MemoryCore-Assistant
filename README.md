# MemoryCore 完整部署包

**版本**：v1.4.0 + 智谱AI 集成  
**部署日期**：2026-03-02  
**状态**：✅ 生产环境就绪

---

## 📦 目录结构

```
memorycore-deployment/
├── README.md                      # 本文件
├── MASTER.md                       # 完整部署指南（主文档）
├── docs/
│   ├── ARCHITECTURE.md            # 系统架构
│   ├── API.md                     # API 接口
│   ├── CONFIG.md                  # 配置说明
│   ├── TROUBLESHOOTING.md        # 故障排查
│   └── BEST_PRACTICES.md         # 最佳实践
├── scripts/
│   ├── install.sh                 # 自动安装脚本
│   ├── setup.sh                   # 系统配置脚本
│   ├── verify.sh                  # 验证脚本
│   ├── memory-health-check.sh     # 健康检查
│   └── memory-backup.sh          # 备份脚本
└── tools/
    ├── memorycore.py             # Python 接口封装
    └── requirements.txt          # Python 依赖
```

---

## 🚀 快速开始

### 方式 1：自动化安装（推荐）

```bash
# 1. 解压部署包
cd memorycore-deployment

# 2. 运行安装脚本
chmod +x scripts/install.sh
./scripts/install.sh

# 3. 运行配置脚本
chmod +x scripts/setup.sh
./scripts/setup.sh

# 4. 验证安装
chmod +x scripts/verify.sh
./scripts/verify.sh
```

### 方式 2：手动安装

```bash
# 按照 MASTER.md 中的详细步骤手动安装
# 步骤包括：
# 1. 系统准备
# 2. 依赖安装
# 3. MemoryCore 部署
# 4. 智谱 AI 配置
# 5. 向量索引构建
# 6. 系统验证
```

---

## 📋 文档说明

| 文档 | 用途 | 目标受众 |
|------|------|---------|
| **MASTER.md** | 完整部署指南 | 所有人员 |
| **docs/ARCHITECTURE.md** | 系统架构 | 架构人员、开发人员 |
| **docs/API.md** | API 接口 | 开发人员、使用人员 |
| **docs/CONFIG.md** | 配置说明 | 配置部署人员 |
| **docs/TROUBLESHOOTING.md** | 故障排查 | 配置部署人员、使用人员 |
| **docs/BEST_PRACTICES.md** | 最佳实践 | 所有人员 |

---

## 🔧 脚本说明

| 脚本 | 用途 | 运行时机 |
|------|------|---------|
| **scripts/install.sh** | 自动安装 | 首次部署 |
| **scripts/setup.sh** | 系统配置 | 部署后立即运行 |
| **scripts/verify.sh** | 验证安装 | 安装和配置后 |
| **scripts/memory-health-check.sh** | 健康检查 | 定期运行 |
| **scripts/memory-backup.sh** | 数据备份 | 定期运行 |

---

## 🎯 部署流程

### 第 1 步：系统准备

阅读 `MASTER.md` 的第 3 节：前置准备

### 第 2 步：安装部署

- 自动化：运行 `scripts/install.sh`
- 手动：按照 `MASTER.md` 第 4 节操作

### 第 3 步：系统配置

- 自动化：运行 `scripts/setup.sh`
- 手动：按照 `MASTER.md` 第 5 节操作

### 第 4 步：验证测试

运行 `scripts/verify.sh`

### 第 5 步：开始使用

参考 `MASTER.md` 第 6 节：使用指南

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

### 文档问题

- 完整指南：`MASTER.md`
- 架构说明：`docs/ARCHITECTURE.md`
- 配置说明：`docs/CONFIG.md`
- 故障排查：`docs/TROUBLESHOOTING.md`

### 运行问题

1. 运行健康检查：`scripts/memory-health-check.sh`
2. 查看故障排查：`docs/TROUBLESHOOTING.md`
3. 检查系统日志

---

## 🎉 开始部署

**按照 `MASTER.md` 开始部署 MemoryCore！**

---

## 📝 版本历史

- **v1.4.0** (2026-03-02)
  - 智谱 AI 向量检索集成
  - 三层记忆架构
  - 混合检索引擎
  - 完整部署包

---

**MemoryCore - 你的智能记忆系统！** 🧠
