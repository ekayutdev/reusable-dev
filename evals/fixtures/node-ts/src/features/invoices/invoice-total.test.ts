import { test } from "node:test";
import assert from "node:assert/strict";
import { invoiceTotal } from "./invoice-total.ts";

test("totals EUR lines", () => {
  assert.equal(invoiceTotal([1, 2.5], "EUR"), "€3.50");
});
