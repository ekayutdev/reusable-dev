pub fn probe() -> &'static str {
    "ok"
}

#[cfg(test)]
mod tests {
    #[test]
    fn probe_runs() {
        assert_eq!(super::probe(), "ok");
    }
}
