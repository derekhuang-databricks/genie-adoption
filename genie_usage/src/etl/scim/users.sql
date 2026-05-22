-- Curated users view, scoped to workspaces present in genie_usage.
CREATE OR REFRESH MATERIALIZED VIEW users
COMMENT 'Workspace users from SCIM, scoped via genie_usage.workspace_id.'
AS
SELECT u.*
FROM scim_users_raw u
WHERE u.workspace_id IN (SELECT DISTINCT workspace_id FROM genie_usage);
