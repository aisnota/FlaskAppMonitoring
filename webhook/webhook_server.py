from flask import Flask, request, jsonify
import sys

app = Flask(__name__)

@app.route('/webhook', methods=['POST'])
def handle_webhook():
    print("\n[알람 발생] 신호가 들어왔습니다!")
    data = request.json
    print(f"전달된 데이터: {data}")
    return jsonify({"message": "수신 완료"}), 200

if __name__ == '__main__':
    print("--- Webhook 서버를 시작합니다 (Port: 8080) ---")
    # host='0.0.0.0'이 있어야 외부 VM에서 이 IP로 접속이 가능합니다.
    try:
        app.run(host='0.0.0.0', port=8080)
    except Exception as e:
        print(f"서버 실행 실패: {e}")
        sys.exit(1)