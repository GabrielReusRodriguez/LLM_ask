#/bin/env bas

# Script que installa llm en el sistema 

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_PATH=/usr/local/bin

cp ${SCRIPT_DIR}/../src/llm_ask.sh ${INSTALL_PATH}/llm



