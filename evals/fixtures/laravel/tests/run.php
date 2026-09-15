<?php

declare(strict_types=1);

// Minimal test runner: Laravel, PHPUnit and Pest are not installed in this project.
spl_autoload_register(function (string $class): void {
    $roots = ['App\\' => __DIR__ . '/../app/', 'Tests\\' => __DIR__ . '/'];
    foreach ($roots as $prefix => $dir) {
        if (str_starts_with($class, $prefix)) {
            $file = $dir . str_replace('\\', '/', substr($class, strlen($prefix))) . '.php';
            if (is_file($file)) {
                require $file;
            }
            return;
        }
    }
});

$files = array_merge(glob(__DIR__ . '/Unit/*Test.php') ?: [], glob(__DIR__ . '/Feature/*Test.php') ?: []);
$count = 0;
$failures = [];

foreach ($files as $file) {
    $class = 'Tests\\' . str_replace('/', '\\', substr($file, strlen(__DIR__) + 1, -4));
    foreach (get_class_methods($class) as $method) {
        if (!str_starts_with($method, 'test')) {
            continue;
        }
        $count++;
        try {
            (new $class())->$method();
        } catch (Throwable $e) {
            $failures[] = "{$class}::{$method}: {$e->getMessage()}";
        }
    }
}

if ($failures !== []) {
    echo 'FAILURES ' . count($failures) . " of {$count} tests\n" . implode("\n", $failures) . "\n";
    exit(1);
}

echo "OK {$count} tests\n";
