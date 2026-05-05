#!/usr/bin/env python3
# http 타입 훅 테스트용 로컬 웹훅 서버
# 실행: python3 hbn_webhook_server.py

import json
from http.server import BaseHTTPRequestHandler, HTTPServer
from datetime import datetime

PORT = 9000


class HBNWebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)

        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            data = {"raw": body.decode()}

        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        tool = data.get("tool_name", "unknown")
        file_path = data.get("tool_input", {}).get("file_path", "")

        print(f"\n[{timestamp}] 훅 수신")
        print(f"  도구  : {tool}")
        print(f"  파일  : {file_path}")
        print(f"  전체  : {json.dumps(data, ensure_ascii=False, indent=2)}")

        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, format, *args):
        pass  # 기본 로그 억제


if __name__ == "__main__":
    server = HTTPServer(("localhost", PORT), HBNWebhookHandler)
    print(f"웹훅 서버 시작: http://localhost:{PORT}/hook")
    print("Claude Code에서 파일을 저장하면 이벤트가 표시됩니다. (Ctrl+C로 종료)")
    server.serve_forever()
