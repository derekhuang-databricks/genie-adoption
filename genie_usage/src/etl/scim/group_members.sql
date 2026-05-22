-- Long-form group membership; direct memberships only (nested IdP groups are not expanded).
CREATE OR REFRESH MATERIALIZED VIEW group_members
COMMENT 'One row per (group, member). Scoped via genie_usage.workspace_id.'
AS
SELECT gm.*
FROM scim_group_members_raw gm
WHERE gm.workspace_id IN (SELECT DISTINCT workspace_id FROM genie_usage);
