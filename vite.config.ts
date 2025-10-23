import { NodeModulesPolyfillPlugin } from "@esbuild-plugins/node-modules-polyfill";
import inject from "@rollup/plugin-inject";
import { sveltekit } from "@sveltejs/kit/vite";
import { readFileSync } from "fs";
import { dirname, join, resolve } from "path";
import { fileURLToPath } from "url";
import type { UserConfig } from "vite";
import { defineConfig, loadEnv } from "vite";

import localCanisterIds from "./.dfx/local/canister_ids.json" assert { type: "json" };

const file = fileURLToPath(new URL("package.json", import.meta.url));
const json = readFileSync(file, "utf8");
const { version } = JSON.parse(json);

const network = process.env.DFX_NETWORK ?? "local";

const readCanisterIds = ({ prefix }: { prefix?: string } = {}): Record<
  string,
  string
> => {
  type Details = { ic?: string; local?: string };

  const source: Record<string, Details> =
    network === "ic"
      ? JSON.parse(
          readFileSync(join(process.cwd(), "canister_ids.json"), "utf-8"),
        )
      : (localCanisterIds as Record<string, Details>);

  return Object.entries(source).reduce(
    (acc, [canisterName, canisterDetails]) => {
      const sanitizedName = canisterName.replace(/-/g, "_"); // hyphens → underscores
      return {
        ...acc,
        [`${prefix ?? ""}${sanitizedName.toUpperCase()}_CANISTER_ID`]:
          canisterDetails[network as keyof Details],
      };
    },
    {},
  );
};

const config: UserConfig = {
  plugins: [sveltekit()],
  resolve: {
    alias: {
      $declarations: resolve("./src/declarations"),
      "lucide-svelte/dist/lucide-svelte.js": "lucide-svelte",
      "lucide-svelte/dist/icons/index": "lucide-svelte",
    },
  },
  css: {},
  ssr: { noExternal: ["svelte-motion", "lucide-svelte"] },
  build: {
    target: "es2020",
    commonjsOptions: { transformMixedEsModules: true },
    rollupOptions: {
      output: {
        manualChunks: (id) => {
          const folder = dirname(id);
          const lazy = ["@dfinity/nns"];
          if (
            ["@sveltejs", "svelte", ...lazy].find((lib) =>
              folder.includes(lib),
            ) === undefined &&
            folder.includes("node_modules")
          )
            return "vendor";
          if (
            lazy.find((lib) => folder.includes(lib)) !== undefined &&
            folder.includes("node_modules")
          )
            return "lazy";
          return "index";
        },
        sanitizeFileName(name) {
          return name.replace(/-/g, "_");
        },
      },
      plugins: [inject({ modules: { Buffer: ["buffer", "Buffer"] } })],
    },
  },
  server: {
    proxy: { "/api": "http://localhost:4943" },
    watch: {
      ignored: ["**/.github/**"],
    },
  },
  optimizeDeps: {
    esbuildOptions: {
      define: { global: "globalThis" },
      plugins: [
        NodeModulesPolyfillPlugin(),
        {
          name: "fix-node-globals-polyfill",
          setup(build) {
            build.onResolve(
              { filter: /_virtual-process-polyfill_\.js/ },
              ({ path }) => ({ path }),
            );
          },
        },
      ],
    },
  },
  worker: { format: "es" },
};

export default defineConfig((): UserConfig => {
  const env = loadEnv(
    network === "ic"
      ? "production"
      : network === "staging"
        ? "staging"
        : "development",
    process.cwd(),
  );

  const CANISTER_ENV = readCanisterIds({});
  const CANISTER_ENV_VITE = readCanisterIds({ prefix: "VITE_" });

  process.env = {
    ...process.env,
    ...env,
    ...CANISTER_ENV_VITE,
    ...CANISTER_ENV,
  };

  return {
    ...config,
    define: {
      "process.env": {
        ...CANISTER_ENV,
        DFX_NETWORK: network,
      },

      "import.meta.env.BACKEND_CANISTER_ID": JSON.stringify(
        CANISTER_ENV.BACKEND_CANISTER_ID,
      ),
      "import.meta.env.FRONTEND_CANISTER_ID": JSON.stringify(
        CANISTER_ENV.FRONTEND_CANISTER_ID,
      ),
      "import.meta.env.__CANDID_UI_CANISTER_ID": JSON.stringify(
        CANISTER_ENV.__CANDID_UI_CANISTER_ID,
      ),

      "import.meta.env.VITE_BACKEND_CANISTER_ID": JSON.stringify(
        CANISTER_ENV_VITE.VITE_BACKEND_CANISTER_ID,
      ),
      "import.meta.env.VITE_FRONTEND_CANISTER_ID": JSON.stringify(
        CANISTER_ENV_VITE.VITE_FRONTEND_CANISTER_ID,
      ),

      VITE_APP_VERSION: JSON.stringify(version),
      VITE_DFX_NETWORK: JSON.stringify(network),
    },
  };
});
