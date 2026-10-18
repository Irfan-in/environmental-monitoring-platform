from typing import Optional
from fastapi import APIRouter, Query
from app.schemas import HistoryResponse, HistoryPoint
from app.crud import get_combined_history

router = APIRouter(prefix="/api/history", tags=["Historical Trends"])


@router.get("", response_model=HistoryResponse)
def get_history(
    timeframe: str = Query("24h", description="Time window: 1h, 24h, or 7d"),
    limit: int = Query(50, description="Max points to return"),
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
