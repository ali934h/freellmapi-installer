# freellmapi-installer

One-line installer for [FreeLLMAPI](https://github.com/tashfeenahmed/freellmapi) on Ubuntu.  
Installs Node.js 20, pm2, clones FreeLLMAPI, builds it, and starts it as a persistent service.

## Install

Run as root on Ubuntu:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ali934h/freellmapi-installer/main/install.sh)
```

The installer will:

- Install Node.js 20 (skips if already installed)
- Install pm2 globally (skips if already installed)
- Clone FreeLLMAPI to `/root/freellmapi`
- Detect a free port (default 3001) and let you change it
- Generate a secure encryption key automatically
- Build the project
- Start it with pm2 and enable autostart on reboot

## After install

1. Open `http://YOUR-VPS-IP:PORT` in your browser
2. Create your admin account on first run
3. Go to **Keys** and add your free provider API keys
4. Reorder the **Fallback Chain** to your preference
5. Copy your unified API key from the **Keys** page
6. In Cline → API Provider: `OpenAI Compatible` → Base URL: `http://YOUR-VPS-IP:PORT/v1`

## Free provider API keys to collect

| Provider | Sign up | Free limit |
|----------|---------|------------|
| Google AI Studio | [aistudio.google.com](https://aistudio.google.com) | 1500 req/day |
| Groq | [console.groq.com](https://console.groq.com) | 1000 req/day |
| Cerebras | [cloud.cerebras.ai](https://cloud.cerebras.ai) | 1M token/day |
| Mistral | [console.mistral.ai](https://console.mistral.ai) | limited |
| OpenRouter | [openrouter.ai](https://openrouter.ai) | 50 req/day free models |
| GitHub Models | [github.com/marketplace/models](https://github.com/marketplace/models) | limited |
| NVIDIA NIM | [build.nvidia.com](https://build.nvidia.com) | 40 RPM |
| Cloudflare | [dash.cloudflare.com](https://dash.cloudflare.com) | limited |

## Daily commands

```bash
pm2 status                              # check service status
pm2 logs freellmapi                     # view logs
pm2 restart freellmapi                  # restart service
bash /root/freellmapi-installer/update.sh    # update to latest
bash /root/freellmapi-installer/uninstall.sh # remove everything
```

## Update

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ali934h/freellmapi-installer/main/update.sh)
```

## Requirements

- Ubuntu (any recent LTS)
- Root access
- ~100 MB free RAM
- ~500 MB free disk
