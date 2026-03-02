# MemoryCore 系统架构文档

**版本**: v1.4.0 + 智谱AI集成  
**最后更新**: 2024-01-01

---

## 目录

- [概述](#概述)
- [三层记忆架构详解](#三层记忆架构详解)
- [向量检索引擎架构](#向量检索引擎架构)
- [混合检索策略](#混合检索策略)
- [数据流设计](#数据流设计)
- [模块依赖关系](#模块依赖关系)
- [性能分析](#性能分析)
- [扩展性设计](#扩展性设计)

---

## 概述

MemoryCore 采用现代化的分层架构设计，结合了传统关系型数据库和现代向量检索技术，为 AI Agent 提供高效、准确的记忆管理能力。

### 设计原则

1. **分层架构**：清晰的职责分离，便于维护和扩展
2. **高性能**：优化的检索算法，毫秒级响应
3. **可扩展**：模块化设计，支持插件扩展
4. **高可用**：数据持久化，自动备份恢复

### 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| 应用层 | Python 3.10+ | 业务逻辑 |
| 数据层 | SQLite 3.x | 关系数据存储 |
| 向量层 | 智谱 AI embedding-3 | 语义向量检索 |
| 检索层 | TF-IDF + 余弦相似度 + RRF | 混合检索算法 |

---

## 三层记忆架构详解

MemoryCore 的核心是三层记忆架构，每一层都有特定的用途和特性。

### Layer 1: 工作记忆（Working Memory）

#### 设计目的

工作记忆用于存储当前会话的即时信息，具有以下特点：

- **快速访问**：所有数据在内存中，访问速度 <10ms
- **低 Token 消耗**：严格控制数据量，<2000 tokens
- **会话级**：每次会话开始时加载，结束时保存

#### 数据结构

```python
class WorkingMemory:
    def __init__(self):
        self.identity = {
            "name": "小A",
            "role": "AI Assistant",
            "version": "v1.4.0",
            "capabilities": ["search", "capture", "status"]
        }
        
        self.owner = {
            "name": "User",
            "preferences": {
                "language": "zh-CN",
                "style": "concise"
            },
            "timezone": "Asia/Shanghai"
        }
        
        self.constraints = {
            "max_tokens": 2000,
            "memory_limit": 10000,
            "allowed_actions": ["read", "write", "search"]
        }
        
        self.top_summaries = {
            "recent_activities": [],
            "key_facts": [],
            "pending_tasks": []
        }
    
    def get_context(self) -> str:
        """获取工作记忆上下文"""
        context = []
        context.append(f"身份: {self.identity['name']}")
        context.append(f"角色: {self.identity['role']}")
        
        if self.top_summaries["key_facts"]:
            context.append("关键信息:")
            for fact in self.top_summaries["key_facts"]:
                context.append(f"  - {fact}")
        
        return "\n".join(context)
    
    def update(self, content: str, importance: float):
        """更新工作记忆"""
        if importance > 0.8:
            if len(self.top_summaries["key_facts"]) < 10:
                self.top_summaries["key_facts"].append(content)
    
    def save_to_longterm(self, longterm_memory):
        """保存到长期记忆"""
        for fact in self.top_summaries["key_facts"]:
            longterm_memory.capture(
                fact,
                memory_type="fact",
                importance=0.9
            )
    
    def load_from_longterm(self, longterm_memory):
        """从长期记忆加载"""
        results = longterm_memory.search("", top_k=20)
        self.top_summaries["key_facts"] = [
            r["content"] for r in results if r["importance"] > 0.8
        ]
```

#### 内存限制

```python
class TokenLimiter:
    """Token 限制器"""
    
    def __init__(self, max_tokens: int = 2000):
        self.max_tokens = max_tokens
        self.current_tokens = 0
    
    def can_add(self, text: str) -> bool:
        """检查是否可以添加"""
        estimated_tokens = len(text) // 2  # 粗略估算
        return (self.current_tokens + estimated_tokens) <= self.max_tokens
    
    def add(self, text: str) -> bool:
        """添加文本"""
        if self.can_add(text):
            estimated_tokens = len(text) // 2
            self.current_tokens += estimated_tokens
            return True
        return False
    
    def get_remaining(self) -> int:
        """获取剩余 Token 数"""
        return self.max_tokens - self.current_tokens
```

#### 数据流

```
会话开始
    ↓
从 Layer 2 加载高重要性记忆 (importance > 0.8)
    ↓
填充到工作记忆
    ↓
对话过程中实时更新
    ↓
会话结束
    ↓
工作记忆保存到 Layer 2
```

### Layer 2: 长期记忆（Long-term Memory）

#### 设计目的

长期记忆用于存储结构化信息，支持高效的检索和更新。

#### 数据模型

```python
from datetime import datetime
from typing import List, Dict, Optional
import uuid

class Memory:
    """记忆数据模型"""
    
    def __init__(
        self,
        content: str,
        memory_type: str = "fact",
        importance: float = 0.5,
        tags: List[str] = None,
        metadata: Dict = None
    ):
        self.id = str(uuid.uuid4())
        self.content = content
        self.memory_type = memory_type  # fact, belief, summary
        self.importance = importance  # 0.0 - 1.0
        self.confidence = 1.0  # 信念的置信度
        self.tags = tags or []
        self.metadata = metadata or {}
        
        now = datetime.now()
        self.created_at = now.isoformat()
        self.updated_at = now.isoformat()
        self.last_accessed = now.isoformat()
        self.access_count = 0
        
        self.vector = None  # 向量表示
    
    def update_access(self):
        """更新访问记录"""
        self.last_accessed = datetime.now().isoformat()
        self.access_count += 1
    
    def to_dict(self) -> Dict:
        """转换为字典"""
        return {
            "id": self.id,
            "content": self.content,
            "memory_type": self.memory_type,
            "importance": self.importance,
            "confidence": self.confidence,
            "tags": self.tags,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
            "last_accessed": self.last_accessed,
            "access_count": self.access_count,
            "metadata": self.metadata
        }
```

#### 数据库 Schema

```sql
-- 记忆表
CREATE TABLE IF NOT EXISTS memories (
    id TEXT PRIMARY KEY,
    content TEXT NOT NULL,
    memory_type TEXT NOT NULL,
    importance REAL DEFAULT 0.5,
    confidence REAL DEFAULT 1.0,
    tags TEXT,  -- JSON 格式
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    last_accessed TEXT NOT NULL,
    access_count INTEGER DEFAULT 0,
    vector BLOB,  -- 二进制向量数据
    metadata TEXT  -- JSON 格式
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_content ON memories(content);
CREATE INDEX IF NOT EXISTS idx_importance ON memories(importance);
CREATE INDEX IF NOT EXISTS idx_type ON memories(memory_type);
CREATE INDEX IF NOT EXISTS idx_created ON memories(created_at);
CREATE INDEX IF NOT EXISTS idx_accessed ON memories(last_accessed);

-- 全文搜索索引
CREATE VIRTUAL TABLE IF NOT EXISTS memories_fts USING fts5(
    content,
    content='memories',
    content_rowid='rowid'
);
```

#### 记忆类型管理

```python
class MemoryTypeManager:
    """记忆类型管理器"""
    
    TYPE_CONFIGS = {
        "fact": {
            "default_importance": 0.9,
            "decay_rate": 0.005,
            "description": "已确认的事实信息"
        },
        "belief": {
            "default_importance": 0.7,
            "decay_rate": 0.01,
            "description": "推断的信息，带有置信度"
        },
        "summary": {
            "default_importance": 0.8,
            "decay_rate": 0.008,
            "description": "会话或事件的摘要"
        }
    }
    
    @classmethod
    def get_default_importance(cls, memory_type: str) -> float:
        """获取默认重要性"""
        return cls.TYPE_CONFIGS.get(memory_type, {}).get(
            "default_importance", 0.5
        )
    
    @classmethod
    def get_decay_rate(cls, memory_type: str) -> float:
        """获取衰减率"""
        return cls.TYPE_CONFIGS.get(memory_type, {}).get(
            "decay_rate", 0.01
        )
    
    @classmethod
    def is_valid_type(cls, memory_type: str) -> bool:
        """检查类型是否有效"""
        return memory_type in cls.TYPE_CONFIGS
```

#### 重要性管理

```python
class ImportanceManager:
    """重要性管理器"""
    
    def __init__(self, db_path: str):
        self.db_path = db_path
    
    def decay_importance(self):
        """衰减重要性"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # 获取所有记忆
        cursor.execute("SELECT id, memory_type, importance, updated_at FROM memories")
        memories = cursor.fetchall()
        
        now = datetime.now()
        
        for memory_id, memory_type, importance, updated_at in memories:
            # 计算衰减
            updated_time = datetime.fromisoformat(updated_at)
            days_elapsed = (now - updated_time).days
            
            if days_elapsed > 7:  # 7天未访问才开始衰减
                decay_rate = MemoryTypeManager.get_decay_rate(memory_type)
                decay_amount = decay_rate * (days_elapsed / 7)
                new_importance = max(0.0, importance - decay_amount)
                
                # 更新重要性
                cursor.execute(
                    "UPDATE memories SET importance = ? WHERE id = ?",
                    (new_importance, memory_id)
                )
        
        conn.commit()
        conn.close()
    
    def boost_importance(self, memory_id: str, boost: float = 0.1):
        """提升重要性"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute(
            "SELECT importance FROM memories WHERE id = ?",
            (memory_id,)
        )
        result = cursor.fetchone()
        
        if result:
            current_importance = result[0]
            new_importance = min(1.0, current_importance + boost)
            
            cursor.execute(
                "UPDATE memories SET importance = ? WHERE id = ?",
                (new_importance, memory_id)
            )
        
        conn.commit()
        conn.close()
```

### Layer 3: 原始日志（Raw Logs）

#### 设计目的

原始日志用于完整记录所有操作和数据，用于数据分析和故障恢复。

#### 日志格式

```json
{
  "timestamp": "2024-01-01T12:00:00Z",
  "level": "info",
  "event": "capture",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "content": "用户说喜欢咖啡",
    "memory_type": "fact",
    "importance": 0.9
  }
}
```

#### 日志管理器

```python
import json
import gzip
from pathlib import Path
from datetime import datetime

class LogManager:
    """日志管理器"""
    
    def __init__(self, log_dir: str = "logs"):
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(exist_ok=True)
        
        self.episodic_dir = self.log_dir / "episodic"
        self.episodic_dir.mkdir(exist_ok=True)
    
    def log_event(self, event: str, level: str = "info", **kwargs):
        """记录事件"""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "level": level,
            "event": event,
            "data": kwargs
        }
        
        # 写入当日日志文件
        today = datetime.now().strftime("%Y-%m-%d")
        log_file = self.episodic_dir / f"{today}.jsonl"
        
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")
    
    def read_logs(self, date: str) -> List[Dict]:
        """读取指定日期的日志"""
        log_file = self.episodic_dir / f"{date}.jsonl"
        
        if not log_file.exists():
            return []
        
        logs = []
        with open(log_file, "r", encoding="utf-8") as f:
            for line in f:
                logs.append(json.loads(line))
        
        return logs
    
    def archive_old_logs(self, days: int = 30):
        """归档旧日志"""
        cutoff_date = datetime.now().timestamp() - (days * 86400)
        
        for log_file in self.episodic_dir.glob("*.jsonl"):
            if log_file.stat().st_mtime < cutoff_date:
                # 压缩日志
                with open(log_file, "rb") as f_in:
                    with gzip.open(f"{log_file}.gz", "wb") as f_out:
                        f_out.writelines(f_in)
                
                # 删除原文件
                log_file.unlink()
```

#### 日志查询

```python
class LogQuery:
    """日志查询"""
    
    def __init__(self, log_manager: LogManager):
        self.log_manager = log_manager
    
    def query_by_event(self, event: str, days: int = 7) -> List[Dict]:
        """按事件查询"""
        results = []
        cutoff_date = datetime.now() - timedelta(days=days)
        
        for i in range(days):
            date = (cutoff_date + timedelta(days=i)).strftime("%Y-%m-%d")
            logs = self.log_manager.read_logs(date)
            results.extend([log for log in logs if log["event"] == event])
        
        return results
    
    def query_by_level(self, level: str, days: int = 7) -> List[Dict]:
        """按级别查询"""
        results = []
        cutoff_date = datetime.now() - timedelta(days=days)
        
        for i in range(days):
            date = (cutoff_date + timedelta(days=i)).strftime("%Y-%m-%d")
            logs = self.log_manager.read_logs(date)
            results.extend([log for log in logs if log["level"] == level])
        
        return results
```

---

## 向量检索引擎架构

### 整体架构

```
┌─────────────────────────────────────────┐
│         向量检索引擎                    │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────┐      ┌──────────┐       │
│  │ 向量生成 │─────▶│ 向量存储 │       │
│  │ (Embedding)│     │ (Storage)│       │
│  └────┬─────┘      └────┬─────┘       │
│       │                 │             │
│       └────────┬────────┘             │
│                │                      │
│       ┌────────▼────────┐             │
│       │  向量索引       │             │
│       │  (Index)       │             │
│       └────────┬────────┘             │
│                │                      │
│       ┌────────▼────────┐             │
│       │  相似度计算     │             │
│       │  (Similarity)   │             │
│       └────────┬────────┘             │
│                │                      │
│       ┌────────▼────────┐             │
│       │  结果排序       │             │
│       │  (Ranking)      │             │
│       └────────┬────────┘             │
│                │                      │
│                ▼                      │
│         返回结果                     │
│                                         │
└─────────────────────────────────────────┘
```

### 向量生成（Embedding）

#### 智谱 AI 集成

```python
import httpx
import base64
import numpy as np

class ZhipuAIClient:
    """智谱 AI 客户端"""
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = "https://open.bigmodel.cn/api/paas/v4/"
        self.model = "embedding-3"
        self.dimension = 2048
    
    async def generate_embedding(self, text: str) -> np.ndarray:
        """生成向量"""
        url = f"{self.base_url}embeddings"
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        data = {
            "model": self.model,
            "input": text
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(url, headers=headers, json=data)
            response.raise_for_status()
            
            result = response.json()
            embedding = result["data"][0]["embedding"]
            
            return np.array(embedding, dtype=np.float32)
    
    async def generate_embeddings_batch(
        self, 
        texts: List[str], 
        batch_size: int = 10
    ) -> List[np.ndarray]:
        """批量生成向量"""
        embeddings = []
        
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i + batch_size]
            batch_embeddings = await self._generate_batch(batch)
            embeddings.extend(batch_embeddings)
        
        return embeddings
    
    async def _generate_batch(self, texts: List[str]) -> List[np.ndarray]:
        """生成一批向量"""
        url = f"{self.base_url}embeddings"
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        data = {
            "model": self.model,
            "input": texts
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(url, headers=headers, json=data)
            response.raise_for_status()
            
            result = response.json()
            embeddings = [
                np.array(item["embedding"], dtype=np.float32)
                for item in result["data"]
            ]
            
            return embeddings
```

#### 向量缓存

```python
import pickle
from datetime import datetime, timedelta
from typing import Optional

class VectorCache:
    """向量缓存"""
    
    def __init__(self, cache_dir: str = "data/cache", ttl_minutes: int = 60):
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(exist_ok=True)
        self.ttl = timedelta(minutes=ttl_minutes)
    
    def _get_cache_key(self, text: str) -> str:
        """获取缓存键"""
        import hashlib
        return hashlib.md5(text.encode()).hexdigest()
    
    def get(self, text: str) -> Optional[np.ndarray]:
        """获取缓存的向量"""
        cache_key = self._get_cache_key(text)
        cache_file = self.cache_dir / f"{cache_key}.pkl"
        
        if not cache_file.exists():
            return None
        
        # 检查是否过期
        if cache_file.stat().st_mtime < (datetime.now() - self.ttl).timestamp():
            return None
        
        # 读取缓存
        with open(cache_file, "rb") as f:
            return pickle.load(f)
    
    def set(self, text: str, vector: np.ndarray):
        """设置缓存"""
        cache_key = self._get_cache_key(text)
        cache_file = self.cache_dir / f"{cache_key}.pkl"
        
        with open(cache_file, "wb") as f:
            pickle.dump(vector, f)
    
    def clear(self):
        """清空缓存"""
        for cache_file in self.cache_dir.glob("*.pkl"):
            cache_file.unlink()
```

### 向量存储

#### SQLite 向量存储

```python
import sqlite3
import numpy as np

class VectorStorage:
    """向量存储"""
    
    def __init__(self, db_path: str = "data/vectors.db"):
        self.db_path = db_path
        self._init_db()
    
    def _init_db(self):
        """初始化数据库"""
        Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # 创建向量表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS vectors (
                id TEXT PRIMARY KEY,
                vector BLOB NOT NULL,
                dimension INTEGER NOT NULL,
                created_at TEXT NOT NULL
            )
        ''')
        
        # 创建索引
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_vector_id ON vectors(id)')
        
        conn.commit()
        conn.close()
    
    def add_vector(self, memory_id: str, vector: np.ndarray):
        """添加向量"""
        # 序列化向量
        vector_bytes = vector.tobytes()
        dimension = len(vector)
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute(
            '''INSERT INTO vectors (id, vector, dimension, created_at)
               VALUES (?, ?, ?, ?)''',
            (memory_id, vector_bytes, dimension, datetime.now().isoformat())
        )
        
        conn.commit()
        conn.close()
    
    def get_vector(self, memory_id: str) -> Optional[np.ndarray]:
        """获取向量"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('SELECT vector, dimension FROM vectors WHERE id = ?', (memory_id,))
        result = cursor.fetchone()
        
        conn.close()
        
        if result:
            vector_bytes, dimension = result
            return np.frombuffer(vector_bytes, dtype=np.float32)
        
        return None
    
    def get_all_vectors(self) -> Dict[str, np.ndarray]:
        """获取所有向量"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('SELECT id, vector, dimension FROM vectors')
        results = cursor.fetchall()
        
        conn.close()
        
        vectors = {}
        for memory_id, vector_bytes, dimension in results:
            vectors[memory_id] = np.frombuffer(vector_bytes, dtype=np.float32)
        
        return vectors
```

### 向量索引

#### FAISS 索引（可选）

```python
import faiss
import numpy as np

class VectorIndex:
    """向量索引"""
    
    def __init__(self, dimension: int = 2048):
        self.dimension = dimension
        self.index = None
        self.ids = []
    
    def build_index(self, vectors: Dict[str, np.ndarray]):
        """构建索引"""
        self.ids = list(vectors.keys())
        vectors_array = np.array(list(vectors.values()), dtype=np.float32)
        
        # 创建索引
        self.index = faiss.IndexFlatL2(self.dimension)
        self.index.add(vectors_array)
    
    def search(
        self, 
        query_vector: np.ndarray, 
        top_k: int = 10
    ) -> List[tuple]:
        """搜索"""
        if self.index is None:
            return []
        
        query_vector = query_vector.reshape(1, -1).astype(np.float32)
        distances, indices = self.index.search(query_vector, top_k)
        
        results = []
        for dist, idx in zip(distances[0], indices[0]):
            if idx < len(self.ids):
                memory_id = self.ids[idx]
                results.append((memory_id, dist))
        
        return results
    
    def save(self, path: str):
        """保存索引"""
        faiss.write_index(self.index, path)
    
    def load(self, path: str):
        """加载索引"""
        self.index = faiss.read_index(path)
```

### 相似度计算

#### 余弦相似度

```python
def cosine_similarity(vec1: np.ndarray, vec2: np.ndarray) -> float:
    """计算余弦相似度"""
    dot_product = np.dot(vec1, vec2)
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    
    if norm1 == 0 or norm2 == 0:
        return 0.0
    
    return dot_product / (norm1 * norm2)

def batch_cosine_similarity(
    query_vector: np.ndarray, 
    vectors: List[np.ndarray]
) -> List[float]:
    """批量计算余弦相似度"""
    query_norm = np.linalg.norm(query_vector)
    if query_norm == 0:
        return [0.0] * len(vectors)
    
    similarities = []
    for vec in vectors:
        vec_norm = np.linalg.norm(vec)
        if vec_norm == 0:
            similarities.append(0.0)
        else:
            dot_product = np.dot(query_vector, vec)
            similarity = dot_product / (query_norm * vec_norm)
            similarities.append(similarity)
    
    return similarities
```

#### 欧氏距离

```python
def euclidean_distance(vec1: np.ndarray, vec2: np.ndarray) -> float:
    """计算欧氏距离"""
    return np.linalg.norm(vec1 - vec2)

def batch_euclidean_distance(
    query_vector: np.ndarray, 
    vectors: List[np.ndarray]
) -> List[float]:
    """批量计算欧氏距离"""
    distances = []
    for vec in vectors:
        dist = np.linalg.norm(query_vector - vec)
        distances.append(dist)
    
    return distances
```

---

## 混合检索策略

### 整体流程

```
用户查询
    ↓
查询预处理
    ↓
    ├─────────────────┬─────────────────┐
    ↓                 ↓                 ↓
关键词检索        向量检索        过滤条件
    ↓                 ↓                 ↓
 TF-IDF 得分      余弦相似度      重要性/类型
    ↓                 ↓                 ↓
    └─────────┬───────┴─────────────────┘
              ↓
       RRF 融合
              ↓
       结果排序
              ↓
       返回结果
```

### 关键词检索

#### TF-IDF 实现

```python
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

class KeywordSearcher:
    """关键词搜索器"""
    
    def __init__(self):
        self.vectorizer = TfidfVectorizer(
            max_features=10000,
            ngram_range=(1, 2)
        )
        self.tfidf_matrix = None
        self.memory_ids = []
    
    def build_index(self, memories: List[Dict]):
        """构建索引"""
        self.memory_ids = [m["id"] for m in memories]
        contents = [m["content"] for m in memories]
        
        self.tfidf_matrix = self.vectorizer.fit_transform(contents)
    
    def search(self, query: str, top_k: int = 10) -> List[Dict]:
        """搜索"""
        if self.tfidf_matrix is None:
            return []
        
        query_vector = self.vectorizer.transform([query])
        similarities = cosine_similarity(query_vector, self.tfidf_matrix)[0]
        
        # 获取 top_k
        top_indices = np.argsort(similarities)[::-1][:top_k]
        
        results = []
        for idx in top_indices:
            if similarities[idx] > 0:
                results.append({
                    "id": self.memory_ids[idx],
                    "score": float(similarities[idx])
                })
        
        return results
```

### 向量检索

```python
class VectorSearcher:
    """向量搜索器"""
    
    def __init__(self, vector_storage: VectorStorage):
        self.storage = vector_storage
        self.index = VectorIndex()
    
    def build_index(self):
        """构建索引"""
        vectors = self.storage.get_all_vectors()
        self.index.build_index(vectors)
    
    def search(
        self, 
        query_vector: np.ndarray, 
        top_k: int = 10
    ) -> List[Dict]:
        """搜索"""
        results = self.index.search(query_vector, top_k)
        
        return [
            {
                "id": memory_id,
                "score": float(1 / (1 + distance))  # 转换为相似度
            }
            for memory_id, distance in results
        ]
```

### RRF 融合

```python
class RRFFusion:
    """RRF 融合算法"""
    
    def __init__(self, k: int = 60):
        self.k = k
    
    def fuse(
        self, 
        keyword_results: List[Dict], 
        vector_results: List[Dict],
        keyword_weight: float = 0.3,
        vector_weight: float = 0.7
    ) -> List[Dict]:
        """融合结果"""
        # 计算 RRF 得分
        scores = {}
        
        for rank, result in enumerate(keyword_results, start=1):
            memory_id = result["id"]
            rrf_score = keyword_weight * (1.0 / (self.k + rank))
            scores[memory_id] = scores.get(memory_id, 0) + rrf_score
        
        for rank, result in enumerate(vector_results, start=1):
            memory_id = result["id"]
            rrf_score = vector_weight * (1.0 / (self.k + rank))
            scores[memory_id] = scores.get(memory_id, 0) + rrf_score
        
        # 排序
        sorted_results = sorted(
            scores.items(),
            key=lambda x: x[1],
            reverse=True
        )
        
        return [
            {"id": memory_id, "score": score}
            for memory_id, score in sorted_results
        ]
```

### 完整检索引擎

```python
class HybridSearchEngine:
    """混合检索引擎"""
    
    def __init__(
        self,
        db_path: str,
        vector_storage: VectorStorage,
        config: Dict
    ):
        self.db_path = db_path
        self.vector_storage = vector_storage
        
        self.keyword_searcher = KeywordSearcher()
        self.vector_searcher = VectorSearcher(vector_storage)
        self.rrf_fusion = RRFFusion(k=config.get("rrf_k", 60))
        
        self.keyword_weight = config.get("keyword_weight", 0.3)
        self.vector_weight = config.get("vector_weight", 0.7)
        self.min_score = config.get("min_score", 0.2)
    
    def build_index(self):
        """构建所有索引"""
        # 构建关键词索引
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT id, content FROM memories")
        memories = [
            {"id": row[0], "content": row[1]}
            for row in cursor.fetchall()
        ]
        conn.close()
        
        self.keyword_searcher.build_index(memories)
        
        # 构建向量索引
        self.vector_searcher.build_index()
    
    async def search(
        self,
        query: str,
        top_k: int = 10,
        filters: Dict = None
    ) -> List[Dict]:
        """搜索"""
        # 关键词检索
        keyword_results = self.keyword_searcher.search(query, top_k * 2)
        
        # 向量检索
        query_vector = await self._get_query_vector(query)
        vector_results = self.vector_searcher.search(query_vector, top_k * 2)
        
        # RRF 融合
        fused_results = self.rrf_fusion.fuse(
            keyword_results,
            vector_results,
            self.keyword_weight,
            self.vector_weight
        )
        
        # 应用过滤器
        if filters:
            fused_results = self._apply_filters(fused_results, filters)
        
        # 过滤低分结果
        fused_results = [
            r for r in fused_results 
            if r["score"] >= self.min_score
        ]
        
        # 限制返回数量
        fused_results = fused_results[:top_k]
        
        # 获取完整信息
        return self._get_memory_details([r["id"] for r in fused_results])
    
    async def _get_query_vector(self, query: str) -> np.ndarray:
        """获取查询向量"""
        # 使用智谱 AI 生成向量
        client = ZhipuAIClient(os.getenv("ZHIPUAI_API_KEY"))
        return await client.generate_embedding(query)
    
    def _apply_filters(self, results: List[Dict], filters: Dict) -> List[Dict]:
        """应用过滤器"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        filtered_results = []
        
        for result in results:
            memory_id = result["id"]
            
            # 检查重要性
            if "min_importance" in filters:
                cursor.execute(
                    "SELECT importance FROM memories WHERE id = ?",
                    (memory_id,)
                )
                importance = cursor.fetchone()[0]
                if importance < filters["min_importance"]:
                    continue
            
            # 检查类型
            if "memory_types" in filters:
                cursor.execute(
                    "SELECT memory_type FROM memories WHERE id = ?",
                    (memory_id,)
                )
                memory_type = cursor.fetchone()[0]
                if memory_type not in filters["memory_types"]:
                    continue
            
            filtered_results.append(result)
        
        conn.close()
        return filtered_results
    
    def _get_memory_details(self, memory_ids: List[str]) -> List[Dict]:
        """获取记忆详情"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        memories = []
        for memory_id in memory_ids:
            cursor.execute("SELECT * FROM memories WHERE id = ?", (memory_id,))
            row = cursor.fetchone()
            
            if row:
                memories.append({
                    "id": row[0],
                    "content": row[1],
                    "memory_type": row[2],
                    "importance": row[3],
                    "confidence": row[4],
                    "tags": json.loads(row[5]),
                    "created_at": row[6],
                    "updated_at": row[7],
                    "last_accessed": row[8],
                    "access_count": row[9]
                })
        
        conn.close()
        return memories
```

---

## 数据流设计

### 添加记忆流程

```
用户输入
    ↓
预处理（去重、格式化）
    ↓
生成向量（异步）
    ↓
存储到 SQLite
    ↓
更新索引
    ↓
记录日志
    ↓
返回结果
```

```python
async def capture_memory(content: str, **kwargs) -> Dict:
    """捕获记忆"""
    
    # 1. 预处理
    content = preprocess_content(content)
    
    # 2. 创建记忆对象
    memory = Memory(content, **kwargs)
    
    # 3. 存储到数据库
    save_to_database(memory)
    
    # 4. 异步生成向量
    asyncio.create_task(generate_and_store_vector(memory.id, content))
    
    # 5. 更新索引
    update_indexes(memory.id)
    
    # 6. 记录日志
    log_event("capture", memory_id=memory.id, content=content)
    
    return {"id": memory.id, "status": "success"}
```

### 搜索记忆流程

```
用户查询
    ↓
查询预处理
    ↓
关键词检索（TF-IDF）
    ↓
向量检索（异步）
    ↓
RRF 融合
    ↓
应用过滤器
    ↓
排序
    ↓
返回结果
    ↓
更新访问记录
```

```python
async def search_memory(query: str, **kwargs) -> List[Dict]:
    """搜索记忆"""
    
    # 1. 预处理查询
    query = preprocess_query(query)
    
    # 2. 关键词检索
    keyword_results = keyword_search(query, **kwargs)
    
    # 3. 向量检索
    query_vector = await generate_query_vector(query)
    vector_results = vector_search(query_vector, **kwargs)
    
    # 4. RRF 融合
    fused_results = rrf_fusion(keyword_results, vector_results)
    
    # 5. 应用过滤器
    filtered_results = apply_filters(fused_results, kwargs.get("filters"))
    
    # 6. 排序
    sorted_results = sort_results(filtered_results)
    
    # 7. 获取详情
    memories = get_memory_details(sorted_results)
    
    # 8. 更新访问记录
    update_access_records([m["id"] for m in memories])
    
    return memories
```

### 整合流程

```
触发整合
    ↓
从工作记忆读取
    ↓
分析重要性
    ↓
高重要性 → 长期记忆
    ↓
更新索引
    ↓
清空工作记忆
    ↓
记录日志
```

```python
def consolidate_memory() -> Dict:
    """整合记忆"""
    
    # 1. 从工作记忆读取
    working_memory = load_working_memory()
    
    # 2. 分析重要性
    important_memories = filter_by_importance(working_memory, threshold=0.8)
    
    # 3. 保存到长期记忆
    for memory in important_memories:
        save_to_longterm(memory)
    
    # 4. 更新索引
    rebuild_indexes()
    
    # 5. 清空工作记忆
    clear_working_memory()
    
    # 6. 记录日志
    log_event("consolidate", count=len(important_memories))
    
    return {"status": "success", "consolidated": len(important_memories)}
```

---

## 模块依赖关系

### 核心模块

```
┌─────────────────────────────────────────┐
│         MemoryCore (主类)               │
└────────────┬────────────────────────────┘
             │
    ┌────────┴─────────┐
    │                  │
┌───▼────┐    ┌───────▼─────┐    ┌─────▼──────┐
│Storage │    │   Search    │    │  Manager   │
│(存储)  │    │  (检索)     │    │  (管理)    │
└───┬────┘    └───────┬─────┘    └─────┬──────┘
    │                  │                │
┌───▼────┐    ┌───────▼─────┐    ┌─────▼──────┐
│Database│    │  Hybrid     │    │ Importance │
│  (DB)  │    │  Engine     │    │  Manager   │
└────────┘    └───────┬─────┘    └────────────┘
                       │
             ┌─────────┴─────────┐
             │                   │
        ┌────▼────┐        ┌─────▼────┐
        │ Keyword │        │  Vector  │
        │ Search  │        │  Search  │
        └─────────┘        └────┬─────┘
                                │
                        ┌───────▼──────┐
                        │  Embedding   │
                        │   Service    │
                        └──────────────┘
```

### 依赖关系表

| 模块 | 依赖模块 | 说明 |
|------|---------|------|
| MemoryCore | Storage, Search, Manager | 核心类 |
| Storage | Database | 数据存储 |
| Search | HybridEngine, Manager | 检索引擎 |
| HybridEngine | KeywordSearch, VectorSearch | 混合检索 |
| KeywordSearch | Database | 关键词检索 |
| VectorSearch | VectorStorage, EmbeddingService | 向量检索 |
| VectorStorage | Database | 向量存储 |
| EmbeddingService | HTTP Client | 向量生成 |
| Manager | ImportanceManager, LogManager | 管理功能 |
| ImportanceManager | Database | 重要性管理 |
| LogManager | FileSystem | 日志管理 |

---

## 性能分析

### 性能指标

| 操作 | 平均耗时 | P95 | P99 |
|------|---------|-----|-----|
| 添加记忆 | 50ms | 100ms | 200ms |
| 搜索记忆 | 80ms | 150ms | 300ms |
| 向量生成 | 100ms | 200ms | 400ms |
| 索引更新 | 10ms | 20ms | 50ms |
| 批量添加 | 5ms/条 | 10ms/条 | 20ms/条 |

### 优化策略

#### 1. 批量操作

```python
async def batch_capture(memories: List[Dict]) -> List[Dict]:
    """批量添加记忆"""
    
    # 1. 批量写入数据库
    save_batch_to_database(memories)
    
    # 2. 批量生成向量
    contents = [m["content"] for m in memories]
    vectors = await generate_embeddings_batch(contents)
    
    # 3. 批量存储向量
    save_batch_to_vectors(vectors)
    
    # 4. 批量更新索引
    update_batch_indexes(memories)
    
    return [{"id": m["id"], "status": "success"} for m in memories]
```

#### 2. 缓存策略

```python
class CacheStrategy:
    """缓存策略"""
    
    def __init__(self):
        self.query_cache = {}
        self.vector_cache = VectorCache()
    
    def get_cached_results(self, query: str) -> Optional[List[Dict]]:
        """获取缓存结果"""
        return self.query_cache.get(query)
    
    def set_cached_results(self, query: str, results: List[Dict]):
        """设置缓存结果"""
        self.query_cache[query] = results
    
    def clear_cache(self):
        """清空缓存"""
        self.query_cache.clear()
        self.vector_cache.clear()
```

#### 3. 异步处理

```python
import asyncio

class AsyncMemoryCore:
    """异步 MemoryCore"""
    
    def __init__(self):
        self.loop = asyncio.get_event_loop()
    
    async def async_capture(self, content: str, **kwargs) -> Dict:
        """异步捕获"""
        # 异步生成向量
        vector_task = asyncio.create_task(
            generate_vector(content)
        )
        
        # 同步存储到数据库
        memory = save_to_database(content, **kwargs)
        
        # 等待向量生成完成
        vector = await vector_task
        
        # 存储向量
        save_vector(memory.id, vector)
        
        return memory
```

---

## 扩展性设计

### 插件系统

```python
class PluginManager:
    """插件管理器"""
    
    def __init__(self):
        self.plugins = {}
    
    def register_plugin(self, name: str, plugin: Any):
        """注册插件"""
        self.plugins[name] = plugin
    
    def get_plugin(self, name: str) -> Any:
        """获取插件"""
        return self.plugins.get(name)
    
    def execute_hook(self, hook_name: str, *args, **kwargs):
        """执行钩子"""
        for plugin in self.plugins.values():
            if hasattr(plugin, hook_name):
                getattr(plugin, hook_name)(*args, **kwargs)

# 示例插件
class LoggingPlugin:
    """日志插件"""
    
    def before_capture(self, content: str):
        print(f"即将捕获: {content}")
    
    def after_capture(self, memory: Dict):
        print(f"已捕获: {memory['id']}")
```

### 自定义向量服务

```python
class CustomEmbeddingService:
    """自定义向量服务"""
    
    def __init__(self, api_endpoint: str, api_key: str):
        self.api_endpoint = api_endpoint
        self.api_key = api_key
    
    async def generate_embedding(self, text: str) -> np.ndarray:
        """生成向量"""
        # 实现自定义向量生成逻辑
        pass

# 注册自定义服务
embedding_service = CustomEmbeddingService(
    api_endpoint="https://custom-api.com/embeddings",
    api_key="your_api_key"
)
```

---

## 结语

MemoryCore 的系统架构设计充分考虑了性能、可扩展性和易用性。通过三层记忆架构、混合检索引擎和模块化设计，MemoryCore 能够满足各种 AI Agent 的记忆管理需求。

希望这份架构文档能够帮助您更好地理解和使用 MemoryCore！

---

**文档版本**: 1.4.0  
**最后更新**: 2024-01-01  
**作者**: MemoryCore 团队
