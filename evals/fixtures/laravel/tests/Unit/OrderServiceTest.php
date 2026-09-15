<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Services\OrderService;
use Tests\TestCase;

class OrderServiceTest extends TestCase
{
    public function testSumsLines(): void
    {
        $this->assertSame('Order total: $25.00', (new OrderService())->orderTotalLabel([[1000, 2], [500, 1]]));
    }
}
