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

# estados de servicios con systemctl
alias scs="systemctl status"
alias sclist="systemctl list-units --type=service --state=running"

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
    local hora="%F{242}[%T]%f"
    
    # Usuario y Host
    local usuario_host=""
    if [ "$EUID" -eq 0 ]; then
        usuario_host="%F{red}%n@%m%f"
    else
        usuario_host="%F{green}%n@%m%f"
    fi
    
    # Ruta actual (recortada a los últimos 2 niveles para que no sea tan larga)
    local ruta="%F{cyan}%3c%f"
    
    # Rama de Git (si aplica)
    local branch=""
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        local b_name=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
        branch=" %F{magenta} $b_name%f"
    fi
    
    # Símbolo final según si el último comando falló o no
    local prompt_symbol="➜"
    if [ $exit_code -ne 0 ]; then
        prompt_symbol="%F{red}✘%f"
    else
        prompt_symbol="%F{yellow}➜%f"
    fi

    # Ensamblar todo el prompt en dos líneas o una línea limpia
    PROMPT="$hora $usuario_host $ruta$branch $prompt_symbol "
}

# Teclas de navegación en Zsh
bindkey "\e[1~" beginning-of-line  # Tecla Home
bindkey "\e[4~" end-of-line        # Tecla End
bindkey "\e[7~" beginning-of-line  # Algunas variantes de Home
bindkey "\e[8~" end-of-line        # Algunas variantes de End
bindkey "\e[H"  beginning-of-line  # Home en algunos sistemas
bindkey "\e[F"  end-of-line        # End en algunos sistemas


function lsh() {
    ls -ltrhFsAi | awk '
    NR==1 {total=$0; next} 
    BEGIN {print "INODO|BLQ|PERMISOS|LK|USER|GROUP|TAM|FECHA|NOMBRE"} 
    {
        f = $8 " " $9 " " $10
        n = $11
        for(i=12; i<=NF; i++) {
            n = n " " $i
        }
        print $1 "|" $2 "|" $3 "|" $4 "|" $5 "|" $6 "|" $7 "|" f "|" n
    } 
    END {
        print ""
        print total
    }' | column -t -s '|'
}

function sysinfo() {
    echo "\033[1;36m===================================================\033[0m"
    echo "\033[1;36m       ESTADO DEL SISTEMA / INFRAESTRUCTURA      \033[0m"
    echo "\033[1;36m===================================================\033[0m"
    echo "\033[1;33mHostname:\033[0m  $(hostname)"
    echo "\033[1;33mKernel:\033[0m    $(uname -r)"
    
    # Detección limpia de la distribución Linux
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "\033[1;33mOS:\033[0m        $PRETTY_NAME"
    else
        echo "\033[1;33mOS:\033[0m        $(uname -s) $(uname -m)"
    fi
    
    echo "\033[1;33mUptime:\033[0m  $(uptime -p 2>/dev/null || uptime)"

    echo "\n\033[1;32m--- PROCESADOR (CPU) ---\033[0m"
    if [ -f /proc/cpuinfo ]; then
        local cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d':' -f2 | xargs)
        local cpu_cores=$(grep -c '^processor' /proc/cpuinfo)
        echo "\033[1;33mModelo:\033[0m    $cpu_model"
        echo "\033[1;33mNúcleos:\033[0m   $cpu_cores"
    fi
    echo "\033[1;33mLoad Avg:\033[0m  $(awk '{print $1", "$2", "$3}' /proc/loadavg)"

    echo "\n\033[1;32m--- RED / INTERFACES ---\033[0m"
    if command -v ip &>/dev/null; then
        ip -o -4 addr show | awk '{print "  \033[1;33m" $2 ":\033[0m " $4}'
    else
        ifconfig 2>/dev/null | awk '/inet / {print "  \033[1;33m" $1 ":\033[0m " $2}'
    fi
    
    echo "\n\033[1;32m--- MEMORIA RAM ---\033[0m"
    free -h | awk 'NR==1 {print "             " $0} NR>1 {print "  " $0}'
    
    echo "\n\033[1;32m--- ALMACENAMIENTO (RAIZ /) ---\033[0m"
    df -h / | awk 'NR==1 {print "  " $0} NR>1 {print "  " $0}'
    echo "\033[1;36m===================================================\033[0m"
}

function ports() {
    echo "\033[1;36m--- PUERTOS ESCUCHANDO (TCP/UDP) ---\033[0m"
    ss -tulpn 2>/dev/null | awk 'NR==1 {print} NR>1 {print $0}'
}

function psg() {
    if [ -z "$1" ]; then
        echo "Uso: psg <nombre_proceso>"
        return 1
	fi
    ps aux | grep -v grep | grep -i -- "$1"
}

function syslogs() {
    echo "\033[1;36m--- ÚLTIMOS ERRORES DEL SISTEMA (Journalctl) ---\033[0m"
    journalctl -p err -b --no-pager -n 20 2>/dev/null || tail -n 20 /var/log/messages
}
