/**
 * HexStrike AI Service Worker - 攻擊層
 * 主動發起模擬攻擊到 Backend 和 AI Workers
 */

import { Container, getContainer } from "@cloudflare/containers";

// 攻擊目標配置
const ATTACK_TARGETS = {
  backend: 'https://unified-backend.pcleegood.workers.dev',
  ai: 'https://unified-ai-quantum.pcleegood.workers.dev'
};

// 攻擊載荷模板
const ATTACK_PAYLOADS = {
  'sql-injection': [
    "' OR '1'='1",
    "'; DROP TABLE users--",
    "1' UNION SELECT NULL, username, password FROM users--",
    "admin'--",
    "' OR 1=1--"
  ],
  'xss': [
    "<script>alert('XSS')</script>",
    "<img src=x onerror=alert('XSS')>",
    "javascript:alert('XSS')",
    "<iframe src='javascript:alert(1)'></iframe>",
    "<svg onload=alert('XSS')>"
  ],
  'dos': [
    'A'.repeat(10000),
    'B'.repeat(50000),
    'C'.repeat(100000)
  ],
  'path-traversal': [
    '../../../etc/passwd',
    '..\\..\\..\\windows\\system32\\config\\sam',
    '../../../proc/self/environ',
    '....//....//....//etc/passwd'
  ]
};

// Durable Object class for HexStrike Container
export class HexStrikeContainer extends Container {
  defaultPort = 8888;
  sleepAfter = "10m";
  
  envVars = {
    SERVICE_NAME: "hexstrike-ai",
    ENVIRONMENT: "production",
    HEXSTRIKE_PORT: "8888",
    HEXSTRIKE_HOST: "0.0.0.0"
  };

  onStart() {
    console.log("HexStrike AI container started");
  }

  onStop() {
    console.log("HexStrike AI container stopped");
  }

  onError(error) {
    console.error("HexStrike AI container error:", error);
  }
}

// Worker fetch handler
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // Health check endpoint
    if (url.pathname === '/health') {
      return new Response(JSON.stringify({
        status: 'ok',
        service: 'hexstrike-attack',
        timestamp: new Date().toISOString(),
        attack_targets: Object.keys(ATTACK_TARGETS),
        attack_types: Object.keys(ATTACK_PAYLOADS)
      }), {
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }

    // SQL Injection 攻擊
    if (url.pathname === '/attack/sql-injection') {
      return handleSQLInjectionAttack(request, env);
    }

    // XSS 攻擊
    if (url.pathname === '/attack/xss') {
      return handleXSSAttack(request, env);
    }

    // DoS 攻擊
    if (url.pathname === '/attack/dos') {
      return handleDoSAttack(request, env);
    }

    // Path Traversal 攻擊
    if (url.pathname === '/attack/path-traversal') {
      return handlePathTraversalAttack(request, env);
    }

    // 自動化攻擊序列
    if (url.pathname === '/attack/auto') {
      return handleAutoAttack(request, env);
    }

    // 攻擊統計
    if (url.pathname === '/attack/stats') {
      return handleAttackStats(request, env);
    }

    // Dashboard
    if (url.pathname === '/dashboard' || url.pathname === '/') {
      return handleDashboard(request, env);
    }

    // Route to container (原有功能)
    try {
      const container = getContainer(env.HEXSTRIKE_CONTAINER);
      return await container.fetch(request);
    } catch (error) {
      return new Response(JSON.stringify({
        error: 'Container unavailable',
        message: error.message,
        tip: 'Try attack endpoints: /attack/sql-injection, /attack/xss, /attack/dos, /attack/auto'
      }), {
        status: 503,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }
  }
};

/**
 * SQL Injection 攻擊
 */
async function handleSQLInjectionAttack(request, env) {
  const url = new URL(request.url);
  const target = url.searchParams.get('target') || 'backend';
  const count = parseInt(url.searchParams.get('count') || '3');
  
  const results = [];
  
  for (let i = 0; i < Math.min(count, 5); i++) {
    const payload = ATTACK_PAYLOADS['sql-injection'][i % ATTACK_PAYLOADS['sql-injection'].length];
    const result = await launchAttack(target, 'sql-injection', payload);
    results.push(result);
    
    // 短暫延遲避免過快
    await sleep(100);
  }
  
  return new Response(JSON.stringify({
    attack_type: 'sql-injection',
    target: target,
    attacks_sent: results.length,
    results: results,
    timestamp: new Date().toISOString()
  }), {
    headers: { 
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

/**
 * XSS 攻擊
 */
async function handleXSSAttack(request, env) {
  const url = new URL(request.url);
  const target = url.searchParams.get('target') || 'backend';
  const count = parseInt(url.searchParams.get('count') || '3');
  
  const results = [];
  
  for (let i = 0; i < Math.min(count, 5); i++) {
    const payload = ATTACK_PAYLOADS['xss'][i % ATTACK_PAYLOADS['xss'].length];
    const result = await launchAttack(target, 'xss', payload);
    results.push(result);
    await sleep(100);
  }
  
  return new Response(JSON.stringify({
    attack_type: 'xss',
    target: target,
    attacks_sent: results.length,
    results: results,
    timestamp: new Date().toISOString()
  }), {
    headers: { 
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

/**
 * DoS 攻擊
 */
async function handleDoSAttack(request, env) {
  const url = new URL(request.url);
  const target = url.searchParams.get('target') || 'backend';
  const count = parseInt(url.searchParams.get('count') || '2');
  
  const results = [];
  
  for (let i = 0; i < Math.min(count, 3); i++) {
    const payload = ATTACK_PAYLOADS['dos'][i % ATTACK_PAYLOADS['dos'].length];
    const result = await launchAttack(target, 'dos', payload);
    results.push(result);
    await sleep(200);
  }
  
  return new Response(JSON.stringify({
    attack_type: 'dos',
    target: target,
    attacks_sent: results.length,
    results: results,
    timestamp: new Date().toISOString()
  }), {
    headers: { 
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

/**
 * Path Traversal 攻擊
 */
async function handlePathTraversalAttack(request, env) {
  const url = new URL(request.url);
  const target = url.searchParams.get('target') || 'backend';
  const count = parseInt(url.searchParams.get('count') || '3');
  
  const results = [];
  
  for (let i = 0; i < Math.min(count, 4); i++) {
    const payload = ATTACK_PAYLOADS['path-traversal'][i % ATTACK_PAYLOADS['path-traversal'].length];
    const result = await launchAttack(target, 'path-traversal', payload, 'path');
    results.push(result);
    await sleep(100);
  }
  
  return new Response(JSON.stringify({
    attack_type: 'path-traversal',
    target: target,
    attacks_sent: results.length,
    results: results,
    timestamp: new Date().toISOString()
  }), {
    headers: { 
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

/**
 * 自動化攻擊序列
 */
async function handleAutoAttack(request, env) {
  const url = new URL(request.url);
  const target = url.searchParams.get('target') || 'both';
  const intensity = url.searchParams.get('intensity') || 'medium';
  
  const attackCounts = {
    low: 1,
    medium: 2,
    high: 3
  };
  
  const count = attackCounts[intensity] || 2;
  const allResults = {
    'sql-injection': [],
    'xss': [],
    'dos': [],
    'path-traversal': []
  };
  
  const targets = target === 'both' ? ['backend', 'ai'] : [target];
  
  for (const attackType of Object.keys(ATTACK_PAYLOADS)) {
    for (const tgt of targets) {
      for (let i = 0; i < count; i++) {
        const payload = ATTACK_PAYLOADS[attackType][i % ATTACK_PAYLOADS[attackType].length];
        const payloadType = attackType === 'path-traversal' ? 'path' : 'query';
        const result = await launchAttack(tgt, attackType, payload, payloadType);
        allResults[attackType].push({...result, target: tgt});
        await sleep(150);
      }
    }
  }
  
  const totalAttacks = Object.values(allResults).reduce((sum, arr) => sum + arr.length, 0);
  
  return new Response(JSON.stringify({
    attack_mode: 'auto',
    intensity: intensity,
    targets: targets,
    total_attacks: totalAttacks,
    results: allResults,
    timestamp: new Date().toISOString()
  }), {
    headers: { 
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

/**
 * 發起單次攻擊
 */
async function launchAttack(target, attackType, payload, payloadLocation = 'query') {
  const targetUrl = ATTACK_TARGETS[target];
  if (!targetUrl) {
    return { error: 'Invalid target', target };
  }
  
  let attackUrl;
  let method = 'GET';
  let body = null;
  
  if (payloadLocation === 'path') {
    attackUrl = `${targetUrl}/file/${encodeURIComponent(payload)}`;
  } else if (payloadLocation === 'body') {
    attackUrl = `${targetUrl}/api/test`;
    method = 'POST';
    body = JSON.stringify({ data: payload, test: true });
  } else {
    attackUrl = `${targetUrl}/api/test?input=${encodeURIComponent(payload)}`;
  }
  
  const startTime = Date.now();
  
  try {
    const response = await fetch(attackUrl, {
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'HexStrike-Attack-Bot/1.0',
        'X-Attack-Type': attackType,
        'X-Attack-Simulation': 'true'
      },
      body: body
    });
    
    const responseTime = Date.now() - startTime;
    const responseText = await response.text();
    
    return {
      success: true,
      status: response.status,
      response_time_ms: responseTime,
      blocked: response.status === 403,
      payload_preview: payload.substring(0, 50),
      response_preview: responseText.substring(0, 100)
    };
  } catch (error) {
    return {
      success: false,
      error: error.message,
      response_time_ms: Date.now() - startTime
    };
  }
}

/**
 * 攻擊統計
 */
async function handleAttackStats(request, env) {
  return new Response(JSON.stringify({
    available_attacks: Object.keys(ATTACK_PAYLOADS),
    targets: Object.keys(ATTACK_TARGETS),
    payload_counts: Object.fromEntries(
      Object.entries(ATTACK_PAYLOADS).map(([k, v]) => [k, v.length])
    ),
    endpoints: {
      'sql-injection': '/attack/sql-injection?target=backend&count=3',
      'xss': '/attack/xss?target=backend&count=3',
      'dos': '/attack/dos?target=backend&count=2',
      'path-traversal': '/attack/path-traversal?target=backend&count=3',
      'auto': '/attack/auto?target=both&intensity=medium'
    },
    timestamp: new Date().toISOString()
  }), {
    headers: { 
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

/**
 * Dashboard
 */
async function handleDashboard(request, env) {
  const html = `
<!DOCTYPE html>
<html>
<head>
  <title>HexStrike Attack Dashboard</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #1a1a1a; color: #fff; }
    .container { max-width: 1200px; margin: 0 auto; }
    .card { background: #2a2a2a; padding: 20px; margin: 20px 0; border-radius: 8px; border: 1px solid #ff4444; }
    h1 { color: #ff4444; }
    .attack-btn { padding: 15px 30px; margin: 10px; background: #ff4444; color: white; border: none; border-radius: 5px; cursor: pointer; font-size: 16px; font-weight: bold; }
    .attack-btn:hover { background: #cc0000; }
    .auto-btn { background: #ff8800; }
    .auto-btn:hover { background: #cc6600; }
    .results { margin-top: 20px; padding: 15px; background: #1a1a1a; border-radius: 5px; max-height: 400px; overflow-y: auto; }
    .success { color: #44ff44; }
    .blocked { color: #ff8800; }
    .error { color: #ff4444; }
    .target-selector { margin: 15px 0; }
    select { padding: 8px; font-size: 14px; background: #1a1a1a; color: #fff; border: 1px solid #ff4444; border-radius: 4px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>⚔️ HexStrike Attack Dashboard</h1>
    
    <div class="card">
      <h2>攻擊控制台</h2>
      <div class="target-selector">
        <label>目標: </label>
        <select id="target">
          <option value="backend">Backend Worker</option>
          <option value="ai">AI Worker</option>
          <option value="both">Both</option>
        </select>
        
        <label style="margin-left: 20px;">強度: </label>
        <select id="intensity">
          <option value="low">低</option>
          <option value="medium" selected>中</option>
          <option value="high">高</option>
        </select>
      </div>
      
      <div>
        <button class="attack-btn" onclick="attack('sql-injection')">SQL Injection</button>
        <button class="attack-btn" onclick="attack('xss')">XSS Attack</button>
        <button class="attack-btn" onclick="attack('dos')">DoS Attack</button>
        <button class="attack-btn" onclick="attack('path-traversal')">Path Traversal</button>
      </div>
      <div>
        <button class="attack-btn auto-btn" onclick="attack('auto')">🚀 自動化攻擊序列</button>
      </div>
    </div>
    
    <div class="card">
      <h2>攻擊結果</h2>
      <div id="results" class="results">
        <p style="color: #888;">點擊上方按鈕發起攻擊...</p>
      </div>
    </div>
    
    <div class="card">
      <h3>目標系統</h3>
      <p>🛡️ Backend: <a href="${ATTACK_TARGETS.backend}/dashboard" target="_blank">${ATTACK_TARGETS.backend}</a></p>
      <p>🤖 AI: <a href="${ATTACK_TARGETS.ai}/dashboard" target="_blank">${ATTACK_TARGETS.ai}</a></p>
    </div>
  </div>
  
  <script>
    async function attack(type) {
      const target = document.getElementById('target').value;
      const intensity = document.getElementById('intensity').value;
      const resultsDiv = document.getElementById('results');
      
      resultsDiv.innerHTML = '<p style="color: #ff8800;">⏳ 攻擊進行中...</p>';
      
      try {
        let url = '/attack/' + type + '?target=' + target;
        if (type === 'auto') {
          url += '&intensity=' + intensity;
        }
        
        const response = await fetch(url);
        const data = await response.json();
        
        let html = '<h3 class="success">✅ 攻擊完成</h3>';
        html += '<p>攻擊類型: ' + data.attack_type + '</p>';
        html += '<p>總攻擊數: ' + (data.attacks_sent || data.total_attacks) + '</p>';
        html += '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
        
        resultsDiv.innerHTML = html;
      } catch (error) {
        resultsDiv.innerHTML = '<p class="error">❌ 攻擊失敗: ' + error.message + '</p>';
      }
    }
  </script>
</body>
</html>`;
  
  return new Response(html, {
    headers: { 
      'Content-Type': 'text/html; charset=utf-8',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

/**
 * Sleep helper
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

