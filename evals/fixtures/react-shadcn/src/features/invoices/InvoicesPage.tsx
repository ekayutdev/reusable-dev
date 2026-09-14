import { DataTable } from "@/shared/ui/DataTable";

type Invoice = { id: string; number: string; issuedAt: string };

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" });
}

export function InvoicesPage({ invoices }: { invoices: Invoice[] }) {
  const rows = invoices.map((i) => ({ ...i, issuedAt: formatDate(i.issuedAt) }));
  return (
    <DataTable
      columns={[{ key: "number", header: "Invoice" }, { key: "issuedAt", header: "Issued" }]}
      data={rows}
    />
  );
}
