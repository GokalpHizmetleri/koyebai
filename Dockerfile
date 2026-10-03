FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Gerekli sistem paketleri, Nginx, Node.js ve zstd kurulumu
RUN apt-get update && apt-get install -y \
    curl \
    zstd \
    nginx \
    nodejs \
    npm \
    git \
    && rm -rf /var/lib/apt/lists/*

# Ollama Kurulumu (Artık zstd olduğu için hata vermeyecek)
RUN curl -fsSL https://ollama.com/install.sh | sh

# NextChat kodlarını çekip hazırlama
RUN git clone https://github.com/ChatGPTNextWeb/ChatGPT-Next-Web.git /tmp/nextchat \
    && cd /tmp/nextchat \
    && npm install --omit=dev \
    && npm run build \
    && cp -r public /var/www/html \
    && cp -r .next/standalone/* /var/www/html/ 2>/dev/null || true \
    && rm -rf /tmp/nextchat

# Nginx Yapılandırması (Port 8000 ve API yönlendirme)
RUN echo 'server {\n\
    listen 8000;\n\
    server_name _;\n\
    root /var/www/html;\n\
    index index.html;\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
    location /api/ {\n\
        proxy_pass http://127.0.0.1:11434/api/;\n\
    }\n\
}' > /etc/nginx/sites-available/default

# Başlatma Betiği
RUN echo '#!/bin/bash\n\
echo "Ollama başlatılıyor..."\n\
ollama serve &\n\
sleep 5\n\
\n\
echo "Qwen 2.5 (0.5B) modeli indiriliyor..."\n\
ollama pull qwen2.5:0.5b\n\
\n\
echo "Nginx başlatılıyor..."\n\
nginx -g "daemon off;"\n\
' > /start.sh && chmod +x /start.sh

EXPOSE 8000
ENTRYPOINT ["/start.sh"]
