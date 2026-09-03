#!/usr/bin/env python3
# 简易 webhook 接收端：模拟企业微信机器人，接收 Alertmanager 告警并打印
from http.server import HTTPServer, BaseHTTPRequestHandler
import json, datetime

LOG = "/tmp/alerts.log"

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(length).decode('utf-8', 'replace')
        ts = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{ts}] ⚠️ 收到告警 Webhook:")
        try:
            data = json.loads(body)
            for alert in data.get('alerts', []):
                labels = alert.get('labels', {})
                annos = alert.get('annotations', {})
                print(f"   [{alert.get('status','')}] {labels.get('alertname','')}")
                print(f"      severity={labels.get('severity','')} | namespace={labels.get('namespace','')} | pod={labels.get('pod','')[:50]}")
                print(f"      {annos.get('summary','')[:120]}")
        except Exception as e:
            print(f"   原始内容: {body[:500]}")
        with open(LOG, 'a') as f:
            f.write(f"[{ts}] {body}\n")
        self.send_response(200)
        self.end_headers()

    def log_message(self, *args):
        pass

if __name__ == '__main__':
    print("Webhook 接收端启动，监听 0.0.0.0:8080")
    HTTPServer(('0.0.0.0', 8080), Handler).serve_forever()
