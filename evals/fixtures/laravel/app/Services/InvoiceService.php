<?php

declare(strict_types=1);

namespace App\Services;

class InvoiceService
{
    /** @param list<int> $amounts cents */
    public function amountDueLabel(array $amounts): string
    {
        return 'Amount due: ' . $this->formatMoney(array_sum($amounts));
    }

    private function formatMoney(int $cents): string
    {
        return '$' . number_format($cents / 100, 2);
    }
}
