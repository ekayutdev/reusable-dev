from fastapi import APIRouter

from app.services.orders import order_total_label

router = APIRouter()


@router.post("/orders/label")
def label(lines: list[tuple[int, int]]) -> dict[str, str]:
    return {"label": order_total_label(lines)}
