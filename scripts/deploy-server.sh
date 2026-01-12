#!/bin/bash
# CEOAgent 服务器部署脚本（SSH 部署到 136.115.199.54）
# 使用方法: ./scripts/deploy-server.sh [环境] [分支/标签]

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
SERVER_IP="${SERVER_IP:-136.115.199.54}"
SERVER_USER="${SERVER_USER:-zouyongming}"
SERVER_PORT="${SERVER_PORT:-22}"
SERVER_DEPLOY_PATH="${SERVER_DEPLOY_PATH:-/opt/ceoagent}"
SERVER_BRANCH="${1:-main}"
ENVIRONMENT="${2:-production}"

# SSH 选项
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p ${SERVER_PORT}"
SSH_CMD="ssh ${SSH_OPTS} ${SERVER_USER}@${SERVER_IP}"

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查 SSH 连接
check_ssh_connection() {
    log_step "检查 SSH 连接到服务器..."
    
    if $SSH_CMD "echo 'SSH 连接正常'" &>/dev/null; then
        log_info "SSH 连接成功"
        return 0
    else
        log_error "无法连接到服务器 ${SERVER_USER}@${SERVER_IP}:${SERVER_PORT}"
        log_error "请检查："
        log_error "  1. 服务器 IP 地址是否正确"
        log_error "  2. SSH 服务是否运行"
        log_error "  3. 防火墙规则是否允许连接"
        log_error "  4. SSH key 或密码是否正确"
        exit 1
    fi
}

# 检查服务器前置条件
check_server_prerequisites() {
    log_step "检查服务器前置条件..."
    
    $SSH_CMD bash << 'EOF'
        # 检查 Docker
        if ! command -v docker &> /dev/null; then
            echo "❌ Docker 未安装"
            exit 1
        fi
        echo "✅ Docker 已安装: $(docker --version)"
        
        # 检查 Docker Compose
        if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
            echo "❌ Docker Compose 未安装"
            exit 1
        fi
        echo "✅ Docker Compose 已安装"
        
        # 检查 Git
        if ! command -v git &> /dev/null; then
            echo "❌ Git 未安装"
            exit 1
        fi
        echo "✅ Git 已安装: $(git --version)"
        
        # 检查必要的目录
        mkdir -p /opt/ceoagent
        mkdir -p /opt/ceoagent/data
        mkdir -p /opt/ceoagent/logs
        echo "✅ 目录已准备"
    EOF
    
    log_info "服务器前置条件检查通过"
}

# 在服务器上克隆或更新代码
setup_repository() {
    log_step "设置代码仓库..."
    
    $SSH_CMD bash << EOF
        cd ${SERVER_DEPLOY_PATH}
        
        if [ -d ".git" ]; then
            echo "📦 更新代码仓库..."
            git fetch origin
            git checkout ${SERVER_BRANCH} || git checkout -b ${SERVER_BRANCH} origin/${SERVER_BRANCH}
            git reset --hard origin/${SERVER_BRANCH}
            git pull origin ${SERVER_BRANCH}
        else
            echo "📦 克隆代码仓库..."
            rm -rf ${SERVER_DEPLOY_PATH}/*
            git clone https://github.com/smithpeter/CEOAgent.git ${SERVER_DEPLOY_PATH}.tmp
            mv ${SERVER_DEPLOY_PATH}.tmp/* ${SERVER_DEPLOY_PATH}/
            mv ${SERVER_DEPLOY_PATH}.tmp/.git ${SERVER_DEPLOY_PATH}/ 2>/dev/null || true
            rm -rf ${SERVER_DEPLOY_PATH}.tmp
            cd ${SERVER_DEPLOY_PATH}
            git checkout ${SERVER_BRANCH}
        fi
    EOF
    
    log_info "代码仓库设置完成"
}

# 创建服务器环境变量文件
setup_environment() {
    log_step "设置环境变量..."
    
    # 检查是否需要创建 .env 文件
    $SSH_CMD bash << EOF
        cd ${SERVER_DEPLOY_PATH}
        
        if [ ! -f .env ]; then
            echo "📝 创建 .env 文件..."
            cp .env.example .env 2>/dev/null || touch .env
            
            # 设置基本环境变量
            cat >> .env << 'ENVEOF'
# CEOAgent 服务器环境配置
ENVIRONMENT=${ENVIRONMENT}
LOG_LEVEL=INFO
DATABASE_URL=postgresql://ceoagent:password@postgres:5432/ceoagent
REDIS_URL=redis://redis:6379/0
WEAVIATE_URL=http://weaviate:8080
ANTHROPIC_API_KEY=
ENVEOF
            echo "✅ .env 文件已创建"
        else
            echo "✅ .env 文件已存在"
        fi
    EOF
    
    log_warn "请确保服务器上的 .env 文件包含正确的配置（特别是 ANTHROPIC_API_KEY）"
}

# 构建 Docker 镜像
build_docker_image() {
    log_step "构建 Docker 镜像..."
    
    $SSH_CMD bash << EOF
        cd ${SERVER_DEPLOY_PATH}
        docker-compose build --no-cache || docker compose build --no-cache
    EOF
    
    log_info "Docker 镜像构建完成"
}

# 停止旧服务
stop_old_services() {
    log_step "停止旧服务..."
    
    $SSH_CMD bash << EOF
        cd ${SERVER_DEPLOY_PATH}
        docker-compose down || docker compose down || true
    EOF
    
    log_info "旧服务已停止"
}

# 启动新服务
start_services() {
    log_step "启动服务..."
    
    $SSH_CMD bash << EOF
        cd ${SERVER_DEPLOY_PATH}
        docker-compose up -d || docker compose up -d
    EOF
    
    log_info "服务启动中..."
}

# 等待服务就绪
wait_for_services() {
    log_step "等待服务就绪..."
    
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if $SSH_CMD "curl -f http://localhost:8000/health &>/dev/null"; then
            log_info "服务已就绪！"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    echo ""
    log_error "服务启动超时"
    return 1
}

# 健康检查
health_check() {
    log_step "运行健康检查..."
    
    local health_url="http://${SERVER_IP}:8000/health"
    
    if curl -f "${health_url}" &>/dev/null; then
        log_info "健康检查通过"
        log_info "服务地址: ${health_url}"
        return 0
    else
        log_error "健康检查失败"
        return 1
    fi
}

# 查看服务日志
show_logs() {
    log_step "查看服务日志（最后 20 行）..."
    
    $SSH_CMD bash << EOF
        cd ${SERVER_DEPLOY_PATH}
        docker-compose logs --tail=20 || docker compose logs --tail=20
    EOF
}

# 显示部署信息
show_deployment_info() {
    log_info "════════════════════════════════════════"
    log_info "部署完成！"
    log_info "════════════════════════════════════════"
    log_info "服务器: ${SERVER_IP}"
    log_info "部署路径: ${SERVER_DEPLOY_PATH}"
    log_info "分支: ${SERVER_BRANCH}"
    log_info "环境: ${ENVIRONMENT}"
    log_info ""
    log_info "服务地址:"
    log_info "  - API: http://${SERVER_IP}:8000"
    log_info "  - 健康检查: http://${SERVER_IP}:8000/health"
    log_info "  - API 文档: http://${SERVER_IP}:8000/docs"
    log_info ""
    log_info "管理命令:"
    log_info "  - 查看日志: ssh ${SERVER_USER}@${SERVER_IP} 'cd ${SERVER_DEPLOY_PATH} && docker-compose logs -f'"
    log_info "  - 重启服务: ssh ${SERVER_USER}@${SERVER_IP} 'cd ${SERVER_DEPLOY_PATH} && docker-compose restart'"
    log_info "  - 停止服务: ssh ${SERVER_USER}@${SERVER_IP} 'cd ${SERVER_DEPLOY_PATH} && docker-compose down'"
    log_info "════════════════════════════════════════"
}

# 主函数
main() {
    log_info "开始部署 CEOAgent 到服务器 ${SERVER_IP}"
    log_info "环境: ${ENVIRONMENT}, 分支: ${SERVER_BRANCH}"
    echo ""
    
    check_ssh_connection
    check_server_prerequisites
    setup_repository
    setup_environment
    stop_old_services
    build_docker_image
    start_services
    
    if wait_for_services && health_check; then
        show_deployment_info
        log_info "部署成功！"
    else
        log_error "部署失败，查看日志："
        show_logs
        exit 1
    fi
}

# 执行主函数
main "$@"
