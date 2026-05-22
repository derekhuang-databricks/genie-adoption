-- Curated groups view, scoped to workspaces present in genie_usage.
CREATE OR REFRESH MATERIALIZED VIEW groups
COMMENT 'Workspace groups from SCIM, scoped via genie_usage.workspace_id.'
AS
SELECT g.*
FROM scim_groups_raw g
WHERE g.workspace_id IN (SELECT DISTINCT workspace_id FROM genie_usage);
