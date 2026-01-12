#!/bin/bash
# CEOAgent 自动部署脚本

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置变量
NAMESPACE="${NAMESPACE:-ceoagent}"
ENVIRONMENT="${ENVIRONMENT:-production}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
KUBECONFIG_PATH="${KUBECONFIG_PATH:-}"

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

# 检查前置条件
check_prerequisites() {
    log_info "检查前置条件..."
    
    # 检查 kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl 未安装"
        exit 1
    fi
    
    # 检查 kubeconfig
    if [ -n "$KUBECONFIG_PATH" ]; then
        export KUBECONFIG="$KUBECONFIG_PATH"
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "无法连接到 Kubernetes 集群"
        exit 1
    fi
    
    log_info "前置条件检查通过"
}

# 创建命名空间
create_namespace() {
    log_info "创建命名空间: $NAMESPACE"
    
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_warn "命名空间 $NAMESPACE 已存在"
    else
        kubectl create namespace "$NAMESPACE"
        log_info "命名空间 $NAMESPACE 创建成功"
    fi
}

# 创建 Secrets
create_secrets() {
    log_info "检查 Secrets..."
    
    if kubectl get secret ceoagent-secrets -n "$NAMESPACE" &> /dev/null; then
        log_warn "Secret ceoagent-secrets 已存在，跳过创建"
    else
        log_warn "请使用以下命令创建 Secret:"
        echo "kubectl create secret generic ceoagent-secrets \\"
        echo "  --from-literal=database-url='...' \\"
        echo "  --from-literal=anthropic-api-key='...' \\"
        echo "  --from-literal=encryption-key='...' \\"
        echo "  -n $NAMESPACE"
        read -p "是否现在创建？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kubectl create secret generic ceoagent-secrets \
                --from-literal=database-url="${DATABASE_URL:-}" \
                --from-literal=anthropic-api-key="${ANTHROPIC_API_KEY:-}" \
                --from-literal=encryption-key="${ENCRYPTION_KEY:-}" \
                -n "$NAMESPACE"
            log_info "Secret 创建成功"
        fi
    fi
}

# 部署 ConfigMap
deploy_configmap() {
    log_info "部署 ConfigMap..."
    
    kubectl apply -f k8s/base/configmap.yaml -n "$NAMESPACE"
    log_info "ConfigMap 部署成功"
}

# 更新镜像标签
update_image_tag() {
    log_info "更新镜像标签为: $IMAGE_TAG"
    
    # 使用 sed 或 yq 更新镜像标签
    if command -v yq &> /dev/null; then
        yq eval ".spec.template.spec.containers[0].image = \"ghcr.io/OWNER/CEOAgent:$IMAGE_TAG\"" \
            -i k8s/base/deployment.yaml
    else
        log_warn "未安装 yq，请手动更新 deployment.yaml 中的镜像标签"
    fi
}

# 部署应用
deploy_application() {
    log_info "部署应用..."
    
    # 应用所有资源
    kubectl apply -f k8s/base/deployment.yaml -n "$NAMESPACE"
    kubectl apply -f k8s/base/service.yaml -n "$NAMESPACE"
    kubectl apply -f k8s/base/ingress.yaml -n "$NAMESPACE"
    kubectl apply -f k8s/base/hpa.yaml -n "$NAMESPACE"
    
    log_info "应用资源部署完成"
}

# 等待部署完成
wait_for_deployment() {
    log_info "等待部署完成..."
    
    kubectl rollout status deployment/ceoagent-api -n "$NAMESPACE" --timeout=5m
    
    if [ $? -eq 0 ]; then
        log_info "部署成功！"
    else
        log_error "部署失败或超时"
        kubectl rollout undo deployment/ceoagent-api -n "$NAMESPACE"
        exit 1
    fi
}

# 运行健康检查
health_check() {
    log_info "运行健康检查..."
    
    # 获取 Pod IP
    POD_IP=$(kubectl get pods -n "$NAMESPACE" -l app=ceoagent-api -o jsonpath='{.items[0].status.podIP}')
    
    if [ -z "$POD_IP" ]; then
        log_error "未找到运行中的 Pod"
        return 1
    fi
    
    # 端口转发进行健康检查
    kubectl port-forward -n "$NAMESPACE" deployment/ceoagent-api 8000:8000 &
    PORT_FORWARD_PID=$!
    
    sleep 5
    
    if curl -f http://localhost:8000/health &> /dev/null; then
        log_info "健康检查通过"
        kill $PORT_FORWARD_PID 2>/dev/null || true
        return 0
    else
        log_error "健康检查失败"
        kill $PORT_FORWARD_PID 2>/dev/null || true
        return 1
    fi
}

# 回滚部署
rollback() {
    log_warn "回滚部署..."
    kubectl rollout undo deployment/ceoagent-api -n "$NAMESPACE"
    log_info "回滚完成"
}

# 主函数
main() {
    log_info "开始部署 CEOAgent 到 $ENVIRONMENT 环境"
    
    check_prerequisites
    create_namespace
    create_secrets
    deploy_configmap
    update_image_tag
    deploy_application
    wait_for_deployment
    
    if health_check; then
        log_info "部署完成并验证成功！"
    else
        log_error "健康检查失败，执行回滚..."
        rollback
        exit 1
    fi
}

# 执行主函数
main "$@"
