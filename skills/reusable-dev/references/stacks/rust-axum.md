<!-- researched 2026-09-15: axum@0.8.9 (docs.rs/axum: Router, State, extract, IntoResponse, error_handling), thiserror@2.0.20 (docs.rs/thiserror), tower@0.5.3 (docs.rs/tower ServiceExt::oneshot), doc.rust-lang.org/cargo/reference/workspaces, doc.rust-lang.org/book/ch11-02-running-tests, ch11-03-test-organization -->

# Stack: rust-axum

axum web service (tokio, tower). No language core file — the general rules plus this reference apply.

## Detection
`axum` in any `Cargo.toml` in the repo — root, member, or excluded crate (detection row 7; doc.rust-lang.org/cargo/reference/workspaces, The `members` and `exclude` Fields). Any other `Cargo.toml` → ecosystem `rust` and the general rules.

## Reuse units
- Workspace crate: one package in `crates/<domain>` — the unit that moves between projects; `members`/`exclude` list it in the root manifest (doc.rust-lang.org/cargo/reference/workspaces).
- Domain module: `crates/<crate>/src/<domain>.rs`, declared in `lib.rs` — the unit of reusable logic inside a crate.
- Trait: the collaborator contract domain code calls and handlers wire (`Arc<dyn Trait + Send + Sync>` or generics).
- Error enum: a domain error type converted to a response via `impl IntoResponse` (docs.rs/axum, response/IntoResponse).
- Custom extractor: a reusable request precondition or parsed input (docs.rs/axum, extract → `FromRequestParts`).

## Paths
- `crates/api` — the axum crate: `Router`, handlers, extractors, `IntoResponse` impls; nothing else depends on axum.
- `crates/<domain>` — pure logic, no axum import; `crates/api` depends on it via `path` (doc.rust-lang.org/cargo/reference/workspaces, path dependencies).
- Shared helpers used by two or more crates: a new `crates/shared` member added to `members`, consumed via `path = "../shared"`; a helper only one crate uses lives in a module of that crate.
- Skip `target/` — build output, never a reuse source (doc.rust-lang.org/cargo/reference/workspaces, shared output directory).

## Component idioms
Not applicable — no UI.

## Logic idioms
- F2: handlers receive `State<AppState>` and delegate; state holds collaborators behind `#[async_trait::async_trait]` traits, constructed once in `main` (docs.rs/axum, extract/State → With `Router`). A native `async fn` in a trait is not usable behind `dyn` (dyn-incompatible) and its generic future is not known to be `Send`; `async_trait` (crate `async-trait = "0.1"`, impls carry the attribute too) boxes a `Send` future so `Arc<dyn ShipmentTracker + Send + Sync>` works. Returning `Json<T>` needs `T: serde::Serialize` (`serde = { version = "1", features = ["derive"] }`). Alternatives: a generic service `S: ShipmentTracker + Send + Sync + 'static`, or a synchronous collaborator.
```rust
#[async_trait::async_trait]
pub trait ShipmentTracker: Send + Sync {
    async fn dispatch(&self, id: u64) -> Result<Shipment, DispatchError>;
}

#[derive(serde::Serialize)]
pub struct Shipment { pub id: u64 } // domain type, in crates/<domain>

#[derive(Clone)]
struct AppState {
    tracker: Arc<dyn ShipmentTracker + Send + Sync>,
}

async fn dispatch_shipment(
    State(state): State<AppState>,
    Path(id): Path<u64>,
) -> Result<Json<Shipment>, ApiError> {
    Ok(Json(state.tracker.dispatch(id).await?))
}

// Router::new().route("/shipments/{id}/dispatch", post(dispatch_shipment)).with_state(state);
```
- Domain functions stay pure and synchronous where possible — an async boundary is needed only at I/O calls; `error_style: result` is the natural default.
- F6: domain crates return `Result<T, DomainError>`; `thiserror` derives the error type, a wrapper in `crates/api` converts it to a response (docs.rs/thiserror, Example; docs.rs/axum, response/IntoResponse → Implementing `IntoResponse`):
```rust
#[derive(thiserror::Error, Debug)]
pub enum DispatchError {
    #[error("shipment {0} not found")]
    NotFound(u64),
}

pub struct ApiError(DispatchError);

impl From<DispatchError> for ApiError {
    fn from(e: DispatchError) -> Self {
        ApiError(e)
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (code, msg) = match self.0 {
            DispatchError::NotFound(id) => (StatusCode::NOT_FOUND, DispatchError::NotFound(id).to_string()),
        };
        (code, msg).into_response()
    }
}
```
- Extractors run left to right and a body extractor must be last — one body per handler (docs.rs/axum, extract → The order of extractors).

## Testing
- `cargo test -p <crate>` for one crate; `cargo test <name>` for one test (doc.rust-lang.org/book/ch11-02-running-tests, Running a Subset of Tests by Name).
- Unit tests in a `#[cfg(test)] mod tests` beside the code, `use super::*;` — private functions testable (doc.rust-lang.org/book/ch11-03-test-organization).
- Handler tests call the router directly with `tower::ServiceExt::oneshot`, no HTTP server (docs.rs/tower, ServiceExt::oneshot) — needs `tower` as a dev-dependency with the `util` feature, and `http-body-util` to read bodies.
- Use exactly what config `commands.test` specifies; if it is empty, run no test command and report `T2 skipped (no command)` (commands above are examples for filling the config).

## Stack-specific anti-patterns
- Business logic in handlers — a handler extracts and delegates; logic goes to a domain crate.
- `unwrap()`/`expect()` in request paths — an outbound service call must not panic the task; convert errors.
- Global `static mut` or lazy singletons for services — pass them through `State` instead (docs.rs/axum, extract/State → Shared mutable state).
- One giant `utils.rs` — split by domain; `crates/shared` modules are named by what they do.
- A domain crate depending on axum — the domain must stay framework-free to stay reusable.
