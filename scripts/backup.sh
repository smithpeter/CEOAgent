#!/bin/bash
# 数据库备份脚本

set -euo pipefail

# 配置
BACKUP_DIR="${BACKUP_DIR:-./backups}"
DATE=$(date +%Y%m%d_%H%M%S)
NAMESPACE="${NAMESPACE:-ceoagent}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# PostgreSQL 备份
backup_postgres() {
    log_info "备份 PostgreSQL 数据库..."
    
    POSTGRES_POD=$(kubectl get pods -n "$NAMESPACE" -l app=postgres -o jsonpath='{.items[0].metadata.name}')
    
    if [ -z "$POSTGRES_POD" ]; then
        log_warn "未找到 PostgreSQL Pod，跳过备份"
        return
    fi
    
    BACKUP_FILE="$BACKUP_DIR/postgres_backup_$DATE.sql"
    
    kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" -- \
        pg_dump -U ceoagent ceoagent > "$BACKUP_FILE"
    
    # 压缩备份
    gzip "$BACKUP_FILE"
    
    log_info "PostgreSQL 备份完成: ${BACKUP_FILE}.gz"
}

# Weaviate 备份
backup_weaviate() {
    log_info "备份 Weaviate 数据..."
    
    WEAVIATE_POD=$(kubectl get pods -n "$NAMESPACE" -l app=weaviate -o jsonpath='{.items[0].metadata.name}')
    
    if [ -z "$WEAVIATE_POD" ]; then
        log_warn "未找到 Weaviate Pod，跳过备份"
        return
    fi
    
    # 使用 Weaviate 备份 API
    BACKUP_ID="backup-$DATE"
    
    kubectl port-forward -n "$NAMESPACE" "$WEAVIATE_POD" 8080:8080 &
    PORT_FORWARD_PID=$!
    sleep 3
    
    curl -X POST "http://localhost:8080/v1/backups/filesystem" \
        -H "Content-Type: application/json" \
        -d "{\"id\": \"$BACKUP_ID\"}" || true
    
    kill $PORT_FORWARD_PID 2>/dev/null || true
    
    log_info "Weaviate 备份完成: $BACKUP_ID"
}

# 清理旧备份
cleanup_old_backups() {
    log_info "清理 $RETENTION_DAYS 天前的备份..."
    
    find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete
    
    log_info "清理完成"
}

# 主函数
main() {
    log_info "开始备份..."
    
    backup_postgres
    backup_weaviate
    cleanup_old_backups
    
    log_info "备份完成！"
}

main "$@"
