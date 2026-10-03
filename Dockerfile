FROM ubuntu:22.04

# Gerekli bağımlılıkları yükle
RUN apt-get update && apt-get install -y \
    curl \
    python3 \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Ollama kurulumu
RUN curl -fsSL https://ollama.com/install.sh | sh

# Python Web Arayüzü bağımlılıkları
RUN pip3 install flask requests

# Çalıştırma betiği oluştur
RUN echo '#!/bin/bash\n\
ollama serve &\n\
sleep 5\n\
ollama pull qwen2.5:0.5b\n\
python3 /app/app.py\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

WORKDIR /app
COPY app.py /app/app.py

EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
