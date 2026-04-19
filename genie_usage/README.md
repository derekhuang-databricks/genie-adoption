# Genie Usage Dashboard

A Declarative Automation Bundle that tracks AI/BI Genie usage within your workspace. It creates a materialized view from `system.access.audit` and powers a AI/BI (Lakeview) dashboard showcasing Genie usage metrics.

## What's Included

- **ETL Pipeline** -- A serverless Spark Declarative Pipeline that creates a `genie_usage` materialized view from audit logs, filtered to the current workspace
- **Dashboard** -- A Lakeview dashboard showing active users from the following Genie events - spaces created, questions asked, feedback submitted
- **Scheduled Job** -- A workflow that refreshes the pipeline and dashboard on a schedule (weekdays at 9am and 1pm Melbourne time, trigger is paused by default)

## Prerequisites

- Databricks workspace with Unity Catalog enabled
- Access to `system.access.audit` system table (requires metastore admin or explicit `SELECT` grant)
- A SQL warehouse for the dashboard
- A catalog and schema to store the materialized view (the schema must already exist)

## Setup

### 1. Configure `databricks.yml`

Replace the placeholder values in the `dev` target (and optionally `prod`):

| Placeholder | Where | Description | Example |
|---|---|---|---|
| `<your-workspace-url>` | `databricks.yml` | Your Databricks workspace URL | `https://my-workspace.cloud.databricks.com` |
| `<your-catalog>` | `databricks.yml` | Catalog for the materialized view | `main` |
| `<your-schema>` | `databricks.yml` | Schema for the materialized view | `genie_usage` |
| `<your-warehouse-id>` | `resources/dashboard.dashboard.yml` | SQL warehouse ID for the dashboard | `abcd1234efgh5678` |

To find your SQL warehouse ID: open **SQL Warehouses** in the Databricks UI, click your warehouse, and copy the ID from the **Connection Details** tab or the URL.

### 2. Configure the prod target (optional)

If you plan to deploy to production, also replace the `<service-principal>` placeholder in `databricks.yml` with the application ID of a service principal that will own the production deployment:

| Placeholder | Description |
|---|---|
| `<service-principal>` | Application ID of the service principal for production (used in `run_as`, `permissions`, and `root_path`) |

### 3. Adjust the schedule (optional)

In `resources/workflow.job.yml`, you can:
- Change the cron expression and `timezone_id` to match your preferred schedule
- Uncomment `email_notifications` and set your email address to receive failure alerts
- Set `pause_status: UNPAUSED` when you're ready to run on a schedule

### 4. Deploy

```bash
databricks bundle deploy --target dev
```

### 5. Run

Run the job to refresh the pipeline and dashboard:

```bash
databricks bundle run genie_usage_job --target dev
```

Or start just the pipeline from the Databricks UI by navigating to the pipeline and clicking **Start**.

## How It Works

The ETL pipeline dynamically detects the current workspace ID at runtime using the Databricks SDK (`WorkspaceClient().get_workspace_id()`), then queries `system.access.audit` for all Genie-related events in the last 365 days. See https://docs.databricks.com/aws/en/ai-bi/admin/audit for example queries that are used.

No hardcoded workspace IDs needed -- it works automatically in any workspace where it's deployed.

The dashboard catalog and schema are set by the bundle variables at deploy time -- you do not need to edit the dashboard JSON file directly.

## Project Structure

```
genie_usage/
├── databricks.yml                  # Bundle configuration and target definitions
├── resources/
│   ├── etl.pipeline.yml            # Serverless SDP pipeline definition
│   ├── workflow.job.yml            # Scheduled job (pipeline + dashboard refresh)
│   └── dashboard.dashboard.yml     # Lakeview dashboard definition
└── src/
    ├── etl/
    │   └── genie_event_detail.sql   # Detailed info for each Genie event
    │   └── genie_usage.py   # Pipeline source: materialized view from audit logs
    │   └── genie_usage_by_day.sql   # Get aggregated daily event metrics in Genie space
    └── dashboard/
        └── [Working Copy] Genie Usage Dashboard.lvdash.json
```
