#!/usr/bin/env python3
"""
MemoryCore - OpenClaw 记忆系统 Python 接口封装
提供简单易用的 Python API，方便任何 Agent 调用
"""

import os
import sys
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple
import subprocess
import json

# 配置常量
MEMORY_SYSTEM_DIR = Path.home() / ".openclaw" / "workspace" / "memory-system-v1.0"
MEMORY_SYSTEM_BIN = MEMORY_SYSTEM_DIR / "src" / "memory.py"

# 默认配置
DEFAULT_ZHIPUAI_API_KEY = "46c7ea42cdfe45b7b072288b6703ee8f.5XIR8I61NyJGZIjV"

class MemoryCore:
    """MemoryCore - 记忆核心系统接口"""
    
    def __init__(self, zhipuai_api_key: str = None, auto_setup: bool = True):
        """
        初始化 MemoryCore
        
        Args:
            zhipuai_api_key: 智谱AI API Key（可选，默认从环境变量获取）
            auto_setup: 是否自动初始化系统（可选，默认 True）
        """
        # 设置 API Key
        if zhipuai_api_key:
            os.environ["ZHIPUAI_API_KEY"] = zhipuai_api_key
        elif "ZHIPUAI_API_KEY" not in os.environ:
            os.environ["ZHIPUAI_API_KEY"] = DEFAULT_ZHIPUAI_API_KEY
        
        # 设置环境
        os.environ["LC_ALL"] = "C.UTF-8"
        
        # 验证系统
        self._validate_system()
        
        # 自动初始化
        if auto_setup:
            self._auto_setup()
    
    def _validate_system(self) -> bool:
        """验证系统完整性"""
        if not MEMORY_SYSTEM_DIR.exists():
            raise FileNotFoundError(f"MemoryCore 系统未找到: {MEMORY_SYSTEM_DIR}")
        
        if not MEMORY_SYSTEM_BIN.exists():
            raise FileNotFoundError(f"MemoryCore 执行文件未找到: {MEMORY_SYSTEM_BIN}")
        
        return True
    
    def _auto_setup(self) -> bool:
        """自动初始化系统（如果需要）"""
        # 检查是否需要初始化
        config_file = MEMORY_SYSTEM_DIR / "memory" / "config.json"
        if not config_file.exists():
            print("⚠️ 系统未初始化，正在初始化...")
            return self.init_system()
        return True
    
    def init_system(self) -> Dict[str, Any]:
        """
        初始化 MemoryCore 系统
        
        Returns:
            初始化结果
        """
        result = self._run_command("init")
        return {
            'success': result['success'],
            'output': result['output'],
            'error': result['error']
        }
    
    def search(self, query: str, top_k: int = 5) -> List[Dict[str, Any]]:
        """
        搜索记忆
        
        Args:
            query: 查询词
            top_k: 返回数量
            
        Returns:
            搜索结果列表
        """
        result = self._run_command("search", query)
        
        # 解析结果
        results = []
        if result['success']:
            lines = result['output'].split('\n')
            for line in lines:
                line = line.strip()
                if line and ('score=' in line or 'ID:' in line):
                    if 'ID:' in line:
                        parts = line.split(',')
                        if len(parts) >= 3:
                            content = parts[1].strip()
                            score = parts[2].split('=')[1].strip()
                            results.append({
                                'content': content,
                                'score': float(score)
                            })
        
        return results[:top_k]
    
    def capture(self, content: str, memory_type: str = "fact", 
               importance: float = 0.9) -> Dict[str, Any]:
        """
        添加记忆
        
        Args:
            content: 记忆内容
            memory_type: 记忆类型
            importance: 重要性 (0-1)
            
        Returns:
            添加结果
        """
        result = self._run_command("capture", 
                                  f"--type {memory_type} --importance {importance}",
                                  content)
        
        return {
            'success': result['success'],
            'output': result['output'],
            'error': result['error']
        }
    
    def status(self) -> Dict[str, Any]:
        """
        获取系统状态
        
        Returns:
            系统状态
        """
        result = self._run_command("status")
        
        # 解析状态
        status = {
            'success': result['success'],
            'output': result['output'],
            'error': result['error'],
            'active_count': 0,
            'vector_enabled': False
        }
        
        # 尝试提取统计信息
        lines = result['output'].split('\n')
        for line in lines:
            if '活跃池:' in line:
                parts = line.split(':')
                if len(parts) >= 2:
                    try:
                        status['active_count'] = int(parts[1].strip().split()[0])
                    except:
                        pass
            elif '向量检索已自动启用' in line:
                status['vector_enabled'] = True
        
        return status
    
    def consolidate(self) -> Dict[str, Any]:
        """
        记忆整合
        
        Returns:
            整合结果
        """
        result = self._run_command("consolidate")
        
        return {
            'success': result['success'],
            'output': result['output'],
            'error': result['error']
        }
    
    def vector_build(self, provider: str = "zhipuai") -> Dict[str, Any]:
        """
        构建向量索引
        
        Args:
            provider: 向量提供者
            
        Returns:
            构建结果
        """
        result = self._run_command("vector-build", f"--provider {provider}")
        
        return {
            'success': result['success'],
            'output': result['output'],
            'error': result['error']
        }
    
    def vector_search(self, query: str, limit: int = 5) -> List[Dict[str, Any]]:
        """
        向量搜索
        
        Args:
            query: 查询词
            limit: 返回数量
            
        Returns:
            搜索结果
        """
        result = self._run_command("vector-search", query)
        
        # 解析结果
        results = []
        if result['success']:
            lines = result['output'].split('\n')
            for line in lines:
                line = line.strip()
                if line and ('score=' in line or 'ID:' in line):
                    if 'ID:' in line:
                        parts = line.split(',')
                        if len(parts) >= 3:
                            content = parts[1].strip()
                            score = parts[2].split('=')[1].strip()
                            results.append({
                                'content': content,
                                'score': float(score)
                            })
        
        return results[:limit]
    
    def _run_command(self, command: str, args: str = "") -> Dict[str, Any]:
        """
        运行命令
        
        Args:
            command: 命令
            args: 参数
            
        Returns:
            运行结果
        """
        cmd = [sys.executable, str(MEMORY_SYSTEM_BIN), command]
        if args:
            cmd.extend(args.split())
        
        try:
            result = subprocess.run(
                cmd,
                cwd=str(MEMORY_SYSTEM_DIR),
                capture_output=True,
                text=True,
                encoding='utf-8',
                timeout=60
            )
            
            return {
                'success': result.returncode == 0,
                'output': result.stdout,
                'error': result.stderr if result.returncode != 0 else None
            }
        except subprocess.TimeoutExpired:
            return {
                'success': False,
                'output': '',
                'error': '命令超时'
            }
        except Exception as e:
            return {
                'success': False,
                'output': '',
                'error': str(e)
            }


# 便捷函数
def search(query: str, top_k: int = 5, zhipuai_api_key: str = None) -> List[Dict[str, Any]]:
    """
    便捷搜索函数
    
    Args:
        query: 查询词
        top_k: 返回数量
        zhipuai_api_key: 智谱AI API Key
        
    Returns:
        搜索结果
    """
    core = MemoryCore(zhipuai_api_key, auto_setup=False)
    return core.search(query, top_k)


def capture(content: str, memory_type: str = "fact", 
           importance: float = 0.9, zhipuai_api_key: str = None) -> Dict[str, Any]:
    """
    便捷添加记忆函数
    
    Args:
        content: 记忆内容
        memory_type: 记忆类型
        importance: 重要性
        zhipuai_api_key: 智谱AI API Key
        
    Returns:
        添加结果
    """
    core = MemoryCore(zhipuai_api_key, auto_setup=False)
    return core.capture(content, memory_type, importance)


def status(zhipuai_api_key: str = None) -> Dict[str, Any]:
    """
    便捷状态函数
    
    Args:
        zhipuai_api_key: 智谱AI API Key
        
    Returns:
        系统状态
    """
    core = MemoryCore(zhipuai_api_key, auto_setup=False)
    return core.status()


def init_system(zhipuai_api_key: str = None) -> Dict[str, Any]:
    """
    便捷初始化函数
    
    Args:
        zhipuai_api_key: 智谱AI API Key
        
    Returns:
        初始化结果
    """
    core = MemoryCore(zhipuai_api_key, auto_setup=False)
    return core.init_system()


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='MemoryCore Python 接口')
    subparsers = parser.add_subparsers(dest='command', help='可用命令')
    
    # 搜索命令
    search_parser = subparsers.add_parser('search', help='搜索记忆')
    search_parser.add_argument('query', help='查询词')
    search_parser.add_argument('--top-k', type=int, default=5, help='返回数量')
    
    # 添加命令
    capture_parser = subparsers.add_parser('capture', help='添加记忆')
    capture_parser.add_argument('content', help='记忆内容')
    capture_parser.add_argument('--type', default='fact', help='记忆类型')
    capture_parser.add_argument('--importance', type=float, default=0.9, help='重要性')
    
    # 状态命令
    subparsers.add_parser('status', help='系统状态')
    
    # 初始化命令
    subparsers.add_parser('init', help='初始化系统')
    
    args = parser.parse_args()
    
    # 执行命令
    if args.command == 'search':
        results = search(args.query, args.top_k)
        print(f"找到 {len(results)} 条结果")
        for r in results:
            print(f"  - {r['content']} (分数: {r['score']})")
    
    elif args.command == 'capture':
        result = capture(args.content, args.type, args.importance)
        if result['success']:
            print("✅ 记忆添加成功")
        else:
            print(f"❌ 记忆添加失败: {result['error']}")
    
    elif args.command == 'status':
        status_result = status()
        print(f"活跃记忆数: {status_result['active_count']}")
        print(f"向量检索: {'启用' if status_result['vector_enabled'] else '禁用'}")
    
    elif args.command == 'init':
        result = init_system()
        if result['success']:
            print("✅ 系统初始化成功")
        else:
            print(f"❌ 系统初始化失败: {result['error']}")
