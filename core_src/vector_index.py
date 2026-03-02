#!/usr/bin/env python3
"""
Vector Index Manager - 向量索引管理
支持 SQLite 向量存储和检索
"""

import sqlite3
import json
import os
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime


class VectorIndexManager:
    """向量索引管理器"""
    
    def __init__(self, memory_dir: Path):
        self.memory_dir = Path(memory_dir)
        self.db_path = self.memory_dir / "vectors.db"
        self.conn = None
        self._init_db()
    
    def _init_db(self):
        """初始化数据库"""
        self.conn = sqlite3.connect(self.db_path)
        self.conn.row_factory = sqlite3.Row
        
        cursor = self.conn.cursor()
        
        # 向量表
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS vectors (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                memory_id TEXT NOT NULL,
                vector BLOB NOT NULL,
                dimension INTEGER NOT NULL,
                created_at TEXT NOT NULL,
                UNIQUE(memory_id)
            )
        """)
        
        self.conn.commit()
    
    def add_vector(self, memory_id: str, vector: List[float]) -> bool:
        """添加向量"""
        dimension = len(vector)
        vector_blob = json.dumps(vector).encode('utf-8')
        created_at = datetime.utcnow().isoformat()
        
        try:
            cursor = self.conn.cursor()
            cursor.execute(
                "INSERT OR REPLACE INTO vectors (memory_id, vector, dimension, created_at) VALUES (?, ?, ?, ?)",
                (memory_id, vector_blob, dimension, created_at)
            )
            self.conn.commit()
            return True
        except Exception as e:
            print(f"❌ 添加向量失败: {e}")
            return False
    
    def get_vector(self, memory_id: str) -> Optional[List[float]]:
        """获取向量"""
        try:
            cursor = self.conn.cursor()
            cursor.execute("SELECT vector FROM vectors WHERE memory_id = ?", (memory_id,))
            row = cursor.fetchone()
            if row:
                return json.loads(row[0].decode('utf-8'))
            return None
        except Exception as e:
            print(f"❌ 获取向量失败: {e}")
            return None
    
    def search(self, query_vector: List[float], limit: int = 20) -> List[Tuple[str, float]]:
        """
        向量相似度搜索（余弦相似度）
        
        Args:
            query_vector: 查询向量
            limit: 返回数量
            
        Returns:
            [(memory_id, score), ...]
        """
        try:
            cursor = self.conn.cursor()
            cursor.execute("SELECT memory_id, vector FROM vectors LIMIT 1000")
            rows = cursor.fetchall()
            
            results = []
            for row in rows:
                memory_id = row[0]
                stored_vector_blob = row[1]
                stored_vector = json.loads(stored_vector_blob.decode('utf-8'))
                
                # 计算余弦相似度
                score = self._cosine_similarity(query_vector, stored_vector)
                results.append((memory_id, score))
            
            # 按相似度排序
            results.sort(key=lambda x: x[1], reverse=True)
            
            return results[:limit]
            
        except Exception as e:
            print(f"❌ 向量搜索失败: {e}")
            return []
    
    def _cosine_similarity(self, vec1: List[float], vec2: List[float]) -> float:
        """计算余弦相似度"""
        import math
        
        dot_product = sum(a * b for a, b in zip(vec1, vec2))
        magnitude1 = math.sqrt(sum(a * a for a in vec1))
        magnitude2 = math.sqrt(sum(b * b for b in vec2))
        
        if magnitude1 * magnitude2 == 0:
            return 0.0
        
        return dot_product / (magnitude1 * magnitude2)
    
    def close(self):
        """关闭连接"""
        if self.conn:
            self.conn.close()


def build_vector_index(memory_dir: Path, embedding_engine, backend: str = "sqlite", force: bool = False, batch_size: int = 10) -> bool:
    """
    构建向量索引
    
    Args:
        memory_dir: 记忆目录
        embedding_engine: 嵌入引擎
        force: 强制重建
        
    Returns:
        是否成功
    """
    index_manager = VectorIndexManager(memory_dir)
    
    try:
        # 加载所有活跃记忆
        all_memories = {}
        for mem_type in ["facts", "beliefs", "summaries"]:
            path = memory_dir / f"layer2/active/{mem_type}.jsonl"
            if not path.exists():
                continue
            
            with open(path, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    record = json.loads(line)
                    all_memories[record['id']] = record
        
        print(f"📊 加载了 {len(all_memories)} 条记忆")
        
        # 为每条记录生成向量
        count = 0
        for memory_id, record in all_memories.items():
            content = record.get('content', '')
            if not content:
                continue
            
            # 生成向量
            embeddings = embedding_engine.embed([content])
            if embeddings is None or len(embeddings) == 0:
                continue
            
            vector = embeddings[0]
            
            # 添加到索引
            if index_manager.add_vector(memory_id, vector):
                count += 1
        
        index_manager.close()
        print(f"✅ 成功构建 {count} 个向量索引")
        
        # 返回统计信息
        return {
            "total": len(all_memories),
            "indexed": count,
            "skipped": len(all_memories) - count,
            "failed": len(all_memories) - count - count
        }
        
    except Exception as e:
        print(f"❌ 构建向量索引失败: {e}")
        return {
            "total": 0,
            "indexed": 0,
            "skipped": 0,
            "failed": 0
        }
