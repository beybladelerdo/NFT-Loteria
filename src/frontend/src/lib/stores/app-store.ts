import { toasts } from "./toasts-store";

function createAppStore() {
  async function copyTextAndShowToast(text: string) {
    try {
      await navigator.clipboard.writeText(text);
      toasts.addToast({
        type: "success",
        message: "Copied to clipboard.",
        duration: 2000,
      });
    } catch (err) {
      console.error("Failed to copy:", err);
    }
  }

  return {
    copyTextAndShowToast,
  };
}

export const appStore = createAppStore();
