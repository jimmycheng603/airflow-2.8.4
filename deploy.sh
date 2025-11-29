#!/bin/bash

# Airflow 2.8.4 自定义修改部署脚本
# 使用方法: ./deploy.sh <环境名称>
# 例如: ./deploy.sh yikescheduler

set -e

if [ -z "$1" ]; then
    echo "错误: 请指定 conda 环境名称"
    echo "使用方法: $0 <环境名称>"
    echo "例如: $0 yikescheduler"
    echo ""
    echo "可用的环境:"
    echo "  - yikescheduler"
    exit 1
fi

ENV_NAME=$1
CONDA_BASE="/Users/chengjunjie/Documents/softwares/anaconda3"
ENV_PATH="${CONDA_BASE}/envs/${ENV_NAME}"

# 检查环境是否存在
if [ ! -d "$ENV_PATH" ]; then
    echo "错误: 环境 '$ENV_NAME' 不存在于 $ENV_PATH"
    exit 1
fi

# 查找 Python 版本和 site-packages 路径
PYTHON_VERSION=$(ls -d ${ENV_PATH}/lib/python* 2>/dev/null | head -1 | xargs basename)
SITE_PACKAGES="${ENV_PATH}/lib/${PYTHON_VERSION}/site-packages"
AIRFLOW_WWW="${SITE_PACKAGES}/airflow/www"

# 检查 Airflow 是否安装
if [ ! -d "$AIRFLOW_WWW" ]; then
    echo "错误: 在环境 '$ENV_NAME' 中未找到 Airflow 安装"
    exit 1
fi

echo "=========================================="
echo "部署 Airflow 修改到环境: $ENV_NAME"
echo "Python 版本: $PYTHON_VERSION"
echo "Airflow 路径: $AIRFLOW_WWW"
echo "=========================================="
echo ""

# 获取当前时间戳
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 1. 备份原文件
echo "1. 备份原文件..."
BACKUP_DIR="${AIRFLOW_WWW}/backup_${TIMESTAMP}"
mkdir -p "$BACKUP_DIR"

if [ -f "${AIRFLOW_WWW}/views.py" ]; then
    cp "${AIRFLOW_WWW}/views.py" "${BACKUP_DIR}/views.py.backup"
    echo "   ✓ 已备份 views.py -> ${BACKUP_DIR}/views.py.backup"
fi

if [ -f "${AIRFLOW_WWW}/utils.py" ]; then
    cp "${AIRFLOW_WWW}/utils.py" "${BACKUP_DIR}/utils.py.backup"
    echo "   ✓ 已备份 utils.py -> ${BACKUP_DIR}/utils.py.backup"
fi

if [ -f "${AIRFLOW_WWW}/templates/airflow/dags.html" ]; then
    mkdir -p "${BACKUP_DIR}/templates/airflow"
    cp "${AIRFLOW_WWW}/templates/airflow/dags.html" "${BACKUP_DIR}/templates/airflow/dags.html.backup"
    echo "   ✓ 已备份 dags.html -> ${BACKUP_DIR}/templates/airflow/dags.html.backup"
fi

echo ""

# 2. 复制修改后的文件
echo "2. 复制修改后的文件..."

# 复制 views.py
if [ -f "airflow/www/views.py" ]; then
    cp "airflow/www/views.py" "${AIRFLOW_WWW}/views.py"
    echo "   ✓ 已复制 views.py"
else
    echo "   ✗ 错误: 找不到 airflow/www/views.py"
    exit 1
fi

# 复制 utils.py
if [ -f "airflow/www/utils.py" ]; then
    cp "airflow/www/utils.py" "${AIRFLOW_WWW}/utils.py"
    echo "   ✓ 已复制 utils.py"
else
    echo "   ✗ 错误: 找不到 airflow/www/utils.py"
    exit 1
fi

# 复制 dags.html
if [ -f "airflow/www/templates/airflow/dags.html" ]; then
    mkdir -p "${AIRFLOW_WWW}/templates/airflow"
    cp "airflow/www/templates/airflow/dags.html" "${AIRFLOW_WWW}/templates/airflow/dags.html"
    echo "   ✓ 已复制 dags.html"
else
    echo "   ✗ 错误: 找不到 airflow/www/templates/airflow/dags.html"
    exit 1
fi

echo ""

# 3. 清理 Python 缓存
echo "3. 清理 Python 缓存..."
find "${AIRFLOW_WWW}" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "${AIRFLOW_WWW}" -name "*.pyc" -delete 2>/dev/null || true
find "${AIRFLOW_WWW}" -name "*.pyo" -delete 2>/dev/null || true
echo "   ✓ 已清理缓存文件"

echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo ""
echo "备份文件位置: $BACKUP_DIR"
echo ""
echo "下一步操作:"
echo "1. 重启 Airflow webserver:"
echo "   conda activate $ENV_NAME"
echo "   airflow webserver --stop"
echo "   airflow webserver --port <端口号>"
echo ""
echo "2. 或者如果使用 systemd/supervisor 管理:"
echo "   systemctl restart airflow-webserver"
echo "   或"
echo "   supervisorctl restart airflow-webserver"
echo ""

