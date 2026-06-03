// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import tailwindcss from '@tailwindcss/vite';

// https://astro.build/config
export default defineConfig({
  site: 'https://decree.doruk.uk',
  integrations: [
    starlight({
      title: 'decree',
      tagline: 'Decision governance for your codebase — and the agents editing it.',
      description:
        'decree tracks the decisions behind your code (PRD → ADR → SPEC) and checks every change against them. It answers only from what is declared — and abstains instead of guessing.',
      customCss: ['./src/styles/global.css', './src/styles/components.css'],
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/doruksahin/decree' },
      ],
      // Default the site to dark (the headline aesthetic); the toggle still works
      // and a user's explicit choice persists. Seeds only when unset.
      head: [
        {
          tag: 'script',
          content:
            "try{var k='starlight-theme';var v=localStorage.getItem(k);if(v!=='light'){localStorage.setItem(k,'dark');document.documentElement.dataset.theme='dark';}}catch(e){document.documentElement.dataset.theme='dark';}",
        },
      ],
      // Code/terminal frames are ALWAYS dark — terminal output is dark by nature,
      // and this keeps real ANSI output readable regardless of page theme.
      expressiveCode: {
        themes: ['github-dark'],
        useStarlightUiThemeColors: false,
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
        { label: 'For agents & CI', link: '/agents/' },
        { label: 'Why decree', link: '/why-decree/' },
        { label: 'decree by example', link: '/examples/' },
      ],
    }),
  ],
  vite: {
    plugins: [tailwindcss()],
  },
});
