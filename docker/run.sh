#!/usr/bin/env bash
# Запуск MinerU Docker (fork) с обходом credsStore Docker Desktop.
#
# Использование:
#   ./run.sh [команда] [профиль]
#
# Команды: build, up, up-fg, down, logs, health, parse-examples
# Профили: build, api (по умолчанию), gradio, openai-server, router
#
# Примеры:
#   ./run.sh build build       # официальная сборка mineru:latest (долго, модели в образе)
#   ./run.sh up api            # REST API на :8000
#   ./run.sh up-fg api         # API в foreground (логи в консоль)
#   ./run.sh health api        # GET /health
#   ./run.sh parse-examples    # разбор тестовых PDF из data/input/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCKER_CONFIG_DIR="${SCRIPT_DIR}/.docker-build"
DATA_INPUT="${REPO_ROOT}/data/input"
DATA_OUTPUT="${REPO_ROOT}/data/output"
API_PORT="${MINERU_API_PORT:-8000}"

if [[ ! -f "${DOCKER_CONFIG_DIR}/config.json" ]]; then
  echo "Создаём .docker-build/config.json (пустой config без credsStore)"
  mkdir -p "$DOCKER_CONFIG_DIR"
  printf '%s\n' '{"auths":{},"currentContext":"default"}' > "${DOCKER_CONFIG_DIR}/config.json"
fi

export DOCKER_CONFIG="${DOCKER_CONFIG_DIR}"

mkdir -p "${DATA_INPUT}" "${DATA_OUTPUT}"

CMD="${1:-up}"
PROFILE="${2:-api}"

cd "$SCRIPT_DIR"

compose() {
  docker compose -f docker-compose.yml "$@"
}

case "$CMD" in
  build)
    echo "Сборка mineru:latest (DOCKER_CONFIG=${DOCKER_CONFIG_DIR})"
    echo "Контекст: docker/global/Dockerfile — загрузка моделей может занять 30–90+ мин."
    compose --profile build build
    ;;
  up)
    echo "Запуск профиля ${PROFILE}"
    compose --profile "$PROFILE" up -d
    case "$PROFILE" in
      api) echo "API docs: http://127.0.0.1:${API_PORT}/docs" ;;
      gradio) echo "WebUI: http://127.0.0.1:${MINERU_GRADIO_PORT:-7860}" ;;
      openai-server) echo "OpenAI server: http://127.0.0.1:${MINERU_OPENAI_PORT:-30000}" ;;
      router) echo "Router: http://127.0.0.1:${MINERU_ROUTER_PORT:-8002}/docs" ;;
    esac
    ;;
  up-fg)
    echo "Запуск в foreground (логи в консоль)"
    compose --profile "$PROFILE" up
    ;;
  down)
    compose --profile "$PROFILE" down
    ;;
  logs)
    compose --profile "$PROFILE" logs -f
    ;;
  health)
    curl -fsS "http://127.0.0.1:${API_PORT}/health" | python3 -m json.tool 2>/dev/null || curl -fsS "http://127.0.0.1:${API_PORT}/health"
    ;;
  parse-examples)
    shopt -s nullglob
    pdfs=("${DATA_INPUT}"/*.pdf)
    if [[ ${#pdfs[@]} -eq 0 ]]; then
      echo "Нет PDF в ${DATA_INPUT}"
      echo "Скопировать примеры: ./scripts/copy-example-pdfs.sh"
      exit 1
    fi
    for pdf in "${pdfs[@]}"; do
      base="$(basename "$pdf")"
      echo "=== POST /file_parse: ${base} ==="
      curl -fsS -X POST "http://127.0.0.1:${API_PORT}/file_parse" \
        -F "files=@${pdf}" \
        -F "return_md=true" \
        -F "response_format_zip=true" \
        -o "${DATA_OUTPUT}/${base%.pdf}_result.zip"
      echo " -> ${DATA_OUTPUT}/${base%.pdf}_result.zip"
    done
    ;;
  *)
    echo "Неизвестная команда: ${CMD}"
    echo "Доступно: build, up, up-fg, down, logs, health, parse-examples"
    exit 1
    ;;
esac
