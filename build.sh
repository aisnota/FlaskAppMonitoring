docker build -t hisieun/auth_server:v2.01 ./auth_server
docker build -t hisieun/employee_server:v2.01 ./employee_server
docker build -t hisieun/gateway:v2.01 ./gateway
docker build -t hisieun/photo_service:v2.01 ./photo_service
docker build -t hisieun/frontend:v2.01 ./frontend
docker push hisieun/auth_server:v2.01
docker push hisieun/employee_server:v2.01
docker push hisieun/gateway:v2.01
docker push hisieun/photo_service:v2.01
docker push hisieun/frontend:v2.01