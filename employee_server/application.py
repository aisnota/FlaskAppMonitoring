import os
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()
Instrumentator().instrument(app).expose(app)

@app.get("/db-test")
async def db_test():
    # 임포트를 여기로 옮겨서 서버 실행 시점의 충돌을 방지합니다.
    try:
        import pymysql
    except ImportError:
        return {"status": "error", "message": "pymysql not installed. Please run pip install."}

    db_config = {
        'host': '192.168.13.120',
        'user': 'kosa',
        'password': 'kosa1004',
        'db': 'testdb',
        'charset': 'utf8mb4',
        'connect_timeout': 3
    }
    conn = None
    try:
        conn = pymysql.connect(**db_config)
        with conn.cursor() as cursor:
            cursor.execute("CREATE TABLE IF NOT EXISTS load_test (id INT AUTO_INCREMENT PRIMARY KEY, test_time DATETIME DEFAULT CURRENT_TIMESTAMP)")
            cursor.execute("INSERT INTO load_test () VALUES ()")
            conn.commit()
            cursor.execute("SELECT COUNT(*) FROM load_test")
            result = cursor.fetchone()
        return {"status": "success", "total_rows": result[0]}
    except Exception as e:
        return JSONResponse(status_code=200, content={"status": "error", "message": str(e)})
    finally:
        if conn:
            conn.close()

@app.get("/")
async def root():
    return {"message": "Database Test Server is Running"}
