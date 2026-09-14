<script lang="ts" module>
  import { type VariantProps, tv } from "tailwind-variants";
  import { cn } from "$lib/utils";

  export const buttonVariants = tv({
    base: "inline-flex shrink-0 items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all outline-none select-none disabled:pointer-events-none disabled:opacity-50",
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/80",
        outline: "border border-border bg-background shadow-xs hover:bg-muted",
      },
      size: { default: "h-9 px-4", sm: "h-8 px-3" },
    },
    defaultVariants: { variant: "default", size: "default" },
  });

  export type ButtonVariant = VariantProps<typeof buttonVariants>["variant"];
  export type ButtonSize = VariantProps<typeof buttonVariants>["size"];
</script>

<script lang="ts">
  import type { HTMLButtonAttributes } from "svelte/elements";

  type Props = HTMLButtonAttributes & {
    variant?: ButtonVariant;
    size?: ButtonSize;
    class?: string;
    children?: import("svelte").Snippet;
  };

  let {
    class: className,
    variant = "default",
    size = "default",
    type = "button",
    children,
    ...rest
  }: Props = $props();
</script>

<button
  type={type}
  class={cn(buttonVariants({ variant, size }), className)}
  {...rest}
>
  {@render children?.()}
</button>
