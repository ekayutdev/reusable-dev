<?php

declare(strict_types=1);

namespace App\Services;

class OrderService
{
    /** @param list<array{int, int}> $lines [cents, quantity] pairs */
    public function orderTotalLabel(array $lines): string
    {
        $total = array_sum(array_map(fn (array $line): int => $line[0] * $line[1], $lines));

        return 'Order total: ' . $this->formatMoney($total);
    }

    private function formatMoney(int $cents): string
    {
        return '$' . number_format($cents / 100, 2);
    }
}
