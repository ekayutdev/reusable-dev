<script setup lang="ts">
defineProps<{ customer: { id: string; name: string; email: string } }>();
</script>

<template>
  <div class="rounded-md border p-4">
    <p class="font-medium">{{ customer.name }}</p>
    <p class="text-sm text-muted-foreground">{{ customer.email }}</p>
  </div>
</template>
