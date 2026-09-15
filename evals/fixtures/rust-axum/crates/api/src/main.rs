use axum::{routing::get, Router};

async fn order_total() -> String {
    billing::orders::order_total_label(&[(1000, 2), (500, 1)])
}

#[tokio::main]
async fn main() {
    let app = Router::new().route("/orders/total", get(order_total));
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
