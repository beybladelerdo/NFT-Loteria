<script lang="ts">
  interface Props {
    variant?: "primary" | "secondary" | "outline";
    fullWidth?: boolean;
    onclick?: () => void;
    disabled?: boolean;
    class?: string;
    children?: () => any;
  }

  let {
    variant = "primary",
    fullWidth = false,
    onclick,
    disabled = false,
    class: className = "",
    children = () => null,
  }: Props = $props();

  const baseStyles =
    "px-6 py-3 font-bold rounded-lg transition uppercase tracking-wide  flex items-center justify-center gap-2";

  const variantStyles = {
    primary:
      "bg-violet-500 text-black hover:bg-violet-400 disabled:bg-gray-700 disabled:text-gray-500",
    secondary:
      "bg-black text-white hover:bg-black/80 disabled:bg-gray-800 disabled:text-gray-600",
    outline:
      "bg-white/10 border-2 border-violet-500 text-white hover:bg-violet-500 hover:text-black disabled:border-gray-700 disabled:text-gray-600",
  };

  const widthStyle = fullWidth ? "w-full" : "";
</script>

<button
  {onclick}
  {disabled}
  class="{baseStyles} {variantStyles[
    variant
  ]} {widthStyle} {className} disabled:cursor-not-allowed"
>
  {@render children()}
</button>
