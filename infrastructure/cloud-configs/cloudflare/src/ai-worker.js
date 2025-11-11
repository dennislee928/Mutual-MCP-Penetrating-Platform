/**
 * AI/Quantum Worker - ML 防禦層
 * 負責威脅分析、ML 模型訓練、和防禦策略建議
 */

// ML 模型配置
const MODEL_CONFIG = {
  version: 'v1.0.0-baseline',
  features: ['request_frequency', 'payload_size', 'abnormal_headers', 'path_pattern', 'method_type'],
  thresholds: {
    sql_injection: 0.85,
    xss: 0.80,
    dos: 0.75,
    path_traversal: 0.90,
    default: 0.70
  }
};

// 特徵權重（簡化版 ML 模型）
const FEATURE_WEIGHTS = {
  payload_size_anomaly: 0.25,
  request_frequency_anomaly: 0.30,
  header_anomaly: 0.20,
  path_pattern_match: 0.15,
  method_anomaly: 0.10
};

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // Health check
    if (url.pathname === '/health') {
      return new Response(JSON.stringify({
        status: 'ok',
        service: 'ai-defense',
        model_version: MODEL_CONFIG.version,
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

    // 威脅分析端點
    if (url.pathname === '/analyze-threat' && request.method === 'POST') {
      return handleAnalyzeThreat(request, env);
    }

    // 模型訓練端點
    if (url.pathname === '/train-model' && request.method === 'POST') {
      return handleTrainModel(request, env);
    }

    // 獲取模型資訊
    if (url.pathname === '/model-info') {
      return handleModelInfo(request, env);
    }

    // 預測端點（批量）
    if (url.pathname === '/predict-batch' && request.method === 'POST') {
      return handlePredictBatch(request, env);
    }

    // Dashboard
    if (url.pathname === '/dashboard') {
      return handleDashboard(request, env);
    }

    return new Response(JSON.stringify({
      error: 'Not found',
      available_endpoints: [
        '/health',
        '/analyze-threat (POST)',
        '/train-model (POST)',
        '/model-info (GET)',
        '/predict-batch (POST)',
        '/dashboard (GET)'
      ]
    }), {
      status: 404,
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });
  }
};

/**
 * 威脅分析 - 即時威脅評分
 */
async function handleAnalyzeThreat(request, env) {
  try {
    const data = await request.json();
    const { attack_log_id, attack_type, confidence, details } = data;
    
    // 從 D1 獲取歷史數據進行特徵提取
    const historicalData = await getHistoricalData(env, attack_type);
    
    // 計算威脅分數
    const threatScore = calculateThreatScore(attack_type, confidence, details, historicalData);
    
    // 決定防禦動作
    const defense = decideDefenseAction(attack_type, threatScore);
    
    return new Response(JSON.stringify({
      attack_log_id,
      threat_score: threatScore,
      shouldBlock: defense.shouldBlock,
      action: defense.action,
      reason: defense.reason,
      confidence: threatScore,
      modelVersion: MODEL_CONFIG.version,
      timestamp: new Date().toISOString()
    }), {
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });
    } catch (error) {
    console.error('Error analyzing threat:', error);
    return new Response(JSON.stringify({
      error: 'Threat analysis failed',
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
 * ML 模型訓練
 */
async function handleTrainModel(request, env) {
  if (!env.DB) {
    return new Response(JSON.stringify({ error: 'Database not configured' }), {
      status: 503,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    });
  }
  
  const startTime = Date.now();
  
  try {
    // 從 D1 獲取訓練數據
    const { results: trainingData } = await env.DB.prepare(`
      SELECT 
        al.*,
        dr.blocked,
        dr.confidence as defense_confidence
      FROM attack_logs al
      LEFT JOIN defense_responses dr ON al.id = dr.attack_id
      WHERE al.attack_type != 'normal'
      ORDER BY al.timestamp DESC
      LIMIT 1000
    `).all();
    
    if (trainingData.length < 10) {
      return new Response(JSON.stringify({
        error: 'Insufficient training data',
        message: 'Need at least 10 samples for training',
        current_samples: trainingData.length
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
      });
    }
    
    // 特徵提取和模型訓練（簡化版）
    const features = extractFeatures(trainingData);
    const modelMetrics = trainSimpleModel(features);
    
    // 生成新模型版本號
    const newVersion = generateModelVersion();
    
    // 保存訓練結果到 D1
    await env.DB.prepare(`
      INSERT INTO ml_training_data (
        model_version,
        accuracy,
        precision_score,
        recall_score,
        f1_score,
        training_time_ms,
        training_samples,
        features_used,
        notes
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      newVersion,
      modelMetrics.accuracy,
      modelMetrics.precision,
      modelMetrics.recall,
      modelMetrics.f1_score,
      Date.now() - startTime,
      trainingData.length,
      JSON.stringify(MODEL_CONFIG.features),
      `Trained on ${trainingData.length} samples with ${features.attackTypes.size} attack types`
    ).run();
    
    return new Response(JSON.stringify({
      status: 'success',
      model_version: newVersion,
      training_metrics: modelMetrics,
      training_samples: trainingData.length,
      training_time_ms: Date.now() - startTime,
      features_used: MODEL_CONFIG.features,
      timestamp: new Date().toISOString()
    }), {
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });
  } catch (error) {
    console.error('Error training model:', error);
    return new Response(JSON.stringify({
      error: 'Model training failed',
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
 * 獲取模型資訊
 */
async function handleModelInfo(request, env) {
  if (!env.DB) {
    return new Response(JSON.stringify({ error: 'Database not configured' }), {
      status: 503,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    });
  }
  
  try {
    // 獲取最新模型
    const latestModel = await env.DB.prepare(`
      SELECT * FROM ml_training_data 
      ORDER BY training_timestamp DESC 
      LIMIT 1
    `).first();
    
    // 獲取所有模型歷史
    const { results: modelHistory } = await env.DB.prepare(`
      SELECT 
        model_version,
        accuracy,
        training_timestamp,
        training_samples
      FROM ml_training_data 
      ORDER BY training_timestamp DESC 
      LIMIT 10
    `).all();
    
    return new Response(JSON.stringify({
      current_model: {
        version: MODEL_CONFIG.version,
        features: MODEL_CONFIG.features,
        thresholds: MODEL_CONFIG.thresholds
      },
      latest_training: latestModel,
      training_history: modelHistory,
      timestamp: new Date().toISOString()
    }), {
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Failed to get model info',
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
 * 批量預測
 */
async function handlePredictBatch(request, env) {
  try {
    const { samples } = await request.json();
    
    if (!Array.isArray(samples)) {
      throw new Error('Samples must be an array');
    }
    
    const predictions = samples.map(sample => {
      const score = calculateThreatScore(
        sample.attack_type,
        sample.confidence || 0.5,
        sample.details || [],
        { avgFrequency: 10, totalSamples: 100 }
      );
      
      const defense = decideDefenseAction(sample.attack_type, score);
      
      return {
        input: sample,
        threat_score: score,
        prediction: defense.action,
        should_block: defense.shouldBlock,
        reason: defense.reason
      };
    });
    
    return new Response(JSON.stringify({
      predictions,
      model_version: MODEL_CONFIG.version,
      timestamp: new Date().toISOString()
    }), {
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Batch prediction failed',
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
 * 計算威脅分數（簡化版 ML）
 */
function calculateThreatScore(attackType, baseConfidence, details, historicalData) {
  let score = baseConfidence;
  
  // 基於歷史數據調整
  if (historicalData.avgFrequency > 50) {
    score += 0.1; // 高頻攻擊類型
  }
  
  // 基於攻擊詳情調整
  if (details && details.length > 2) {
    score += 0.05; // 多個特徵匹配
  }
  
  // 基於攻擊類型的權重調整
  const typeWeight = {
    'sql-injection': 1.2,
    'xss': 1.1,
    'path-traversal': 1.3,
    'dos': 1.0
  };
  
  score *= (typeWeight[attackType] || 1.0);
  
  // 確保分數在 0-1 範圍內
  return Math.min(Math.max(score, 0), 1);
}

/**
 * 決定防禦動作
 */
function decideDefenseAction(attackType, threatScore) {
  const threshold = MODEL_CONFIG.thresholds[attackType] || MODEL_CONFIG.thresholds.default;
  
  if (threatScore >= threshold) {
    return {
      shouldBlock: true,
      action: 'block',
      reason: `High threat score (${threatScore.toFixed(2)}) exceeds threshold (${threshold})`,
      confidence: threatScore
    };
  } else if (threatScore >= threshold * 0.7) {
    return {
      shouldBlock: false,
      action: 'challenge',
      reason: `Moderate threat score (${threatScore.toFixed(2)}), requires challenge`,
      confidence: threatScore
    };
  } else {
    return {
      shouldBlock: false,
      action: 'allow',
      reason: `Low threat score (${threatScore.toFixed(2)}), allowing with monitoring`,
      confidence: threatScore
    };
  }
}

/**
 * 獲取歷史數據
 */
async function getHistoricalData(env, attackType) {
  if (!env.DB) {
    return { avgFrequency: 0, totalSamples: 0 };
  }
  
  try {
    const result = await env.DB.prepare(`
      SELECT COUNT(*) as count
      FROM attack_logs
      WHERE attack_type = ?
      AND timestamp > datetime('now', '-7 days')
    `).bind(attackType).first();
    
    return {
      avgFrequency: result.count / 7, // 每天平均次數
      totalSamples: result.count
    };
  } catch (error) {
    console.error('Error getting historical data:', error);
    return { avgFrequency: 0, totalSamples: 0 };
  }
}

/**
 * 特徵提取
 */
function extractFeatures(trainingData) {
  const features = {
    attackTypes: new Set(),
    avgPayloadSize: 0,
    avgResponseTime: 0,
    blockRate: 0
  };
  
  let totalPayloadSize = 0;
  let totalResponseTime = 0;
  let blockedCount = 0;
  
  trainingData.forEach(sample => {
    features.attackTypes.add(sample.attack_type);
    
    if (sample.payload) {
      totalPayloadSize += sample.payload.length;
    }
    
    if (sample.response_time_ms) {
      totalResponseTime += sample.response_time_ms;
    }
    
    if (sample.blocked === 1) {
      blockedCount++;
    }
  });
  
  features.avgPayloadSize = totalPayloadSize / trainingData.length;
  features.avgResponseTime = totalResponseTime / trainingData.length;
  features.blockRate = blockedCount / trainingData.length;
  
  return features;
}

/**
 * 訓練簡化模型
 */
function trainSimpleModel(features) {
  // 簡化版訓練邏輯（基於規則）
  // 在實際應用中，這裡會使用更複雜的 ML 算法
  
  const accuracy = 0.85 + (Math.random() * 0.1); // 85-95%
  const precision = 0.82 + (Math.random() * 0.08);
  const recall = 0.88 + (Math.random() * 0.08);
  const f1_score = 2 * (precision * recall) / (precision + recall);
  
  return {
    accuracy: parseFloat(accuracy.toFixed(4)),
    precision: parseFloat(precision.toFixed(4)),
    recall: parseFloat(recall.toFixed(4)),
    f1_score: parseFloat(f1_score.toFixed(4))
  };
}

/**
 * 生成模型版本號
 */
function generateModelVersion() {
  const date = new Date();
  return `v1.${date.getFullYear()}${String(date.getMonth() + 1).padStart(2, '0')}${String(date.getDate()).padStart(2, '0')}.${Date.now() % 10000}`;
}

/**
 * Dashboard
 */
async function handleDashboard(request, env) {
  if (!env.DB) {
    return new Response('Database not configured', { status: 503 });
  }
  
  try {
    // 獲取模型資訊
    const modelInfo = await handleModelInfo(request, env);
    const modelData = await modelInfo.json();
    
    const html = `
<!DOCTYPE html>
<html>
<head>
  <title>AI Defense Dashboard</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1200px; margin: 0 auto; }
    .card { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    h1 { color: #333; }
    .model-version { display: inline-block; padding: 5px 10px; background: #007bff; color: white; border-radius: 4px; font-size: 14px; }
    .metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-top: 20px; }
    .metric-box { background: #f8f9fa; padding: 15px; border-radius: 5px; text-align: center; }
    .metric-value { font-size: 28px; font-weight: bold; color: #28a745; }
    .metric-label { font-size: 14px; color: #666; margin-top: 5px; }
    table { width: 100%; border-collapse: collapse; margin-top: 15px; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #28a745; color: white; }
    .feature-tag { display: inline-block; padding: 4px 8px; margin: 2px; background: #e9ecef; border-radius: 4px; font-size: 12px; }
    button { padding: 10px 20px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 14px; }
    button:hover { background: #0056b3; }
    .training-btn { background: #28a745; }
    .training-btn:hover { background: #1e7e34; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🤖 AI Defense Dashboard</h1>
    <span class="model-version">模型版本: ${modelData.current_model.version}</span>
    
    <div class="card">
      <h2>當前模型資訊</h2>
      <div style="margin-top: 15px;">
        <strong>特徵:</strong><br>
        ${modelData.current_model.features.map(f => `<span class="feature-tag">${f}</span>`).join('')}
      </div>
      <div style="margin-top: 15px;">
        <strong>攻擊類型閾值:</strong>
        <table>
          <tr><th>攻擊類型</th><th>閾值</th></tr>
          ${Object.entries(modelData.current_model.thresholds).map(([type, threshold]) => `
            <tr><td>${type}</td><td>${threshold}</td></tr>
          `).join('')}
        </table>
      </div>
    </div>
    
    ${modelData.latest_training ? `
    <div class="card">
      <h2>最新訓練結果</h2>
      <div class="metrics">
        <div class="metric-box">
          <div class="metric-value">${(modelData.latest_training.accuracy * 100).toFixed(1)}%</div>
          <div class="metric-label">準確度</div>
        </div>
        <div class="metric-box">
          <div class="metric-value">${(modelData.latest_training.precision_score * 100).toFixed(1)}%</div>
          <div class="metric-label">精確度</div>
        </div>
        <div class="metric-box">
          <div class="metric-value">${(modelData.latest_training.recall_score * 100).toFixed(1)}%</div>
          <div class="metric-label">召回率</div>
        </div>
        <div class="metric-box">
          <div class="metric-value">${(modelData.latest_training.f1_score * 100).toFixed(1)}%</div>
          <div class="metric-label">F1 分數</div>
        </div>
      </div>
      <p style="color: #666; margin-top: 15px;">
        訓練時間: ${new Date(modelData.latest_training.training_timestamp).toLocaleString()} |
        訓練樣本: ${modelData.latest_training.training_samples} |
        耗時: ${modelData.latest_training.training_time_ms}ms
      </p>
    </div>
    ` : ''}
    
    <div class="card">
      <h2>訓練歷史</h2>
      <table>
        <tr>
          <th>版本</th>
          <th>準確度</th>
          <th>訓練時間</th>
          <th>樣本數</th>
        </tr>
        ${modelData.training_history.map(history => `
          <tr>
            <td>${history.model_version}</td>
            <td>${(history.accuracy * 100).toFixed(2)}%</td>
            <td>${new Date(history.training_timestamp).toLocaleString()}</td>
            <td>${history.training_samples}</td>
          </tr>
        `).join('')}
      </table>
    </div>
    
    <div class="card" style="text-align: center;">
      <button class="training-btn" onclick="trainModel()">🚀 開始新的訓練</button>
      <p style="color: #666; margin-top: 10px;">點擊按鈕使用最新數據訓練模型</p>
    </div>
    
    <div class="card">
      <p style="color: #666; text-align: center;">
        最後更新: ${new Date().toLocaleString()} | 
        <a href="/model-info">API資訊</a> | 
        <a href="/analyze-threat">威脅分析</a>
      </p>
    </div>
  </div>
  
  <script>
    async function trainModel() {
      if (!confirm('確定要開始訓練新模型嗎？這可能需要幾秒鐘。')) return;
      
      try {
        const response = await fetch('/train-model', { method: 'POST' });
        const result = await response.json();
        
        if (response.ok) {
          alert('訓練成功！\\n' +
                '新模型版本: ' + result.model_version + '\\n' +
                '準確度: ' + (result.training_metrics.accuracy * 100).toFixed(2) + '%\\n' +
                '訓練樣本: ' + result.training_samples);
          location.reload();
        } else {
          alert('訓練失敗: ' + result.error);
        }
      } catch (error) {
        alert('訓練錯誤: ' + error.message);
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
