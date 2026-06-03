// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import tailwindcss from '@tailwindcss/vite';

// https://astro.build/config
export default defineConfig({
  // Placeholder; the site is not deployed yet (deploy = local for now).
  site: 'https://decree.dev',
  integrations: [
    starlight({
      title: 'decree',
      tagline: 'Decision governance for your codebase — and the agents editing it.',
      description:
        'decree tracks the decisions behind your code (PRD → ADR → SPEC) and checks every change against them. It answers only from what is declared — and abstains instead of guessing.',
      customCss: ['./src/styles/global.css'],
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/doruksahin/decree' },
      ],
      // Dark is the headline aesthetic; keep the light toggle available.
      expressiveCode: {
        themes: ['github-dark'],
        useStarlightUiThemeColors: true,
        styleOverrides: {
          borderRadius: '0.5rem',
          borderColor: '#1f2430',
          codeFontFamily: "'JetBrains Mono', ui-monospace, monospace",
          frames: {
            terminalBackground: '#0c0c10',
            terminalTitlebarBackground: '#13131a',
            terminalTitlebarForeground: '#c9d1d9',
            editorTabBarBackground: '#13131a',
            editorActiveTabBackground: '#0c0c10',
            frameBoxShadowCssValue: '0 0 0 1px #1f2430, 0 16px 40px -16px rgba(0,0,0,0.6)',
          },
        },
      },
      sidebar: [
        { label: 'Start here', link: '/start/' },
        { label: 'Capabilities', items: [{ autogenerate: { directory: 'capabilities' } }] },
        { label: 'decree by example', link: '/examples/' },
      ],
    }),
  ],
  vite: {
    plugins: [tailwindcss()],
  },
});
