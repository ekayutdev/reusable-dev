import { Injectable } from "@nestjs/common";

export type Customer = { id: string; name: string; balanceCents: number };

@Injectable()
export class CustomersService {
  findAll(): Customer[] {
    return [{ id: "c1", name: "Ada", balanceCents: 1250 }];
  }
}
