import { test } from "node:test";
import assert from "node:assert/strict";
import { orderSummary } from "./order-summary.ts";

test("sums items", () => {
  assert.equal(orderSummary([{ price: 10, qty: 2 }, { price: 5, qty: 1 }]), "Total: $25.00");
});
