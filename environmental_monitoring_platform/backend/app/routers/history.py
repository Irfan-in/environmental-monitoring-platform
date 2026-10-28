from typing import Optional, List
from fastapi import APIRouter, Query
from app.schemas import HistoryResponse, HistoryPoint
from app.crud import get_combined_history, get_recorded_history_dates

router = APIRouter(prefix="/api/history", tags=["Historical Trends"])


@router.get("/dates")
def get_history_dates():
    """
    Retrieve distinct dates (YYYY-MM-DD) that have recorded sensor telemetry in SQLite.
    Used by the app calendar to display availability indicators under dates.
    """
    return {"dates": get_recorded_history_dates()}


@router.get("", response_model=HistoryResponse)
def get_history(
    timeframe: str = Query("24h", description="Time window: 1h, 24h, or 7d"),
    limit: int = Query(500, description="Max points to return"),
    date: Optional[str] = Query(None, description="Target calendar date (YYYY-MM-DD)")
):
    """
    Retrieve paired historical data points for graphing indoor vs outdoor trends.
    Supports filtering by calendar date for historical day-by-day browsing.
    """
    raw_points = get_combined_history(limit=limit, target_date=date)
    points = [HistoryPoint(**p) for p in raw_points]

    return HistoryResponse(
        timeframe=timeframe,
        count=len(points),
        points=points
    )
