<script lang="ts">
  let {
    customer,
  }: { customer: { id: string; name: string; email: string } } = $props();
</script>

<div class="rounded-md border p-4">
  <p class="font-medium">{customer.name}</p>
  <p class="text-sm text-muted-foreground">{customer.email}</p>
</div>
