fn format_money(cents: i64) -> String {
    format!("${}.{:02}", cents / 100, cents % 100)
}

pub fn order_total_label(lines: &[(i64, i64)]) -> String {
    let total: i64 = lines.iter().map(|(cents, qty)| cents * qty).sum();
    format!("Order total: {}", format_money(total))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sums_lines() {
        assert_eq!(order_total_label(&[(1000, 2), (500, 1)]), "Order total: $25.00");
    }
}
