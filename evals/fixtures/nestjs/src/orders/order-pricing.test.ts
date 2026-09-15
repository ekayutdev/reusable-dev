import { test } from "node:test";
import assert from "node:assert/strict";
import { orderTotalLabel } from "./order-pricing.ts";

test("sums order lines", () => {
  assert.equal(orderTotalLabel([{ cents: 1000, qty: 2 }, { cents: 500, qty: 1 }]), "Order total: $25.00");
});
