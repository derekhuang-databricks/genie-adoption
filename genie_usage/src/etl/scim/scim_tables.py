"""Raw SCIM ingestion for users, groups, and group memberships.

Lives in Python because SCIM requires an authenticated API call — SDP SQL cannot
make HTTP requests. Downstream curation lives in ./sql/*.sql.
"""
from datetime import datetime, timezone

from databricks.sdk import WorkspaceClient
from pyspark import pipelines as dp
from pyspark.sql.types import (
    BooleanType,
    IntegerType,
    StringType,
    StructField,
    StructType,
    TimestampType,
)

_w = WorkspaceClient()
_workspace_id = str(_w.get_workspace_id())
_snapshot_ts = datetime.now(timezone.utc)


def _fetch_users():
    return list(_w.users.list(attributes="id,userName,displayName,active"))


def _fetch_groups():
    return list(_w.groups.list(attributes="id,displayName,members"))


@dp.table(
    name="scim_users_raw",
    comment=f"Raw SCIM users for workspace {_workspace_id}; refreshed each pipeline update.",
)
def scim_users_raw():
    users = _fetch_users()
    rows = [
        {
            "workspace_id": _workspace_id,
            "snapshot_ts": _snapshot_ts,
            "user_id": u.id,
            "user_email": (u.user_name or "").lower(),
            "display_name": u.display_name,
            "active": bool(u.active) if u.active is not None else None,
        }
        for u in users
    ]
    schema = StructType([
        StructField("workspace_id", StringType(),    False),
        StructField("snapshot_ts",  TimestampType(), False),
        StructField("user_id",      StringType(),    False),
        StructField("user_email",   StringType(),    True),
        StructField("display_name", StringType(),    True),
        StructField("active",       BooleanType(),   True),
    ])
    return spark.createDataFrame(rows, schema=schema)


@dp.table(
    name="scim_groups_raw",
    comment=f"Raw SCIM groups for workspace {_workspace_id} with member counts.",
)
def scim_groups_raw():
    groups = _fetch_groups()
    rows = [
        {
            "workspace_id": _workspace_id,
            "snapshot_ts": _snapshot_ts,
            "group_id": g.id,
            "group_name": g.display_name,
            "member_count": len(g.members or []),
        }
        for g in groups
    ]
    schema = StructType([
        StructField("workspace_id", StringType(),    False),
        StructField("snapshot_ts",  TimestampType(), False),
        StructField("group_id",     StringType(),    False),
        StructField("group_name",   StringType(),    True),
        StructField("member_count", IntegerType(),   True),
    ])
    return spark.createDataFrame(rows, schema=schema)


@dp.table(
    name="scim_group_members_raw",
    comment=(
        f"Long form (group, member) pairs for workspace {_workspace_id}. "
        "Direct memberships only — nested IdP groups are not expanded."
    ),
)
def scim_group_members_raw():
    groups = _fetch_groups()
    users = _fetch_users()
    user_email = {u.id: (u.user_name or "").lower() for u in users if u.id}

    rows = []
    for g in groups:
        members = g.members or []
        if not members:
            rows.append({
                "workspace_id":   _workspace_id,
                "snapshot_ts":    _snapshot_ts,
                "group_id":       g.id,
                "group_name":     g.display_name,
                "member_id":      None,
                "member_type":    None,
                "member_ref":     None,
                "member_email":   None,
                "member_display": None,
            })
            continue
        for m in members:
            ref = m.ref or ""
            mtype = None
            if "/" in ref:
                prefix = ref.split("/", 1)[0]
                mtype = {
                    "Users": "User",
                    "Groups": "Group",
                    "ServicePrincipals": "ServicePrincipal",
                }.get(prefix, prefix)
            rows.append({
                "workspace_id":   _workspace_id,
                "snapshot_ts":    _snapshot_ts,
                "group_id":       g.id,
                "group_name":     g.display_name,
                "member_id":      m.value,
                "member_type":    mtype,
                "member_ref":     ref,
                "member_email":   user_email.get(m.value) if mtype == "User" else None,
                "member_display": m.display,
            })

    schema = StructType([
        StructField("workspace_id",   StringType(),    False),
        StructField("snapshot_ts",    TimestampType(), False),
        StructField("group_id",       StringType(),    False),
        StructField("group_name",     StringType(),    True),
        StructField("member_id",      StringType(),    True),
        StructField("member_type",    StringType(),    True),
        StructField("member_ref",     StringType(),    True),
        StructField("member_email",   StringType(),    True),
        StructField("member_display", StringType(),    True),
    ])
    return spark.createDataFrame(rows, schema=schema)
