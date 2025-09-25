<script lang="ts">
  interface Props {
    className: string;
    fill: string;
  }
  let { className, fill }: Props = $props();
</script>

<svg
  viewBox="0 0 24 24"
  class={className}
  {fill}
  xmlns="http://www.w3.org/2000/svg"
>
  <path
    fill-rule="evenodd"
    clip-rule="evenodd"
    d="M19 24H5C3.896 24 3 23.104 3 22V5H2V3H8V1.5C8 0.673 8.673 0 9.5 0H14.5C15.325 0 16 0.671 16 1.5V3H22V5H21V22C21 23.104 20.104 24 19 24ZM19 5H5V21.5C5 21.776 5.224 22 5.5 22H18.5C18.776 22 19 21.776 19 21.5V5ZM10 9C10 8.448 9.552 8 9 8C8.448 8 8 8.448 8 9V18C8 18.552 8.448 19 9 19C9.552 19 10 18.552 10 18V9ZM16 9C16 8.448 15.552 8 15 8C14.448 8 14 8.448 14 9V18C14 18.552 14.448 19 15 19C15.552 19 16 18.552 16 18V9ZM14 2H10V3H14V2Z"
    {fill}
  />
</svg>
