import { test } from "node:test";
import assert from "node:assert/strict";
import { amountDueLabel } from "./invoice-pricing.ts";

test("sums invoice amounts", () => {
  assert.equal(amountDueLabel([100, 250]), "Amount due: $3.50");
});
