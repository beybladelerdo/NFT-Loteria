<script lang="ts">
	import { onMount } from 'svelte';
	import { toasts } from '$lib/stores/toasts-store';
	import type { Toast } from '$lib/stores/toasts-store';

	interface Props {
		toast: Toast;
    }
    let { toast }: Props = $props();

	let timer: ReturnType<typeof setTimeout> | null = null;
	let bgColorClass = $state("");
	let textColorClass = $state("");

	onMount(() => {
		if (toast.duration && toast.duration > 0) {
			timer = setTimeout(closeToast, toast.duration);
		}
	});

	function closeToast() {
		toasts.removeToast(toast.id);
	}

</script>

<div class={`fixed top-0 left-0 right-0 z-[9999] p-4 shadow-md flex justify-between items-center bg-BrandBlue text-white`}>
  <span>{toast.message}</span>
  <button class="ml-4 font-bold hover:text-BrandHighlight" onclick={closeToast}>
    &times;
  </button>
</div>
