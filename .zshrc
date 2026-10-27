# ==========================================
# MEJORAS NATIVAS PARA ZSH
# ==========================================

# 1. Historial inteligente y compartido entre sesiones (SecureCRT)
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt append_history       # No sobrescribir el historial, acumularlo
setopt share_history        # Compartir historial entre múltiples pestañas/conexiones abiertas
setopt hist_expire_dups_first # Borrar duplicados antiguos primero si se llena
setopt hist_ignore_dups     # No guardar comandos repetidos consecutivos
setopt hist_find_no_dups    # No mostrar duplicados al buscar hacia atrás (Ctrl+R)

# 2. Autocompletado potente y sensible a mayúsculas/minúsculas
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Ignorar mayúsculas al autocompletar
zstyle ':completion:*' menu select                      # Menú visual con las flechas para elegir opciones
setopt AUTO_LIST                                        # Listar elecciones en la primera pestaña ambigua
setopt AUTO_MENU                                        # Usar menú en la segunda pestaña

# 3. Corrección ortográfica ligera para comandos (opcional, avisa si te equivocaste en un comando)
# setopt CORRECT

# 4. Solución rápida para el botón Borrar (BackSpace) en SecureCRT
bindkey "^?" backward-delete-char
bindkey "^[[3~" delete-char

# ==========================================
# ALIAS Y FUNCIONES DE SYSADMIN
# ==========================================

# Redes y Puertos (usando ss)
alias ports="sudo ss -tulpn"
alias myip="curl -s ifconfig.me && echo"

# Logs y Monitoreo rápido
alias jnl="journalctl -u"

# Docker rápido
alias dps="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
alias dlogs="docker logs -f --tail=100"

# Búsqueda de archivos
alias fcat="bat"

# Prompt personalizado para Sysadmin
# Cargar módulos de prompt de Zsh
autoload -U promptinit && promptinit

# Prompt personalizado y seguro para Sysadmin
if [ "$EUID" -eq 0 ]; then
    # Root: Prompt en rojo de advertencia
    PROMPT='%F{red}%n@%m%f %F{blue}%~%f # '
else
    # Usuario normal: Prompt clásico verde y azul
    PROMPT='%F{green}%n@%m%f %F{blue}%~%f %# '
fi

# Opciones y configuración avanzada del prompt
setopt PROMPT_SUBST

# Función para mostrar el estado de error del último comando
zle-line-init() {
    zle reset-prompt
}

# Definir el prompt dinámico
precmd() {
    local exit_code=$?
    local hora="%F{242}[%T]%f" # Hora actual en gris tenue
    local usuario_host=""

    if [ "$EUID" -eq 0 ]; then
        usuario_host="%F{red}%n@%m%f" # Root en rojo
    else
        usuario_host="%F{green}%n@%m%f" # Usuario normal en verde
    fi

    local ruta="%F{cyan}%~%f" # Directorio actual en cian

    # Si el último comando falló, cambia el símbolo final a rojo
    local prompt_symbol="%# "
    if [ $exit_code -ne 0 ]; then
        prompt_symbol="%F{red}%#%f "
    else
        prompt_symbol="%F{yellow}%#%f "
    fi

    PROMPT="$hora $usuario_host $ruta $prompt_symbol"
}
