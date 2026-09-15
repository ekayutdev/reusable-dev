<!-- researched 2026-09-15: django@6.1.1 (docs.djangoproject.com/en/stable/intro/reusable-apps, /topics/db/managers, /howto/custom-template-tags, /ref/templates/builtins, /releases/6.0, /topics/testing/overview) -->
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
- Inline partial `{% partialdef %}` / `{% partial %}` (Django 6.0+): a named fragment defined and rendered inside one template (docs.djangoproject.com/en/stable/releases/6.0, /ref/templates/builtins).

## Paths
- Feature apps at the project root (`accounts/`, `reports/`); shared logic in a `common/` or `core/` app with its own `__init__.py` (per config `shared_paths.functions`).
- Add the shared app to `INSTALLED_APPS` — needed for its templates and `{% load %}` (docs.djangoproject.com/en/stable/howto/custom-template-tags).
- Shared templates in `common/templates/common/` (per config `shared_paths.components`) — the `common/` prefix stops name collisions.
- Skip `migrations/` — generated, never a reuse source.

## Component idioms
- C3 variants: an inclusion tag takes a `variant` argument — one tag, every look, no per-look copies (docs.djangoproject.com/en/stable/howto/custom-template-tags). The tag module lives in `common/templatetags/common_tags.py` with a `templatetags/__init__.py` beside it:
```python
# common/templatetags/common_tags.py
from django import template

register = template.Library()


@register.inclusion_tag("common/button.html")
def button(label, variant="primary"):
    return {"label": label, "variant": variant}
```
- Load the library before using the tag (docs.djangoproject.com/en/stable/howto/custom-template-tags):
```django
{% load common_tags %}
{% button "Delete" variant="danger" %}
```
- `{% include %}`: pass only what the partial needs at the call site — `only` renders the partial with exactly the given variables (docs.djangoproject.com/en/stable/ref/templates/builtins):
```django
{% include "common/button.html" with label="Delete" variant="danger" only %}
```
- C4: content goes through a `{% block %}` in a base partial used with `{% extends %}` (or is passed pre-rendered); `{% include %}` has no slots.
- C5: accept an `attrs`/`class` argument rendered on the root element; refs do not apply to server templates.
- C6: a field's value comes from the bound form (`data`), its default from `initial`; customize a widget by subclassing it with its own `template_name` (or enable `FORM_RENDERER = "django.forms.renderers.TemplatesSetting"` to override built-in widget templates) instead of copying forms.
- No copy-and-tweak templates (`button_danger.html` beside `button.html`); C7: no hardcoded colors in the partial — variants map to CSS classes.

## Logic idioms
- Business logic lives in `services.py`, never in views or signals — a view is an adapter like a router. Single-row invariants may live on the model (`Model.save()`); cross-model workflows go in services.
- F6: services raise domain exceptions (per python.md); views map them to `Http404` or form errors — services never raise `Http404`.
- Reusable queries are `QuerySet` methods, composable by name (docs.djangoproject.com/en/stable/topics/db/managers):
```python
from django.db import models


class TenantQuerySet(models.QuerySet):
    def active(self) -> "TenantQuerySet":
        return self.filter(deleted_at__isnull=True)


class Tenant(models.Model):
    objects = TenantQuerySet.as_manager()
```
- `selectors.py` composes QuerySet methods into named reads — not a second home for filters.
- F2: pass collaborators (mailer, clock, store) into service functions as arguments, per python.md — never module-level singletons inside logic.

## Testing
- `python3 manage.py test reports.tests.test_summary` — one app, module, class, or method (docs.djangoproject.com/en/stable/topics/testing/overview).
- Plain-Python services in `services.py` test with `unittest` alone, no Django settings — per python.md.
- Use exactly what config `commands.test` specifies; if it is empty, run no test command and report `T2 skipped (no command)` (commands above are examples for filling the config).

## Stack-specific anti-patterns
- Fat views — parse and delegate in the view; logic goes to a service.
- Business logic in signals — call sites invisible to readers.
- Reaching into another app's internals (`accounts` importing another app's private model helper): an app's internals are its models' private helpers, views, and forms; calling another app's public `services.py` is the intended reuse.
- Copy-and-tweak templates — one partial with a `variant` instead.
