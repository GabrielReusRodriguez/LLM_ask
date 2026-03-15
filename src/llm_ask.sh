#!/bin/env bash

# Author: Gabriel Reus
# https://github.com/GabrielReusRodriguez/
# Requisitos :
#   curl
#   jq
# Probado con Linux mint y Mistral.

LLM_URL='https://api.mistral.ai/v1/chat/completions'
LLM_MODEL='mistral-tiny'
LLM_API_KEY=${MISTRAL_API_KEY}

# Funcion para preguntas genericas
pregunta(){
    local prompt="$*"
    curl -s ${LLM_URL} \
        -H "Authorization: Bearer ${LLM_API_KEY}" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "'${LLM_MODEL}'",
            "messages": [{"role": "user", "content": "'"$prompt"'"}]
        }' | jq -r '.choices[0].message.content'
}

# Funcion para explicar los comandos bash
explicar_comando(){
    local comando="$1"
    curl -s ${LLM_URL} \
        -H "Authorization: Bearer ${LLM_API_KEY}" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "'${LLM_MODEL}'",
            "messages": [{"role": "user", "content": "Explica el comando '"$comando"' en Linux"}]
        }' | jq -r '.choices[0].message.content'
}

# Genera un script de bash
crear_script(){
    local descripcion="$*"
    curl -s ${LLM_URL} \
        -H "Authorization: Bearer ${LLM_API_KEY}" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "'${LLM_MODEL}'",
            "messages": [{"role": "user", "content": "Genera un script de Bash que '"$descripcion"'"}]
        }' | jq -r '.choices[0].message.content'
}

# Instala el alias para poder usarlo como pipe
install_alias(){
    local alias="# Definimos los alias del usuario
mistral() { # Alias installed
    local prompt=\"\$*\"
    local input=\"\$(cat)\"
    local content=\"\${prompt}\${input}\"

    # Usamos jq para construir el JSON de forma segura
    local json=\$(jq -n --arg content \"\$content\" '{
        model: \"${LLM_MODEL}\",
        messages: [{
            role: \"user\",
            content: \$content
        }]
    }')

    curl -s \"${LLM_URL}\" \\
        -H \"Authorization: Bearer ${MISTRAL_API_KEY}\" \\
        -H \"Content-Type: application/json\" \\
        -d \"\$json\" | jq -r \".choices[0].message.content\"
}"
    # Si no existe el .bash_aliases, lo creamos si existe, solo modificará la fecha y hora de actualziacion
    touch ~/.bash_aliases
    # Checkear si está instalado el alias. SI no lo está lo instalamos.
    grep -q "mistral() { # Alias installed" ~/.bash_aliases && echo "El alias ya está instalado" || echo -e "$alias" >> ~/.bash_aliases

}

help(){
    local ayuda="llm_ask
--------
    Script para integrar llms con bash.
    Usage: llm_ask -aeshi
    "
    echo -e "$ayuda"
}


# Inicio del programa en si.
OPTIONS="a:e:s:ih"
LONGOPTS="ask:,explain:,create-script:,install,help"

# Parseamos las opcioens
TEMP=$(getopt -o "${OPTIONS}" -l "${LONGOPTS}" -n "$0" -- "$@")
# Check si se ha parseado bien
if [ $? != 0 ]; then
    echo "Error parsing the options" >&2
    exit 1
fi

eval set -- "$TEMP"

while true; do
    case "$1" in
        -a|--ask)
            action="ask" 
            query="$2"
            shift 2
            ;;
        -i|--install)
            action="install_alias"
            shift
            ;;
        -e|--explain)
            action="explain"
            command="$2"
            shift 2
            ;;
        -s|--create-script)
            action="create_script"
            query="$2"
            shift 2
            ;;
        -h|--help)
            action="help"
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Unsupported option: $1" >&2
            exit 1
            ;;
    esac
done

if [ "$action" = "ask" ]; then
    pregunta $query
    exit 0
fi

if [ "$action" = 'install_alias' ]; then
    install_alias
    exit 0
fi

if [ "$action" = 'explain' ]; then
    explicar_comando $command
    exit 0
fi

if [ "$action" = 'create_script' ]; then
    crear_script $query
    exit 0
fi

if [ "$action" = 'help' ]; then
    help
    exit 0
fi

# En caso que la accion on esté soportada => Error
echo "Error, executed without action" >&2
exit 1
