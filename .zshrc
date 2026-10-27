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

# Redes y Puertos (usando ss que ya prefieres)
alias ports="sudo ss -tulpn"
alias myip="curl -s ifconfig.me && echo"

# Logs y Monitoreo rápido
alias jnl="journalctl -u" # Uso: jnl nginx para ver logs de systemd

# Docker rápido (si usas contenedores)
alias dps="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
alias dlogs="docker logs -f --tail=100"

# Búsqueda de archivos ultra rápida (si usas fd)
alias fcat="bat" # Si usas bat en lugar de cat

# Prompt personalizado para Sysadmin
autoload -U colors && colors
if [ "$EUID" -eq 0 ]; then
    # Si eres root, el prompt se pone rojo de advertencia
    PROMPT='%B%{$fg[red]%}%n@%m %{$fg[blue]%}%~ %# %b%{$reset_color%}'
else
    # Si eres usuario normal, va en verde/azul clásico
    PROMPT='%B%{$fg[green]%}%n@%m %{$fg[blue]%}%~ %# %b%{$reset_color%}'
fi


