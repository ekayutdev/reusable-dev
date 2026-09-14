import { DataTable } from "@/shared/ui/DataTable";

type Order = { id: string; customer: string; createdAt: string };

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" });
}

export function OrdersPage({ orders }: { orders: Order[] }) {
  const rows = orders.map((o) => ({ ...o, createdAt: formatDate(o.createdAt) }));
  return (
    <DataTable
      columns={[{ key: "customer", header: "Customer" }, { key: "createdAt", header: "Created" }]}
      data={rows}
    />
  );
}
