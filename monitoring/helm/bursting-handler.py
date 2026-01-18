from flask import Flask, request, jsonify
from kubernetes import client, config
from datetime import datetime
import logging

app = Flask(__name__)

# 로깅 설정 (한글 출력 지원)
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# --- 설정 변수 (이 부분만 수정하세요) ---
DEPLOYMENT_NAME = "my-app"     # EKS에서 관리할 앱 이름
NAMESPACE = "default"          # 앱이 배포된 네임스페이스
BURST_REPLICAS = 5             # 🚨 버스팅 시 확장할 파드 개수
IDLE_REPLICAS = 0              # ✅ 평상시 유지할 파드 개수
# ---------------------------------------

# EKS 접속용 kubeconfig 로드
try:
    config.load_kube_config(config_file="./eks-kubeconfig.yaml")
    v1 = client.AppsV1Api()
    logging.info("✅ EKS 클러스터 연결 성공")
except Exception as e:
    logging.error(f"❌ EKS 설정 로드 실패: {e}")

@app.route('/webhook', methods=['POST'])
def webhook():
    data = request.json
    status = data.get('status')  # 'firing' 또는 'resolved'
    alerts = data.get('alerts', [])
    alert_name = alerts[0].get('labels', {}).get('alertname', 'Unknown') if alerts else "알 수 없는 알람"
    
    now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    # 상태에 따른 레플리카 설정
    if status == 'firing':
        target_replicas = BURST_REPLICAS
        msg = f"🚨 [발생] {now} - 온프레미스 자원 부족 ({alert_name}). EKS 확장을 시작합니다 (목표: {target_replicas}개)."
    else:
        target_replicas = IDLE_REPLICAS
        msg = f"✅ [해결] {now} - 온프레미스 자원 정상화. EKS 리소스를 회수합니다 (목표: {target_replicas}개)."

    try:
        # 1. EKS Deployment Scale 조절
        v1.patch_namespaced_deployment_scale(
            name=DEPLOYMENT_NAME, 
            namespace=NAMESPACE, 
            body={'spec': {'replicas': target_replicas}}
        )
        
        # 2. Deployment에 한글 주석 추가
        v1.patch_namespaced_deployment(
            name=DEPLOYMENT_NAME,
            namespace=NAMESPACE,
            body={
                "metadata": {
                    "annotations": {
                        "bursting.status": msg,
                        "bursting.last_update": now
                    }
                }
            }
        )
        
        logging.info(msg)
        return jsonify({"result": "success", "target_replicas": target_replicas}), 200

    except Exception as e:
        error_msg = f"❌ [오류] 스케일링 실패: {str(e)}"
        logging.error(error_msg)
        return jsonify({"result": "error", "message": error_msg}), 500

if __name__ == '__main__':
    logging.info(f"🚀 웹훅 리시버 대기 중... (버스팅: {BURST_REPLICAS}개 / 평시: {IDLE_REPLICAS}개)")
    app.run(host='0.0.0.0', port=5000)