FROM ubuntu:22.04

# Gerekli araçları yükle
RUN apt-get update && apt-get install -y \
    curl \
    nodejs \
    npm \
    git \
    && rm -rf /var/lib/apt/lists/*

# Ollama kurulumu
RUN curl -fsSL https://ollama.com/install.sh | sh

# ChatGPT benzeri hafif NextChat arayüzünü indir ve kur
RUN git clone https://github.com/ChatGPTNextWeb/ChatGPT-Next-Web.git /app
WORKDIR /app
RUN npm install && npm run build

# Başlatma betiği
RUN echo '#!/bin/bash\n\
ollama serve &\n\
sleep 5\n\
ollama pull qwen2.5:0.5b\n\
# Ollama OpenAI uyumlu API sunar (port 11434)\n\
export CUSTOM_MODELS="-all,+qwen2.5:0.5b"\n\
export BASE_URL="http://127.0.0.1:11434"\n\
npm run start -- -p 8000\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
