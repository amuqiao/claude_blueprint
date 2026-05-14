#!/usr/bin/env bash
# ==============================================================================
# check_server.sh — 服务器服务与端口状态检测脚本
# 用途：部署 docker-compose 项目前，了解服务器当前占用情况
# 使用：bash check_server.sh [--ports 80,443,3000,5432]
# ==============================================================================

set -euo pipefail

# ── 颜色定义 ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── 工具函数 ──────────────────────────────────────────────────────────────────
header()  { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; \
            echo -e "${BOLD}${CYAN}  $1${RESET}"; \
            echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; }
info()    { echo -e "  ${GREEN}✔${RESET}  $1"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
danger()  { echo -e "  ${RED}✖${RESET}  $1"; }
label()   { printf "  ${BOLD}%-28s${RESET}" "$1"; }

has_cmd() { command -v "$1" &>/dev/null; }

# ── 解析参数（自定义端口列表）────────────────────────────────────────────────
CUSTOM_PORTS=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ports) CUSTOM_PORTS="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# ── 0. 基础环境信息 ───────────────────────────────────────────────────────────
header "0. 基础环境"
label "主机名";       echo "$(hostname)"
label "当前用户";     echo "$(whoami)  (uid=$(id -u), groups=$(id -Gn))"
label "操作系统";     echo "$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || uname -sr)"
label "内核版本";     echo "$(uname -r)"
label "系统时间";     echo "$(date '+%Y-%m-%d %H:%M:%S %Z')"
label "运行时长";     uptime -p 2>/dev/null || uptime

# sudo 可用性
if sudo -n true 2>/dev/null; then
  info "sudo 免密可用（ss/lsof 将以 root 权限运行，结果更完整）"
  SUDO="sudo"
else
  warn "sudo 需要密码或不可用，部分进程归属信息可能不完整"
  SUDO=""
fi

# ── 1. 资源概况 ───────────────────────────────────────────────────────────────
header "1. 系统资源概况"

# CPU
CPUS=$(nproc)
LOAD=$(awk '{print $1,$2,$3}' /proc/loadavg)
label "CPU 核心数";   echo "$CPUS"
label "系统负载(1/5/15min)"; echo "$LOAD"

# 内存
if has_cmd free; then
  MEM=$(free -h | awk '/^Mem:/{printf "总计:%s  已用:%s  可用:%s", $2,$3,$7}')
  label "内存"; echo "$MEM"
fi

# 磁盘
echo ""
echo -e "  ${BOLD}磁盘使用（>70% 标黄，>90% 标红）:${RESET}"
df -h --output=source,size,used,avail,pcent,target 2>/dev/null | tail -n +2 | \
  grep -v '^tmpfs\|^devtmpfs\|^udev\|^none' | \
  while read -r line; do
    PCT=$(echo "$line" | awk '{print $5}' | tr -d '%')
    if [[ "$PCT" =~ ^[0-9]+$ ]]; then
      if   (( PCT >= 90 )); then echo -e "  ${RED}$line${RESET}"
      elif (( PCT >= 70 )); then echo -e "  ${YELLOW}$line${RESET}"
      else                       echo -e "  $line"
      fi
    fi
  done

# ── 2. Docker 状态 ────────────────────────────────────────────────────────────
header "2. Docker 状态"

if ! has_cmd docker; then
  warn "Docker 未安装"
else
  DOCKER_VER=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "无法连接 daemon")
  label "Docker 版本"; echo "$DOCKER_VER"

  if has_cmd docker-compose; then
    label "docker-compose 版本"; echo "$(docker-compose version --short 2>/dev/null || echo '未知')"
  elif docker compose version &>/dev/null 2>&1; then
    label "docker compose 版本"; echo "$(docker compose version --short 2>/dev/null || echo '未知')"
  else
    warn "docker-compose / docker compose 插件均未找到"
  fi

  # 运行中的容器
  echo ""
  echo -e "  ${BOLD}运行中的容器:${RESET}"
  RUNNING=$(docker ps --format '  {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null)
  if [[ -z "$RUNNING" ]]; then
    info "当前无运行中的容器"
  else
    echo -e "  ${BOLD}NAME\t\t\t\tIMAGE\t\t\tSTATUS\t\tPORTS${RESET}"
    echo "$RUNNING"
  fi

  # 全部容器（含停止）
  echo ""
  STOPPED_COUNT=$(docker ps -a --filter status=exited --format '{{.Names}}' 2>/dev/null | wc -l)
  if (( STOPPED_COUNT > 0 )); then
    warn "另有 $STOPPED_COUNT 个已停止的容器（docker ps -a 可查看）"
  fi

  # Docker 网络
  echo ""
  echo -e "  ${BOLD}自定义 Docker 网络:${RESET}"
  docker network ls --filter type=custom --format '  {{.Name}}\t{{.Driver}}\t{{.Scope}}' 2>/dev/null || true

  # Docker 磁盘占用
  echo ""
  echo -e "  ${BOLD}Docker 磁盘占用:${RESET}"
  docker system df 2>/dev/null | sed 's/^/  /' || true
fi

# ── 3. 端口占用检测 ───────────────────────────────────────────────────────────
header "3. 端口占用检测"

# 常见端口列表（可通过 --ports 追加）
DEFAULT_PORTS="21 22 80 443 3000 3001 3306 5432 5672 6379 8080 8443 9200 9000 27017"
if [[ -n "$CUSTOM_PORTS" ]]; then
  ALL_PORTS=$(echo "$DEFAULT_PORTS $CUSTOM_PORTS" | tr ',' ' ' | tr ' ' '\n' | sort -un | tr '\n' ' ')
  echo -e "  检测端口（默认 + 自定义）: ${BOLD}$ALL_PORTS${RESET}"
else
  ALL_PORTS=$DEFAULT_PORTS
  echo -e "  检测端口（默认常用）: ${BOLD}$ALL_PORTS${RESET}"
  echo -e "  提示: 使用 ${CYAN}--ports 8888,9999${RESET} 追加自定义端口"
fi
echo ""

# 优先用 ss，备用 netstat
if has_cmd ss; then
  LISTEN_CMD="$SUDO ss -tlnp"
elif has_cmd netstat; then
  LISTEN_CMD="$SUDO netstat -tlnp"
else
  warn "ss 和 netstat 均不可用，跳过端口检测"
  LISTEN_CMD=""
fi

if [[ -n "$LISTEN_CMD" ]]; then
  printf "  ${BOLD}%-8s %-22s %-10s %s${RESET}\n" "端口" "监听地址" "状态" "进程"
  echo "  ──────────────────────────────────────────────────────────────"

  for PORT in $ALL_PORTS; do
    # 匹配 :PORT 结尾（避免误匹配 :PORT/ 之类）
    LINE=$($LISTEN_CMD 2>/dev/null | grep -E ":${PORT}[[:space:]]" | head -1 || true)
    if [[ -n "$LINE" ]]; then
      ADDR=$(echo "$LINE" | awk '{print $4}')
      PROC=$(echo "$LINE" | grep -oP 'users:\(\("[^"]+",pid=\K[^,]+|"[^"]+"' | head -1 || echo "未知")
      # 尝试解析进程名
      PROC_INFO=$(echo "$LINE" | grep -oP 'users:\(\("[^"]+"\)' | grep -oP '"[^"]+"' | tr -d '"' || true)
      [[ -z "$PROC_INFO" ]] && PROC_INFO="（需 root 查看进程）"
      printf "  ${RED}%-8s${RESET} %-22s %-10s %s\n" "$PORT" "$ADDR" "占用" "$PROC_INFO"
    else
      printf "  ${GREEN}%-8s${RESET} %-22s %-10s\n" "$PORT" "-" "空闲"
    fi
  done
fi

# ── 4. 所有监听端口总览 ───────────────────────────────────────────────────────
header "4. 所有监听中的端口（TOP 30）"
if has_cmd ss; then
  $SUDO ss -tlnp 2>/dev/null | head -31 | sed 's/^/  /' || true
elif has_cmd netstat; then
  $SUDO netstat -tlnp 2>/dev/null | head -31 | sed 's/^/  /' || true
fi

# ── 5. 关键系统服务状态 ───────────────────────────────────────────────────────
header "5. 关键系统服务状态"
SERVICES=("nginx" "apache2" "httpd" "mysql" "postgresql" "redis" "mongod" "docker" "firewalld" "ufw")

if has_cmd systemctl; then
  printf "  ${BOLD}%-20s %s${RESET}\n" "服务" "状态"
  echo "  ────────────────────────────────"
  for SVC in "${SERVICES[@]}"; do
    STATUS=$(systemctl is-active "$SVC" 2>/dev/null || echo "not-found")
    case "$STATUS" in
      active)    printf "  ${GREEN}%-20s${RESET} ${GREEN}%s${RESET}\n" "$SVC" "● 运行中" ;;
      inactive)  printf "  ${YELLOW}%-20s${RESET} ${YELLOW}%s${RESET}\n" "$SVC" "○ 已停止" ;;
      not-found) printf "  %-20s %s\n" "$SVC" "— 未安装" ;;
      *)         printf "  ${RED}%-20s${RESET} ${RED}%s${RESET}\n" "$SVC" "✖ $STATUS" ;;
    esac
  done
else
  warn "systemctl 不可用（非 systemd 系统）"
fi

# ── 6. 防火墙状态 ─────────────────────────────────────────────────────────────
header "6. 防火墙状态"
if has_cmd ufw; then
  UFW_STATUS=$(sudo ufw status 2>/dev/null || echo "需要 sudo")
  echo "$UFW_STATUS" | sed 's/^/  /'
elif has_cmd firewall-cmd; then
  echo -e "  ${BOLD}firewalld 状态:${RESET}"
  sudo firewall-cmd --state 2>/dev/null | sed 's/^/  /' || true
  echo -e "  ${BOLD}开放的端口:${RESET}"
  sudo firewall-cmd --list-ports 2>/dev/null | sed 's/^/  /' || true
elif has_cmd iptables; then
  warn "使用 iptables（建议手动检查规则）"
  $SUDO iptables -L INPUT --line-numbers -n 2>/dev/null | head -20 | sed 's/^/  /' || true
else
  warn "未检测到防火墙工具（ufw/firewalld/iptables）"
fi

# ── 7. 其他用户进程概览 ───────────────────────────────────────────────────────
header "7. 其他用户的进程概览（需关注潜在冲突）"
ME=$(whoami)
echo -e "  当前用户: ${BOLD}$ME${RESET}（以下为其他用户的进程）"
echo ""
$SUDO ps aux 2>/dev/null | awk -v me="$ME" 'NR==1{print "  "$0} $1!=me && $1!="root" && NR>1{print "  "$0}' | head -25 || true
echo ""
warn "root 用户的服务进程请通过 'sudo ps aux | grep root' 单独确认"

# ── 8. docker-compose 项目冲突预检 ───────────────────────────────────────────
header "8. docker-compose 项目冲突预检"

COMPOSE_FILE=""
for f in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
  [[ -f "$f" ]] && COMPOSE_FILE="$f" && break
done

if [[ -z "$COMPOSE_FILE" ]]; then
  warn "当前目录未找到 docker-compose 文件，跳过冲突预检"
  warn "请在项目目录下运行本脚本以获得完整预检结果"
else
  info "找到配置文件: $COMPOSE_FILE"
  echo ""

  # 提取端口映射
  echo -e "  ${BOLD}配置文件中的端口映射:${RESET}"
  COMPOSE_PORTS=$(grep -E '^\s+-\s+"?[0-9]+:[0-9]+"?' "$COMPOSE_FILE" 2>/dev/null | \
                  grep -oP '(?<=-\s{0,5})"?[0-9]+(?=:[0-9])' | tr -d '"' | sort -u || true)

  if [[ -z "$COMPOSE_PORTS" ]]; then
    warn "未解析到端口映射（可能使用 env 变量或 YAML 锚点，请手动确认）"
  else
    HAS_CONFLICT=0
    for P in $COMPOSE_PORTS; do
      IN_USE=$($LISTEN_CMD 2>/dev/null | grep -cE ":${P}[[:space:]]" || true)
      if (( IN_USE > 0 )); then
        danger "端口 ${BOLD}$P${RESET} 已被占用 → ${RED}存在冲突！${RESET}"
        HAS_CONFLICT=1
      else
        info  "端口 $P 空闲"
      fi
    done
    echo ""
    if (( HAS_CONFLICT == 1 )); then
      danger "存在端口冲突，直接执行 docker-compose up 会失败！"
      echo -e "  建议：修改 compose 文件中的宿主机端口，或停止占用进程（确认安全后）"
    else
      info "所有端口均空闲，可以安全启动"
    fi
  fi

  # 检查项目名/网络冲突
  echo ""
  PROJ_DIR=$(basename "$PWD")
  NETWORK_NAME="${PROJ_DIR}_default"
  echo -e "  ${BOLD}Docker 网络冲突检测:${RESET}"
  if docker network ls --format '{{.Name}}' 2>/dev/null | grep -q "^${NETWORK_NAME}$"; then
    warn "网络 ${BOLD}$NETWORK_NAME${RESET} 已存在（可能是同名项目残留，或项目已部分启动）"
  else
    info "网络 $NETWORK_NAME 不存在，无冲突"
  fi
fi

# ── 总结 ──────────────────────────────────────────────────────────────────────
header "✅ 检测完成"
echo -e "  ${BOLD}部署前建议清单:${RESET}"
echo -e "  1. 确认第 3/8 节无端口冲突"
echo -e "  2. 确认第 5 节无同类服务（如 nginx、mysql）与容器争抢端口"
echo -e "  3. 确认第 6 节防火墙已放行所需端口"
echo -e "  4. 若需占用 root 服务的端口，先与服务器管理员确认"
echo -e "  5. 安全启动命令: ${CYAN}docker compose up -d --remove-orphans${RESET}"
echo -e "  6. 启动后验证: ${CYAN}docker compose ps && docker compose logs --tail=50${RESET}"
echo ""