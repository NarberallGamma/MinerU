# MinerU — локальный Docker (fork)

Официальный образ: `docker/global/Dockerfile` (база `vllm/vllm-openai`, `mineru[core]`, `mineru-models-download`).

## Структура

| Путь | Назначение |
|------|------------|
| `docker-compose.yml` | Сервисы и профили compose |
| `run.sh` | build / up / down / health / parse-examples |
| `.docker-build/` | Временный `DOCKER_CONFIG` без credsStore (не в git) |
| `../data/input/` | PDF для разбора (read-only в контейнере) |
| `../data/output/` | ZIP-результаты API |

## Профили

| Профиль | Порт | Описание |
|---------|------|----------|
| `build` | — | Только сборка `mineru:latest` |
| `api` | 8000 | FastAPI (`/file_parse`, `/tasks`, `/docs`) |
| `gradio` | 7860 | WebUI |
| `openai-server` | 30000 | OpenAI-совместимый сервер для `*-http-client` |
| `router` | 8002 | Единая точка входа, multi-GPU |

Переменные: `MINERU_API_PORT`, `MINERU_GRADIO_PORT`, `MINERU_OPENAI_PORT`, `MINERU_ROUTER_PORT`.

## API

Синхронный разбор:

```bash
curl -X POST http://127.0.0.1:8000/file_parse \
  -F "files=@../data/input/invoice_example.pdf" \
  -F "return_md=true" \
  -F "response_format_zip=true" \
  -o ../data/output/invoice_example.zip
```

При нехватке VRAM в `docker-compose.yml` раскомментировать `--gpu-memory-utilization` в upstream `compose.yaml` (см. комментарии в официальном репозитории).
