#!/usr/bin/env python3
"""
Vector Embedding Engine - 支持智谱 AI (Zhipu AI)
"""

import os
import requests
from typing import Optional, List

class VectorEmbeddingEngine:
    """向量嵌入引擎"""
    
    def __init__(self, provider: str = "openai", model: str = None, base_url: str = None):
        self.provider = provider
        self.model = model
        self.base_url = base_url
        self.api_key = None
        self.dimension = None
        
        # 初始化不同提供商
        if provider == "zhipuai":
            self._init_zhipuai()
        elif provider == "openai":
            self._init_openai()
        elif provider == "local":
            self._init_local()
        else:
            print(f"❌ 不支持的 provider: {provider}")
            self.dimension = None
    
    def _init_zhipuai(self):
        """初始化智谱 AI"""
        self.api_key = os.environ.get("ZHIPUAI_API_KEY")
        if not self.api_key:
            print("⚠️ ZHIPUAI_API_KEY 环境变量未设置")
        
        # 默认端点
        if not self.base_url:
            self.base_url = "https://open.bigmodel.cn/api/paas/v4/"
        
        # 默认模型
        if not self.model:
            self.model = "embedding-3"
        
        # 智谱 embedding-3 的维度是 2048
        self.dimension = 2048
        
        print(f"✅ 智谱 AI 初始化完成 - 模型: {self.model}, 维度: {self.dimension}")
    
    def _init_openai(self):
        """初始化 OpenAI"""
        self.api_key = os.environ.get("OPENAI_API_KEY")
        if not self.api_key:
            print("⚠️ OPENAI_API_KEY 环境变量未设置")
        
        # 默认端点
        if not self.base_url:
            self.base_url = "https://api.openai.com/v1/"
        
        # 默认模型
        if not self.model:
            self.model = "text-embedding-3-small"
        
        # OpenAI text-embedding-3-small 的维度是 1536
        self.dimension = 1536
        
        print(f"✅ OpenAI 初始化完成 - 模型: {self.model}, 维度: {self.dimension}")
    
    def _init_local(self):
        """初始化本地模型（预留）"""
        # TODO: 实现 BGE-M3 本地方案
        print("⚠️ 本地 embedding 尚未实现")
        self.dimension = None
    
    def embed(self, texts: List[str]) -> Optional[List[List[float]]]:
        """
        生成向量嵌入
        
        Args:
            texts: 文本列表
            
        Returns:
            向量列表，失败返回 None
        """
        if not self.api_key:
            print("❌ API Key 未设置")
            return None
        
        if self.provider == "zhipuai":
            return self._embed_zhipuai(texts)
        elif self.provider == "openai":
            return self._embed_openai(texts)
        else:
            print(f"❌ 不支持的 provider: {self.provider}")
            return None
    
    def _embed_zhipuai(self, texts: List[str]) -> Optional[List[List[float]]]:
        """智谱 AI embedding"""
        endpoint = f"{self.base_url}embeddings"
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        # 批量处理（智谱支持）
        try:
            if len(texts) > 1:
                payload = {
                    "model": self.model,
                    "input": texts,
                    "encoding_format": "float"
                }
            else:
                payload = {
                    "model": self.model,
                    "input": texts[0],
                    "encoding_format": "float"
                }
            
            response = requests.post(endpoint, headers=headers, json=payload, timeout=30)
            
            if response.status_code != 200:
                print(f"❌ 智谱 AI 请求失败: {response.status_code}")
                print(f"错误信息: {response.text}")
                return None
            
            result = response.json()
            
            if "data" not in result:
                print(f"❌ 智谱 AI 响应格式异常: {result}")
                return None
            
            embeddings = []
            for item in result["data"]:
                embeddings.append(item["embedding"])
            
            return embeddings
            
        except Exception as e:
            print(f"❌ 智谱 AI embedding 失败: {e}")
            return None
    
    def _embed_openai(self, texts: List[str]) -> Optional[List[List[float]]]:
        """OpenAI embedding"""
        endpoint = f"{self.base_url}embeddings"
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        try:
            response = requests.post(
                endpoint,
                headers=headers,
                json={"input": texts, "model": self.model},
                timeout=30
            )
            
            if response.status_code != 200:
                print(f"❌ OpenAI 请求失败: {response.status_code}")
                return None
            
            result = response.json()
            
            embeddings = []
            for item in result.get("data", []):
                embeddings.append(item["embedding"])
            
            return embeddings
            
        except Exception as e:
            print(f"❌ OpenAI embedding 失败: {e}")
            return None


def get_embedding_engine(provider: str = "openai", model: str = None, base_url: str = None) -> Optional[VectorEmbeddingEngine]:
    """
    获取向量嵌入引擎
    
    Args:
        provider: 提供商 (openai, zhipuai, local)
        model: 模型名称
        base_url: API 基础 URL
        
    Returns:
        VectorEmbeddingEngine 实例，失败返回 None
    """
    try:
        engine = VectorEmbeddingEngine(provider=provider, model=model, base_url=base_url)
        return engine
    except Exception as e:
        print(f"❌ 初始化 embedding 引擎失败: {e}")
        return None
