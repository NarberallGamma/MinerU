#!/usr/bin/env bash
# Копирование тестовых PDF (счёт-фактура, УПД) в data/input с ASCII-именами для curl.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEST="${REPO_ROOT}/data/input"
SRC_DIR="/mnt/c/Users/Narberall/Downloads/Telegram Desktop"

mkdir -p "${DEST}"

copy_one() {
  local src_name="$1"
  local dest_name="$2"
  local src="${SRC_DIR}/${src_name}"
  if [[ ! -f "${src}" ]]; then
    echo "Не найден: ${src}"
    exit 1
  fi
  cp -f "${src}" "${DEST}/${dest_name}"
  echo "OK: ${dest_name}"
}

copy_one "счет-фактура_приммер.pdf" "invoice_example.pdf"
copy_one "УПД-пример (2).pdf" "upd_example.pdf"

ls -la "${DEST}"
