<!-- researched 2026-09-15: python@3.14.7 (docs.python.org/3/library/unittest, /3/library/typing#typing.Protocol, /3/library/dataclasses), pytest@9.1.1 (docs.pytest.org/en/stable/how-to/usage.html) -->
# Stack: python

Python core (no web framework). Framework stacks (Django, FastAPI) have their own files and inherit this one's rules.

## Detection
`pyproject.toml`, `requirements*.txt`, or `setup.py` present, without `django` or `fastapi` in the dependency list.

## Reuse units
- Pure function/domain: one module per domain area, named by domain — `pricing.py`, `dates.py` (verb + noun exports).
- Service class: groups related IO-orchestrating methods behind a constructor-injected client.
- `typing.Protocol`: a structural interface — name it after the role (`Clock`, `OrderStore`) and depend on it, not on a concrete class.
- Frozen dataclass: immutable value object (`@dataclass(frozen=True)`).

## Paths
- `src/<pkg>/` layout, or a root package next to the tests; shared code in `common/`, `core/`, or `shared/` (per config `shared_paths.functions`).
- Domain modules import nothing that does IO. Services receive clients via constructor or parameters.

## Component idioms
Not applicable — no UI. C3–C6 (variant enums, children/slots, rest props/ref, controlled inputs) have no Python equivalent; apply component-design.md only where a UI stack exists in the same repo.

## Logic idioms
- F2 DI: constructor/parameter injection, typed with `Protocol`.
```python
from typing import Protocol


class OrderStore(Protocol):
    def get(self, order_id: str) -> Order: ...


class OrderService:
    def __init__(self, store: OrderStore) -> None:
        self._store = store   # client arrives as an argument, never an import inside logic
```
- F6 `throw` = domain exception classes; `result` = `Ok`/`Err` dataclasses. Pick ONE per config `error_style`, never mix in one module.
```python
# throw style
class OrderNotFoundError(Exception):
    pass


# result style (alternative)
from dataclasses import dataclass
from typing import Union


@dataclass(frozen=True)
class Ok:
    value: "Order"


@dataclass(frozen=True)
class Err:
    message: str


Result = Union[Ok, Err]
```
- F7: type hints on every public function (`def price(cents: int) -> str: ...`).

## Testing
- unittest (stdlib): one module `python3 -m unittest tests.test_pricing`; default suite `python3 -m unittest discover -s tests -t .` (docs.python.org/3/library/unittest).
- pytest (if in deps): one file `pytest tests/test_pricing.py`, one test `pytest tests/test_pricing.py::test_name` (docs.pytest.org/en/stable/how-to/usage.html).
- Tests next to the code or in `tests/` mirroring the package layout.

## Stack-specific anti-patterns
- A catch-all `utils.py` — group by domain (`money.py`, `dates.py`).
- Mutable module-level state (a module-global dict or list mutated at runtime) — pass state explicitly.
- Import-time side effects (connect DB, read env, start threads at module top level).
- `except Exception: pass` — catch the specific domain error or let it propagate.
