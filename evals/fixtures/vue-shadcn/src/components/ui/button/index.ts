import type { VariantProps } from "class-variance-authority";
import { cva } from "class-variance-authority";

export { default as Button } from "./Button.vue";

export const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        outline: "border bg-background shadow-xs hover:bg-accent hover:text-accent-foreground",
      },
      size: { default: "h-9 px-4", sm: "h-8 px-3" },
    },
    defaultVariants: { variant: "default", size: "default" },
  },
);

export type ButtonVariants = VariantProps<typeof buttonVariants>;
