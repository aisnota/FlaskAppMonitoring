FROM nginx:latest
# 1. 소스 복사
COPY . /var/www/frontend/
# 2. 우리가 만든 설정을 Nginx 기본 설정 위치에 덮어쓰기
COPY nginx.conf /etc/nginx/conf.d/default.conf