/**
 * Backend Worker - 防禦層
 * 負責接收請求、檢測攻擊、記錄日誌、並呼叫 AI 進行威脅分析
 */

// 攻擊檢測規則
const ATTACK_PATTERNS = {
  'sql-injection': [
    /(\bunion\b.*\bselect\b)|(\bselect\b.*\bfrom\b)/i,
    /(\bdrop\b.*\btable\b)|(\binsert\b.*\binto\b)/i,
    /'.*or.*'.*=.*'/i,
    /--.*$/,
    /\/\*.*\*\//
  ],
  'xss': [
    /<script[^>]*>.*<\/script>/i,
    /javascript:/i,
    /on\w+\s*=\s*['"]/i,
    /<iframe/i,
    /eval\s*\(/i
  ],
  'dos': {
    maxRequestSize: 1024 * 1024, // 1MB
    suspiciousHeaders: ['x-forwarded-for', 'x-real-ip']
  },
  'path-traversal': [
    /\.\.[\/\\]/,
    /\/(etc|proc|sys)\//i,
    /\.\.%2f/i
  ]
};

// AI Worker URL（將從環境變數獲取）
const AI_WORKER_URL = 'https://unified-ai-quantum.dennisleehappy.org';

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // Health check endpoint
    if (url.pathname === '/health') {
      return new Response(JSON.stringify({
        status: 'ok',
        service: 'backend-defense',
        timestamp: new Date().toISOString(),
        db_status: env.DB ? 'connected' : 'not configured'
      }), {
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }

    // CORS preflight
    if (request.method === 'OPTIONS') {
      return handleCORS(request);
    }

    // 日誌查詢端點
    if (url.pathname === '/logs') {
      return handleGetLogs(request, env);
    }

    // 統計數據端點
    if (url.pathname === '/stats') {
      return handleGetStats(request, env);
    }

    // Dashboard 端點
    if (url.pathname === '/dashboard') {
      return handleDashboard(request, env);
    }

    // 所有其他請求都進行攻擊檢測和記錄
    return handleRequest(request, env, ctx);
  }
};

/**
 * 處理一般請求 - 攻擊檢測和記錄
 */
async function handleRequest(request, env, ctx) {
  const startTime = Date.now();
  const attackDetected = await detectAttack(request);
  
  try {
    // 記錄攻擊日誌到 D1
    const attackLogId = await logAttack(request, attackDetected, env);
    
    // 如果檢測到攻擊，呼叫 AI 進行威脅分析
    let defenseResponse = null;
    if (attackDetected.isAttack) {
      defenseResponse = await analyzeWithAI(attackDetected, attackLogId, env);
      
      // 記錄防禦響應
      await logDefenseResponse(attackLogId, defenseResponse, env);
      
      // 根據 AI 建議採取行動
      if (defenseResponse.shouldBlock) {
        return new Response(JSON.stringify({
          error: 'Request blocked',
          reason: defenseResponse.reason,
          attack_type: attackDetected.attackType,
          confidence: defenseResponse.confidence,
          timestamp: new Date().toISOString()
        }), {
          status: 403,
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        });
      }
    }
    
    // 正常處理請求
    const responseTime = Date.now() - startTime;
    
    return new Response(JSON.stringify({
      status: 'success',
      message: 'Request processed',
      attack_detected: attackDetected.isAttack,
      attack_type: attackDetected.attackType,
      defense_action: defenseResponse ? defenseResponse.action : 'allow',
      response_time_ms: responseTime,
      timestamp: new Date().toISOString()
    }), {
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });
    
    } catch (error) {
    console.error('Error handling request:', error);
      return new Response(JSON.stringify({
      error: 'Internal server error',
        message: error.message
      }), {
      status: 500,
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });
  }
}

/**
 * 攻擊檢測邏輯
 */
async function detectAttack(request) {
  const url = new URL(request.url);
  const method = request.method;
  const headers = Object.fromEntries(request.headers);
  
  let body = '';
  if (method === 'POST' || method === 'PUT') {
    try {
      body = await request.clone().text();
    } catch (e) {
      body = '';
    }
  }
  
  const attackInfo = {
    isAttack: false,
    attackType: 'none',
    confidence: 0,
    details: []
  };
  
  // 檢查 SQL Injection
  if (checkSQLInjection(url.searchParams.toString() + body)) {
    attackInfo.isAttack = true;
    attackInfo.attackType = 'sql-injection';
    attackInfo.confidence = 0.9;
    attackInfo.details.push('SQL injection pattern detected');
  }
  
  // 檢查 XSS
  if (checkXSS(url.searchParams.toString() + body)) {
    attackInfo.isAttack = true;
    attackInfo.attackType = 'xss';
    attackInfo.confidence = 0.85;
    attackInfo.details.push('XSS pattern detected');
  }
  
  // 檢查 Path Traversal
  if (checkPathTraversal(url.pathname)) {
    attackInfo.isAttack = true;
    attackInfo.attackType = 'path-traversal';
    attackInfo.confidence = 0.95;
    attackInfo.details.push('Path traversal attempt detected');
  }
  
  // 檢查 DoS（請求大小異常）
  const contentLength = parseInt(headers['content-length'] || '0');
  if (contentLength > ATTACK_PATTERNS.dos.maxRequestSize) {
    attackInfo.isAttack = true;
    attackInfo.attackType = 'dos';
    attackInfo.confidence = 0.8;
    attackInfo.details.push('Abnormally large request size');
  }
  
  return attackInfo;
}

function checkSQLInjection(input) {
  return ATTACK_PATTERNS['sql-injection'].some(pattern => pattern.test(input));
}

function checkXSS(input) {
  return ATTACK_PATTERNS['xss'].some(pattern => pattern.test(input));
}

function checkPathTraversal(path) {
  return ATTACK_PATTERNS['path-traversal'].some(pattern => pattern.test(path));
}

/**
 * 記錄攻擊日誌到 D1
 */
async function logAttack(request, attackDetected, env) {
  if (!env.DB) {
    console.warn('D1 database not configured');
    return null;
  }
  
  const url = new URL(request.url);
  const headers = Object.fromEntries(request.headers);
  
  let body = '';
  if (request.method === 'POST' || request.method === 'PUT') {
    try {
      body = await request.clone().text();
    } catch (e) {
      body = '';
    }
  }
  
  try {
    const result = await env.DB.prepare(`
      INSERT INTO attack_logs (
        source, target, attack_type, method, path, 
        payload, headers, user_agent, ip_address
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      headers['x-forwarded-for'] || headers['cf-connecting-ip'] || 'unknown',
      'backend-worker',
      attackDetected.isAttack ? attackDetected.attackType : 'normal',
      request.method,
      url.pathname,
      body.substring(0, 1000), // 限制大小
      JSON.stringify(headers).substring(0, 2000),
      headers['user-agent'] || 'unknown',
      headers['cf-connecting-ip'] || 'unknown'
    ).run();
    
    return result.meta.last_row_id;
  } catch (error) {
    console.error('Error logging attack:', error);
    return null;
  }
}

/**
 * 呼叫 AI Worker 進行威脅分析
 */
async function analyzeWithAI(attackDetected, attackLogId, env) {
  try {
    const response = await fetch(`${AI_WORKER_URL}/analyze-threat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        attack_log_id: attackLogId,
        attack_type: attackDetected.attackType,
        confidence: attackDetected.confidence,
        details: attackDetected.details
      })
    });
    
    if (!response.ok) {
      throw new Error(`AI analysis failed: ${response.statusText}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error('Error analyzing with AI:', error);
    // 降級策略：基於規則的簡單判斷
    return {
      shouldBlock: attackDetected.confidence > 0.8,
      action: attackDetected.confidence > 0.8 ? 'block' : 'allow',
      reason: 'AI unavailable, using rule-based decision',
      confidence: attackDetected.confidence
    };
  }
}

/**
 * 記錄防禦響應到 D1
 */
async function logDefenseResponse(attackLogId, defenseResponse, env) {
  if (!env.DB || !attackLogId) return;
  
  try {
    await env.DB.prepare(`
      INSERT INTO defense_responses (
        attack_id, response_type, blocked, reason, confidence, ml_model_version
      ) VALUES (?, ?, ?, ?, ?, ?)
    `).bind(
      attackLogId,
      defenseResponse.action,
      defenseResponse.shouldBlock ? 1 : 0,
      defenseResponse.reason,
      defenseResponse.confidence,
      defenseResponse.modelVersion || 'v1.0.0-baseline'
    ).run();
  } catch (error) {
    console.error('Error logging defense response:', error);
  }
}

/**
 * 查詢攻擊日誌
 */
async function handleGetLogs(request, env) {
  if (!env.DB) {
    return new Response(JSON.stringify({ error: 'Database not configured' }), {
      status: 503,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    });
  }
  
  const url = new URL(request.url);
  const limit = parseInt(url.searchParams.get('limit') || '50');
  const offset = parseInt(url.searchParams.get('offset') || '0');
  
  try {
    const { results } = await env.DB.prepare(`
      SELECT * FROM attack_logs 
      ORDER BY timestamp DESC 
      LIMIT ? OFFSET ?
    `).bind(limit, offset).all();
    
    return new Response(JSON.stringify({
      logs: results,
      count: results.length,
      limit,
      offset
    }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    });
  }
}

/**
 * 獲取統計數據
 */
async function handleGetStats(request, env) {
  if (!env.DB) {
    return new Response(JSON.stringify({ error: 'Database not configured' }), {
      status: 503,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    });
  }
  
  try {
    // 總攻擊次數
    const totalAttacks = await env.DB.prepare(`
      SELECT COUNT(*) as count FROM attack_logs WHERE attack_type != 'normal'
    `).first();
    
    // 按類型統計
    const { results: attacksByType } = await env.DB.prepare(`
      SELECT attack_type, COUNT(*) as count 
      FROM attack_logs 
      WHERE attack_type != 'normal'
      GROUP BY attack_type
    `).all();
    
    // 防禦成功率
    const defenseStats = await env.DB.prepare(`
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN blocked = 1 THEN 1 ELSE 0 END) as blocked
      FROM defense_responses
    `).first();
    
    const blockRate = defenseStats.total > 0 
      ? (defenseStats.blocked / defenseStats.total * 100).toFixed(2)
      : 0;
    
    return new Response(JSON.stringify({
      total_attacks: totalAttacks.count,
      attacks_by_type: attacksByType,
      defense_stats: {
        total_responses: defenseStats.total,
        blocked: defenseStats.blocked,
        block_rate_percent: blockRate
      },
      timestamp: new Date().toISOString()
    }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    });
  }
}

/**
 * Dashboard HTML
 */
async function handleDashboard(request, env) {
  if (!env.DB) {
    return new Response('Database not configured', { status: 503 });
  }
  
  try {
    // 獲取統計數據
    const stats = await handleGetStats(request, env);
    const statsData = await stats.json();
    
    // 獲取最近的攻擊日誌
    const { results: recentLogs } = await env.DB.prepare(`
      SELECT * FROM attack_logs 
      WHERE attack_type != 'normal'
      ORDER BY timestamp DESC 
      LIMIT 10
    `).all();
    
    const html = `
<!DOCTYPE html>
<html>
<head>
  <title>Backend Defense Dashboard</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1200px; margin: 0 auto; }
    .card { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    h1 { color: #333; }
    .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; }
    .stat-box { background: #f8f9fa; padding: 15px; border-radius: 5px; text-align: center; }
    .stat-value { font-size: 32px; font-weight: bold; color: #007bff; }
    .stat-label { font-size: 14px; color: #666; margin-top: 5px; }
    table { width: 100%; border-collapse: collapse; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #007bff; color: white; }
    .attack-type { display: inline-block; padding: 4px 8px; border-radius: 4px; font-size: 12px; }
    .sql-injection { background: #ffebee; color: #c62828; }
    .xss { background: #fff3e0; color: #e65100; }
    .dos { background: #f3e5f5; color: #6a1b9a; }
    .path-traversal { background: #e0f7fa; color: #00695c; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🛡️ Backend Defense Dashboard</h1>
    
    <div class="card">
      <h2>統計概覽</h2>
      <div class="stats">
        <div class="stat-box">
          <div class="stat-value">${statsData.total_attacks}</div>
          <div class="stat-label">總攻擊次數</div>
        </div>
        <div class="stat-box">
          <div class="stat-value">${statsData.defense_stats.blocked}</div>
          <div class="stat-label">已阻擋攻擊</div>
        </div>
        <div class="stat-box">
          <div class="stat-value">${statsData.defense_stats.block_rate_percent}%</div>
          <div class="stat-label">阻擋成功率</div>
        </div>
      </div>
    </div>
    
    <div class="card">
      <h2>攻擊類型分佈</h2>
      <table>
        <tr><th>攻擊類型</th><th>次數</th></tr>
        ${statsData.attacks_by_type.map(item => `
          <tr>
            <td><span class="attack-type ${item.attack_type}">${item.attack_type}</span></td>
            <td>${item.count}</td>
          </tr>
        `).join('')}
      </table>
    </div>
    
    <div class="card">
      <h2>最近攻擊日誌</h2>
      <table>
        <tr>
          <th>時間</th>
          <th>來源</th>
          <th>類型</th>
          <th>路徑</th>
        </tr>
        ${recentLogs.map(log => `
          <tr>
            <td>${new Date(log.timestamp).toLocaleString()}</td>
            <td>${log.source}</td>
            <td><span class="attack-type ${log.attack_type}">${log.attack_type}</span></td>
            <td>${log.path}</td>
          </tr>
        `).join('')}
      </table>
    </div>
    
    <div class="card">
      <p style="color: #666; text-align: center;">
        最後更新: ${new Date().toLocaleString()} | 
        <a href="/logs">查看完整日誌</a> | 
        <a href="/stats">API統計</a>
      </p>
    </div>
  </div>
</body>
</html>`;
    
    return new Response(html, {
      headers: { 
        'Content-Type': 'text/html; charset=utf-8',
        'Access-Control-Allow-Origin': '*'
      }
    });
  } catch (error) {
    return new Response(`Dashboard Error: ${error.message}`, {
      status: 500,
      headers: { 'Content-Type': 'text/plain' }
    });
  }
}

/**
 * CORS 處理
 */
function handleCORS(request) {
  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Max-Age': '86400'
    }
  });
}
