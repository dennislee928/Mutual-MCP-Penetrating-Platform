/**
 * Cloudflare Worker - 統一安全平台路由器
 * 
 * 此 Worker 負責：
 * 1. 接收所有請求
 * 2. 路由到適當的容器服務
 * 3. 管理容器實例生命週期
 * 
 * 文檔：https://developers.cloudflare.com/containers/
 */

import { Container, getContainer } from "@cloudflare/containers";

// ============================================
// Container 類定義
// ============================================

/**
 * Go 後端容器（防禦面 API）
 */
export class GoBackend extends Container {
  defaultPort = 3001;
  sleepAfter = "15m";  // 15 分鐘無請求後休眠
  
  // 健康檢查
  async healthCheck() {
    try {
      const response = await fetch(`http://localhost:${this.defaultPort}/health`);
      return response.ok;
    } catch {
      return false;
    }
  }
}

/**
 * AI/量子容器
 */
export class AIQuantum extends Container {
  defaultPort = 8000;
  sleepAfter = "20m";  // 20 分鐘無請求後休眠
  
  async healthCheck() {
    try {
      const response = await fetch(`http://localhost:${this.defaultPort}/health`);
      return response.ok;
    } catch {
      return false;
    }
  }
}

/**
 * HexStrike AI 容器（攻擊面）
 */
export class HexStrikeAI extends Container {
  defaultPort = 8888;
  sleepAfter = "30m";  // 30 分鐘無請求後休眠（掃描可能較久）
  
  async healthCheck() {
    try {
      const response = await fetch(`http://localhost:${this.defaultPort}/health`);
      return response.ok;
    } catch {
      return false;
    }
  }
}

// ============================================
// 路由邏輯
// ============================================

/**
 * 路由請求到適當的容器
 */
function routeToContainer(url, env) {
  const pathname = url.pathname;
  
  // Go 後端路由（防禦面 API）
  if (pathname.startsWith('/api/v1/')) {
    // 使用固定實例（或基於 session）
    const instanceId = 'backend-main';
    return getContainer(env.GO_BACKEND, instanceId);
  }
  
  // AI/量子服務路由
  if (pathname.startsWith('/api/ai/') || pathname.startsWith('/api/quantum/')) {
    const instanceId = 'ai-quantum-main';
    return getContainer(env.AI_QUANTUM, instanceId);
  }
  
  // HexStrike AI 路由
  if (pathname.startsWith('/api/tools/') || 
      pathname.startsWith('/api/intelligence/') ||
      pathname.startsWith('/api/agents/')) {
    // HexStrike 可能需要多個實例（基於 session 或 user）
    const sessionId = getSessionId(url);
    return getContainer(env.HEXSTRIKE_AI, sessionId);
  }
  
  // 健康檢查
  if (pathname === '/health' || pathname === '/') {
    return null; // 由 Worker 直接處理
  }
  
  return null;
}

/**
 * 從 URL 或 Cookie 取得 session ID
 */
function getSessionId(url) {
  // 優先使用 query parameter
  const sessionId = url.searchParams.get('session');
  if (sessionId) return sessionId;
  
  // 或使用固定實例
  return 'hexstrike-default';
}

// ============================================
// Worker Fetch Handler
// ============================================

export default {
  /**
   * 主要請求處理器
   */
  async fetch(request, env, ctx) {
    try {
      const url = new URL(request.url);
      
      // 處理 CORS
      if (request.method === 'OPTIONS') {
        return handleCORS();
      }
      
      // 健康檢查（Worker 層級）
      if (url.pathname === '/health') {
        return new Response(JSON.stringify({
          status: 'ok',
          service: 'unified-security-platform',
          platform: 'cloudflare-containers',
          timestamp: new Date().toISOString()
        }), {
          headers: {
            'Content-Type': 'application/json',
            ...getCORSHeaders()
          }
        });
      }
      
      // 路由到容器
      const container = routeToContainer(url, env);
      
      if (!container) {
        return new Response(JSON.stringify({
          error: 'Not Found',
          message: `No service available for path: ${url.pathname}`,
          available_paths: [
            '/api/v1/* (Go Backend)',
            '/api/ai/* (AI/Quantum)',
            '/api/quantum/* (AI/Quantum)',
            '/api/tools/* (HexStrike AI)',
            '/api/intelligence/* (HexStrike AI)',
            '/health'
          ]
        }), {
          status: 404,
          headers: {
            'Content-Type': 'application/json',
            ...getCORSHeaders()
          }
        });
      }
      
      // 轉發請求到容器
      const response = await container.fetch(request);
      
      // 添加 CORS headers
      const headers = new Headers(response.headers);
      Object.entries(getCORSHeaders()).forEach(([key, value]) => {
        headers.set(key, value);
      });
      
      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers
      });
      
    } catch (error) {
      console.error('Worker error:', error);
      
      return new Response(JSON.stringify({
        error: 'Internal Server Error',
        message: error.message,
        timestamp: new Date().toISOString()
      }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          ...getCORSHeaders()
        }
      });
    }
  }
};

// ============================================
// Helper Functions
// ============================================

/**
 * CORS Headers
 */
function getCORSHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-API-Key',
    'Access-Control-Max-Age': '86400'
  };
}

/**
 * 處理 CORS 預檢請求
 */
function handleCORS() {
  return new Response(null, {
    status: 204,
    headers: getCORSHeaders()
  });
}




