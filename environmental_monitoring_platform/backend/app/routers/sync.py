from fastapi import APIRouter
from app.crud import export_database_backup, import_database_backup

router = APIRouter(prefix="/api/sync", tags=["Cloud Backup & Sync"])


@router.get("/backup")
def get_backup():
    """Export complete snapshot of sensor history and configuration for cloud backup."""
    return export_database_backup()


@router.post("/restore")
def restore_backup(payload: dict):
    """Restore database readings and thresholds from a backup payload."""
    counts = import_database_backup(payload)
    return {
        "success": True,
        "message": "Data restored successfully into local database.",
        "restored": counts
    }
