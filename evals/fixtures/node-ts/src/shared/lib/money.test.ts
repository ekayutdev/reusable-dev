import { test } from "node:test";
import assert from "node:assert/strict";
import { formatCurrency } from "./money.ts";

test("formats USD", () => {
  assert.equal(formatCurrency(1234.5, "USD"), "$1,234.50");
});
