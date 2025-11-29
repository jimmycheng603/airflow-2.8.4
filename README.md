# Airflow 2.8.4 自定义修改

![Tag 过滤功能截图](filter.jpg)

## 修改说明

### 修改点 1：DAG Tag 过滤逻辑

**文件位置**: `airflow/www/views.py` (第 796-798 行)

**修改内容**: 将 DAG tag 过滤从 OR 逻辑改为 AND 逻辑

**修改前（OR 逻辑）**:

```python
if arg_tags_filter:
    cond = [DagModel.tags.any(DagTag.name == tag) for tag in arg_tags_filter]
    dags_query = dags_query.where(or_(*cond))
```

- 选择多个 tag 时，显示包含**任意一个**选中 tag 的 DAG

**修改后（AND 逻辑）**:

```python
if arg_tags_filter:
    for tag in arg_tags_filter:
        dags_query = dags_query.where(DagModel.tags.any(DagTag.name == tag))
```

- 选择多个 tag 时，只显示**同时包含所有**选中 tag 的 DAG

### 功能说明

**示例场景**:

- DAG A: tags = ['tag1']
- DAG B: tags = ['tag2']
- DAG C: tags = ['tag1', 'tag2']

**选择 `tag1` 和 `tag2` 时的行为**:

- ✅ DAG C: 显示（同时有 tag1 和 tag2）
- ❌ DAG A: 不显示（只有 tag1，没有 tag2）
- ❌ DAG B: 不显示（只有 tag2，没有 tag1）

### 修改点 2：DAGs 列表每页显示条数选择

**文件位置**:

- `airflow/www/views.py` (添加 page_size 参数处理)
- `airflow/www/utils.py` (更新 generate_pages 函数)
- `airflow/www/templates/airflow/dags.html` (添加下拉框)

**修改内容**: 在 DAGs 列表翻页栏旁边添加下拉框，支持选择每页显示的条数

**修改前**:

- 每页显示条数由配置文件 `webserver.page_size` 固定设置
- 用户无法在界面上动态调整每页显示条数

**修改后**:

- 在翻页栏旁边添加"Show:"下拉框
- 支持选择：100、200、500、全部
- 选择后自动刷新页面并应用新的页面大小
- 保持其他筛选条件（搜索、标签、状态等）

**功能说明**:

- 下拉框选项：100、200、500、全部
- 默认值：100（如果配置的 PAGE_SIZE 不在允许值中）
- 切换页面大小时自动重置到第一页
- 保持其他筛选条件（搜索、标签、状态等）

**示例场景**:

- 用户可以选择每页显示 100/200/500 条 DAG，或选择"全部"显示所有 DAG
- 选择后页面会自动刷新并应用新的页面大小

## 部署方式

### 方法 1：使用部署脚本（推荐）

1. **运行部署脚本**

   ```bash
   cd /Users/chengjunjie/Documents/workspace_github/airflow-2.8.4
   ./deploy.sh <环境名称>
   ```

   例如：

   ```bash
   ./deploy.sh yikescheduler
   ```

2. **脚本会自动完成**:

   - 备份原文件（views.py, utils.py, dags.html）
   - 复制修改后的文件
   - 清理 Python 缓存

3. **重启 Airflow webserver**

   ```bash
   conda activate <环境名称>
   airflow webserver --stop
   airflow webserver --port <端口号>
   ```

### 方法 2：手动部署

### 前置条件

1. 确保已安装 Airflow 2.8.4
2. 确认 conda 环境路径正确
3. 确保有文件写入权限

4. **备份原文件**

   ```bash
   ENV_PATH="<环境路径>/lib/python3.10/site-packages/airflow/www"
   TIMESTAMP=$(date +%Y%m%d_%H%M%S)

   cp ${ENV_PATH}/views.py ${ENV_PATH}/views.py.backup.${TIMESTAMP}
   cp ${ENV_PATH}/utils.py ${ENV_PATH}/utils.py.backup.${TIMESTAMP}
   cp ${ENV_PATH}/templates/airflow/dags.html ${ENV_PATH}/templates/airflow/dags.html.backup.${TIMESTAMP}
   ```

5. **复制修改后的文件**

   ```bash
   cp airflow/www/views.py ${ENV_PATH}/views.py
   cp airflow/www/utils.py ${ENV_PATH}/utils.py
   cp airflow/www/templates/airflow/dags.html ${ENV_PATH}/templates/airflow/dags.html
   ```

6. **清理 Python 缓存**

   ```bash
   find ${ENV_PATH} -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
   find ${ENV_PATH} -name "*.pyc" -delete 2>/dev/null || true
   ```

7. **重启 Airflow webserver**

   ```bash
   conda activate <环境名称>
   airflow webserver --stop
   airflow webserver --port <端口号>
   ```
