#!/usr/bin/env python3
"""
Hybrid Search Engine - 混合检索引擎
结合关键词、向量等多种检索方式
"""

from pathlib import Path
from typing import List, Dict, Any, Optional
from vector_index import VectorIndexManager


class SearchResult:
    """搜索结果"""
    
    def __init__(self, id: str, content: str, score: float, 
                 vector_score: float = 0.0, keyword_score: float = 0.0,
                 metadata: Dict = None):
        self.id = id
        self.content = content
        self.score = score
        self.vector_score = vector_score
        self.keyword_score = keyword_score
        self.metadata = metadata or {}


class HybridSearchEngine:
    """混合检索引擎"""
    
    def __init__(self, memory_dir: Path, embedding_engine, 
                 backend: str = "sqlite", keyword_weight: float = 0.3,
                 vector_weight: float = 0.7, min_score: float = 0.2):
        self.memory_dir = Path(memory_dir)
        self.embedding_engine = embedding_engine
        self.backend = backend
        self.keyword_weight = keyword_weight
        self.vector_weight = vector_weight
        self.min_score = min_score
        
        # 初始化向量索引
        self.vector_index = VectorIndexManager(memory_dir)
    
    def search(self, query: str, top_k: int = 20,
              use_keyword: bool = True, use_vector: bool = True) -> List[SearchResult]:
        """
        执行混合检索
        
        Args:
            query: 查询词
            top_k: 返回数量
            use_keyword: 是否使用关键词检索
            use_vector: 是否使用向量检索
            
        Returns:
            搜索结果列表
        """
        all_results = {}  # {memory_id: SearchResult}
        
        # 关键词检索
        if use_keyword:
            keyword_results = self._keyword_search(query)
            for memory_id, score in keyword_results:
                if memory_id not in all_results:
                    all_results[memory_id] = SearchResult(
                        id=memory_id,
                        content=self._get_content(memory_id),
                        score=score,
                        keyword_score=score
                    )
                else:
                    # 合并分数
                    existing = all_results[memory_id]
                    existing.keyword_score = max(existing.keyword_score, score)
                    existing.score = max(existing.score, score * self.keyword_weight)
        
        # 向量检索
        if use_vector and self.embedding_engine:
            query_vector = self._get_query_vector(query)
            if query_vector:
                vector_results = self.vector_index.search(query_vector, limit=top_k)
                for memory_id, score in vector_results:
                    if memory_id not in all_results:
                        all_results[memory_id] = SearchResult(
                            id=memory_id,
                            content=self._get_content(memory_id),
                            score=score,
                            vector_score=score
                        )
                    else:
                        # 合并分数
                        existing = all_results[memory_id]
                        existing.vector_score = max(existing.vector_score, score)
                        # 混合分数
                        existing.score = (
                            existing.keyword_score * self.keyword_weight +
                            existing.vector_score * self.vector_weight
                        )
        
        # 过滤低分结果
        filtered_results = [
            r for r in all_results.values()
            if r.score >= self.min_score
        ]
        
        # 排序并返回
        filtered_results.sort(key=lambda x: x.score, reverse=True)
        return filtered_results[:top_k]
    
    def _keyword_search(self, query: str) -> List[tuple]:
        """
        关键词检索（简化版，基于内容匹配）
        
        Args:
            query: 查询词
            
        Returns:
            [(memory_id, score), ...]
        """
        query_lower = query.lower()
        results = []
        
        # 搜索所有类型
        for mem_type in ["facts", "beliefs", "summaries"]:
            path = self.memory_dir / f"layer2/active/{mem_type}.jsonl"
            if not path.exists():
                continue
            
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    for line in f:
                        line = line.strip()
                        if not line:
                            continue
                        record = json.loads(line)
                        content = record.get('content', '')
                        
                        # 简单的包含匹配
                        if query_lower in content.lower():
                            score = 0.8  # 基础分数
                            
                            # 精确匹配加分
                            if content.lower() == query_lower:
                                score = 1.0
                            
                            # 首词匹配加分
                            elif content.lower().startswith(query_lower):
                                score = 0.9
                            
                            results.append((record['id'], score))
                            
            except Exception as e:
                continue
        
        return results
    
    def _get_query_vector(self, query: str) -> Optional[List[float]]:
        """获取查询向量"""
        if not self.embedding_engine:
            return None
        
        try:
            embeddings = self.embedding_engine.embed([query])
            if embeddings and len(embeddings) > 0:
                return embeddings[0]
            return None
        except Exception as e:
            print(f"❌ 生成查询向量失败: {e}")
            return None
    
    def _get_content(self, memory_id: str) -> str:
        """获取记忆内容"""
        # 搜索所有类型
        for mem_type in ["facts", "beliefs", "summaries"]:
            path = self.memory_dir / f"layer2/active/{mem_type}.jsonl"
            if not path.exists():
                continue
            
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    for line in f:
                        line = line.strip()
                        if not line:
                            continue
                        record = json.loads(line)
                        if record.get('id') == memory_id:
                            return record.get('content', '')
            except Exception:
                continue
        
        return ""


def create_hybrid_search_engine(memory_dir: Path, embedding_engine,
                              backend: str = "sqlite", keyword_weight: float = 0.3,
                              vector_weight: float = 0.7, min_score: float = 0.2) -> Optional[HybridSearchEngine]:
    """
    创建混合检索引擎
    
    Args:
        memory_dir: 记忆目录
        embedding_engine: 嵌入引擎
        backend: 后端类型
        keyword_weight: 关键词权重
        vector_weight: 向量权重
        min_score: 最小分数
        
    Returns:
        HybridSearchEngine 实例，失败返回 None
    """
    try:
        return HybridSearchEngine(
            memory_dir=memory_dir,
            embedding_engine=embedding_engine,
            backend=backend,
            keyword_weight=keyword_weight,
            vector_weight=vector_weight,
            min_score=min_score
        )
    except Exception as e:
        print(f"❌ 创建混合检索引擎失败: {e}")
        return None
