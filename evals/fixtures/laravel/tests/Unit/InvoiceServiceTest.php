<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Services\InvoiceService;
use Tests\TestCase;

class InvoiceServiceTest extends TestCase
{
    public function testSumsAmounts(): void
    {
        $this->assertSame('Amount due: $3.50', (new InvoiceService())->amountDueLabel([100, 250]));
    }
}
