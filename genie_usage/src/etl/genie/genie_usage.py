from pyspark.sql import functions as F
from databricks.sdk import WorkspaceClient
from pyspark import pipelines as dp

ws_id = str(WorkspaceClient().get_workspace_id())
workspace_url = spark.conf.get("spark.databricks.workspaceUrl")

@dp.table(
    name="genie_usage",
    comment=f"Get Genie usage within workspace {ws_id}",
)
@dp.expect_or_fail("workspace_id_not_null", "workspace_id IS NOT NULL")
def genie_usage():
    return (
        spark.table("system.access.audit")
        .filter(F.col("workspace_id") == ws_id)
        .filter(F.col("service_name") == "aibiGenie")
        .filter(F.col("event_date") >= F.date_sub(F.current_date(), 365))
        .withColumn("workspace_url", F.lit(workspace_url))
    )

