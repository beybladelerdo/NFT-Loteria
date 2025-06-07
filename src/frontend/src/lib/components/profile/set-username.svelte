<script lang="ts">
    import { isUsernameValid } from "$lib/utils/helpers";
    import { userStore } from "$lib/stores/user-store";
    import FullScreenSpinner from "../shared/global/full-screen-spinner.svelte";
    import { goto } from "$app/navigation";

    interface Props {
        userCreated: () => void;
    }
    let { userCreated }: Props = $props();

    let isLoading = $state(false);
    let username = $state("");
    let usernameAvailable = $state(false);
    let isCheckingUsername = $state(false);
    let usernameError = $state("");
    let usernameTimeout: NodeJS.Timeout;

    async function checkUsername() {
        isCheckingUsername = true;
        try {
            if(!isUsernameValid(username)){
                usernameError = "Username must be between 5 and 20 characters.";
            }
            const available = await userStore.isUsernameValid(username);
            usernameAvailable = available;
            usernameError = available ? "" : "Username is already taken";
        } catch (error) {
            console.error("Error checking username:", error);
            usernameError = "Error checking username availability";
        } finally {
            isCheckingUsername = false;
        }
    } 
  
    function handleUsernameInput() {
        clearTimeout(usernameTimeout);
        usernameAvailable = false;
        if (username.length >= 5) {
            usernameTimeout = setTimeout(checkUsername, 500);
        }
    }

    async function saveUsername(){
        isLoading = true;
        try{
            await userStore.createProfile(username);
            await userCreated();
        } catch {
            console.error('Error creating profile')
        } finally {
            goto('/');
            isLoading = false;
        }
    }
</script>

{#if isLoading}
    <FullScreenSpinner />
{:else}
    <div class="flex flex-col items-center justify-center min-h-screen px-4 py-12 font-mono bg-BrandBackground text-BrandText">
        <div class="w-full max-w-md p-8 space-y-6 border rounded-lg shadow-lg bg-BrandSurface border-BrandBorder">
            <h2 class="mb-2 text-2xl font-bold tracking-wider text-center text-BrandHighlight retro-text">Choose Your Username</h2>
            
            <p class="mb-6 text-center text-BrandSecondary retro-text">For people to message you, please select a username:</p>

            <div class="space-y-4">
                <div class="space-y-2">
                    <label for="username" class="block text-sm font-medium text-BrandText">
                        Username <span class="text-red-500">*</span>
                    </label>
                    <p class="text-xs text-BrandSecondary">
                        5-20 characters
                    </p>
                    <input
                        id="username"
                        type="text"
                        bind:value={username}
                        oninput={handleUsernameInput}
                        class="w-full px-4 py-3 transition-colors border rounded-lg border-BrandBorder text-BrandText placeholder-BrandSecondary focus:outline-none focus:border-BrandHighlight focus:ring-1 focus:ring-BrandHighlight"
                        placeholder="Enter username"
                    />
                    {#if username.length > 0}
                        <div class="mt-2 text-sm">
                            {#if isCheckingUsername}
                                <p class="text-BrandSecondary">Checking availability...</p>
                            {:else if usernameError}
                                <p class="text-red-500">{usernameError}</p>
                            {:else if usernameAvailable}
                                <p class="text-BrandHighlight">Username available</p>
                            {/if}
                        </div>
                    {/if}
                </div>

                <button 
                    onclick={saveUsername}
                    class="flex justify-center w-full mt-4 transition-colors duration-200 brand-button "
                >
                    Save Username
                </button>
            </div>
        </div>
    </div>
{/if}