type Customer = { id: string; name: string; email: string };

export function CustomerCard({ customer }: { customer: Customer }) {
  return (
    <div className="rounded-md border p-4">
      <p className="font-medium">{customer.name}</p>
      <p className="text-sm text-muted-foreground">{customer.email}</p>
    </div>
  );
}
