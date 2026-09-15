import { Injectable } from "@nestjs/common";
import { orderTotalLabel } from "./order-pricing.ts";

@Injectable()
export class OrdersService {
  label(lines: { cents: number; qty: number }[]): string {
    return orderTotalLabel(lines);
  }
}
