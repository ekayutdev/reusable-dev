<?php

declare(strict_types=1);

namespace Tests;

abstract class TestCase
{
    protected function assertSame(mixed $expected, mixed $actual): void
    {
        if ($expected !== $actual) {
            throw new \RuntimeException('Expected ' . var_export($expected, true) . ', got ' . var_export($actual, true));
        }
    }
}
