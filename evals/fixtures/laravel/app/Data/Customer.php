<?php

declare(strict_types=1);

namespace App\Data;

final readonly class Customer
{
    public function __construct(
        public string $id,
        public string $name,
        public int $balanceCents,
    ) {
    }
}
