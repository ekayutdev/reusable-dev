<script setup lang="ts">
import type { ButtonVariants } from ".";
import { cn } from "@/lib/utils";
import { buttonVariants } from ".";

interface Props {
  variant?: ButtonVariants["variant"];
  size?: ButtonVariants["size"];
  class?: import("vue").HTMLAttributes["class"];
}

const props = defineProps<Props>();
</script>

<template>
  <button :class="cn(buttonVariants({ variant, size }), props.class)">
    <slot />
  </button>
</template>
