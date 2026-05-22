-- Per-user group aggregation; join key for genie_event_detail.user (identity_metadata.run_as).
CREATE OR REFRESH MATERIALIZED VIEW user_groups
COMMENT 'Per-user list of group memberships. Joinable on member_email = genie_event_detail.user.'
AS
SELECT
    workspace_id,
    member_email,
    collect_set(group_name)     AS groups,
    count(DISTINCT group_id)    AS group_count
FROM group_members
WHERE member_type = 'User'
  AND member_email IS NOT NULL
GROUP BY workspace_id, member_email;
