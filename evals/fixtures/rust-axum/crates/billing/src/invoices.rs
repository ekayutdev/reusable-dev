fn format_money(cents: i64) -> String {
    format!("${}.{:02}", cents / 100, cents % 100)
}

pub fn amount_due_label(amounts: &[i64]) -> String {
    format!("Amount due: {}", format_money(amounts.iter().sum()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sums_amounts() {
        assert_eq!(amount_due_label(&[100, 250]), "Amount due: $3.50");
    }
}
