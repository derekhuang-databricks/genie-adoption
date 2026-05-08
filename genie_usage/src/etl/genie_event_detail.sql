CREATE OR REFRESH MATERIALIZED VIEW genie_event_detail
TBLPROPERTIES ('delta.feature.timestampNtz' = 'supported')
AS
-- Create Space
SELECT
    workspace_id,
    concat('https://', workspace_url) as workspace_url,
    date_trunc('second', convert_timezone('UTC', 'Australia/Melbourne', event_time)) as event_time_local_tz,
    identity_metadata.run_as as user,
    from_json(response.result, 'MAP<STRING, STRING>').space_id as space_id,
    concat('https://', workspace_url, '/genie/rooms/', space_id, '?o=', workspace_id) as genie_link,
    'Create Space' as action,
    action_name,
    null as feedback_rating,
    CASE
        WHEN user_agent LIKE '%AppleWebKit%' OR user_agent LIKE '%Chrome%' OR user_agent LIKE '%Mozilla%' OR user_agent LIKE '%Safari%' THEN 'Genie UI (Browser)'
        WHEN user_agent LIKE '%databricks-sdk%' AND user_agent LIKE '%auth/model-serving%' THEN 'Model Serving / Agent'
        WHEN user_agent LIKE '%databricks-sdk%' AND user_agent LIKE '%auth/oauth-m2m%' THEN 'Service Principal (M2M)'
        WHEN user_agent LIKE '%databricks-sdk%' AND user_agent LIKE '%runtime/client%' THEN 'Databricks Runtime'
        WHEN user_agent LIKE '%databricks-sdk%' THEN 'REST API (SDK)'
        WHEN user_agent LIKE '%python-requests%' OR user_agent LIKE '%python-httpx%' OR user_agent LIKE '%aiohttp%' THEN 'REST API (Python)'
        WHEN user_agent LIKE '%DatabricksOpenAI%' THEN 'OpenAI-Compatible API'
        WHEN user_agent LIKE '%curl%' THEN 'REST API (curl)'
        ELSE 'Other'
    END AS interaction_channel
FROM
    genie_usage
WHERE
    action_name IN (
        'createSpace',
        'genieCreateSpace'
    )
UNION
-- Provide Feedback
SELECT
    workspace_id,
    concat('https://', workspace_url) as workspace_url,
    date_trunc('second', convert_timezone('UTC', 'Australia/Melbourne', event_time)) as event_time_local_tz,
    identity_metadata.run_as as user,
    request_params.space_id,
    concat('https://', workspace_url, '/genie/rooms/', request_params.space_id, '/monitoring?o=', workspace_id, '&mc=', request_params.conversation_id) as genie_link,
    'Ask Question' as action,
    action_name,
    null as feedback_rating,
    CASE
        WHEN user_agent LIKE '%AppleWebKit%' OR user_agent LIKE '%Chrome%' OR user_agent LIKE '%Mozilla%' OR user_agent LIKE '%Safari%' THEN 'Genie UI (Browser)'
        WHEN user_agent LIKE '%databricks-sdk%' AND user_agent LIKE '%auth/model-serving%' THEN 'Model Serving / Agent'
        WHEN user_agent LIKE '%databricks-sdk%' AND user_agent LIKE '%auth/oauth-m2m%' THEN 'Service Principal (M2M)'
        WHEN user_agent LIKE '%databricks-sdk%' AND user_agent LIKE '%runtime/client%' THEN 'Databricks Runtime'
        WHEN user_agent LIKE '%databricks-sdk%' THEN 'REST API (SDK)'
        WHEN user_agent LIKE '%python-requests%' OR user_agent LIKE '%python-httpx%' OR user_agent LIKE '%aiohttp%' THEN 'REST API (Python)'
        WHEN user_agent LIKE '%DatabricksOpenAI%' THEN 'OpenAI-Compatible API'
        WHEN user_agent LIKE '%curl%' THEN 'REST API (curl)'
        ELSE 'Other'
    END AS interaction_channel
FROM
    genie_usage
WHERE
    action_name IN (
        'createConversationMessage',
        'genieCreateConversationMessage',
        'genieStartConversationMessage'
    )
UNION
-- Ask Question
SELECT
    workspace_id,
    concat('https://', workspace_url) as workspace_url,
    date_trunc('second', convert_timezone('UTC', 'Australia/Melbourne', event_time)) as event_time_local_tz,
    identity_metadata.run_as as user,
    request_params.space_id,
    concat('https://', workspace_url, '/genie/rooms/', request_params.space_id, '/monitoring?o=', workspace_id, '&mc=', request_params.conversation_id, '&m=', request_params.message_id) as genie_link,
    'Provide Feedback' as action,
    action_name,
    request_params.feedback_rating,
    CASE
        WHEN user_agent LIKE '%AppleWebKit%' OR user_agent LIKE '%Chrome%' OR user_agent LIKE '%Mozilla%' OR user_agent LIKE '%Safari%' THEN 'Genie UI (Browser)'
        WHEN user_agent LIKE '%databricks-sdk%' AND user_agent LIKE '%auth/model-serving%' THEN 'Model Serving / Agent'
        WHEN user_agent LIKE '%databricks-sdk%' AND user_agent LIKE '%auth/oauth-m2m%' THEN 'Service Principal (M2M)'
        WHEN user_agent LIKE '%databricks-sdk%' AND user_agent LIKE '%runtime/client%' THEN 'Databricks Runtime'
        WHEN user_agent LIKE '%databricks-sdk%' THEN 'REST API (SDK)'
        WHEN user_agent LIKE '%python-requests%' OR user_agent LIKE '%python-httpx%' OR user_agent LIKE '%aiohttp%' THEN 'REST API (Python)'
        WHEN user_agent LIKE '%DatabricksOpenAI%' THEN 'OpenAI-Compatible API'
        WHEN user_agent LIKE '%curl%' THEN 'REST API (curl)'
        ELSE 'Other'
    END AS interaction_channel
FROM
    genie_usage
WHERE
    action_name IN (
        'updateConversationMessageFeedback',
        'createConversationMessageComment'
    )
GROUP BY ALL
ORDER BY event_time_local_tz;