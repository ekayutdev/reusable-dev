<!-- researched 2026-09-15: django@6.1.1 (docs.djangoproject.com/en/stable/intro/reusable-apps, /topics/db/managers, /howto/custom-template-tags, /ref/templates/builtins, /topics/testing/overview) -->
Read python.md first.

# Stack: django

Django backend (ORM, templates, admin). All rules from python.md apply; this file adds the app/service split and template reuse.

## Detection
`manage.py`, or `django` in `pyproject.toml` / `requirements*.txt` (detection row 4).

## Reuse units
- Reusable app: a self-contained app installed via `INSTALLED_APPS` — the unit that can move between projects (docs.djangoproject.com/en/stable/intro/reusable-apps).
- Service module: per-app `services.py` (business logic) and `selectors.py` (queries) — plain functions a view, command, or job delegates to.
- Custom `Manager` / `QuerySet` methods: "table-level" model functionality, chainable (docs.djangoproject.com/en/stable/topics/db/managers).
- Template partial (`{% include %}`) and inclusion tag: template reuse (docs.djangoproject.com/en/stable/ref/templates/builtins, /howto/custom-template-tags).

## Paths
- Feature apps at the project root (`accounts/`, `reports/`); shared logic in a `common/` or `core/` app with its own `__init__.py` (per config `shared_paths.functions`).
- Shared templates in `common/templates/common/` (per config `shared_paths.components`) — the `common/` prefix stops name collisions.
- Skip `migrations/` — generated, never a reuse source.

## Component idioms (C3-C6)
- C3 variants: an inclusion tag takes a `variant` argument — one tag, every look, no per-look copies (docs.djangoproject.com/en/stable/howto/custom-template-tags).
```python
# common/templatetags/common_tags.py
@register.inclusion_tag("common/button.html")
def button(label, variant="primary"):
    return {"label": label, "variant": variant}
```
- Pass the variant and nothing else at the call site — `only` renders the partial with exactly the given variables (docs.djangoproject.com/en/stable/ref/templates/builtins):
```django
{% include "common/button.html" with label="Delete" variant="danger" only %}
```
- No copy-and-tweak templates (`button_danger.html` beside `button.html`); C7: no hardcoded colors in the partial — variants map to CSS classes.

## Logic idioms
- Business logic lives in `services.py`, never in views, signals, or `Model.save()` — a view is an adapter like a router.
- Reusable queries are `QuerySet` methods, composable by name:
```python
class TenantQuerySet(models.QuerySet):
    def active(self) -> "TenantQuerySet":
        return self.filter(deleted_at__isnull=True)
```
- F2: pass collaborators (mailer, clock, store) into service functions as arguments, per python.md — never module-level singletons inside logic.

## Testing
- `python manage.py test reports.tests.test_summary` — one app, module, class, or method (docs.djangoproject.com/en/stable/topics/testing/overview).
- Plain-Python services in `services.py` test with `unittest` alone, no Django settings — per python.md.
- Use exactly what config `commands.test` specifies.

## Stack-specific anti-patterns
- Fat views — parse and delegate in the view; logic goes to a service.
- Business logic in signals or `Model.save()` — call sites invisible to readers.
- Feature apps importing each other's internals (`accounts` reaching into `reports.services`) — share via `common/`.
- Copy-and-tweak templates — one partial with a `variant` instead.
