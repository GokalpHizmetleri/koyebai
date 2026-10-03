FROM alpine:latest

# Gerekli ultra hafif paketleri ve zstd/curl yükle
RUN apk add --no-cache \
    curl \
    zstd \
    bash \
    python3 \
    py3-pip

# Ollama Kurulumu
RUN curl -fsSL https://ollama.com/install.sh | sh

# Python bağımlılıkları (sadece Flask ve Requests)
RUN pip3 install --no-cache-dir flask requests

# ChatGPT benzeri hafif web arayüzünü (app.py) hazırlama
RUN mkdir /app
WORKDIR /app

RUN echo 'import os, requests\n\
from flask import Flask, render_template_string, request, jsonify\n\
app = Flask(__name__)\n\
HTML = """<!DOCTYPE html><html lang="tr"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>ChatGPT - Qwen 2.5</title><style>* { box-sizing: border-box; margin: 0; padding: 0; font-family: system-ui, sans-serif; } body { display: flex; height: 100vh; background: #212121; color: #ececec; } #sidebar { width: 260px; background: #171717; padding: 15px; display: flex; flex-direction: column; justify-content: space-between; border-right: 1px solid #333; } .new-chat { border: 1px solid #424242; border-radius: 8px; padding: 10px; cursor: pointer; text-align: center; background: #2f2f2f; } #chat-area { flex: 1; display: flex; flex-direction: column; justify-content: space-between; } #messages { flex: 1; overflow-y: auto; padding: 20px 15%; display: flex; flex-direction: column; gap: 20px; } .msg { padding: 15px; border-radius: 10px; line-height: 1.6; } .user { background: #2f2f2f; align-self: flex-end; max-width: 80%; } .bot { background: transparent; max-width: 100%; } #input-area { padding: 20px 15%; background: #212121; } .input-box { display: flex; background: #2f2f2f; border-radius: 12px; padding: 10px 15px; border: 1px solid #424242; } input { flex: 1; background: transparent; border: none; color: white; outline: none; font-size: 16px; } button { background: #10a37f; border: none; color: white; padding: 8px 15px; border-radius: 8px; cursor: pointer; }</style></head><body><div id="sidebar"><div><div class="new-chat" onclick="location.reload()">+ Yeni Sohbet</div></div><div style="font-size: 12px; color: #888; text-align: center;">Qwen 2.5 (0.5B)</div></div><div id="chat-area"><div id="messages"><div class="msg bot"><b>AI:</b> Merhaba! Ben Qwen 2.5. Size nasıl yardımcı olabilirim?</div></div><div id="input-area"><div class="input-box"><input type="text" id="prompt" placeholder="Message ChatGPT..." onkeypress="if(event.key===\"Enter\") send()"><button onclick="send()">Gönder</button></div></div></div><script>async function send() { let input = document.getElementById("prompt"); let msgs = document.getElementById("messages"); if(!input.value.trim()) return; let text = input.value; input.value = ""; msgs.innerHTML += `<div class="msg user">${text}</div>`; msgs.scrollTop = msgs.scrollHeight; let botId = "bot-" + Date.now(); msgs.innerHTML += `<div class="msg bot"><b>AI:</b> <span id="${botId}">Yazıyor...</span></div>`; msgs.scrollTop = msgs.scrollHeight; try { let res = await fetch("/chat", { method: "POST", headers: {"Content-Type": "application/json"}, body: JSON.stringify({prompt: text}) }); let data = await res.json(); document.getElementById(botId).innerText = data.response; } catch(e) { document.getElementById(botId).innerText = "Hata oluştu."; } msgs.scrollTop = msgs.scrollHeight; }</script></body></html>"""\n\
@app.route("/")\n\
def home(): return render_template_string(HTML)\n\
@app.route("/chat", methods=["POST"])\n\
def chat():\n\
    p = request.json.get("prompt")\n\
    r = requests.post("http://localhost:11434/api/generate", json={"model": "qwen2.5:0.5b", "prompt": p, "stream": False})\n\
    return jsonify({"response": r.json().get("response", "Hata")})\n\
if __name__ == "__main__": app.run(host="0.0.0.0", port=8000)\n\
' > /app/app.py

# Başlatma Betiği
RUN echo '#!/bin/bash\n\
ollama serve &\n\
sleep 5\n\
ollama pull qwen2.5:0.5b\n\
python3 /app/app.py\n\
' > /start.sh && chmod +x /start.sh

EXPOSE 8000
ENTRYPOINT ["/start.sh"]
