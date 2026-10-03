# 1. AŞAMA: NextChat Arayüzünü Derleme
FROM node:18-alpine AS builder
WORKDIR /app
RUN apk add --no-network --no-cache git
RUN git clone https://github.com/ChatGPTNextWeb/ChatGPT-Next-Web.git .
RUN yarn install
RUN yarn build

# 2. AŞAMA: Çalıştırma Ortamı (Ollama + Nginx)
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Gerekli sistem araçları ve Nginx kurulumu
RUN apt-get update && apt-get install -y \
    curl \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Ollama kurulumu
RUN curl -fsSL https://ollama.com/install.sh | sh

# Derlenen NextChat dosyalarını Nginx dizinine kopyala
COPY --from=builder /app/out /var/www/html

# Nginx Yapılandırması (Port 8000 & API Yönlendirmesi)
RUN echo 'server {\n\
    listen 8000;\n\
    server_name _;\n\
    root /var/www/html;\n\
    index index.html;\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
    location /v1/ {\n\
        proxy_pass http://127.0.0.1:11434/v1/;\n\
        proxy_set_header Host $host;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
    }\n\
}' > /etc/nginx/sites-available/default

# Başlatma Betiği
RUN echo '#!/bin/bash\n\
echo "Ollama servisi başlatılıyor..."\n\
ollama serve &\n\
sleep 5\n\
\n\
echo "Qwen 2.5 (0.5B) modeli otomatik indiriliyor..."\n\
ollama pull qwen2.5:0.5b\n\
\n\
echo "Nginx başlatılıyor..."\n\
nginx -g "daemon off;"\n\
' > /start.sh && chmod +x /start.sh

EXPOSE 8000
ENTRYPOINT ["/start.sh"]
