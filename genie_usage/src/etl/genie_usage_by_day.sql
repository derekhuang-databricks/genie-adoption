CREATE OR REFRESH MATERIALIZED VIEW genie_usage_by_day
TBLPROPERTIES ('delta.feature.timestampNtz' = 'supported')
AS
WITH by_day AS (
    SELECT
        workspace_id,
        convert_timezone('UTC', 'Australia/Melbourne', event_date) as event_date,
        TRUNC(convert_timezone('UTC', 'Australia/Melbourne', event_date), 'MM') as event_month,
        TO_DATE(DATE_TRUNC('WEEK', convert_timezone('UTC', 'Australia/Melbourne', event_date))) as event_week,
        -- Metrics
        COUNT(DISTINCT identity_metadata.run_as) as active_users,
        COUNT(DISTINCT CASE WHEN action_name = 'createSpace' THEN request_params.space_id END) + COUNT(DISTINCT CASE WHEN action_name = 'genieCreateSpace' THEN request_params.space_id END) as spaces_created,
        COUNT(CASE WHEN action_name IN ('createConversationMessage','genieCreateConversationMessage','genieStartConversationMessage') THEN 1 END) as questions_asked,
        COUNT(CASE WHEN action_name IN ('updateConversationMessageFeedback','genieSendMessageFeedback') THEN 1 END) as feedback_events
    FROM
        genie_usage
    GROUP BY ALL
)
SELECT
    *
FROM
    by_day
WHERE
    spaces_created > 0
OR
    questions_asked > 0
OR
    feedback_events > 0
;