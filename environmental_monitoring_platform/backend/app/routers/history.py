from fastapi import APIRouter, Query
from app.schemas import HistoryResponse, HistoryPoint
from app.crud import get_combined_history

router = APIRouter(prefix="/api/history", tags=["Historical Trends"])


@router.get("", response_model=HistoryResponse)
def get_history(
    timeframe: str = Query("24h", description="Time window: 1h, 24h, or 7d"),
    limit: int = Query(50, description="Max points to return")
):
    """
    Retrieve paired historical data points for graphing indoor vs outdoor trends.
    """
    raw_points = get_combined_history(limit=limit)
    points = [HistoryPoint(**p) for p in raw_points]

    return HistoryResponse(
        timeframe=timeframe,
        count=len(points),
        points=points
    )
