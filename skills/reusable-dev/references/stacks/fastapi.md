<!-- researched 2026-09-15: fastapi@0.141.1 (fastapi.tiangolo.com/tutorial/dependencies, /tutorial/bigger-applications, /tutorial/testing), pytest@9.1.1 (docs.pytest.org/en/stable/how-to/usage.html) -->
Read python.md first.

# Stack: fastapi

FastAPI backend. All rules from python.md apply; this file adds the router/service/schema split.

## Detection
`fastapi` in `pyproject.toml` / `requirements*.txt` (detection row 5).

## Reuse units
- Service: a function or class holding business logic, in `app/services/` — the unit a router delegates to and the thing worth reusing.
- Dependency provider: a function consumed via `Depends(...)` (auth, DB session, settings) — one per concern, never inlined per route.
- Pydantic schema: request/response validation model in `app/schemas/` — boundary only, not a domain model.

## Paths
- `app/routers/` (thin adapters over HTTP) → `app/services/` (business logic, could be called from a CLI or job too) → `app/domain/` (pure logic, no IO).
- Shared helpers used by several services in `app/shared/` (per config `shared_paths.functions`).
- `app/schemas/` for Pydantic models; `app/dependencies.py` (or `app/deps.py`) for providers.

## Component idioms
Not applicable — no UI. C3–C6 have no FastAPI equivalent; apply component-design.md only where a UI stack exists in the same repo.

## Logic idioms
- F2 DI: services receive collaborators via constructor/parameter injection (per python.md); only path operations and dependency providers use `Depends()` (fastapi.tiangolo.com/tutorial/dependencies).
```python
from typing import Annotated

from fastapi import APIRouter, Depends

from app.dependencies import get_report_service
from app.services.reports import ReportService

router = APIRouter()


@router.post("/reports/summary")
def summary(
    buckets: list[str],
    service: Annotated[ReportService, Depends(get_report_service)],
) -> dict[str, str]:
    return {"summary": service.summarize(buckets)}   # path operation stays thin
```
- Thin routers: parse and validate input, delegate to a service, shape the response. Business logic in a path operation body is a copy no CLI or job can reuse.

## Testing
- Pure services and domain functions: unittest or pytest, no FastAPI involved — `python3 -m unittest discover -s tests -t .` or `pytest tests/test_services.py`.
- Routes: `fastapi.testclient.TestClient` — `client = TestClient(app)` then `client.post("/reports/summary", json=...)` (fastapi.tiangolo.com/tutorial/testing; requires `httpx` installed).
- Single-file commands per config `commands.test`; use exactly what is configured.

## Stack-specific anti-patterns
- Business logic inside path operations — move it to a service the router calls.
- A module-level shared DB Session — create the engine once (module level or lifespan) and yield a Session per request via `Depends()`.
- Pydantic schemas reused as domain models in every layer — domain code takes plain data; convert at the boundary.
- Fat `routers/` module doing parse + logic + persistence; split adapters from services.
