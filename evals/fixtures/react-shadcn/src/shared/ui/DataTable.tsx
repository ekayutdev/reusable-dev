import * as React from "react";

export type Column<T> = { key: keyof T; header: string };

export function DataTable<T extends { id: string }>({
  columns,
  data,
}: {
  columns: Column<T>[];
  data: T[];
}) {
  return (
    <table>
      <thead>
        <tr>{columns.map((c) => <th key={String(c.key)}>{c.header}</th>)}</tr>
      </thead>
      <tbody>
        {data.map((row) => (
          <tr key={row.id}>
            {columns.map((c) => <td key={String(c.key)}>{String(row[c.key])}</td>)}
          </tr>
        ))}
      </tbody>
    </table>
  );
}
