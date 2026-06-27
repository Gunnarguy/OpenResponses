Title: Live Content

Description: Fetched live

Source: https://platform.openai.com/docs/assistants/overview

---

<!DOCTYPE html><html lang="en"> <head><!-- Global Metadata --><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="icon" type="image/png" href="/favicon.png"><meta name="generator" content="Astro v6.0.4"><link rel="preload" href="/fonts/OpenAISans-Regular.woff" as="font" type="font/woff" crossorigin><link rel="preload" href="/fonts/OpenAISans-Bold.woff" as="font" type="font/woff" crossorigin><style>
  @layer theme, base, components, utilities;
</style><!-- Canonical URL --><link rel="canonical" href="https://developers.openai.com/api/docs/assistants/migration"><!-- Primary Meta Tags --><title>Assistants migration guide | OpenAI API</title><meta name="title" content="Assistants migration guide | OpenAI API"><meta name="description" content="Guidance for migrating from the Assistants API to the Responses API, including side-by-side comparisons and updated patterns."><!-- Open Graph / Facebook --><meta property="og:type" content="website"><meta property="og:url" content="https://developers.openai.com/api/docs/assistants/migration"><meta property="og:title" content="Assistants migration guide | OpenAI API"><meta property="og:description" content="Guidance for migrating from the Assistants API to the Responses API, including side-by-side comparisons and updated patterns."><meta property="og:image" content="https://developers.openai.com/og/api/docs/assistants/migration.png"><!-- Twitter --><meta name="twitter:card" content="summary_large_image"><meta name="twitter:site" content="@OpenAIDevs"><meta name="twitter:url" content="https://developers.openai.com/api/docs/assistants/migration"><meta name="twitter:title" content="Assistants migration guide | OpenAI API"><meta name="twitter:description" content="Guidance for migrating from the Assistants API to the Responses API, including side-by-side comparisons and updated patterns."><meta name="twitter:image" content="https://developers.openai.com/og/api/docs/assistants/migration.png"><meta name="twitter:image:alt" content="Assistants migration guide | OpenAI API"><!-- Sitemap --><link rel="sitemap" href="/sitemap-index.xml"><!-- RSS Feed --><link rel="alternate" type="application/rss+xml" title="Assistants migration guide | OpenAI API" href="https://developers.openai.com/rss.xml"><!-- Global Scripts --><script src="/js/theme.js"></script><script src="/js/scroll.js"></script><script src="/js/animate.js"></script><script defer src="/js/copy.js"></script><meta name="astro-view-transitions-enabled" content="true"><meta name="astro-view-transitions-fallback" content="swap"><script type="module" src="/_astro/ClientRouter.astro_astro_type_script_index_0_lang.BHh7hlg8.js"></script><link rel="stylesheet" href="/_astro/platform-docs.C8tKlvDz.css">
<link rel="stylesheet" href="/_astro/PageLayout.D4qwu_TR.css">
<style>.prompt-scroll:where(.astro-blfj6jyd){--prompt-scroll-gutter-x: 14px;--prompt-scroll-gutter-y: 16px;padding:0 calc(4.5rem + var(--prompt-scroll-gutter-x)) 0 1.5rem;scrollbar-gutter:stable;scrollbar-width:thin;scrollbar-color:rgb(15 23 42 / 28%) transparent}.prompt-scroll--header-actions:where(.astro-blfj6jyd){padding-right:1.5rem}.prompt-scroll-frame:where(.astro-blfj6jyd){position:relative;background:inherit}.prompt-scroll__content:where(.astro-blfj6jyd){margin-right:calc(-1 * var(--prompt-scroll-gutter-x))}.prompt-scroll--header-actions:where(.astro-blfj6jyd) .prompt-scroll__content:where(.astro-blfj6jyd){margin-right:0}.prompt-scroll-frame:where(.astro-blfj6jyd):before,.prompt-scroll-frame:where(.astro-blfj6jyd):after{content:"";position:absolute;right:0;width:calc(1.5rem + var(--prompt-scroll-gutter-x) + 8px);height:var(--prompt-scroll-gutter-y);background:inherit;pointer-events:none;z-index:1}.prompt-scroll-frame:where(.astro-blfj6jyd):before{top:0}.prompt-scroll-frame:where(.astro-blfj6jyd):after{bottom:0}.prompt-actions:where(.astro-blfj6jyd){z-index:2}.prompt-scroll:where(.astro-blfj6jyd)::-webkit-scrollbar{width:8px;height:8px}.prompt-scroll:where(.astro-blfj6jyd)::-webkit-scrollbar-track{background:transparent;margin-block:var(--prompt-scroll-gutter-y)}.prompt-scroll:where(.astro-blfj6jyd)::-webkit-scrollbar-thumb{background-color:#0f172a47;border:2px solid transparent;border-radius:9999px;background-clip:padding-box}html.dark .prompt-scroll:where(.astro-blfj6jyd),[data-theme=dark] .prompt-scroll:where(.astro-blfj6jyd){scrollbar-color:rgb(255 255 255 / 28%) transparent}html.dark .prompt-scroll:where(.astro-blfj6jyd)::-webkit-scrollbar-thumb,[data-theme=dark] .prompt-scroll:where(.astro-blfj6jyd)::-webkit-scrollbar-thumb{background-color:#ffffff47}
.page-copy-action:where(.astro-y3m22efp){display:inline-flex;min-height:26px;align-items:center;justify-content:center;gap:6px;border:1px solid var(--border-primary-outline, rgb(209 213 219));border-radius:8px;background:var(--surface-primary, #fff);padding:5px 10px;color:var(--text-primary, #202123);font-size:12px;font-weight:500;line-height:1;white-space:nowrap;transition:border-color .12s ease,background-color .12s ease,color .12s ease,opacity .12s ease}.page-copy-action:where(.astro-y3m22efp):hover:not(:disabled){background:var(--surface-primary-hover, #f7f7f8)}.page-copy-action:where(.astro-y3m22efp):focus-visible{outline:2px solid var(--border-primary, #111);outline-offset:2px}.page-copy-action:where(.astro-y3m22efp):disabled{cursor:progress;opacity:.7}.page-copy-action--cta:where(.astro-y3m22efp){min-height:42px;gap:8px;border-radius:9999px;padding:10px 18px;font-size:14px}.page-copy-action__icon:where(.astro-y3m22efp){display:inline-flex;width:14px;height:14px;align-items:center;justify-content:center}.page-copy-action__icon:where(.astro-y3m22efp) svg{width:14px;height:14px}.page-copy-action__icon--check:where(.astro-y3m22efp),.page-copy-action:where(.astro-y3m22efp)[data-copied=true] .page-copy-action__icon--copy:where(.astro-y3m22efp){display:none}.page-copy-action:where(.astro-y3m22efp)[data-copied=true] .page-copy-action__icon--check:where(.astro-y3m22efp){display:inline-flex}
@layer components{._Arrow_t2o77_1{--arrow-size: 6px;position:absolute;width:0;height:0}._Arrow_t2o77_1[data-side=top]{bottom:0;left:50%;border-top:var(--arrow-size) solid var(--gray-700);border-right:var(--arrow-size) solid transparent;border-left:var(--arrow-size) solid transparent;margin-right:-8px;transform:translate(-50%) translateY(100%)}._Arrow_t2o77_1[data-side=bottom]{top:0;left:50%;border-right:var(--arrow-size) solid transparent;border-bottom:var(--arrow-size) solid var(--gray-700);border-left:var(--arrow-size) solid transparent;margin-left:-8px;transform:translate(-50%) translateY(-100%)}._Arrow_t2o77_1[data-side=left]{top:50%;right:0;border-top:var(--arrow-size) solid transparent;border-bottom:var(--arrow-size) solid transparent;border-left:var(--arrow-size) solid var(--gray-700);margin-right:-8px;transform:translate(100%) translateY(-50%)}._Arrow_t2o77_1[data-side=right]{top:50%;left:0;border-top:var(--arrow-size) solid transparent;border-right:var(--arrow-size) solid var(--gray-700);border-bottom:var(--arrow-size) solid transparent;margin-left:-8px;transform:translate(-100%) translateY(-50%)}}
@layer components.base{._root_1x2h7_2{position:relative;display:flex;flex-direction:column;margin:20px 0;border:.5px solid var(--color-border-primary-surface);border-radius:8px;background:var(--code-snippet-bg)}._root_1x2h7_2+._root_1x2h7_2{margin-top:1em}._flush_1x2h7_16{width:100%;border:0;background:transparent;background-color:transparent;color:var(--color-text-emphasis);line-height:20px}._flush_1x2h7_16 code>code{padding-right:20px!important}._flush_1x2h7_16 .syntax-highlighter{background:transparent;font-size:13px;letter-spacing:var(--font-tracking-wide)}._flush_1x2h7_16 ._header_1x2h7_34{position:relative;z-index:1;justify-content:space-between;padding-left:8px;border-bottom:none;background:transparent}._flush_1x2h7_16 ._header_1x2h7_34 ._title_1x2h7_42{display:none}._flush_1x2h7_16 ._header_1x2h7_34 .code-sample-select-val{font-size:12px;letter-spacing:var(--font-tracking-wide)}._flush_1x2h7_16 ._header_1x2h7_34 .code-sample-select-wrap{margin-bottom:4px;margin-left:12px;font-size:12px;letter-spacing:var(--font-tracking-wide)}._flush_1x2h7_16 ._body_1x2h7_59{background:transparent}._flush_1x2h7_16 ._body_1x2h7_59 ._pre_1x2h7_62{padding-top:0}._root_1x2h7_2 .python-upgrade-banner{display:flex;padding:2px;background:var(--card-gradient);color:#fff;font-size:.8em;font-weight:var(--font-weight-bold);text-align:center}._root_1x2h7_2 .python-upgrade-banner svg{margin-top:6px;margin-right:8px;margin-left:8px}._root_1x2h7_2 .python-upgrade-banner path{stroke:#fff}._header_1x2h7_34{overflow:auto;display:flex;align-items:center;gap:4px;flex-shrink:0;padding:4px 8px 4px 14px;border-bottom:.5px solid var(--color-border-primary-surface);border-top-left-radius:8px;border-top-right-radius:8px}._title_1x2h7_42{overflow:hidden;flex:1 1 auto;margin-right:12px;color:var(--color-text);font-family:var(--monospace);font-size:12px;font-weight:var(--font-weight-normal);letter-spacing:var(--font-tracking-wide);text-overflow:ellipsis;white-space:nowrap}._sep_1x2h7_113{flex:0 0 auto;min-width:1px;height:22px;padding-left:8px;border-left:1px solid var(--color-background-primary-soft);margin-left:8px}._body_1x2h7_59{position:relative;flex-grow:1;flex-shrink:0}._body_1x2h7_59 ._pre_1x2h7_62{height:100%;min-height:44px;padding:12px 16px;border-radius:8px;margin:0;font-size:14px;line-height:20px;white-space:pre;background:var(--code-snippet-bg)}._body_1x2h7_59._bodyWithHeader_1x2h7_139 ._pre_1x2h7_62{border-top-left-radius:0;border-top-right-radius:0}._bodyWithCopyFloat_1x2h7_145 ._pre_1x2h7_62{padding-right:56px}._copyFloat_1x2h7_157{position:absolute;top:6px;right:6px}._oneliner_1x2h7_162 ._copyFloat_1x2h7_157{top:50%;transform:translateY(-50%)}._copyButton_1x2h7_168{height:1.75rem;padding:0 .5rem;border-radius:.375rem}}
</style>
<link rel="stylesheet" href="/_astro/index.avIh2ZpK.css">
<style>@layer base{.syntax-highlighter{background:transparent;color:var(--color-text);overflow-x:auto}.syntax-highlighter>code{border:none;box-shadow:none;font-family:var(--monospace)}.syntax-highlighter>code>code{padding-right:16px;border:none;box-shadow:none;float:left;font-family:var(--monospace);line-height:20px}.syntax-highlighter .react-syntax-highlighter-line-number{color:var(--color-text-disabled);line-height:20px;opacity:.5;text-align:right;-webkit-user-select:none;-moz-user-select:none;user-select:none}.syntax-highlighter [data-highlighted-row=true]{display:block;width:150%;margin-left:-25%;background-color:var(--pill-success-bg)}.syntax-highlighter [data-highlighted-row-subtle=true]{background-color:rgba(var(--sh-fg),.08)}.hljs-comment{color:rgba(var(--sh-fg),.5)}.hljs-meta{color:rgba(var(--sh-fg),.6)}.hljs-built_in,.hljs-class .hljs-title{color:var(--syntax1)}.hljs-doctag,.hljs-keyword,.hljs-formula,.hljs-literal{color:var(--syntax2)}.hljs-string,.hljs-regexp,.hljs-addition,.hljs-attribute,.hljs-meta-string{color:var(--syntax3)}.hljs-attr,.hljs-variable,.hljs-template-variable,.hljs-type,.hljs-selector-class,.hljs-selector-attr,.hljs-selector-pseudo,.hljs-number{color:var(--syntax4)}.hljs-symbol,.hljs-bullet,.hljs-link,.hljs-selector-id,.hljs-title{color:var(--syntax5)}}
</style><script type="module" src="/_astro/page.C1AneYUt.js"></script><style>@layer base{.code-comparison{display:flex;flex-direction:column;gap:16px}.code-comparison .code-sample{display:flex;flex-direction:column;flex:1 1 0;align-self:stretch;margin-top:0!important}.code-comparison .code-sample+.code-sample{margin-top:0!important}.code-comparison .code-sample>div:last-child{flex:1 1 auto}@media(width>=767px){.code-comparison{flex-direction:row;align-items:stretch}.code-comparison .code-sample{max-width:50%;margin:0;align-self:stretch}}@media(width<=767px){.code-comparison .code-sample{max-width:100%;margin:24px 0}.code-comparison .code-sample+.code-comparison .code-sample{margin-top:0}}.code-comparison .syntax-highlighter:has([data-highlighted-row=true]) code>span:before{content:" "}.code-comparison .syntax-highlighter:has([data-highlighted-row=true]) [data-highlighted-row=true]{display:unset;width:unset;padding:1.5px 0;margin:unset;background-color:var(--pill-success-bg)}.code-comparison .syntax-highlighter:has([data-highlighted-row=true]) [data-highlighted-row-addition=true]:before{content:"+"!important}.code-comparison .syntax-highlighter:has([data-highlighted-row=true]) [data-highlighted-row-addition=true]{background-color:var(--pill-success-bg)}.code-comparison .syntax-highlighter:has([data-highlighted-row=true]) [data-highlighted-row-removal=true]:before{content:"-"!important}.code-comparison .syntax-highlighter:has([data-highlighted-row=true]) [data-highlighted-row-removal=true]{background-color:#f8514940}}
</style><style>@layer components{._Notice_wyxfv_1{margin-top:24px;margin-bottom:24px}._Notice_wyxfv_1 p,._Notice_wyxfv_1 code{margin:0!important;line-height:18px!important}._Notice_wyxfv_1 p code{font-size:.875em}}
</style><style>@layer components{._TransitionItem_1lpir_1{will-change:var(--tg-will-change)}[data-transition-position=absolute] ._TransitionItem_1lpir_1[data-exiting],[data-transition-position=absolute] ._TransitionItem_1lpir_1:not([data-exiting])+._TransitionItem_1lpir_1[data-entering]{position:absolute;top:0;left:0;width:100%}._TransitionItem_1lpir_1[data-entering]{filter:var(--tg-initial-filter);opacity:var(--tg-initial-opacity);transform:var(--tg-initial-transform)}._TransitionItem_1lpir_1[data-exiting]{filter:var(--tg-enter-filter);opacity:var(--tg-enter-opacity);transform:var(--tg-enter-transform)}._TransitionItem_1lpir_1[data-entering-active],._TransitionItem_1lpir_1[data-entering][data-interrupted]{filter:var(--tg-enter-filter);opacity:var(--tg-enter-opacity);transform:var(--tg-enter-transform);transition:opacity var(--tg-enter-duration) var(--tg-enter-timing-function) var(--tg-enter-delay),transform var(--tg-enter-duration) var(--tg-enter-timing-function) var(--tg-enter-delay),filter var(--tg-enter-duration) var(--tg-enter-timing-function) var(--tg-enter-delay)}._TransitionItem_1lpir_1[data-exiting-active],._TransitionItem_1lpir_1[data-exiting][data-interrupted]{filter:var(--tg-exit-filter, none);opacity:var(--tg-exit-opacity, 0);transform:var(--tg-exit-transform, none);transition:opacity var(--tg-exit-duration) var(--tg-exit-timing-function) var(--tg-exit-delay),transform var(--tg-exit-duration) var(--tg-exit-timing-function) var(--tg-exit-delay),filter var(--tg-exit-duration) var(--tg-exit-timing-function) var(--tg-exit-delay)}._TransitionItem_1lpir_1[data-entering][data-interrupted],._TransitionItem_1lpir_1[data-exiting][data-interrupted]{transition-delay:0ms}}
</style><style>.content-switcher-root:where(.astro-cr4aci74){margin-top:24px}.content-switcher-selector:where(.astro-cr4aci74){width:100%;max-width:100%;margin-bottom:24px;overflow-x:auto;overflow-y:hidden;-webkit-overflow-scrolling:touch;touch-action:pan-x}.content-switcher-selector-right:where(.astro-cr4aci74){text-align:right}
</style><style>@layer components{._Tooltip_purug_1{max-width:300px;border-radius:var(--tooltip-border-radius);animation-duration:.25s;animation-name:_scale-in_purug_1;animation-timing-function:var(--cubic-enter);background:var(--tooltip-background-color);box-shadow:var(--tooltip-box-shadow);color:var(--tooltip-text-color);font-size:var(--tooltip-font-size);font-weight:var(--tooltip-font-weight);line-height:var(--tooltip-line-height);transform-origin:var(--radix-tooltip-content-transform-origin);transition:background-color .15s ease}._Tooltip_purug_1[data-state=closed]{animation:_scale-out_purug_1 .25s var(--cubic-enter)}._Tooltip_purug_1[data-clickable=false]{cursor:default}._Tooltip_purug_1[data-clickable=true]{cursor:pointer}@media(hover:hover)and (pointer:fine){._Tooltip_purug_1[data-compact=true][data-clickable=true]:hover{background:var(--tooltip-compact-interactive-background-color-hover);color:var(--tooltip-compact-interactive-text-color-hover)}}._Tooltip_purug_1[data-gutter-size=sm]{padding:var(--tooltip-padding-sm)}._Tooltip_purug_1[data-gutter-size=md]{padding:var(--tooltip-padding-md)}._Tooltip_purug_1[data-gutter-size=lg]{padding:var(--tooltip-padding-lg)}._Tooltip_purug_1[data-compact=true]{padding:var(--tooltip-compact-padding);background:var(--tooltip-compact-background-color);color:var(--tooltip-compact-text-color);font-size:var(--tooltip-compact-font-size);font-weight:var(--tooltip-compact-font-weight)}@keyframes _scale-in_purug_1{0%{opacity:0;transform:scale(.95)}to{opacity:1;transform:scale(1)}}@keyframes _scale-out_purug_1{0%{opacity:1;transform:scale(1)}to{opacity:0;transform:scale(.97)}}._TriggerDecorator_purug_84{display:inline-flex;cursor:pointer;-webkit-text-decoration:underline dotted;text-decoration:underline dotted;text-decoration-color:transparent;transition:-webkit-text-decoration .2s var(--cubic-exit);transition:text-decoration .2s var(--cubic-exit);transition:text-decoration .2s var(--cubic-exit),-webkit-text-decoration .2s var(--cubic-exit)}._TriggerDecorator_purug_84:focus{outline:0}._TriggerDecorator_purug_84[data-state*=open]{text-decoration-color:var(--color-text-tertiary);transition-timing-function:var(--cubic-enter)}}
</style><link rel="stylesheet" href="/_astro/Alert.Dl332ZUE.css"><link rel="stylesheet" href="/_astro/SegmentedControl.BVdWyLBX.css"><link rel="stylesheet" href="/_astro/Button.Cu9_vjWu.css"><link rel="stylesheet" href="/_astro/Select.ZFNnOywo.css"></head> <body class="overflow-x-hidden" data-pagefind-filter="section:api"> <header id="header" class="fixed top-0 w-full h-16 z-50 bg-white dark:bg-black border-b border-primary-surface astro-3ef6ksr2"> <div class="flex items-center h-full px-4 md:px-8 md:grid md:grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)] md:gap-6 astro-3ef6ksr2"> <!-- Logo --> <a href="/" class="flex items-center font-semibold ml-0 md:-ml-2 md:justify-self-start astro-3ef6ksr2"> <img src="/OpenAI_Developers.svg" alt="OpenAI Developers" class="h-6 w-48 md:h-6 dark:invert astro-3ef6ksr2"> </a> <!-- Links --> <nav class="hidden md:flex items-center justify-center gap-1 astro-3ef6ksr2"> <div class="relative group astro-3ef6ksr2"> <a href="/" class="flex items-center gap-1 text-sm px-2.5 py-1 rounded-md text-primary-soft hover:text-default hover:bg-primary-soft-alpha astro-3ef6ksr2"> Home  </a>  </div><div class="relative group astro-3ef6ksr2"> <a href="/api" class="flex items-center gap-1 text-sm px-2.5 py-1 rounded-md text-default bg-primary-soft astro-3ef6ksr2" aria-haspopup="menu"> API <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-tertiary astro-3ef6ksr2 " ><path d="M11.2929 16.2929C11.6834 16.6834 12.3166 16.6834 12.7071 16.2929L18.7071 10.2929C19.0976 9.90237 19.0976 9.26921 18.7071 8.87868C18.3166 8.48816 17.6834 8.48816 17.2929 8.87868L12 14.1716L6.70711 8.87868C6.31658 8.48816 5.68342 8.48816 5.29289 8.87868C4.90237 9.26921 4.90237 9.90237 5.29289 10.2929L11.2929 16.2929Z" fill="currentColor"></path></svg> </a> <div class="invisible opacity-0 absolute left-0 top-full z-50 mt-2 min-w-full w-max transition-opacity duration-150 group-hover:visible group-hover:opacity-100 group-focus-within:visible group-focus-within:opacity-100 before:content-[''] before:absolute before:-top-2 before:left-0 before:right-0 before:h-2 astro-3ef6ksr2" role="menu"> <div class="overflow-hidden rounded-md border border-primary-surface bg-surface shadow-md ring-1 ring-black/5 dark:ring-white/10 astro-3ef6ksr2"> <a role="menuitem" href="/api/docs" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Docs</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Guides and concepts for the OpenAI API </div> </div> </a><a role="menuitem" href="/api/reference/overview" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">API reference</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Endpoints, parameters, and responses </div> </div> </a> </div> </div> </div><div class="relative group astro-3ef6ksr2"> <a href="/codex" class="flex items-center gap-1 text-sm px-2.5 py-1 rounded-md text-primary-soft hover:text-default hover:bg-primary-soft-alpha astro-3ef6ksr2" aria-haspopup="menu"> Codex <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-tertiary astro-3ef6ksr2 " ><path d="M11.2929 16.2929C11.6834 16.6834 12.3166 16.6834 12.7071 16.2929L18.7071 10.2929C19.0976 9.90237 19.0976 9.26921 18.7071 8.87868C18.3166 8.48816 17.6834 8.48816 17.2929 8.87868L12 14.1716L6.70711 8.87868C6.31658 8.48816 5.68342 8.48816 5.29289 8.87868C4.90237 9.26921 4.90237 9.90237 5.29289 10.2929L11.2929 16.2929Z" fill="currentColor"></path></svg> </a> <div class="invisible opacity-0 absolute left-0 top-full z-50 mt-2 min-w-full w-max transition-opacity duration-150 group-hover:visible group-hover:opacity-100 group-focus-within:visible group-focus-within:opacity-100 before:content-[''] before:absolute before:-top-2 before:left-0 before:right-0 before:h-2 astro-3ef6ksr2" role="menu"> <div class="overflow-hidden rounded-md border border-primary-surface bg-surface shadow-md ring-1 ring-black/5 dark:ring-white/10 astro-3ef6ksr2"> <a role="menuitem" href="/codex" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Docs</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Guides, concepts, and product docs for Codex </div> </div> </a><a role="menuitem" href="/codex/use-cases" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Use cases</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Example workflows and tasks teams hand to Codex </div> </div> </a> </div> </div> </div><div class="relative group astro-3ef6ksr2"> <a href="/chatgpt" class="flex items-center gap-1 text-sm px-2.5 py-1 rounded-md text-primary-soft hover:text-default hover:bg-primary-soft-alpha astro-3ef6ksr2" aria-haspopup="menu"> ChatGPT <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-tertiary astro-3ef6ksr2 " ><path d="M11.2929 16.2929C11.6834 16.6834 12.3166 16.6834 12.7071 16.2929L18.7071 10.2929C19.0976 9.90237 19.0976 9.26921 18.7071 8.87868C18.3166 8.48816 17.6834 8.48816 17.2929 8.87868L12 14.1716L6.70711 8.87868C6.31658 8.48816 5.68342 8.48816 5.29289 8.87868C4.90237 9.26921 4.90237 9.90237 5.29289 10.2929L11.2929 16.2929Z" fill="currentColor"></path></svg> </a> <div class="invisible opacity-0 absolute left-0 top-full z-50 mt-2 min-w-full w-max transition-opacity duration-150 group-hover:visible group-hover:opacity-100 group-focus-within:visible group-focus-within:opacity-100 before:content-[''] before:absolute before:-top-2 before:left-0 before:right-0 before:h-2 astro-3ef6ksr2" role="menu"> <div class="overflow-hidden rounded-md border border-primary-surface bg-surface shadow-md ring-1 ring-black/5 dark:ring-white/10 astro-3ef6ksr2"> <a role="menuitem" href="/apps-sdk" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Apps SDK</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Build apps to extend ChatGPT </div> </div> </a><a role="menuitem" href="/workspace-agents" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Workspace Agents</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Trigger published ChatGPT workspace agents </div> </div> </a><a role="menuitem" href="/commerce" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Commerce</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Build commerce flows in ChatGPT </div> </div> </a><a role="menuitem" href="/ads" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Ads</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Publish and measure ads in ChatGPT </div> </div> </a> </div> </div> </div><div class="relative group astro-3ef6ksr2"> <a href="/learn" class="flex items-center gap-1 text-sm px-2.5 py-1 rounded-md text-primary-soft hover:text-default hover:bg-primary-soft-alpha astro-3ef6ksr2" aria-haspopup="menu"> Resources <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-tertiary astro-3ef6ksr2 " ><path d="M11.2929 16.2929C11.6834 16.6834 12.3166 16.6834 12.7071 16.2929L18.7071 10.2929C19.0976 9.90237 19.0976 9.26921 18.7071 8.87868C18.3166 8.48816 17.6834 8.48816 17.2929 8.87868L12 14.1716L6.70711 8.87868C6.31658 8.48816 5.68342 8.48816 5.29289 8.87868C4.90237 9.26921 4.90237 9.90237 5.29289 10.2929L11.2929 16.2929Z" fill="currentColor"></path></svg> </a> <div class="invisible opacity-0 absolute left-0 top-full z-50 mt-2 min-w-full w-max transition-opacity duration-150 group-hover:visible group-hover:opacity-100 group-focus-within:visible group-focus-within:opacity-100 before:content-[''] before:absolute before:-top-2 before:left-0 before:right-0 before:h-2 astro-3ef6ksr2" role="menu"> <div class="overflow-hidden rounded-md border border-primary-surface bg-surface shadow-md ring-1 ring-black/5 dark:ring-white/10 astro-3ef6ksr2"> <a role="menuitem" href="/showcase" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Showcase</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Demo apps to get inspired </div> </div> </a><a role="menuitem" href="/blog" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Blog</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Learnings and experiences from developers </div> </div> </a><a role="menuitem" href="/cookbook" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Cookbook</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Notebook examples for building with OpenAI models </div> </div> </a><a role="menuitem" href="/learn" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Learn</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Docs, videos, and demo apps for building with OpenAI </div> </div> </a><a role="menuitem" href="/community" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Community</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Programs, meetups, and support for builders </div> </div> </a> </div> </div> </div>  </nav> <!-- Theme Toggle, Mobile Menu --> <div class="ml-auto flex items-center gap-4 md:gap-5 md:ml-0 md:justify-end md:justify-self-end astro-3ef6ksr2"> <button type="button" data-header-search-button aria-controls="header-search-overlay" aria-expanded="false" class="hidden min-w-52 items-center justify-between gap-3 rounded-full border border-primary-surface bg-surface px-4 py-2 text-sm text-secondary transition-colors hover:bg-primary-soft-alpha hover:text-default xl:flex astro-3ef6ksr2"> <span class="truncate astro-3ef6ksr2">Start searching</span> <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="h-4 w-4 shrink-0 astro-3ef6ksr2 " ><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg> </button> <div class="hidden md:flex astro-3ef6ksr2"> <div class="flex items-center gap-2"><a target="_blank" rel="noopener noreferrer" href="https://platform.openai.com/login" class="_Button_6dmow_1 not-prose !h-9 !w-9 justify-center !px-0 min-[1000px]:!w-auto min-[1000px]:!px-4" data-color="primary" data-variant="solid" data-pill="" data-size="md"><span class="_ButtonInner_6dmow_4"><span class="sr-only min-[1000px]:not-sr-only">API Dashboard</span><svg width="1em" height="1em" viewBox="0 0 24 24" fill="currentColor" class="shrink-0"><path fill-rule="evenodd" d="M16.243 6.757a1 1 0 0 1 1 1v7.072a1 1 0 0 1-2 0v-4.657L8.464 16.95a1 1 0 0 1-1.414-1.414l6.778-6.779H9.172a1 1 0 0 1 0-2h7.07Z" clip-rule="evenodd"></path></svg></span></a></div> </div> <button id="header-theme-button" aria-label="Toggle light and dark theme" class="hidden md:flex text-secondary hover:text-default transition-colors astro-3ef6ksr2"> <svg width="22" height="22" viewBox="0 0 22 22" fill="none" xmlns="http://www.w3.org/2000/svg" class="block dark:hidden w-4 h-4 astro-3ef6ksr2 " ><path fill-rule="evenodd" clip-rule="evenodd" d="M11 0C11.5523 0 12 0.447715 12 1V3C12 3.55228 11.5523 4 11 4C10.4477 4 10 3.55228 10 3V1C10 0.447715 10.4477 0 11 0ZM3.22183 3.22183C3.61235 2.8313 4.24551 2.8313 4.63604 3.22183L6.05025 4.63604C6.44078 5.02656 6.44078 5.65973 6.05025 6.05025C5.65973 6.44078 5.02656 6.44078 4.63604 6.05025L3.22183 4.63604C2.8313 4.24551 2.8313 3.61235 3.22183 3.22183ZM18.7782 3.22183C19.1687 3.61235 19.1687 4.24551 18.7782 4.63604L17.364 6.05025C16.9734 6.44078 16.3403 6.44078 15.9497 6.05025C15.5592 5.65973 15.5592 5.02656 15.9497 4.63604L17.364 3.22183C17.7545 2.8313 18.3876 2.8313 18.7782 3.22183ZM11 8C9.34315 8 8 9.34315 8 11C8 12.6569 9.34315 14 11 14C12.6569 14 14 12.6569 14 11C14 9.34315 12.6569 8 11 8ZM6 11C6 8.23858 8.23858 6 11 6C13.7614 6 16 8.23858 16 11C16 13.7614 13.7614 16 11 16C8.23858 16 6 13.7614 6 11ZM0 11C0 10.4477 0.447715 10 1 10H3C3.55228 10 4 10.4477 4 11C4 11.5523 3.55228 12 3 12H1C0.447715 12 0 11.5523 0 11ZM18 11C18 10.4477 18.4477 10 19 10H21C21.5523 10 22 10.4477 22 11C22 11.5523 21.5523 12 21 12H19C18.4477 12 18 11.5523 18 11ZM6.05025 15.9497C6.44078 16.3403 6.44078 16.9734 6.05025 17.364L4.63604 18.7782C4.24551 19.1687 3.61235 19.1687 3.22183 18.7782C2.8313 18.3876 2.8313 17.7545 3.22183 17.364L4.63604 15.9497C5.02656 15.5592 5.65973 15.5592 6.05025 15.9497ZM15.9497 15.9497C16.3403 15.5592 16.9734 15.5592 17.364 15.9497L18.7782 17.364C19.1687 17.7545 19.1687 18.3876 18.7782 18.7782C18.3877 19.1687 17.7545 19.1687 17.364 18.7782L15.9497 17.364C15.5592 16.9734 15.5592 16.3403 15.9497 15.9497ZM11 18C11.5523 18 12 18.4477 12 19V21C12 21.5523 11.5523 22 11 22C10.4477 22 10 21.5523 10 21V19C10 18.4477 10.4477 18 11 18Z" fill="currentColor"></path></svg> <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg" class="hidden dark:block w-4 h-4 astro-3ef6ksr2 " ><path d="M10.7836 0.470481C10.9676 0.765118 10.9855 1.13415 10.8309 1.44525C10.2994 2.51497 10 3.7211 10 5.00001C10 9.41829 13.5817 13 18 13L18.0575 12.9998C18.4049 12.9974 18.7287 13.1754 18.9127 13.47C19.0968 13.7647 19.1147 14.1337 18.9601 14.4448C17.325 17.7352 13.9279 20 10 20C4.47715 20 0 15.5229 0 10C0 4.50107 4.43841 0.038857 9.92838 0.000268937C10.2758 -0.00217271 10.5995 0.175844 10.7836 0.470481ZM8.40989 2.15803C4.75344 2.8954 2 6.12619 2 10C2 14.4183 5.58172 18 10 18C12.587 18 14.8886 16.7721 16.3516 14.8648C11.6131 14.0789 8 9.96139 8 5.00001C8 4.01361 8.1431 3.05953 8.40989 2.15803Z" fill="currentColor"></path></svg> </button> <button type="button" data-header-search-button aria-label="Search the API docs" aria-controls="header-search-overlay" aria-expanded="false" class="text-secondary hover:text-default transition-colors md:inline-flex xl:hidden astro-3ef6ksr2"> <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="w-4 h-4 text-secondary hover:text-default transition-colors astro-3ef6ksr2 " ><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg> </button> <!-- Mobile Menu Button --> <button id="header-drawer-button" type="button" aria-label="Toggle menu" aria-controls="drawer" aria-expanded="false" class="md:hidden relative right-1 text-secondary hover:text-default transition-colors astro-3ef6ksr2"> <svg width="18" height="10" viewBox="0 0 18 10" fill="none" xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 text-secondary hover:text-default transition-colors astro-3ef6ksr2 " ><path d="M0 1C0 0.447715 0.447715 0 1 0H17C17.5523 0 18 0.447715 18 1C18 1.55228 17.5523 2 17 2H1C0.447715 2 0 1.55228 0 1ZM0 9C0 8.44772 0.447715 8 1 8H11C11.5523 8 12 8.44772 12 9C12 9.55229 11.5523 10 11 10H1C0.447715 10 0 9.55229 0 9Z" fill="currentColor"></path></svg> </button> </div> </div> </header> <div id="header-search-overlay" role="dialog" aria-modal="true" aria-labelledby="header-search-title" aria-hidden="true" data-open="false" class="fixed inset-0 z-[60] hidden items-start justify-center px-4 pt-20 pb-10 md:px-6 md:pt-24 astro-3ef6ksr2"> <div class="absolute inset-0 bg-black/35 backdrop-blur-xs transition-opacity dark:bg-black/70 astro-3ef6ksr2" data-header-search-dismiss></div> <div class="relative z-10 w-full max-w-4xl overflow-hidden rounded-[28px] bg-surface shadow-[0_36px_120px_-48px_rgba(15,23,42,0.55)] ring-1 ring-black/10 dark:ring-white/10 astro-3ef6ksr2" data-header-search-panel> <div data-header-search-body class="p-0 astro-3ef6ksr2"> <h2 id="header-search-title" class="sr-only astro-3ef6ksr2"> Search the API docs </h2> <div class="relative flex min-h-0 flex-1 flex-col astro-3ef6ksr2"> <button type="button" data-header-search-close aria-label="Close search" class="absolute right-5 top-7 z-20 inline-flex h-8 w-8 shrink-0 appearance-none items-center justify-center rounded-md border-0 bg-transparent p-0 leading-none text-tertiary shadow-none transition-colors hover:text-default focus-visible:outline-none focus-visible:ring-0 md:right-7 astro-3ef6ksr2"> <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="h-[18px] w-[18px] shrink-0 astro-3ef6ksr2 " ><path d="M18 6 6 18"></path><path d="m6 6 12 12"></path></svg> </button> <astro-island uid="Z19tmGq" prefix="r112" component-url="/_astro/AlgoliaSearch.react.DMaHK7Vr.js" component-export="default" renderer-url="/_astro/client.BWriqC1y.js" props="{&quot;id&quot;:[0,&quot;header-site-search&quot;],&quot;className&quot;:[0,&quot;pagefind-header-ui pagefind-desktop-ui oai-site-search-overlay astro-3ef6ksr2&quot;],&quot;query&quot;:[0,&quot;&quot;],&quot;scope&quot;:[0,&quot;api&quot;],&quot;uiOptions&quot;:[0,{&quot;showImages&quot;:[0,false],&quot;showSubResults&quot;:[0,false],&quot;translations&quot;:[0,{&quot;placeholder&quot;:[0,&quot;Start searching&quot;],&quot;zeroResults&quot;:[0,&quot;No matches yet. Try a different keyword.&quot;]}]}]}" ssr client="load" opts="{&quot;name&quot;:&quot;AlgoliaSearchReact&quot;,&quot;value&quot;:true}" await-children><div id="header-site-search" class="pagefind-header-ui pagefind-desktop-ui oai-site-search-overlay astro-3ef6ksr2 _root_1wztd_1" data-site-search-root="true" data-site-search-provider="algolia" data-site-search-variant="overlay" data-query="" data-scope="api"><div class="flex h-full min-h-0 flex-col gap-0"><div class="shrink-0 border-b border-primary-surface px-4 py-4 md:px-6 md:py-5"><label class="sr-only" for="header-site-search-input">Search docs</label><input id="header-site-search-input" type="text" placeholder="Start searching" autoComplete="off" spellCheck="false" data-site-search-input="true" class="w-full outline-none transition-colors rounded-none border-0 bg-transparent py-0 pl-0 pr-14 text-[18px] leading-tight text-default placeholder:text-tertiary focus:ring-0 md:text-[18px]" value=""/></div><div class="flex min-h-0 flex-1 flex-col gap-4 px-4 py-4 md:px-6 md:py-5"><div data-site-search-empty-state="true" class="flex flex-col gap-4"><section class="_emptySection_1wztd_68"><h3 class="_emptyHeading_1wztd_74">Suggested</h3><div class="flex flex-wrap gap-2"><button type="button" class="_emptyChip_1wztd_81" data-search-query-button="true" data-search-query="responses create">responses create</button><button type="button" class="_emptyChip_1wztd_81" data-search-query-button="true" data-search-query="reasoning_effort">reasoning_effort</button><button type="button" class="_emptyChip_1wztd_81" data-search-query-button="true" data-search-query="realtime">realtime</button><button type="button" class="_emptyChip_1wztd_81" data-search-query-button="true" data-search-query="prompt caching">prompt caching</button></div></section></div></div></div></div><!--astro:end--></astro-island> </div> </div> </div> </div> <div id="drawer" data-default-tab-id="mobile-nav-tab-api" data-default-search-placeholder="Start searching" data-default-search-scope="api" class="fixed inset-0 z-40 flex flex-col bg-surface transform translate-x-full transition-transform duration-300 md:hidden astro-3ef6ksr2"> <div class="flex flex-col h-full w-full astro-3ef6ksr2"> <div class="px-6 pt-6 w-full mt-16 astro-3ef6ksr2"> <span id="mobile-nav-primary-label" class="sr-only astro-3ef6ksr2">Primary navigation</span> <div class="flex items-center gap-2 astro-3ef6ksr2"> <nav class="min-w-0 flex-1 flex items-center gap-2 overflow-x-auto pb-2 -mx-1 px-1 astro-3ef6ksr2" role="tablist" aria-labelledby="mobile-nav-primary-label"> <button type="button" role="tab" data-mobile-nav-tab data-tab-id="mobile-nav-tab-api" data-has-nav="true" data-href="/api/docs" data-label="API" data-search-placeholder="Start searching" data-search-scope="api" data-selected="true" aria-selected="true" class="shrink-0 rounded-full border border-primary-surface px-3.5 py-1.5 text-sm text-secondary transition-colors duration-150 data-[selected=true]:bg-primary-soft data-[selected=true]:text-default hover:bg-primary-soft-alpha hover:text-default focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-surface astro-3ef6ksr2"> API </button><button type="button" role="tab" data-mobile-nav-tab data-tab-id="mobile-nav-tab-api-reference" data-has-nav="false" data-href="/api/reference/overview" data-label="API Reference" data-search-placeholder="Start searching" data-search-scope="api" data-selected="false" aria-selected="false" class="shrink-0 rounded-full border border-primary-surface px-3.5 py-1.5 text-sm text-secondary transition-colors duration-150 data-[selected=true]:bg-primary-soft data-[selected=true]:text-default hover:bg-primary-soft-alpha hover:text-default focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-surface astro-3ef6ksr2"> API Reference </button><button type="button" role="tab" data-mobile-nav-tab data-tab-id="mobile-nav-tab-2" data-has-nav="true" data-href="/codex" data-label="Codex" data-search-placeholder="Start searching" data-search-scope="codex" data-selected="false" aria-selected="false" class="shrink-0 rounded-full border border-primary-surface px-3.5 py-1.5 text-sm text-secondary transition-colors duration-150 data-[selected=true]:bg-primary-soft data-[selected=true]:text-default hover:bg-primary-soft-alpha hover:text-default focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-surface astro-3ef6ksr2"> Codex </button><button type="button" role="tab" data-mobile-nav-tab data-tab-id="mobile-nav-tab-3" data-has-nav="true" data-href="/chatgpt" data-label="ChatGPT" data-search-placeholder="Start searching" data-search-scope="chatgpt" data-selected="false" aria-selected="false" class="shrink-0 rounded-full border border-primary-surface px-3.5 py-1.5 text-sm text-secondary transition-colors duration-150 data-[selected=true]:bg-primary-soft data-[selected=true]:text-default hover:bg-primary-soft-alpha hover:text-default focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-surface astro-3ef6ksr2"> ChatGPT </button><button type="button" role="tab" data-mobile-nav-tab data-tab-id="mobile-nav-tab-4" data-has-nav="true" data-href="/learn" data-label="Resources" data-search-placeholder="Start searching" data-search-scope="learn" data-selected="false" aria-selected="false" class="shrink-0 rounded-full border border-primary-surface px-3.5 py-1.5 text-sm text-secondary transition-colors duration-150 data-[selected=true]:bg-primary-soft data-[selected=true]:text-default hover:bg-primary-soft-alpha hover:text-default focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-surface astro-3ef6ksr2"> Resources </button> </nav> <button id="drawer-theme-button" type="button" aria-label="Toggle light and dark theme" class="shrink-0 mb-2 rounded-full border border-primary-surface p-2 text-secondary transition-colors hover:text-default astro-3ef6ksr2"> <svg width="22" height="22" viewBox="0 0 22 22" fill="none" xmlns="http://www.w3.org/2000/svg" class="block dark:hidden w-5 h-5 astro-3ef6ksr2 " ><path fill-rule="evenodd" clip-rule="evenodd" d="M11 0C11.5523 0 12 0.447715 12 1V3C12 3.55228 11.5523 4 11 4C10.4477 4 10 3.55228 10 3V1C10 0.447715 10.4477 0 11 0ZM3.22183 3.22183C3.61235 2.8313 4.24551 2.8313 4.63604 3.22183L6.05025 4.63604C6.44078 5.02656 6.44078 5.65973 6.05025 6.05025C5.65973 6.44078 5.02656 6.44078 4.63604 6.05025L3.22183 4.63604C2.8313 4.24551 2.8313 3.61235 3.22183 3.22183ZM18.7782 3.22183C19.1687 3.61235 19.1687 4.24551 18.7782 4.63604L17.364 6.05025C16.9734 6.44078 16.3403 6.44078 15.9497 6.05025C15.5592 5.65973 15.5592 5.02656 15.9497 4.63604L17.364 3.22183C17.7545 2.8313 18.3876 2.8313 18.7782 3.22183ZM11 8C9.34315 8 8 9.34315 8 11C8 12.6569 9.34315 14 11 14C12.6569 14 14 12.6569 14 11C14 9.34315 12.6569 8 11 8ZM6 11C6 8.23858 8.23858 6 11 6C13.7614 6 16 8.23858 16 11C16 13.7614 13.7614 16 11 16C8.23858 16 6 13.7614 6 11ZM0 11C0 10.4477 0.447715 10 1 10H3C3.55228 10 4 10.4477 4 11C4 11.5523 3.55228 12 3 12H1C0.447715 12 0 11.5523 0 11ZM18 11C18 10.4477 18.4477 10 19 10H21C21.5523 10 22 10.4477 22 11C22 11.5523 21.5523 12 21 12H19C18.4477 12 18 11.5523 18 11ZM6.05025 15.9497C6.44078 16.3403 6.44078 16.9734 6.05025 17.364L4.63604 18.7782C4.24551 19.1687 3.61235 19.1687 3.22183 18.7782C2.8313 18.3876 2.8313 17.7545 3.22183 17.364L4.63604 15.9497C5.02656 15.5592 5.65973 15.5592 6.05025 15.9497ZM15.9497 15.9497C16.3403 15.5592 16.9734 15.5592 17.364 15.9497L18.7782 17.364C19.1687 17.7545 19.1687 18.3876 18.7782 18.7782C18.3877 19.1687 17.7545 19.1687 17.364 18.7782L15.9497 17.364C15.5592 16.9734 15.5592 16.3403 15.9497 15.9497ZM11 18C11.5523 18 12 18.4477 12 19V21C12 21.5523 11.5523 22 11 22C10.4477 22 10 21.5523 10 21V19C10 18.4477 10.4477 18 11 18Z" fill="currentColor"></path></svg> <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg" class="hidden dark:block w-5 h-5 astro-3ef6ksr2 " ><path d="M10.7836 0.470481C10.9676 0.765118 10.9855 1.13415 10.8309 1.44525C10.2994 2.51497 10 3.7211 10 5.00001C10 9.41829 13.5817 13 18 13L18.0575 12.9998C18.4049 12.9974 18.7287 13.1754 18.9127 13.47C19.0968 13.7647 19.1147 14.1337 18.9601 14.4448C17.325 17.7352 13.9279 20 10 20C4.47715 20 0 15.5229 0 10C0 4.50107 4.43841 0.038857 9.92838 0.000268937C10.2758 -0.00217271 10.5995 0.175844 10.7836 0.470481ZM8.40989 2.15803C4.75344 2.8954 2 6.12619 2 10C2 14.4183 5.58172 18 10 18C12.587 18 14.8886 16.7721 16.3516 14.8648C11.6131 14.0789 8 9.96139 8 5.00001C8 4.01361 8.1431 3.05953 8.40989 2.15803Z" fill="currentColor"></path></svg> </button> </div> </div> <div class="flex-1 w-full overflow-y-auto px-6 py-4 flex flex-col gap-6 astro-3ef6ksr2" data-mobile-nav-panels> <div data-mobile-search class="astro-3ef6ksr2"> <astro-island uid="2m9xLh" prefix="r113" component-url="/_astro/AlgoliaSearch.react.DMaHK7Vr.js" component-export="default" renderer-url="/_astro/client.BWriqC1y.js" props="{&quot;id&quot;:[0,&quot;header-mobile-search&quot;],&quot;className&quot;:[0,&quot;pagefind-header-ui pagefind-mobile-ui astro-3ef6ksr2&quot;],&quot;query&quot;:[0,&quot;&quot;],&quot;scope&quot;:[0,&quot;api&quot;],&quot;uiOptions&quot;:[0,{&quot;showImages&quot;:[0,false],&quot;showSubResults&quot;:[0,false],&quot;translations&quot;:[0,{&quot;placeholder&quot;:[0,&quot;Start searching&quot;],&quot;zeroResults&quot;:[0,&quot;No matches yet. Try a different keyword.&quot;]}]}]}" ssr client="load" opts="{&quot;name&quot;:&quot;AlgoliaSearchReact&quot;,&quot;value&quot;:true}" await-children><div id="header-mobile-search" class="pagefind-header-ui pagefind-mobile-ui astro-3ef6ksr2 _root_1wztd_1" data-site-search-root="true" data-site-search-provider="algolia" data-site-search-variant="default" data-query="" data-scope="api"><div class="flex h-full min-h-0 flex-col gap-4"><div class=""><label class="sr-only" for="header-mobile-search-input">Search docs</label><input id="header-mobile-search-input" type="text" placeholder="Start searching" autoComplete="off" spellCheck="false" data-site-search-input="true" class="w-full outline-none transition-colors rounded-[18px] border border-transparent bg-primary-soft-alpha py-4 pl-6 pr-14 text-[18px] leading-tight text-default placeholder:text-tertiary focus:border-transparent focus:ring-0" value=""/></div><div class="flex min-h-0 flex-1 flex-col gap-4"><div data-site-search-empty-state="true" class="flex flex-col gap-4"><section class="_emptySection_1wztd_68"><h3 class="_emptyHeading_1wztd_74">Suggested</h3><div class="flex flex-wrap gap-2"><button type="button" class="_emptyChip_1wztd_81" data-search-query-button="true" data-search-query="responses create">responses create</button><button type="button" class="_emptyChip_1wztd_81" data-search-query-button="true" data-search-query="reasoning_effort">reasoning_effort</button><button type="button" class="_emptyChip_1wztd_81" data-search-query-button="true" data-search-query="realtime">realtime</button><button type="button" class="_emptyChip_1wztd_81" data-search-query-button="true" data-search-query="prompt caching">prompt caching</button></div></section></div></div></div></div><!--astro:end--></astro-island> </div> <div id="mobile-nav-panel-api" data-mobile-nav-content data-tab-id="mobile-nav-tab-api" data-default-variant-id="mobile-nav-tab-api-variant-default" class="flex flex-col gap-4 pb-8 astro-3ef6ksr2">  <div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-api-variant-default" class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Get started </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/api/docs/quickstart" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Quickstart   </a> </li><li> <a href="/api/docs/models" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Models   </a> </li><li> <a href="/api/docs/pricing" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Pricing   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <a href="/api/docs/libraries" class="flex-1 " data-mobile-nav-link> SDKs and CLI  </a> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/libraries" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> OpenAI SDK   </a> </li><li> <a href="/api/docs/guides/agents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Agents SDK   </a> </li><li> <a href="/api/docs/libraries/openai-cli" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> OpenAI CLI   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/latest-model" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Latest: GPT-5.5   </a> </li><li> <a href="/api/docs/guides/prompt-guidance" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Prompt guidance   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Core concepts </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/text" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Text generation   </a> </li><li> <a href="/api/docs/guides/code-generation" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Code generation   </a> </li><li> <a href="/api/docs/guides/images-vision" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Images and vision   </a> </li><li> <a href="/api/docs/guides/audio" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Audio and speech   </a> </li><li> <a href="/api/docs/guides/structured-outputs" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Structured output   </a> </li><li> <a href="/api/docs/guides/function-calling" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Function calling   </a> </li><li> <a href="/api/docs/guides/migrate-to-responses" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Responses API   </a> </li><li> <a href="/api/docs/guides/tools" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Using tools   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Agents SDK </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/agents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/api/docs/guides/agents/quickstart" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Quickstart   </a> </li><li> <a href="/api/docs/guides/agents/define-agents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Agent definitions   </a> </li><li> <a href="/api/docs/guides/agents/models" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Models and providers   </a> </li><li> <a href="/api/docs/guides/agents/running-agents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Running agents   </a> </li><li> <a href="/api/docs/guides/agents/sandboxes" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Sandbox agents   </a> </li><li> <a href="/api/docs/guides/agents/orchestration" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Orchestration   </a> </li><li> <a href="/api/docs/guides/agents/guardrails-approvals" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Guardrails   </a> </li><li> <a href="/api/docs/guides/agents/results" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Results and state   </a> </li><li> <a href="/api/docs/guides/agents/integrations-observability" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Integrations and observability   </a> </li><li> <a href="/api/docs/guides/agent-evals" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Evaluate agent workflows   </a> </li><li> <a href="/api/docs/guides/voice-agents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Voice agents   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">ChatKit</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/chatkit" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/api/docs/guides/chatkit-themes" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Customize   </a> </li><li> <a href="/api/docs/guides/chatkit-widgets" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Widgets   </a> </li><li> <a href="/api/docs/guides/chatkit-actions" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Actions   </a> </li><li> <a href="/api/docs/guides/custom-chatkit" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Advanced integrations   </a> </li> </ul> </details> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Tools </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/tools-web-search" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Web search   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <a href="/api/docs/guides/tools-connectors-mcp" class="flex-1 " data-mobile-nav-link> MCP and Connectors  </a> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/secure-mcp-tunnels" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Secure MCP Tunnel   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/tools-skills" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Skills   </a> </li><li> <a href="/api/docs/guides/tools-shell" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Shell   </a> </li><li> <a href="/api/docs/guides/tools-computer-use" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Computer use   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">File search and retrieval</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/tools-file-search" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> File search   </a> </li><li> <a href="/api/docs/guides/retrieval" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Retrieval   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/tools-tool-search" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Tool search   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">More tools</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/tools-apply-patch" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Apply Patch   </a> </li><li> <a href="/api/docs/guides/tools-local-shell" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Local shell   </a> </li><li> <a href="/api/docs/guides/tools-image-generation" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Image generation   </a> </li><li> <a href="/api/docs/guides/tools-code-interpreter" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Code interpreter   </a> </li> </ul> </details> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Run and scale </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/conversation-state" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Conversation state   </a> </li><li> <a href="/api/docs/guides/background" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Background mode   </a> </li><li> <a href="/api/docs/guides/streaming-responses" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Streaming   </a> </li><li> <a href="/api/docs/guides/websocket-mode" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> WebSocket mode   </a> </li><li> <a href="/api/docs/guides/webhooks" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Webhooks   </a> </li><li> <a href="/api/docs/guides/file-inputs" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> File inputs   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Context management</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/compaction" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Compaction   </a> </li><li> <a href="/api/docs/guides/token-counting" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Counting tokens   </a> </li><li> <a href="/api/docs/guides/prompt-caching" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Prompt caching   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Prompting</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/prompting" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/api/docs/guides/prompt-engineering" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Prompt engineering   </a> </li><li> <a href="/api/docs/guides/citation-formatting" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Citation formatting   </a> </li><li> <a href="/api/docs/guides/prompting/migrate-from-prompt-object" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Migration guide   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Reasoning</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/reasoning" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Reasoning models   </a> </li><li> <a href="/api/docs/guides/reasoning-best-practices" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Reasoning best practices   </a> </li> </ul> </details> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Evaluation </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/red-teaming" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Red teaming   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Realtime and audio </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/realtime" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/api/docs/guides/voice-agents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Voice agents   </a> </li><li> <a href="/api/docs/guides/realtime-translation" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Live translation   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Transcription</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/realtime-transcription" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Realtime transcription   </a> </li><li> <a href="/api/docs/guides/speech-to-text" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Speech to text   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/text-to-speech" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Speech generation   </a> </li><li> <a href="/api/docs/guides/realtime-models-prompting" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Realtime prompting guide   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Connection methods</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/realtime-webrtc" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> WebRTC   </a> </li><li> <a href="/api/docs/guides/realtime-websocket" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> WebSocket   </a> </li><li> <a href="/api/docs/guides/realtime-sip" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> SIP   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Realtime sessions</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/realtime-conversations" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Managing conversations   </a> </li><li> <a href="/api/docs/guides/realtime-vad" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Voice activity detection   </a> </li><li> <a href="/api/docs/guides/realtime-mcp" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Realtime with tools   </a> </li><li> <a href="/api/docs/guides/realtime-server-controls" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Webhooks and server-side controls   </a> </li><li> <a href="/api/docs/guides/realtime-costs" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Managing costs   </a> </li> </ul> </details> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Specialized models </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/image-generation" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Image generation   </a> </li><li> <a href="/api/docs/guides/video-generation" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Video generation   </a> </li><li> <a href="/api/docs/guides/deep-research" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Deep research   </a> </li><li> <a href="/api/docs/guides/embeddings" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Embeddings   </a> </li><li> <a href="/api/docs/guides/moderation" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Moderation   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Going live </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/production-best-practices" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Production best practices   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <a href="/api/docs/guides/workload-identity-federation" class="flex-1 " data-mobile-nav-link> Workload identity federation  </a> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/workload-identity-federation" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/kubernetes" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Kubernetes   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/aws" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> AWS   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/microsoft-azure" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Microsoft Azure   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/google-cloud" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Google Cloud   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/github-actions" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> GitHub Actions   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/spiffe" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> SPIFFE   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/deployment-checklist" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Deployment checklist   </a> </li><li> <a href="/api/docs/guides/amazon-bedrock" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Amazon Bedrock   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Latency optimization</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/latency-optimization" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/api/docs/guides/predicted-outputs" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Predicted Outputs   </a> </li><li> <a href="/api/docs/guides/priority-processing" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Priority processing   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Cost optimization</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/cost-optimization" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/api/docs/guides/batch" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Batch   </a> </li><li> <a href="/api/docs/guides/flex-processing" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Flex processing   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/optimizing-llm-accuracy" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Accuracy optimization   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Safety</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/safety-best-practices" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Safety best practices   </a> </li><li> <a href="/api/docs/guides/safety-checks" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Safety checks   </a> </li><li> <a href="/api/docs/guides/safety-checks/cybersecurity" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Cybersecurity checks   </a> </li><li> <a href="/api/docs/guides/safety-checks/under-18-api-guidance" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Under 18 API Guidance   </a> </li> </ul> </details> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Legacy APIs </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Agent Builder</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/agent-builder" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/api/docs/guides/agent-builder/migrate-from-agent-builder" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Migration guide   </a> </li><li> <a href="/api/docs/guides/node-reference" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Node reference   </a> </li><li> <a href="/api/docs/guides/agent-builder-safety" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Safety in building agents   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Evals</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/evaluation-getting-started" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Getting started   </a> </li><li> <a href="/api/docs/guides/evals" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Working with evals   </a> </li><li> <a href="/api/docs/guides/prompt-optimizer" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Prompt optimizer   </a> </li><li> <a href="/api/docs/guides/external-models" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> External models   </a> </li><li> <a href="/api/docs/guides/evaluation-best-practices" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Best practices   </a> </li><li> <a href="/api/docs/guides/graders" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Graders   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Fine-tuning</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/model-optimization" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Optimization cycle   </a> </li><li> <a href="/api/docs/guides/supervised-fine-tuning" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Supervised fine-tuning   </a> </li><li> <a href="/api/docs/guides/vision-fine-tuning" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Vision fine-tuning   </a> </li><li> <a href="/api/docs/guides/direct-preference-optimization" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Direct preference optimization   </a> </li><li> <a href="/api/docs/guides/reinforcement-fine-tuning" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Reinforcement fine-tuning   </a> </li><li> <a href="/api/docs/guides/rft-use-cases" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> RFT use cases   </a> </li><li> <a href="/api/docs/guides/fine-tuning-best-practices" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Best practices   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure" open> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Assistants API</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/assistants/migration" class="px-3 py-1.5 rounded-lg transition-colors block text-default bg-primary-ghost-active " data-mobile-nav-link> Migration guide   </a> </li><li> <a href="/api/docs/assistants/deep-dive" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Deep dive   </a> </li><li> <a href="/api/docs/assistants/tools" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Tools   </a> </li> </ul> </details> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Resources </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="https://openai.com/policies" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover flex items-center justify-between gap-2" target="_blank" rel="noopener noreferrer" data-mobile-nav-link> Terms and policies  <svg viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg" class="w-2 h-2 inline-block ml-1 text-gray-600 dark:text-gray-300 " ><path d="M10.2426 0.757385C10.7949 0.757385 11.2426 1.2051 11.2426 1.75738V8.82845C11.2426 9.38074 10.7949 9.82845 10.2426 9.82845C9.69035 9.82845 9.24264 9.38074 9.24264 8.82845V4.1716L2.46446 10.9498C2.07394 11.3403 1.44077 11.3403 1.05025 10.9498C0.659724 10.5592 0.659723 9.92608 1.05025 9.53556L7.82842 2.75739H3.17157C2.61928 2.75739 2.17157 2.30967 2.17157 1.75738C2.17157 1.2051 2.61928 0.757385 3.17157 0.757385H10.2426Z" fill="currentColor"></path></svg> </a> </li><li> <a href="/api/docs/changelog" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Changelog   </a> </li><li> <a href="/api/docs/guides/your-data" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Your data   </a> </li><li> <a href="/api/docs/guides/rbac" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Permissions   </a> </li><li> <a href="/api/docs/guides/rate-limits" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Rate limits   </a> </li><li> <a href="/api/docs/guides/ip-addresses" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> IP egress ranges   </a> </li><li> <a href="/api/docs/guides/admin-apis" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Admin APIs   </a> </li><li> <a href="/api/docs/deprecations" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Deprecations   </a> </li><li> <a href="/api/docs/mcp" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> MCP for deep research   </a> </li><li> <a href="/api/docs/guides/developer-mode" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Developer mode   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">ChatGPT Actions</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/actions/introduction" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Introduction   </a> </li><li> <a href="/api/docs/actions/getting-started" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Getting started   </a> </li><li> <a href="/api/docs/actions/actions-library" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Actions library   </a> </li><li> <a href="/api/docs/actions/authentication" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Authentication   </a> </li><li> <a href="/api/docs/actions/production" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Production   </a> </li><li> <a href="/api/docs/actions/data-retrieval" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Data retrieval   </a> </li><li> <a href="/api/docs/actions/sending-files" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Sending files   </a> </li> </ul> </details> </li> </ul> </div> </div> </div><div id="mobile-nav-panel-2" data-mobile-nav-content data-tab-id="mobile-nav-tab-2" data-default-variant-id="mobile-nav-tab-2-variant-0" hidden class="flex flex-col gap-4 pb-8 astro-3ef6ksr2"> <div class="group flex flex-col gap-1 astro-3ef6ksr2" data-mobile-context-options data-context-active="false"> <button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-2-variant-0" data-context-label="Docs" data-context-href="/codex" data-context-is-home="false" data-selected="true"> Docs </button><button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-2-variant-1" data-context-label="Use cases" data-context-href="/codex/use-cases" data-context-is-home="false" data-selected="false"> Use cases </button> </div> <div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-2-variant-0" class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Getting Started </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/codex/quickstart" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Quickstart   </a> </li><li> <a href="/codex/use-cases" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Explore use cases   </a> </li><li> <a href="/codex/import" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Import to Codex   </a> </li><li> <a href="/codex/pricing" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Pricing   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Concepts</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/prompting" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Prompting   </a> </li><li> <a href="/codex/concepts/customization" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Customization   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <a href="/codex/memories" class="flex-1 " data-mobile-nav-link> Memories  </a> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/memories/chronicle" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Chronicle   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <a href="/codex/concepts/sandboxing" class="flex-1 " data-mobile-nav-link> Sandboxing  </a> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/concepts/sandboxing/auto-review" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Auto-review   </a> </li> </ul> </details> </li><li> <a href="/codex/concepts/subagents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Subagents   </a> </li><li> <a href="/codex/workflows" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Workflows   </a> </li><li> <a href="/codex/models" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Models   </a> </li><li> <a href="/codex/concepts/cyber-safety" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Cyber Safety   </a> </li><li> <a href="/codex/glossary" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Glossary   </a> </li> </ul> </details> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Using Codex </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">App</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/app" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/codex/app/features" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Features   </a> </li><li> <a href="/codex/app/settings" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Settings   </a> </li><li> <a href="/codex/app/review" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Review   </a> </li><li> <a href="/codex/app/automations" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Automations   </a> </li><li> <a href="/codex/app/worktrees" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Worktrees   </a> </li><li> <a href="/codex/app/local-environments" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Local Environments   </a> </li><li> <a href="/codex/app/browser" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> In-app browser   </a> </li><li> <a href="/codex/app/chrome-extension" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Chrome extension   </a> </li><li> <a href="/codex/app/computer-use" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Computer Use   </a> </li><li> <a href="/codex/appshots" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Appshots   </a> </li><li> <a href="/codex/app/commands" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Commands   </a> </li><li> <a href="/codex/app/windows" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Windows   </a> </li><li> <a href="/codex/app/troubleshooting" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Troubleshooting   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">IDE Extension</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/ide" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/codex/ide/features" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Features   </a> </li><li> <a href="/codex/ide/settings" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Settings   </a> </li><li> <a href="/codex/ide/commands" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> IDE Commands   </a> </li><li> <a href="/codex/ide/slash-commands" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Slash commands   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">CLI</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/cli" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/codex/cli/features" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Features   </a> </li><li> <a href="/codex/cli/reference" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Command Line Options   </a> </li><li> <a href="/codex/cli/slash-commands" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Slash commands   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Web</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/cloud" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/codex/cloud/environments" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Environments   </a> </li><li> <a href="/codex/cloud/internet-access" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Internet Access   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Integrations</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/integrations/github" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> GitHub   </a> </li><li> <a href="/codex/integrations/slack" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Slack   </a> </li><li> <a href="/codex/integrations/linear" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Linear   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Codex Security</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/security" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Codex Security plugin</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/security/plugin" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Quickstart   </a> </li><li> <a href="/codex/security/plugin/scans" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Run a security scan   </a> </li><li> <a href="/codex/security/plugin/deep-scans" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Run a deep scan   </a> </li><li> <a href="/codex/security/plugin/code-changes" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Review code changes   </a> </li><li> <a href="/codex/security/plugin/triage-backlog" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Triage a backlog   </a> </li><li> <a href="/codex/security/plugin/fix-findings" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Fix findings   </a> </li><li> <a href="/codex/security/plugin/export-findings" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Export and track findings   </a> </li><li> <a href="/codex/security/plugin/changelog" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Changelog   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Codex Security cloud</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/security/setup" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Setup   </a> </li><li> <a href="/codex/security/threat-model" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Improving the threat model   </a> </li> </ul> </details> </li><li> <a href="/codex/security/faq" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> FAQ   </a> </li> </ul> </details> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Configuration </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Config File</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/config-basic" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Config Basics   </a> </li><li> <a href="/codex/config-advanced" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Advanced Config   </a> </li><li> <a href="/codex/config-reference" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Config Reference   </a> </li><li> <a href="/codex/environment-variables" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Environment Variables   </a> </li><li> <a href="/codex/config-sample" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Sample Config   </a> </li> </ul> </details> </li><li> <a href="/codex/permissions" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Permissions   </a> </li><li> <a href="/codex/speed" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Speed   </a> </li><li> <a href="/codex/rules" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Rules   </a> </li><li> <a href="/codex/hooks" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Hooks   </a> </li><li> <a href="/codex/guides/agents-md" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> AGENTS.md   </a> </li><li> <a href="/codex/mcp" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> MCP   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Plugins</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/plugins" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/codex/plugins/build" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Build plugins   </a> </li> </ul> </details> </li><li> <a href="/codex/sites" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Sites   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Skills</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/skills" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/codex/record-and-replay" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Record &amp; Replay   </a> </li> </ul> </details> </li><li> <a href="/codex/subagents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Subagents   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Administration </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Authentication</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/auth" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/codex/enterprise/access-tokens" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Access tokens   </a> </li> </ul> </details> </li><li> <a href="/codex/agent-approvals-security" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Agent approvals &amp; security   </a> </li><li> <a href="/codex/remote-connections" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Remote connections   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Deployment</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/amazon-bedrock" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Amazon Bedrock   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Enterprise</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/enterprise/admin-setup" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Admin Setup   </a> </li><li> <a href="/codex/enterprise/governance" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Governance   </a> </li><li> <a href="/codex/enterprise/managed-configuration" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Managed configuration   </a> </li> </ul> </details> </li><li> <a href="/codex/windows" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Windows   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Automation </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/noninteractive" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Non-interactive Mode   </a> </li><li> <a href="/codex/sdk" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Codex SDK   </a> </li><li> <a href="/codex/app-server" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> App Server   </a> </li><li> <a href="/codex/guides/agents-sdk" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> MCP Server   </a> </li><li> <a href="/codex/github-action" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> GitHub Action   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Learn </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/learn/best-practices" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Best practices   </a> </li><li> <a href="/codex/videos" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Videos   </a> </li><li> <a href="/community" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Community   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Blog</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/blog/mastering-codex-remote-for-engineering" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Mastering Codex Remote for engineering   </a> </li><li> <a href="/blog/skills-agents-sdk" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Using skills to accelerate OSS maintenance   </a> </li><li> <a href="/blog/topic/codex" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> View all   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Cookbooks</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/cookbook/examples/agents_sdk/agent_improvement_loop" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Build an Agent Improvement Loop with Traces, Evals, and Codex   </a> </li><li> <a href="/cookbook/examples/codex/build_iterative_repair_loops_with_codex" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Build iterative repair loops with Codex   </a> </li><li> <a href="/cookbook/topic/codex" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> View all   </a> </li> </ul> </details> </li><li> <a href="/codex/guides/build-ai-native-engineering-team" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Building AI Teams   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Releases </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/changelog" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Changelog   </a> </li><li> <a href="/codex/feature-maturity" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Feature Maturity   </a> </li><li> <a href="/codex/open-source" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Open Source   </a> </li> </ul> </div> </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-2-variant-1" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/use-cases" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Home   </a> </li><li> <a href="/codex/use-cases/collections" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Collections   </a> </li> </ul> </div> </div> </div><div id="mobile-nav-panel-3" data-mobile-nav-content data-tab-id="mobile-nav-tab-3" data-default-variant-id="mobile-nav-tab-3-variant-0" hidden class="flex flex-col gap-4 pb-8 astro-3ef6ksr2"> <div class="group flex flex-col gap-1 astro-3ef6ksr2" data-mobile-context-options data-context-active="false"> <button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-3-variant-1" data-context-label="Apps SDK" data-context-href="/apps-sdk" data-context-is-home="false" data-selected="false"> Apps SDK </button><button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-3-variant-2" data-context-label="Workspace Agents" data-context-href="/workspace-agents" data-context-is-home="false" data-selected="false"> Workspace Agents </button><button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-3-variant-3" data-context-label="Commerce" data-context-href="/commerce" data-context-is-home="false" data-selected="false"> Commerce </button><button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-3-variant-4" data-context-label="Ads" data-context-href="/ads" data-context-is-home="false" data-selected="false"> Ads </button> </div> <div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-3-variant-0" class="flex flex-col gap-6 astro-3ef6ksr2">  </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-3-variant-1" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/apps-sdk" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Home   </a> </li><li> <a href="/apps-sdk/quickstart" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Quickstart   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Core Concepts </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/apps-sdk/mcp-apps-in-chatgpt" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> MCP Apps in ChatGPT   </a> </li><li> <a href="/apps-sdk/concepts/mcp-server" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> MCP Server   </a> </li><li> <a href="/apps-sdk/concepts/ux-principles" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> UX principles   </a> </li><li> <a href="/apps-sdk/concepts/ui-guidelines" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> UI guidelines   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Plan </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/apps-sdk/plan/use-case" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Research use cases   </a> </li><li> <a href="/apps-sdk/plan/tools" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Define tools   </a> </li><li> <a href="/apps-sdk/plan/components" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Design components   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Build </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/apps-sdk/build/mcp-server" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Set up your server   </a> </li><li> <a href="/apps-sdk/build/chatgpt-ui" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Build your ChatGPT UI   </a> </li><li> <a href="/apps-sdk/build/auth" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Authenticate users   </a> </li><li> <a href="/apps-sdk/build/state-management" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Manage state   </a> </li><li> <a href="/apps-sdk/build/monetization" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Monetize your app   </a> </li><li> <a href="/apps-sdk/build/examples" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Examples   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Deploy </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/apps-sdk/deploy" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Deploy your app   </a> </li><li> <a href="/apps-sdk/deploy/connect-chatgpt" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Connect from ChatGPT   </a> </li><li> <a href="/apps-sdk/deploy/testing" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Test your integration   </a> </li><li> <a href="/apps-sdk/deploy/submission" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Submit your app   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Conversion apps </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/apps-sdk/guides/restaurant-reservation-conversion-spec" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Restaurant reservation spec   </a> </li><li> <a href="/apps-sdk/guides/product-checkout-conversion-spec" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Product checkout spec   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Guides </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/apps-sdk/guides/optimize-metadata" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Optimize Metadata   </a> </li><li> <a href="/apps-sdk/guides/security-privacy" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Security &amp; Privacy   </a> </li><li> <a href="/apps-sdk/deploy/troubleshooting" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Troubleshooting   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Resources </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/apps-sdk/changelog" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Changelog   </a> </li><li> <a href="/apps-sdk/app-submission-guidelines" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> App submission guidelines   </a> </li><li> <a href="/apps-sdk/reference" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Reference   </a> </li> </ul> </div> </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-3-variant-2" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/workspace-agents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Home   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Get started </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/workspace-agents/trigger-runs" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Trigger workspace agent runs   </a> </li><li> <a href="/workspace-agents/authentication" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Authenticate with Workspace Agent access tokens   </a> </li> </ul> </div> </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-3-variant-3" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/commerce" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Home   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Guides </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/commerce/guides/get-started" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Get started   </a> </li><li> <a href="/commerce/guides/best-practices" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Best practices   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> File Upload </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/commerce/specs/file-upload/overview" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/commerce/specs/file-upload/products" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Products   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> API </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/commerce/specs/api/overview" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/commerce/specs/api/feeds" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Feeds   </a> </li><li> <a href="/commerce/specs/api/products" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Products   </a> </li><li> <a href="/commerce/specs/api/promotions" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Promotions   </a> </li> </ul> </div> </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-3-variant-4" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/ads" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Ads Overview   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Measurement </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/ads/measurement-pixel" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> JavaScript Pixel   </a> </li><li> <a href="/ads/image-tag" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Image tag   </a> </li><li> <a href="/ads/conversions-api" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Conversions API   </a> </li><li> <a href="/ads/supported-events" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Supported events   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Advertiser API </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/ads/api-overview" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/ads/api-quickstart" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Quickstart   </a> </li><li> <a href="/ads/product-feeds" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Product feeds   </a> </li><li> <a href="/ads/campaign-targeting" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Campaign Targeting   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> API Reference </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/ads/api-reference/authentication" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Authentication   </a> </li><li> <a href="/ads/api-reference/campaigns" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Campaigns   </a> </li><li> <a href="/ads/api-reference/ad-groups" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Ad Groups   </a> </li><li> <a href="/ads/api-reference/ads" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Ads   </a> </li><li> <a href="/ads/api-reference/ad-account" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Ad Account   </a> </li><li> <a href="/ads/api-reference/insights" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Insights   </a> </li><li> <a href="/ads/api-reference/files" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Files   </a> </li> </ul> </div> </div> </div><div id="mobile-nav-panel-4" data-mobile-nav-content data-tab-id="mobile-nav-tab-4" data-default-variant-id="mobile-nav-tab-4-variant-0" hidden class="flex flex-col gap-4 pb-8 astro-3ef6ksr2"> <div class="group flex flex-col gap-1 astro-3ef6ksr2" data-mobile-context-options data-context-active="false"> <button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-4-variant-1" data-context-label="Showcase" data-context-href="/showcase" data-context-is-home="false" data-selected="false"> Showcase </button><button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-4-variant-2" data-context-label="Blog" data-context-href="/blog" data-context-is-home="false" data-selected="false"> Blog </button><button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-4-variant-3" data-context-label="Cookbook" data-context-href="/cookbook" data-context-is-home="false" data-selected="false"> Cookbook </button><button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-4-variant-4" data-context-label="Learn" data-context-href="/learn" data-context-is-home="false" data-selected="false"> Learn </button><button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-4-variant-5" data-context-label="Community" data-context-href="/community" data-context-is-home="false" data-selected="false"> Community </button> </div> <div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-4-variant-0" class="flex flex-col gap-6 astro-3ef6ksr2">  </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-4-variant-1" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/showcase" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Home   </a> </li><li> <a href="/showcase/api-examples" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> API examples   </a> </li><li> <a href="/showcase/sites" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Sites   </a> </li> </ul> </div> </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-4-variant-2" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/blog" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> All posts   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Recent </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/blog/mastering-codex-remote-for-engineering" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Mastering Codex Remote for engineering   </a> </li><li> <a href="/blog/realtime-perplexity-computer" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> How Perplexity Brought Voice Search to Millions Using the Realtime API   </a> </li><li> <a href="/blog/designing-delightful-frontends-with-gpt-5-4" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Designing delightful frontends with GPT-5.4   </a> </li><li> <a href="/blog/one-year-of-responses" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> From prompts to products: One year of Responses   </a> </li><li> <a href="/blog/skills-agents-sdk" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Using skills to accelerate OSS maintenance   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Topics </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/blog/topic/general" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> General   </a> </li><li> <a href="/blog/topic/api" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> API   </a> </li><li> <a href="/blog/topic/apps-sdk" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Apps SDK   </a> </li><li> <a href="/blog/topic/audio" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Audio   </a> </li><li> <a href="/blog/topic/codex" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Codex   </a> </li> </ul> </div> </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-4-variant-3" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/cookbook" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Home   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Topics </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/cookbook/topic/agents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Agents   </a> </li><li> <a href="/cookbook/topic/evals" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Evals   </a> </li><li> <a href="/cookbook/topic/multimodal" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Multimodal   </a> </li><li> <a href="/cookbook/topic/text" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Text   </a> </li><li> <a href="/cookbook/topic/guardrails" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Guardrails   </a> </li><li> <a href="/cookbook/topic/optimization" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Optimization   </a> </li><li> <a href="/cookbook/topic/chatgpt" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> ChatGPT   </a> </li><li> <a href="/cookbook/topic/codex" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Codex   </a> </li><li> <a href="/cookbook/topic/gpt-oss" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> gpt-oss   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Contribute </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="https://github.com/openai/openai-cookbook" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover flex items-center justify-between gap-2" target="_blank" rel="noopener noreferrer" data-mobile-nav-link> Cookbook on GitHub  <svg viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg" class="w-2 h-2 inline-block ml-1 text-gray-600 dark:text-gray-300 " ><path d="M10.2426 0.757385C10.7949 0.757385 11.2426 1.2051 11.2426 1.75738V8.82845C11.2426 9.38074 10.7949 9.82845 10.2426 9.82845C9.69035 9.82845 9.24264 9.38074 9.24264 8.82845V4.1716L2.46446 10.9498C2.07394 11.3403 1.44077 11.3403 1.05025 10.9498C0.659724 10.5592 0.659723 9.92608 1.05025 9.53556L7.82842 2.75739H3.17157C2.61928 2.75739 2.17157 2.30967 2.17157 1.75738C2.17157 1.2051 2.61928 0.757385 3.17157 0.757385H10.2426Z" fill="currentColor"></path></svg> </a> </li> </ul> </div> </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-4-variant-4" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/learn" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Home   </a> </li><li> <a href="/learn/developers-codex-plugin" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> OpenAI Developers plugin   </a> </li><li> <a href="/learn/docs-mcp" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Docs MCP   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Categories </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/learn/code" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Demo apps   </a> </li><li> <a href="/learn/videos" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Videos   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Topics </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/learn/agents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Agents   </a> </li><li> <a href="/learn/audio" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Audio &amp; Voice   </a> </li><li> <a href="/learn/cua" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Computer Use   </a> </li><li> <a href="/learn/codex" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Codex   </a> </li><li> <a href="/learn/evals" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Evals   </a> </li><li> <a href="/learn/gpt-oss" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> gpt-oss   </a> </li><li> <a href="/learn/fine-tuning" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Fine-tuning   </a> </li><li> <a href="/learn/imagegen" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Image generation   </a> </li><li> <a href="/learn/scaling" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Scaling   </a> </li><li> <a href="/learn/tools" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Tools   </a> </li><li> <a href="/learn/videogen" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Video generation   </a> </li> </ul> </div> </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-4-variant-5" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/community" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Community   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Programs </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/community/codex-ambassadors" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Codex Ambassadors   </a> </li><li> <a href="/community/students" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Codex for Students   </a> </li><li> <a href="/community/codex-for-oss" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Codex for Open Source   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Events </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/community/meetups" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Meetups   </a> </li><li> <a href="/community/hackathons" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Hackathon Support   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="https://community.openai.com/" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover flex items-center justify-between gap-2" target="_blank" rel="noopener noreferrer" data-mobile-nav-link> Forum  <svg viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg" class="w-2 h-2 inline-block ml-1 text-gray-600 dark:text-gray-300 " ><path d="M10.2426 0.757385C10.7949 0.757385 11.2426 1.2051 11.2426 1.75738V8.82845C11.2426 9.38074 10.7949 9.82845 10.2426 9.82845C9.69035 9.82845 9.24264 9.38074 9.24264 8.82845V4.1716L2.46446 10.9498C2.07394 11.3403 1.44077 11.3403 1.05025 10.9498C0.659724 10.5592 0.659723 9.92608 1.05025 9.53556L7.82842 2.75739H3.17157C2.61928 2.75739 2.17157 2.30967 2.17157 1.75738C2.17157 1.2051 2.61928 0.757385 3.17157 0.757385H10.2426Z" fill="currentColor"></path></svg> </a> </li><li> <a href="https://discord.com/invite/openai" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover flex items-center justify-between gap-2" target="_blank" rel="noopener noreferrer" data-mobile-nav-link> Discord  <svg viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg" class="w-2 h-2 inline-block ml-1 text-gray-600 dark:text-gray-300 " ><path d="M10.2426 0.757385C10.7949 0.757385 11.2426 1.2051 11.2426 1.75738V8.82845C11.2426 9.38074 10.7949 9.82845 10.2426 9.82845C9.69035 9.82845 9.24264 9.38074 9.24264 8.82845V4.1716L2.46446 10.9498C2.07394 11.3403 1.44077 11.3403 1.05025 10.9498C0.659724 10.5592 0.659723 9.92608 1.05025 9.53556L7.82842 2.75739H3.17157C2.61928 2.75739 2.17157 2.30967 2.17157 1.75738C2.17157 1.2051 2.61928 0.757385 3.17157 0.757385H10.2426Z" fill="currentColor"></path></svg> </a> </li> </ul> </div> </div> </div> </div> <div class="w-full px-6 py-6 border-t border-primary-surface astro-3ef6ksr2"> <div class="flex flex-col gap-5 astro-3ef6ksr2"> <div class="flex items-center gap-2 w-full gap-3 astro-3ef6ksr2"><a target="_blank" rel="noopener noreferrer" href="https://platform.openai.com/login" class="_Button_6dmow_1 not-prose flex-1 justify-center" data-color="primary" data-variant="solid" data-pill="" data-size="md"><span class="_ButtonInner_6dmow_4"><span class="">API Dashboard</span><svg width="1em" height="1em" viewBox="0 0 24 24" fill="currentColor" class="shrink-0"><path fill-rule="evenodd" d="M16.243 6.757a1 1 0 0 1 1 1v7.072a1 1 0 0 1-2 0v-4.657L8.464 16.95a1 1 0 0 1-1.414-1.414l6.778-6.779H9.172a1 1 0 0 1 0-2h7.07Z" clip-rule="evenodd"></path></svg></span></a></div> <div class="flex flex-wrap items-center gap-4 text-sm text-gray-700 dark:text-gray-300 astro-3ef6ksr2">  </div> </div> </div> </div> </div>  <script>
  const MOBILE_NAV_PERSIST_KEY = "mobile-nav:restore-open";

  const readPersistedMobileNavOpen = () => {
    try {
      return sessionStorage.getItem(MOBILE_NAV_PERSIST_KEY) === "true";
    } catch {
      return false;
    }
  };

  const setPersistedMobileNavOpen = (isOpen) => {
    try {
      if (isOpen) {
        sessionStorage.setItem(MOBILE_NAV_PERSIST_KEY, "true");
      } else {
        sessionStorage.removeItem(MOBILE_NAV_PERSIST_KEY);
      }
    } catch {}
  };

  function initializeMobileNavigation() {
    const drawer = document.getElementById("drawer");
    const drawerButton = document.getElementById("header-drawer-button");

    if (
      !drawer ||
      !drawerButton ||
      drawer.dataset.mobileNavInitialized === "true"
    ) {
      return;
    }

    const navTabElements = Array.from(
      drawer.querySelectorAll("[data-mobile-nav-tab]")
    );
    const defaultSearchPlaceholder =
      drawer.dataset.defaultSearchPlaceholder || "Search the site";
    const defaultSearchScope = drawer.dataset.defaultSearchScope || "";
    const headerSearchOverlay = document.getElementById(
      "header-search-overlay"
    );
    const navLinkElements = Array.from(
      drawer.querySelectorAll("[data-mobile-nav-link]")
    );
    const tabPanels = Array.from(
      drawer.querySelectorAll("[data-mobile-nav-content]")
    );
    const isStarlightApiReferenceRoute =
      window.location.pathname === "/api/reference" ||
      window.location.pathname.startsWith("/api/reference/");
    const shouldRestoreDrawerOpen =
      matchMedia("(max-width: 50rem)").matches &&
      !isStarlightApiReferenceRoute &&
      readPersistedMobileNavOpen();

    let activeTabId =
      drawer.dataset.defaultTabId ||
      navTabElements.find((tab) => tab.dataset.selected === "true")?.dataset
        .tabId ||
      null;

    const updateSelectedOption = (tabId) => {
      let selectedLabel = "";
      let selectedPlaceholder = "";
      let selectedScope = "";

      navTabElements.forEach((tab) => {
        const isSelected = tab.dataset.tabId === tabId;
        tab.dataset.selected = isSelected ? "true" : "false";
        tab.setAttribute("aria-selected", isSelected ? "true" : "false");

        if (isSelected && !selectedLabel) {
          selectedLabel = tab.dataset.label || tab.textContent?.trim() || "";
        }

        if (isSelected && !selectedPlaceholder) {
          selectedPlaceholder = tab.dataset.searchPlaceholder || "";
        }

        if (isSelected && !selectedScope) {
          selectedScope = tab.dataset.searchScope || "";
        }
      });

      if (!selectedLabel && navTabElements[0]) {
        selectedLabel =
          navTabElements[0].dataset.label ||
          navTabElements[0].textContent?.trim() ||
          "";
      }

      if (!selectedPlaceholder && navTabElements[0]) {
        selectedPlaceholder = navTabElements[0].dataset.searchPlaceholder || "";
      }

      if (!selectedScope && navTabElements[0]) {
        selectedScope = navTabElements[0].dataset.searchScope || "";
      }

      const nextPlaceholder = selectedPlaceholder || defaultSearchPlaceholder;
      const nextScope = selectedScope || defaultSearchScope;
      const updatePlaceholder = (container) => {
        if (!container) return;
        const input = container.querySelector("[data-site-search-input]");
        if (input instanceof HTMLInputElement) {
          input.placeholder = nextPlaceholder;
        }
      };
      const updateScope = (container) => {
        if (!container) return;
        const target = container.querySelector("[data-site-search-root]");
        if (!target) return;
        target.setAttribute("data-scope", nextScope);
        target.dispatchEvent(new CustomEvent("site-search:update"));
      };
      updatePlaceholder(drawer);
      updatePlaceholder(headerSearchOverlay);
      updateScope(drawer);
      updateScope(headerSearchOverlay);
    };

    const activeVariantByTabId = new Map();

    const getTabLabel = (tabId) => {
      return (
        navTabElements.find((tab) => tab.dataset.tabId === tabId)?.dataset
          .label || ""
      );
    };

    const updatePanelBreadcrumb = (panel, tabId, contextLabel) => {
      const breadcrumb = panel.querySelector("[data-mobile-breadcrumb]");
      const parent = panel.querySelector("[data-mobile-breadcrumb-parent]");
      const childWrapper = panel.querySelector(
        "[data-mobile-breadcrumb-child-wrapper]"
      );
      const child = panel.querySelector("[data-mobile-breadcrumb-child]");
      const contextOptions = panel.querySelector(
        "[data-mobile-context-options]"
      );

      if (contextOptions) {
        contextOptions.dataset.contextActive = contextLabel ? "true" : "false";
      }

      if (!breadcrumb || !parent || !childWrapper || !child) {
        return;
      }

      const tabLabel = getTabLabel(tabId);
      parent.textContent = tabLabel;

      if (!contextLabel) {
        breadcrumb.setAttribute("hidden", "true");
        childWrapper.setAttribute("hidden", "true");
        child.textContent = "";
        return;
      }

      breadcrumb.removeAttribute("hidden");
      childWrapper.removeAttribute("hidden");
      child.textContent = contextLabel;
    };

    const selectVariantForPanel = (panel, tabId, variantId) => {
      if (!variantId) {
        updatePanelBreadcrumb(panel, tabId, "");
        return;
      }

      const contextOptions = Array.from(
        panel.querySelectorAll("[data-mobile-context-option]")
      );
      let selectedContextLabel = "";

      contextOptions.forEach((option) => {
        const isSelected = option.dataset.contextId === variantId;
        option.dataset.selected = isSelected ? "true" : "false";
        if (isSelected) {
          selectedContextLabel = option.dataset.contextLabel || "";
        }
      });

      const variantSections = Array.from(
        panel.querySelectorAll("[data-mobile-nav-variant-content]")
      );
      variantSections.forEach((section) => {
        const isSelected = section.dataset.variantId === variantId;
        if (isSelected) {
          section.removeAttribute("hidden");
        } else {
          section.setAttribute("hidden", "true");
        }
      });

      updatePanelBreadcrumb(panel, tabId, selectedContextLabel);
      activeVariantByTabId.set(tabId, variantId);
    };

    const activateTab = (tabId) => {
      if (!tabId) return;
      activeTabId = tabId;
      updateSelectedOption(tabId);

      tabPanels.forEach((panel) => {
        const panelTabId = panel.getAttribute("data-tab-id");
        const isActive = panelTabId === tabId;
        if (isActive) {
          panel.removeAttribute("hidden");
          const defaultVariantId = panel.getAttribute(
            "data-default-variant-id"
          );
          const nextVariantId =
            activeVariantByTabId.get(tabId) ||
            defaultVariantId ||
            panel.querySelector("[data-mobile-nav-variant-content]")?.dataset
              .variantId ||
            "";
          selectVariantForPanel(panel, tabId, nextVariantId);
        } else {
          panel.setAttribute("hidden", "true");
        }
      });
    };

    const closeDrawer = () => {
      drawer.classList.remove("open");
      drawerButton.classList.remove("open");
      drawerButton.setAttribute("aria-expanded", "false");
      setPersistedMobileNavOpen(false);
    };

    const openDrawer = () => {
      drawer.classList.add("open");
      drawerButton.classList.add("open");
      drawerButton.setAttribute("aria-expanded", "true");
      if (activeTabId) {
        activateTab(activeTabId);
      }
    };

    const toggleDrawer = () => {
      if (drawer.classList.contains("open")) {
        closeDrawer();
      } else {
        openDrawer();
      }
    };

    const handleTabSelection = (tab) => {
      const hasNav = tab.dataset.hasNav === "true";
      const href = tab.dataset.href;
      const tabId = tab.dataset.tabId;

      if (!tabId) {
        return;
      }

      if (!hasNav && href) {
        setPersistedMobileNavOpen(true);
        window.location.href = href;
        return;
      }

      activateTab(tabId);
    };

    drawerButton.addEventListener("click", toggleDrawer);

    navTabElements.forEach((tab) => {
      tab.addEventListener("click", () => {
        handleTabSelection(tab);
      });

      tab.addEventListener("keydown", (event) => {
        if (!navTabElements.length) return;

        const currentIndex = navTabElements.indexOf(tab);

        if (event.key === "ArrowRight") {
          event.preventDefault();
          const nextIndex = (currentIndex + 1) % navTabElements.length;
          navTabElements[nextIndex]?.focus();
        } else if (event.key === "ArrowLeft") {
          event.preventDefault();
          const prevIndex =
            (currentIndex - 1 + navTabElements.length) % navTabElements.length;
          navTabElements[prevIndex]?.focus();
        } else if (event.key === "Home") {
          event.preventDefault();
          navTabElements[0]?.focus();
        } else if (event.key === "End") {
          event.preventDefault();
          navTabElements[navTabElements.length - 1]?.focus();
        } else if (
          event.key === "Enter" ||
          event.key === " " ||
          event.key === "Space" ||
          event.key === "Spacebar"
        ) {
          event.preventDefault();
          handleTabSelection(tab);
        } else if (event.key === "Escape") {
          event.preventDefault();
          closeDrawer();
          drawerButton.focus();
        }
      });
    });

    tabPanels.forEach((panel) => {
      const tabId = panel.getAttribute("data-tab-id") || "";
      const contextOptions = Array.from(
        panel.querySelectorAll("[data-mobile-context-option]")
      );

      contextOptions.forEach((option) => {
        option.addEventListener("click", () => {
          const contextHref = option.dataset.contextHref;
          if (
            contextHref &&
            contextHref.startsWith("/api/reference") &&
            tabId
          ) {
            closeDrawer();
            window.location.href = contextHref;
            return;
          }

          const variantId = option.dataset.contextId;
          if (!variantId || !tabId) {
            return;
          }

          selectVariantForPanel(panel, tabId, variantId);
        });
      });
    });

    navLinkElements.forEach((link) => {
      link.addEventListener("click", () => {
        closeDrawer();
      });
    });

    const mobileSearch = drawer.querySelector("[data-mobile-search]");
    mobileSearch?.addEventListener("click", (event) => {
      const target = event.target;
      if (target instanceof Element) {
        const anchor = target.closest("a[href]");
        if (anchor) {
          closeDrawer();
        }
      }
    });

    mobileSearch?.addEventListener("focusin", (event) => {
      const target = event.target;
      if (!(target instanceof HTMLInputElement) || target.type !== "text") {
        return;
      }
      closeDrawer();
      window.requestAnimationFrame(() => {
        if (document.activeElement === target) {
          target.blur();
        }
        document.dispatchEvent(
          new CustomEvent("header:open-search", {
            detail: {
              trigger: target,
              variant: "mobile",
            },
          })
        );
      });
    });

    drawer.addEventListener("keydown", (event) => {
      if (event.key === "Escape") {
        closeDrawer();
        drawerButton.focus();
      }
    });

    drawer.dataset.mobileNavInitialized = "true";
    if (activeTabId) {
      activateTab(activeTabId);
    }

    if (shouldRestoreDrawerOpen) {
      openDrawer();
      setPersistedMobileNavOpen(false);
    }
  }

  function initializeHeaderSearch() {
    const overlay = document.getElementById("header-search-overlay");
    if (!overlay) {
      return;
    }

    const getSearchButtons = () =>
      Array.from(document.querySelectorAll("[data-header-search-button]"));

    const closeButtons = overlay.querySelectorAll("[data-header-search-close]");
    const dismissTarget = overlay.querySelector("[data-header-search-dismiss]");
    const panel = overlay.querySelector("[data-header-search-panel]");
    const overlayMobileClass = "header-search-overlay--mobile";
    const panelMobileClass = "header-search-panel--mobile";
    let lastTrigger = null;
    let lastVariant = null;

    const setExpandedState = (isOpen) => {
      const expanded = isOpen ? "true" : "false";
      getSearchButtons().forEach((button) => {
        button.setAttribute("aria-expanded", expanded);
        button.setAttribute("data-active", expanded);
      });
      overlay.dataset.open = expanded;
      overlay.setAttribute("aria-hidden", isOpen ? "false" : "true");
    };

    const focusSearchInput = () => {
      window.requestAnimationFrame(() => {
        const input = overlay.querySelector("[data-site-search-input]");
        if (input) {
          input.focus();
          input.select();
        }
      });
    };

    const openOverlay = (trigger, options = {}) => {
      lastTrigger = trigger ?? document.activeElement;
      const variant = options.variant ?? null;
      lastVariant = typeof variant === "string" ? variant : null;
      overlay.classList.remove("hidden");
      overlay.classList.add("flex");
      const isMobileVariant = lastVariant === "mobile";
      if (isMobileVariant) {
        overlay.dataset.variant = "mobile";
      } else {
        delete overlay.dataset.variant;
      }
      overlay.classList.toggle(overlayMobileClass, isMobileVariant);
      panel?.classList.toggle(panelMobileClass, isMobileVariant);
      document.documentElement.classList.add("has-header-search-open");
      setExpandedState(true);
      focusSearchInput();
    };

    const closeOverlay = () => {
      overlay.classList.add("hidden");
      overlay.classList.remove("flex");
      document.documentElement.classList.remove("has-header-search-open");
      overlay.classList.remove(overlayMobileClass);
      panel?.classList.remove(panelMobileClass);
      delete overlay.dataset.variant;
      setExpandedState(false);
      if (lastTrigger instanceof HTMLElement) {
        if (
          lastVariant === "mobile" &&
          typeof lastTrigger.blur === "function"
        ) {
          lastTrigger.blur();
        } else if (lastVariant !== "mobile") {
          lastTrigger.focus();
        }
      }
      lastTrigger = null;
      lastVariant = null;
    };

    const bindSearchButtons = () => {
      getSearchButtons().forEach((button) => {
        if (button.dataset.searchButtonInitialized === "true") {
          return;
        }

        button.addEventListener("click", (event) => {
          event.preventDefault();
          openOverlay(button);
        });

        button.dataset.searchButtonInitialized = "true";
      });
    };

    if (overlay.dataset.searchInitialized !== "true") {
      closeButtons.forEach((button) => {
        button.addEventListener("click", () => {
          closeOverlay();
        });
      });

      overlay.addEventListener("click", (event) => {
        if (event.target === overlay) {
          closeOverlay();
        }
      });

      dismissTarget?.addEventListener("click", closeOverlay);

      const handleKeydown = (event) => {
        const key = "key" in event ? event.key : undefined;
        const isShortcut =
          !!key &&
          key.toLowerCase() === "k" &&
          (event.metaKey || event.ctrlKey);

        if (isShortcut) {
          event.preventDefault();
          const buttons = getSearchButtons();
          openOverlay(buttons[0] ?? null);
          return;
        }

        if (key === "Escape" && overlay.dataset.open === "true") {
          event.preventDefault();
          closeOverlay();
        }
      };

      document.addEventListener("keydown", handleKeydown);

      document.addEventListener("header:open-search", (event) => {
        const detail =
          event instanceof CustomEvent && typeof event.detail === "object"
            ? event.detail
            : {};
        const trigger =
          detail && detail.trigger instanceof HTMLElement
            ? detail.trigger
            : null;
        openOverlay(trigger, detail);
      });

      document.addEventListener("astro:before-swap", () => {
        if (overlay.dataset.open === "true") {
          closeOverlay();
        }
      });

      overlay.dataset.searchInitialized = "true";
    }

    bindSearchButtons();
  }

  const handleAfterSwap = () => {
    initializeMobileNavigation();
    window.requestAnimationFrame(() => {
      initializeHeaderSearch();
    });
  };

  document.addEventListener("astro:after-swap", handleAfterSwap);
  handleAfterSwap();
</script> <div data-docs-agent-page class="min-h-dvh"> <div class="flex pt-16"> <div class="hidden md:flex md:flex-col w-[218px] px-3 pb-6 pt-2 md:fixed md:top-16 md:bottom-0 md:z-40 bg-surface dark:bg-black astro-73gi4scu" data-left-nav-container><nav class="flex-1 overflow-y-auto overflow-x-visible astro-73gi4scu" data-left-nav data-left-nav-id="/api/docs"><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Get started</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="/api/docs" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Overview </span>   </a> </li><li> <a href="/api/docs/quickstart" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Quickstart </span>   </a> </li><li> <a href="/api/docs/models" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Models </span>   </a> </li><li> <a href="/api/docs/pricing" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Pricing </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <a href="/api/docs/libraries" class="flex-1 min-w-0 "> <span class="line-clamp-2 "> SDKs and CLI </span>  </a>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/libraries" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> OpenAI SDK </span>   </a> </li><li> <a href="/api/docs/guides/agents" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Agents SDK </span>   </a> </li><li> <a href="/api/docs/libraries/openai-cli" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> OpenAI CLI </span>   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/latest-model" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Latest: GPT-5.5 </span>   </a> </li><li> <a href="/api/docs/guides/prompt-guidance" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Prompt guidance </span>   </a> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Core concepts</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="/api/docs/guides/text" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Text generation </span>   </a> </li><li> <a href="/api/docs/guides/code-generation" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Code generation </span>   </a> </li><li> <a href="/api/docs/guides/images-vision" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Images and vision </span>   </a> </li><li> <a href="/api/docs/guides/audio" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Audio and speech </span>   </a> </li><li> <a href="/api/docs/guides/structured-outputs" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Structured output </span>   </a> </li><li> <a href="/api/docs/guides/function-calling" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Function calling </span>   </a> </li><li> <a href="/api/docs/guides/migrate-to-responses" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Responses API </span>   </a> </li><li> <a href="/api/docs/guides/tools" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Using tools </span>   </a> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Agents SDK</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="/api/docs/guides/agents" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Overview </span>   </a> </li><li> <a href="/api/docs/guides/agents/quickstart" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Quickstart </span>   </a> </li><li> <a href="/api/docs/guides/agents/define-agents" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Agent definitions </span>   </a> </li><li> <a href="/api/docs/guides/agents/models" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Models and providers </span>   </a> </li><li> <a href="/api/docs/guides/agents/running-agents" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Running agents </span>   </a> </li><li> <a href="/api/docs/guides/agents/sandboxes" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Sandbox agents </span>   </a> </li><li> <a href="/api/docs/guides/agents/orchestration" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Orchestration </span>   </a> </li><li> <a href="/api/docs/guides/agents/guardrails-approvals" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Guardrails </span>   </a> </li><li> <a href="/api/docs/guides/agents/results" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Results and state </span>   </a> </li><li> <a href="/api/docs/guides/agents/integrations-observability" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Integrations and observability </span>   </a> </li><li> <a href="/api/docs/guides/agent-evals" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Evaluate agent workflows </span>   </a> </li><li> <a href="/api/docs/guides/voice-agents" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Voice agents </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">ChatKit</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/chatkit" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Overview </span>   </a> </li><li> <a href="/api/docs/guides/chatkit-themes" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Customize </span>   </a> </li><li> <a href="/api/docs/guides/chatkit-widgets" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Widgets </span>   </a> </li><li> <a href="/api/docs/guides/chatkit-actions" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Actions </span>   </a> </li><li> <a href="/api/docs/guides/custom-chatkit" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Advanced integrations </span>   </a> </li> </ul> </details> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Tools</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="/api/docs/guides/tools-web-search" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Web search </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <a href="/api/docs/guides/tools-connectors-mcp" class="flex-1 min-w-0 "> <span class="line-clamp-2 "> MCP and Connectors </span>  </a>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/secure-mcp-tunnels" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Secure MCP Tunnel </span>   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/tools-skills" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Skills </span>   </a> </li><li> <a href="/api/docs/guides/tools-shell" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Shell </span>   </a> </li><li> <a href="/api/docs/guides/tools-computer-use" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Computer use </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">File search and retrieval</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/tools-file-search" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> File search </span>   </a> </li><li> <a href="/api/docs/guides/retrieval" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Retrieval </span>   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/tools-tool-search" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Tool search </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">More tools</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/tools-apply-patch" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Apply Patch </span>   </a> </li><li> <a href="/api/docs/guides/tools-local-shell" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Local shell </span>   </a> </li><li> <a href="/api/docs/guides/tools-image-generation" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Image generation </span>   </a> </li><li> <a href="/api/docs/guides/tools-code-interpreter" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Code interpreter </span>   </a> </li> </ul> </details> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Run and scale</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="/api/docs/guides/conversation-state" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Conversation state </span>   </a> </li><li> <a href="/api/docs/guides/background" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Background mode </span>   </a> </li><li> <a href="/api/docs/guides/streaming-responses" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Streaming </span>   </a> </li><li> <a href="/api/docs/guides/websocket-mode" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> WebSocket mode </span>   </a> </li><li> <a href="/api/docs/guides/webhooks" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Webhooks </span>   </a> </li><li> <a href="/api/docs/guides/file-inputs" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> File inputs </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Context management</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/compaction" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Compaction </span>   </a> </li><li> <a href="/api/docs/guides/token-counting" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Counting tokens </span>   </a> </li><li> <a href="/api/docs/guides/prompt-caching" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Prompt caching </span>   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Prompting</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/prompting" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Overview </span>   </a> </li><li> <a href="/api/docs/guides/prompt-engineering" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Prompt engineering </span>   </a> </li><li> <a href="/api/docs/guides/citation-formatting" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Citation formatting </span>   </a> </li><li> <a href="/api/docs/guides/prompting/migrate-from-prompt-object" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Migration guide </span>   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Reasoning</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/reasoning" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Reasoning models </span>   </a> </li><li> <a href="/api/docs/guides/reasoning-best-practices" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Reasoning best practices </span>   </a> </li> </ul> </details> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Evaluation</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="/api/docs/guides/red-teaming" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Red teaming </span>   </a> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Realtime and audio</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="/api/docs/guides/realtime" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Overview </span>   </a> </li><li> <a href="/api/docs/guides/voice-agents" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Voice agents </span>   </a> </li><li> <a href="/api/docs/guides/realtime-translation" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Live translation </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Transcription</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/realtime-transcription" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Realtime transcription </span>   </a> </li><li> <a href="/api/docs/guides/speech-to-text" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Speech to text </span>   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/text-to-speech" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Speech generation </span>   </a> </li><li> <a href="/api/docs/guides/realtime-models-prompting" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Realtime prompting guide </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Connection methods</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/realtime-webrtc" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> WebRTC </span>   </a> </li><li> <a href="/api/docs/guides/realtime-websocket" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> WebSocket </span>   </a> </li><li> <a href="/api/docs/guides/realtime-sip" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> SIP </span>   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Realtime sessions</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/realtime-conversations" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Managing conversations </span>   </a> </li><li> <a href="/api/docs/guides/realtime-vad" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Voice activity detection </span>   </a> </li><li> <a href="/api/docs/guides/realtime-mcp" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Realtime with tools </span>   </a> </li><li> <a href="/api/docs/guides/realtime-server-controls" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Webhooks and server-side controls </span>   </a> </li><li> <a href="/api/docs/guides/realtime-costs" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Managing costs </span>   </a> </li> </ul> </details> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Specialized models</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="/api/docs/guides/image-generation" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Image generation </span>   </a> </li><li> <a href="/api/docs/guides/video-generation" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Video generation </span>   </a> </li><li> <a href="/api/docs/guides/deep-research" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Deep research </span>   </a> </li><li> <a href="/api/docs/guides/embeddings" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Embeddings </span>   </a> </li><li> <a href="/api/docs/guides/moderation" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Moderation </span>   </a> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Going live</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="/api/docs/guides/production-best-practices" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Production best practices </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <a href="/api/docs/guides/workload-identity-federation" class="flex-1 min-w-0 "> <span class="line-clamp-2 "> Workload identity federation </span>  </a>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/workload-identity-federation" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Overview </span>   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/kubernetes" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Kubernetes </span>   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/aws" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> AWS </span>   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/microsoft-azure" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Microsoft Azure </span>   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/google-cloud" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Google Cloud </span>   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/github-actions" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> GitHub Actions </span>   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/spiffe" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> SPIFFE </span>   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/deployment-checklist" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Deployment checklist </span>   </a> </li><li> <a href="/api/docs/guides/amazon-bedrock" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Amazon Bedrock </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Latency optimization</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/latency-optimization" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Overview </span>   </a> </li><li> <a href="/api/docs/guides/predicted-outputs" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Predicted Outputs </span>   </a> </li><li> <a href="/api/docs/guides/priority-processing" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Priority processing </span>   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Cost optimization</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/cost-optimization" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Overview </span>   </a> </li><li> <a href="/api/docs/guides/batch" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Batch </span>   </a> </li><li> <a href="/api/docs/guides/flex-processing" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Flex processing </span>   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/optimizing-llm-accuracy" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Accuracy optimization </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Safety</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/safety-best-practices" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Safety best practices </span>   </a> </li><li> <a href="/api/docs/guides/safety-checks" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Safety checks </span>   </a> </li><li> <a href="/api/docs/guides/safety-checks/cybersecurity" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Cybersecurity checks </span>   </a> </li><li> <a href="/api/docs/guides/safety-checks/under-18-api-guidance" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Under 18 API Guidance </span>   </a> </li> </ul> </details> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Legacy APIs</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Agent Builder</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/agent-builder" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Overview </span>   </a> </li><li> <a href="/api/docs/guides/agent-builder/migrate-from-agent-builder" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Migration guide </span>   </a> </li><li> <a href="/api/docs/guides/node-reference" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Node reference </span>   </a> </li><li> <a href="/api/docs/guides/agent-builder-safety" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Safety in building agents </span>   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Evals</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/evaluation-getting-started" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Getting started </span>   </a> </li><li> <a href="/api/docs/guides/evals" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Working with evals </span>   </a> </li><li> <a href="/api/docs/guides/prompt-optimizer" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Prompt optimizer </span>   </a> </li><li> <a href="/api/docs/guides/external-models" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> External models </span>   </a> </li><li> <a href="/api/docs/guides/evaluation-best-practices" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Best practices </span>   </a> </li><li> <a href="/api/docs/guides/graders" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Graders </span>   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Fine-tuning</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/model-optimization" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Optimization cycle </span>   </a> </li><li> <a href="/api/docs/guides/supervised-fine-tuning" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Supervised fine-tuning </span>   </a> </li><li> <a href="/api/docs/guides/vision-fine-tuning" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Vision fine-tuning </span>   </a> </li><li> <a href="/api/docs/guides/direct-preference-optimization" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Direct preference optimization </span>   </a> </li><li> <a href="/api/docs/guides/reinforcement-fine-tuning" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Reinforcement fine-tuning </span>   </a> </li><li> <a href="/api/docs/guides/rft-use-cases" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> RFT use cases </span>   </a> </li><li> <a href="/api/docs/guides/fine-tuning-best-practices" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Best practices </span>   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure" open> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Assistants API</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/assistants/migration" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block bg-primary-ghost-hover "> <span class="line-clamp-2 "> Migration guide </span>   </a> </li><li> <a href="/api/docs/assistants/deep-dive" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Deep dive </span>   </a> </li><li> <a href="/api/docs/assistants/tools" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Tools </span>   </a> </li> </ul> </details> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Resources</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="https://openai.com/policies" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover flex items-center justify-between gap-1" target="_blank" rel="noopener noreferrer"> <span class="line-clamp-2 min-w-0 flex-1"> Terms and policies </span> <svg viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg" class="w-2 h-2 inline-block shrink-0 text-current " ><path d="M10.2426 0.757385C10.7949 0.757385 11.2426 1.2051 11.2426 1.75738V8.82845C11.2426 9.38074 10.7949 9.82845 10.2426 9.82845C9.69035 9.82845 9.24264 9.38074 9.24264 8.82845V4.1716L2.46446 10.9498C2.07394 11.3403 1.44077 11.3403 1.05025 10.9498C0.659724 10.5592 0.659723 9.92608 1.05025 9.53556L7.82842 2.75739H3.17157C2.61928 2.75739 2.17157 2.30967 2.17157 1.75738C2.17157 1.2051 2.61928 0.757385 3.17157 0.757385H10.2426Z" fill="currentColor"></path></svg>  </a> </li><li> <a href="/api/docs/changelog" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Changelog </span>   </a> </li><li> <a href="/api/docs/guides/your-data" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Your data </span>   </a> </li><li> <a href="/api/docs/guides/rbac" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Permissions </span>   </a> </li><li> <a href="/api/docs/guides/rate-limits" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Rate limits </span>   </a> </li><li> <a href="/api/docs/guides/ip-addresses" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> IP egress ranges </span>   </a> </li><li> <a href="/api/docs/guides/admin-apis" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Admin APIs </span>   </a> </li><li> <a href="/api/docs/deprecations" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Deprecations </span>   </a> </li><li> <a href="/api/docs/mcp" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> MCP for deep research </span>   </a> </li><li> <a href="/api/docs/guides/developer-mode" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Developer mode </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">ChatGPT Actions</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/actions/introduction" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Introduction </span>   </a> </li><li> <a href="/api/docs/actions/getting-started" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Getting started </span>   </a> </li><li> <a href="/api/docs/actions/actions-library" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Actions library </span>   </a> </li><li> <a href="/api/docs/actions/authentication" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Authentication </span>   </a> </li><li> <a href="/api/docs/actions/production" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Production </span>   </a> </li><li> <a href="/api/docs/actions/data-retrieval" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Data retrieval </span>   </a> </li><li> <a href="/api/docs/actions/sending-files" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Sending files </span>   </a> </li> </ul> </details> </li> </ul></div></nav></div><script>
  const NAV_SELECTOR = "nav[data-left-nav]";
  const STORAGE_PREFIX = "left-nav-scroll:";
  const INITIALIZED_ATTRIBUTE = "data-left-nav-scroll-initialized";

  const isStorageAvailable = (() => {
    try {
      const storageKey = `${STORAGE_PREFIX}__test__`;
      sessionStorage.setItem(storageKey, "1");
      sessionStorage.removeItem(storageKey);
      return true;
    } catch (error) {
      return false;
    }
  })();

  const getNav = () => document.querySelector(NAV_SELECTOR);

  const getStorageKey = (nav) =>
    `${STORAGE_PREFIX}${nav.dataset.leftNavId ?? "default"}`;

  const restoreScrollPosition = (nav) => {
    if (!isStorageAvailable) return;
    const storedValue = sessionStorage.getItem(getStorageKey(nav));
    if (storedValue !== null) {
      nav.scrollTop = Number(storedValue);
    }
  };

  const saveScrollPosition = (nav) => {
    if (!isStorageAvailable) return;
    sessionStorage.setItem(getStorageKey(nav), String(nav.scrollTop));
  };

  const setupNav = () => {
    const nav = getNav();
    if (!nav || nav.getAttribute(INITIALIZED_ATTRIBUTE) === "true") return;

    restoreScrollPosition(nav);

    nav.addEventListener(
      "scroll",
      () => {
        saveScrollPosition(nav);
      },
      { passive: true }
    );

    nav.setAttribute(INITIALIZED_ATTRIBUTE, "true");
  };

  const persistScrollPosition = () => {
    const nav = getNav();
    if (!nav) return;
    saveScrollPosition(nav);
  };

  const initialize = () => {
    setupNav();
    const nav = getNav();
    if (!nav) return;
    restoreScrollPosition(nav);
  };

  window.addEventListener("pageshow", initialize);
  document.addEventListener("astro:page-load", initialize);
  document.addEventListener("astro:after-swap", initialize);

  document.addEventListener("astro:before-swap", persistScrollPosition);
  window.addEventListener("beforeunload", persistScrollPosition);

  initialize();
</script> <main class="min-w-0 flex-1 md:pl-[240px]"> <div class="page-container md:max-w-6xl pb-12 pt-0" data-content-page-container> <div class="mx-auto md:w-full grid grid-cols-1 gap-12 max-w-7xl xl:grid-cols-[minmax(0,1fr)_200px]"> <div data-content-page-toc-rail class="hidden xl:flex fixed right-8 top-[6rem] z-30 w-[200px] h-[calc(100vh-6rem)] max-h-[calc(100vh-6rem)] flex-col pb-6"> <div class="mb-4 shrink-0">  </div> <script>window._$HY||(e=>{let t=e=>e&&e.hasAttribute&&(e.hasAttribute("data-hk")?e:t(e.host&&e.host.nodeType?e.host:e.parentNode));["click", "input"].forEach((o=>document.addEventListener(o,(o=>{if(!e.events)return;let s=t(o.composedPath&&o.composedPath()[0]||o.target);s&&!e.completed.has(s)&&e.events.push([s,o])}))))})(_$HY={events:[],completed:new WeakSet,r:{},fe(){}});</script><!--xs--><astro-island uid="1LnebC" data-solid-render-id="s0" component-url="/_astro/TableOfContents.CkwfG4zx.js" component-export="default" renderer-url="/_astro/client.DjvmFpsL.js" props="{&quot;variant&quot;:[0,&quot;static&quot;],&quot;targetSelector&quot;:[0,&quot;#mainContent&quot;],&quot;headingSelector&quot;:[0,&quot;h2&quot;],&quot;class&quot;:[0,&quot;flex-1 min-h-0 overflow-y-auto pr-1&quot;]}" ssr client="load" opts="{&quot;name&quot;:&quot;TableOfContents&quot;,&quot;value&quot;:true}" await-children><nav data-hk="s00000" class="hidden xl:block w-full overflow-y-auto flex-1 min-h-0 overflow-y-auto pr-1"><div class="relative"><div class="absolute left-0 top-0 bottom-0 w-[2.15px] bg-primary-soft"></div><div class="absolute left-0 w-[2.15px] bg-primary-solid transition-transform duration-200 ease-out" style="transform:translateY(0);height:0px"></div><ul class="relative list-none p-0 m-0 ml-3 [&amp;>*+*]:mt-3"></ul></div></nav><!--astro:end--></astro-island>  <div class="mt-4 shrink-0"> <button type="button" class="page-copy-action astro-y3m22efp" data-page-copy-action data-page-copy-default-label="Copy Page" data-page-copy-copied-label="Copied"> <span class="page-copy-action__icon page-copy-action__icon--copy astro-y3m22efp" aria-hidden="true"> <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" viewBox="0 0 24 24" class="astro-y3m22efp " ><path fill-rule="evenodd" d="M7 5a3 3 0 0 1 3-3h9a3 3 0 0 1 3 3v9a3 3 0 0 1-3 3h-2v2a3 3 0 0 1-3 3H5a3 3 0 0 1-3-3v-9a3 3 0 0 1 3-3h2V5Zm2 2h5a3 3 0 0 1 3 3v5h2a1 1 0 0 0 1-1V5a1 1 0 0 0-1-1h-9a1 1 0 0 0-1 1v2ZM5 9a1 1 0 0 0-1 1v9a1 1 0 0 0 1 1h9a1 1 0 0 0 1-1v-9a1 1 0 0 0-1-1H5Z" clip-rule="evenodd"></path></svg> </span> <span class="page-copy-action__icon page-copy-action__icon--check astro-y3m22efp" aria-hidden="true"> <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" viewBox="0 0 24 24" class="astro-y3m22efp " ><path fill-rule="evenodd" d="M18.063 5.674a1 1 0 0 1 .263 1.39l-7.5 11a1 1 0 0 1-1.533.143l-4.5-4.5a1 1 0 1 1 1.414-1.414l3.647 3.647 6.82-10.003a1 1 0 0 1 1.39-.263Z" clip-rule="evenodd"></path></svg> </span> <span data-page-copy-label class="astro-y3m22efp">Copy Page</span> </button> <script type="module" src="/_astro/PageCopyAction.astro_astro_type_script_index_0_lang.Df1nqr2j.js"></script> </div> </div> <div class="flex flex-col relative">  <div class="flex flex-col gap-8 mb-2"> <div class="w-full max-w-xs xl:hidden mb-6">  </div> <header class="flex flex-col not-prose gap-1 pt-20 items-start text-left"> <div class="w-full">  </div> <h1 class="heading-2xl md:heading-2xl"> Assistants migration guide </h1> <p class="text-lg text-secondary">Migrate from the Assistants API to the Responses API.</p> <div class="w-full"> <div class="flex w-full flex-wrap items-center gap-3 justify-start">  <button type="button" class="page-copy-action astro-y3m22efp" data-page-copy-action data-page-copy-default-label="Copy Page" data-page-copy-copied-label="Copied"> <span class="page-copy-action__icon page-copy-action__icon--copy astro-y3m22efp" aria-hidden="true"> <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" viewBox="0 0 24 24" class="astro-y3m22efp " ><path fill-rule="evenodd" d="M7 5a3 3 0 0 1 3-3h9a3 3 0 0 1 3 3v9a3 3 0 0 1-3 3h-2v2a3 3 0 0 1-3 3H5a3 3 0 0 1-3-3v-9a3 3 0 0 1 3-3h2V5Zm2 2h5a3 3 0 0 1 3 3v5h2a1 1 0 0 0 1-1V5a1 1 0 0 0-1-1h-9a1 1 0 0 0-1 1v2ZM5 9a1 1 0 0 0-1 1v9a1 1 0 0 0 1 1h9a1 1 0 0 0 1-1v-9a1 1 0 0 0-1-1H5Z" clip-rule="evenodd"></path></svg> </span> <span class="page-copy-action__icon page-copy-action__icon--check astro-y3m22efp" aria-hidden="true"> <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" viewBox="0 0 24 24" class="astro-y3m22efp " ><path fill-rule="evenodd" d="M18.063 5.674a1 1 0 0 1 .263 1.39l-7.5 11a1 1 0 0 1-1.533.143l-4.5-4.5a1 1 0 1 1 1.414-1.414l3.647 3.647 6.82-10.003a1 1 0 0 1 1.39-.263Z" clip-rule="evenodd"></path></svg> </span> <span data-page-copy-label class="astro-y3m22efp">Copy Page</span> </button>  </div> </div> </header>  </div> <article id="mainContent" class="prose prose-content dark:prose-invert max-w-none pt-4 pb-0"> <div class="_Alert_1bpiz_1" data-variant="outline" data-color="warning" data-actions-placement="end"><div class="_Indicator_1bpiz_159"><svg width="1em" height="1em" viewBox="0 0 24 24" fill="currentColor"><path d="M10.42 2.006a4 4 0 0 1 3.159 0c.674.29 1.188.822 1.667 1.456.474.627 1 1.473 1.653 2.523l3.542 5.696c.72 1.16 1.3 2.09 1.682 2.854.384.766.654 1.517.59 2.292a4 4 0 0 1-1.604 2.886c-.625.463-1.405.63-2.258.709-.85.078-1.945.078-3.311.078H8.46c-1.366 0-2.46 0-3.31-.078-.854-.078-1.634-.246-2.26-.71a4 4 0 0 1-1.603-2.885c-.064-.775.206-1.526.59-2.292.383-.764.961-1.694 1.682-2.854l3.542-5.696c.653-1.05 1.18-1.896 1.653-2.523.48-.634.993-1.166 1.667-1.456Zm2.37 1.838a2 2 0 0 0-1.58 0c-.192.083-.448.28-.86.825-.413.544-.891 1.312-1.577 2.415l-3.488 5.61c-.755 1.214-1.283 2.066-1.62 2.737-.34.678-.402 1.02-.385 1.232a2 2 0 0 0 .802 1.443c.171.127.494.255 1.25.324.748.069 1.75.07 3.18.07h6.976c1.43 0 2.432-.001 3.18-.07.756-.069 1.079-.197 1.25-.324a2 2 0 0 0 .802-1.443c.017-.212-.045-.554-.385-1.232-.337-.671-.865-1.523-1.62-2.737l-3.488-5.61c-.686-1.103-1.164-1.87-1.576-2.415-.413-.546-.67-.742-.861-.825"></path><path d="M12 7.5a1 1 0 0 1 1 1v3a1 1 0 1 1-2 0v-3a1 1 0 0 1 1-1M10.851 15a1.15 1.15 0 1 1 2.3 0 1.15 1.15 0 0 1-2.3 0"></path></svg></div><div class="_Content_1bpiz_147"><div class="_Message_1bpiz_166"><div class="_Description_1bpiz_176">After achieving feature parity in the Responses API, we&#x27;ve deprecated the Assistants API. It will shut down on August 26, 2026. Follow the<!-- --> <a href="/platform/assistants/migration" style="color:inherit">migration guide</a> <!-- -->to update your integration.<!-- --> <a href="https://platform.openai.com/docs/guides/migrate-to-responses" style="color:inherit">Learn more</a>.</div></div></div></div>
<br/>
<p>We’re moving from the Assistants API to the new <a href="/api/docs/guides/responses-vs-chat-completions">Responses API</a> for a simpler and more flexible mental model.</p>
<p>Responses are simpler—send input items and get output items back. With the Responses API, you also get better performance and new features like <a href="/api/docs/guides/deep-research">deep research</a>, <a href="/api/docs/guides/tools-remote-mcp">MCP</a>, and <a href="/api/docs/guides/tools-computer-use">computer use</a>. This change also lets you manage conversations instead of passing back <code>previous_response_id</code>.</p>
<h3 id="whats-changed" class="group flex items-center gap-1 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">What’s changed?</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="whats-changed" aria-label="Copy link to whats changed" title="Copy link to whats changed"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h3>
<table><thead><tr><th>Before</th><th>Now</th><th>Why?</th></tr></thead><tbody><tr><td><code>Assistants</code></td><td><code>Prompts</code></td><td><p>Prompts hold configuration (model, tools, instructions) and are easier
to version and update</p></td></tr><tr><td><code>Threads</code></td><td><code>Conversations</code></td><td>Streams of items instead of just messages</td></tr><tr><td><code>Runs</code></td><td><code>Responses</code></td><td><p>Responses send input items or use a conversation object and receive
output items; tool call loops are explicitly managed</p></td></tr><tr><td><code>Run steps</code></td><td><code>Items</code></td><td><p>Generalized objects—can be messages, tool calls, outputs, and more</p></td></tr></tbody></table>
<h2 id="from-assistants-to-prompts" class="group flex items-center gap-2 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">From assistants to prompts</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="from-assistants-to-prompts" aria-label="Copy link to from assistants to prompts" title="Copy link to from assistants to prompts"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h2>
<p>Assistants were persistent API objects that bundled model choice, instructions, and tool declarations—created and managed entirely through the API. Their replacement, prompts, can only be created in the dashboard, where you can version them as you develop your product.</p>
<h3 id="why-this-is-helpful" class="group flex items-center gap-1 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">Why this is helpful</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="why-this-is-helpful" aria-label="Copy link to why this is helpful" title="Copy link to why this is helpful"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h3>
<ul>
<li><strong>Portability and versioning</strong>: You can snapshot, review, diff, and roll back prompt specs. You can also version a prompt, so your code can just point the latest version.</li>
<li><strong>Separation of concerns</strong>: Your application code now handles orchestration (history pruning, tool loop, retries) while your prompt focuses on high‑level behavior and constraints (system guidance, tool availability, structured output schema, temperature defaults).</li>
<li><strong>Realtime compatibility</strong>: The same prompt configuration can be reused when you connect through the Realtime API, giving you a single definition of behavior across chat, streaming, and low‑latency interactive sessions.</li>
<li><strong>Tool and output consistency</strong>: Using prompts, every Responses or Realtime session you start inherits a consistent contract because prompts encapsulate tool schemas and structured output expectations.</li>
</ul>
<h3 id="practical-migration-steps" class="group flex items-center gap-1 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">Practical migration steps</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="practical-migration-steps" aria-label="Copy link to practical migration steps" title="Copy link to practical migration steps"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h3>
<ol>
<li>Identify each existing Assistant’s <em>instruction + tool</em> bundle.</li>
<li>In the dashboard, recreate that bundle as a named prompt.</li>
<li>Store the prompt ID (or its exported spec) in source control so application code can refer to a stable identifier.</li>
<li>During rollout, run A/B tests by swapping prompt IDs—no need to create or delete assistant objects programmatically.</li>
</ol>
<p>Think of a prompt as a <strong>versioned behavioral profile</strong> to plug into either Responses or Realtime API.</p>
<hr/>
<h2 id="from-threads-to-conversations" class="group flex items-center gap-2 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">From threads to conversations</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="from-threads-to-conversations" aria-label="Copy link to from threads to conversations" title="Copy link to from threads to conversations"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h2>
<p>A thread was a collection of messages stored server-side. Threads could <em>only</em> store messages. Conversations store items, which can include messages, tool calls, tool outputs, and other data.</p>
<h3 id="request-example" class="group flex items-center gap-1 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">Request example</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="request-example" aria-label="Copy link to request example" title="Copy link to request example"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h3>
<astro-island uid="Z1kcM16" prefix="r116" component-url="/_astro/CodeComparison.react.1JEj8E5I.js" component-export="CodeComparison" renderer-url="/_astro/client.BWriqC1y.js" props="{&quot;snippets&quot;:[1,[[0,{&quot;language&quot;:[0,&quot;python&quot;],&quot;code&quot;:[0,&quot;\nthread = openai.beta.threads.create(\n  messages=[{\&quot;role\&quot;: \&quot;user\&quot;, \&quot;content\&quot;: \&quot;what are the 5 Ds of dodgeball?\&quot;}],\n  metadata={\&quot;user_id\&quot;: \&quot;peter_le_fleur\&quot;},\n)\n&quot;],&quot;title&quot;:[0,&quot;Thread object&quot;]}],[0,{&quot;language&quot;:[0,&quot;python&quot;],&quot;code&quot;:[0,&quot;\nconversation = openai.conversations.create(\n  items=[{\&quot;role\&quot;: \&quot;user\&quot;, \&quot;content\&quot;: \&quot;what are the 5 Ds of dodgeball?\&quot;}],\n  metadata={\&quot;user_id\&quot;: \&quot;peter_le_fleur\&quot;},\n)\n&quot;],&quot;title&quot;:[0,&quot;Conversation object&quot;]}]]]}" ssr client="load" opts="{&quot;name&quot;:&quot;CodeComparison&quot;,&quot;value&quot;:true}" await-children><div class="code-comparison"><div class="code-sample not-prose _root_1x2h7_2 light-mode"><div class="_header_1x2h7_34"><div class="_title_1x2h7_42 body-small">Thread object</div></div><div class="_body_1x2h7_59 _bodySmall_1x2h7_151 _bodyWithHeader_1x2h7_139"><pre class="hljs syntax-highlighter light-mode _pre_1x2h7_62" data-1p-ignore="true" data-copy-ignore="true"><code data-1p-ignore="true" data-language="python" style="white-space:pre"><code style="float:left;padding-right:10px"><span class="react-syntax-highlighter-line-number">1
</span><span class="react-syntax-highlighter-line-number">2
</span><span class="react-syntax-highlighter-line-number">3
</span><span class="react-syntax-highlighter-line-number">4
</span></code><span><span>thread = openai.beta.threads.create(
</span></span><span><span>  messages=[{</span><span class="hljs-string">&quot;role&quot;</span><span>: </span><span class="hljs-string">&quot;user&quot;</span><span>, </span><span class="hljs-string">&quot;content&quot;</span><span>: </span><span class="hljs-string">&quot;what are the 5 Ds of dodgeball?&quot;</span><span>}],
</span></span><span><span>  metadata={</span><span class="hljs-string">&quot;user_id&quot;</span><span>: </span><span class="hljs-string">&quot;peter_le_fleur&quot;</span><span>},
</span></span><span>)</span></code></pre></div></div><div class="code-sample not-prose _root_1x2h7_2 light-mode"><div class="_header_1x2h7_34"><div class="_title_1x2h7_42 body-small">Conversation object</div></div><div class="_body_1x2h7_59 _bodySmall_1x2h7_151 _bodyWithHeader_1x2h7_139"><pre class="hljs syntax-highlighter light-mode _pre_1x2h7_62" data-1p-ignore="true" data-copy-ignore="true"><code data-1p-ignore="true" data-language="python" style="white-space:pre"><code style="float:left;padding-right:10px"><span class="react-syntax-highlighter-line-number">1
</span><span class="react-syntax-highlighter-line-number">2
</span><span class="react-syntax-highlighter-line-number">3
</span><span class="react-syntax-highlighter-line-number">4
</span></code><span><span>conversation = openai.conversations.create(
</span></span><span><span>  items=[{</span><span class="hljs-string">&quot;role&quot;</span><span>: </span><span class="hljs-string">&quot;user&quot;</span><span>, </span><span class="hljs-string">&quot;content&quot;</span><span>: </span><span class="hljs-string">&quot;what are the 5 Ds of dodgeball?&quot;</span><span>}],
</span></span><span><span>  metadata={</span><span class="hljs-string">&quot;user_id&quot;</span><span>: </span><span class="hljs-string">&quot;peter_le_fleur&quot;</span><span>},
</span></span><span>)</span></code></pre></div></div></div><!--astro:end--></astro-island>
<h3 id="response-example" class="group flex items-center gap-1 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">Response example</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="response-example" aria-label="Copy link to response example" title="Copy link to response example"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h3>
<astro-island uid="Z1Kx5iL" prefix="r117" component-url="/_astro/CodeComparison.react.1JEj8E5I.js" component-export="CodeComparison" renderer-url="/_astro/client.BWriqC1y.js" props="{&quot;snippets&quot;:[1,[[0,{&quot;language&quot;:[0,&quot;json&quot;],&quot;code&quot;:[0,&quot;\n{\n\&quot;id\&quot;: \&quot;thread_CrXtCzcyEQbkAcXuNmVSKFs1\&quot;,\n\&quot;object\&quot;: \&quot;thread\&quot;,\n\&quot;created_at\&quot;: 1752855924,\n\&quot;metadata\&quot;: {\n  \&quot;user_id\&quot;: \&quot;peter_le_fleur\&quot;\n},\n\&quot;tool_resources\&quot;: {}\n}\n&quot;],&quot;title&quot;:[0,&quot;Thread object&quot;]}],[0,{&quot;language&quot;:[0,&quot;json&quot;],&quot;code&quot;:[0,&quot;\n{\n\&quot;id\&quot;: \&quot;conv_68542dc602388199a30af27d040cefd4087a04b576bfeb24\&quot;,\n\&quot;object\&quot;: \&quot;conversation\&quot;,\n\&quot;created_at\&quot;: 1752855924,\n\&quot;metadata\&quot;: {\n\t\&quot;user_id\&quot;: \&quot;peter_le_fleur\&quot;\n}\n}\n&quot;],&quot;title&quot;:[0,&quot;Conversation object&quot;]}]]]}" ssr client="load" opts="{&quot;name&quot;:&quot;CodeComparison&quot;,&quot;value&quot;:true}" await-children><div class="code-comparison"><div class="code-sample not-prose _root_1x2h7_2 light-mode"><div class="_header_1x2h7_34"><div class="_title_1x2h7_42 body-small">Thread object</div></div><div class="_body_1x2h7_59 _bodySmall_1x2h7_151 _bodyWithHeader_1x2h7_139"><pre class="hljs syntax-highlighter light-mode _pre_1x2h7_62" data-1p-ignore="true" data-copy-ignore="true"><code data-1p-ignore="true" data-language="json" style="white-space:pre"><code style="float:left;padding-right:10px"><span class="react-syntax-highlighter-line-number">1
</span><span class="react-syntax-highlighter-line-number">2
</span><span class="react-syntax-highlighter-line-number">3
</span><span class="react-syntax-highlighter-line-number">4
</span><span class="react-syntax-highlighter-line-number">5
</span><span class="react-syntax-highlighter-line-number">6
</span><span class="react-syntax-highlighter-line-number">7
</span><span class="react-syntax-highlighter-line-number">8
</span><span class="react-syntax-highlighter-line-number">9
</span></code><span><span>{
</span></span><span><span></span><span class="hljs-attr">&quot;id&quot;</span><span>: </span><span class="hljs-string">&quot;thread_CrXtCzcyEQbkAcXuNmVSKFs1&quot;</span><span>,
</span></span><span><span></span><span class="hljs-attr">&quot;object&quot;</span><span>: </span><span class="hljs-string">&quot;thread&quot;</span><span>,
</span></span><span><span></span><span class="hljs-attr">&quot;created_at&quot;</span><span>: </span><span class="hljs-number">1752855924</span><span>,
</span></span><span><span></span><span class="hljs-attr">&quot;metadata&quot;</span><span>: {
</span></span><span><span>  </span><span class="hljs-attr">&quot;user_id&quot;</span><span>: </span><span class="hljs-string">&quot;peter_le_fleur&quot;</span><span>
</span></span><span>},
</span><span><span></span><span class="hljs-attr">&quot;tool_resources&quot;</span><span>: {}
</span></span><span>}</span></code></pre></div></div><div class="code-sample not-prose _root_1x2h7_2 light-mode"><div class="_header_1x2h7_34"><div class="_title_1x2h7_42 body-small">Conversation object</div></div><div class="_body_1x2h7_59 _bodySmall_1x2h7_151 _bodyWithHeader_1x2h7_139"><pre class="hljs syntax-highlighter light-mode _pre_1x2h7_62" data-1p-ignore="true" data-copy-ignore="true"><code data-1p-ignore="true" data-language="json" style="white-space:pre"><code style="float:left;padding-right:10px"><span class="react-syntax-highlighter-line-number">1
</span><span class="react-syntax-highlighter-line-number">2
</span><span class="react-syntax-highlighter-line-number">3
</span><span class="react-syntax-highlighter-line-number">4
</span><span class="react-syntax-highlighter-line-number">5
</span><span class="react-syntax-highlighter-line-number">6
</span><span class="react-syntax-highlighter-line-number">7
</span><span class="react-syntax-highlighter-line-number">8
</span></code><span><span>{
</span></span><span><span></span><span class="hljs-attr">&quot;id&quot;</span><span>: </span><span class="hljs-string">&quot;conv_68542dc602388199a30af27d040cefd4087a04b576bfeb24&quot;</span><span>,
</span></span><span><span></span><span class="hljs-attr">&quot;object&quot;</span><span>: </span><span class="hljs-string">&quot;conversation&quot;</span><span>,
</span></span><span><span></span><span class="hljs-attr">&quot;created_at&quot;</span><span>: </span><span class="hljs-number">1752855924</span><span>,
</span></span><span><span></span><span class="hljs-attr">&quot;metadata&quot;</span><span>: {
</span></span><span><span>	</span><span class="hljs-attr">&quot;user_id&quot;</span><span>: </span><span class="hljs-string">&quot;peter_le_fleur&quot;</span><span>
</span></span><span>}
</span><span>}</span></code></pre></div></div></div><!--astro:end--></astro-island>
<hr/>
<h2 id="from-runs-to-responses" class="group flex items-center gap-2 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">From runs to responses</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="from-runs-to-responses" aria-label="Copy link to from runs to responses" title="Copy link to from runs to responses"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h2>
<p>Runs were asynchronous processes that executed against threads. See the example below. Responses are simpler: provide a set of input items to execute, and get a list of output items back.</p>
<p>Responses are designed to be used alone, but you can also use them with prompt and conversation objects for storing context and configuration.</p>
<h3 id="request-example-1" class="group flex items-center gap-1 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">Request example</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="request-example-1" aria-label="Copy link to request example 1" title="Copy link to request example 1"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h3>
<astro-island uid="1EipX0" prefix="r118" component-url="/_astro/CodeComparison.react.1JEj8E5I.js" component-export="CodeComparison" renderer-url="/_astro/client.BWriqC1y.js" props="{&quot;snippets&quot;:[1,[[0,{&quot;language&quot;:[0,&quot;python&quot;],&quot;code&quot;:[0,&quot;\nthread_id = \&quot;thread_CrXtCzcyEQbkAcXuNmVSKFs1\&quot;\nassistant_id = \&quot;asst_8fVY45hU3IM6creFkVi5MBKB\&quot;\n\nrun = openai.beta.threads.runs.create(thread_id=thread_id, assistant_id=assistant.id)\n\nwhile run.status in (\&quot;queued\&quot;, \&quot;in_progress\&quot;):\ntime.sleep(1)\nrun = openai.beta.threads.runs.retrieve(thread_id=thread_id, run_id=run.id)\n&quot;],&quot;title&quot;:[0,&quot;Run object&quot;]}],[0,{&quot;language&quot;:[0,&quot;python&quot;],&quot;code&quot;:[0,&quot;\nresponse = openai.responses.create(\nmodel=\&quot;gpt-5.5\&quot;,\ninput=[{\&quot;role\&quot;: \&quot;user\&quot;, \&quot;content\&quot;: \&quot;What are the 5 Ds of dodgeball?\&quot;}]\nconversation: \&quot;conv_689667905b048191b4740501625afd940c7533ace33a2dab\&quot;\n)\n&quot;],&quot;title&quot;:[0,&quot;Response object&quot;]}]]]}" ssr client="load" opts="{&quot;name&quot;:&quot;CodeComparison&quot;,&quot;value&quot;:true}" await-children><div class="code-comparison"><div class="code-sample not-prose _root_1x2h7_2 light-mode"><div class="_header_1x2h7_34"><div class="_title_1x2h7_42 body-small">Run object</div></div><div class="_body_1x2h7_59 _bodySmall_1x2h7_151 _bodyWithHeader_1x2h7_139"><pre class="hljs syntax-highlighter light-mode _pre_1x2h7_62" data-1p-ignore="true" data-copy-ignore="true"><code data-1p-ignore="true" data-language="python" style="white-space:pre"><code style="float:left;padding-right:10px"><span class="react-syntax-highlighter-line-number">1
</span><span class="react-syntax-highlighter-line-number">2
</span><span class="react-syntax-highlighter-line-number">3
</span><span class="react-syntax-highlighter-line-number">4
</span><span class="react-syntax-highlighter-line-number">5
</span><span class="react-syntax-highlighter-line-number">6
</span><span class="react-syntax-highlighter-line-number">7
</span><span class="react-syntax-highlighter-line-number">8
</span></code><span><span>thread_id = </span><span class="hljs-string">&quot;thread_CrXtCzcyEQbkAcXuNmVSKFs1&quot;</span><span>
</span></span><span><span>assistant_id = </span><span class="hljs-string">&quot;asst_8fVY45hU3IM6creFkVi5MBKB&quot;</span><span>
</span></span><span>
</span><span><span>run = openai.beta.threads.runs.create(thread_id=thread_id, assistant_id=assistant.</span><span class="hljs-built_in">id</span><span>)
</span></span><span>
</span><span><span></span><span class="hljs-keyword">while</span><span> run.status </span><span class="hljs-keyword">in</span><span> (</span><span class="hljs-string">&quot;queued&quot;</span><span>, </span><span class="hljs-string">&quot;in_progress&quot;</span><span>):
</span></span><span><span>time.sleep(</span><span class="hljs-number">1</span><span>)
</span></span><span><span>run = openai.beta.threads.runs.retrieve(thread_id=thread_id, run_id=run.</span><span class="hljs-built_in">id</span><span>)</span></span></code></pre></div></div><div class="code-sample not-prose _root_1x2h7_2 light-mode"><div class="_header_1x2h7_34"><div class="_title_1x2h7_42 body-small">Response object</div></div><div class="_body_1x2h7_59 _bodySmall_1x2h7_151 _bodyWithHeader_1x2h7_139"><pre class="hljs syntax-highlighter light-mode _pre_1x2h7_62" data-1p-ignore="true" data-copy-ignore="true"><code data-1p-ignore="true" data-language="python" style="white-space:pre"><code style="float:left;padding-right:10px"><span class="react-syntax-highlighter-line-number">1
</span><span class="react-syntax-highlighter-line-number">2
</span><span class="react-syntax-highlighter-line-number">3
</span><span class="react-syntax-highlighter-line-number">4
</span><span class="react-syntax-highlighter-line-number">5
</span></code><span><span>response = openai.responses.create(
</span></span><span><span>model=</span><span class="hljs-string">&quot;gpt-5.5&quot;</span><span>,
</span></span><span><span></span><span class="hljs-built_in">input</span><span>=[{</span><span class="hljs-string">&quot;role&quot;</span><span>: </span><span class="hljs-string">&quot;user&quot;</span><span>, </span><span class="hljs-string">&quot;content&quot;</span><span>: </span><span class="hljs-string">&quot;What are the 5 Ds of dodgeball?&quot;</span><span>}]
</span></span><span><span>conversation: </span><span class="hljs-string">&quot;conv_689667905b048191b4740501625afd940c7533ace33a2dab&quot;</span><span>
</span></span><span>)</span></code></pre></div></div></div><!--astro:end--></astro-island>
<h3 id="response-example-1" class="group flex items-center gap-1 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">Response example</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="response-example-1" aria-label="Copy link to response example 1" title="Copy link to response example 1"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h3>
<astro-island uid="1N38jc" prefix="r119" component-url="/_astro/CodeComparison.react.1JEj8E5I.js" component-export="CodeComparison" renderer-url="/_astro/client.BWriqC1y.js" props="{&quot;snippets&quot;:[1,[[0,{&quot;language&quot;:[0,&quot;python&quot;],&quot;code&quot;:[0,&quot;\n{\n\&quot;id\&quot;: \&quot;run_FKIpcs5ECSwuCmehBqsqkORj\&quot;,\n\&quot;assistant_id\&quot;: \&quot;asst_8fVY45hU3IM6creFkVi5MBKB\&quot;,\n\&quot;cancelled_at\&quot;: null,\n\&quot;completed_at\&quot;: 1752857327,\n\&quot;created_at\&quot;: 1752857322,\n\&quot;expires_at\&quot;: null,\n\&quot;failed_at\&quot;: null,\n\&quot;incomplete_details\&quot;: null,\n\&quot;instructions\&quot;: null,\n\&quot;last_error\&quot;: null,\n\&quot;max_completion_tokens\&quot;: null,\n\&quot;max_prompt_tokens\&quot;: null,\n\&quot;metadata\&quot;: {},\n\&quot;model\&quot;: \&quot;gpt-4.1\&quot;,\n\&quot;object\&quot;: \&quot;thread.run\&quot;,\n\&quot;parallel_tool_calls\&quot;: true,\n\&quot;required_action\&quot;: null,\n\&quot;response_format\&quot;: \&quot;auto\&quot;,\n\&quot;started_at\&quot;: 1752857324,\n\&quot;status\&quot;: \&quot;completed\&quot;,\n\&quot;thread_id\&quot;: \&quot;thread_CrXtCzcyEQbkAcXuNmVSKFs1\&quot;,\n\&quot;tool_choice\&quot;: \&quot;auto\&quot;,\n\&quot;tools\&quot;: [],\n\&quot;truncation_strategy\&quot;: {\n  \&quot;type\&quot;: \&quot;auto\&quot;,\n  \&quot;last_messages\&quot;: null\n},\n\&quot;usage\&quot;: {\n  \&quot;completion_tokens\&quot;: 130,\n  \&quot;prompt_tokens\&quot;: 34,\n  \&quot;total_tokens\&quot;: 164,\n  \&quot;prompt_token_details\&quot;: {\n    \&quot;cached_tokens\&quot;: 0\n  },\n  \&quot;completion_tokens_details\&quot;: {\n    \&quot;reasoning_tokens\&quot;: 0\n  }\n},\n\&quot;temperature\&quot;: 1.0,\n\&quot;top_p\&quot;: 1.0,\n\&quot;tool_resources\&quot;: {},\n\&quot;reasoning_effort\&quot;: null\n}\n&quot;],&quot;title&quot;:[0,&quot;Run object&quot;]}],[0,{&quot;language&quot;:[0,&quot;python&quot;],&quot;code&quot;:[0,&quot;\n{\n\&quot;id\&quot;: \&quot;resp_687a7b53036c819baad6012d58b39bcb074adcd9e24850fc\&quot;,\n\&quot;created_at\&quot;: 1752857427,\n\&quot;conversation\&quot;: {\n  \&quot;id\&quot;: \&quot;conv_689667905b048191b4740501625afd940c7533ace33a2dab\&quot;\n},\n\&quot;error\&quot;: null,\n\&quot;incomplete_details\&quot;: null,\n\&quot;instructions\&quot;: null,\n\&quot;metadata\&quot;: {},\n\&quot;model\&quot;: \&quot;gpt-5.5\&quot;,\n\&quot;object\&quot;: \&quot;response\&quot;,\n\&quot;output\&quot;: [\n  {\n    \&quot;id\&quot;: \&quot;msg_687a7b542948819ba79e77e14791ef83074adcd9e24850fc\&quot;,\n    \&quot;content\&quot;: [\n      {\n        \&quot;annotations\&quot;: [],\n        \&quot;text\&quot;: \&quot;The \\\&quot;5 Ds of Dodgeball\\\&quot; are a humorous set of rules made famous by the 2004 comedy film **\\\&quot;Dodgeball: A True Underdog Story.\\\&quot;** In the movie, dodgeball coach Patches O’Houlihan teaches these basics to his team. The **5 Ds** are:\n\n1. **Dodge**\n2. **Duck**\n3. **Dip**\n4. **Dive**\n5. **Dodge** (yes, dodge is listed twice for emphasis!)\n\nIn summary:  \n&gt; **“If you can dodge a wrench, you can dodge a ball!”**\n\nThese 5 Ds are not official competitive rules, but have become a fun and memorable pop culture reference for the sport of dodgeball.\&quot;,\n        \&quot;type\&quot;: \&quot;output_text\&quot;,\n        \&quot;logprobs\&quot;: []\n      }\n    ],\n    \&quot;role\&quot;: \&quot;assistant\&quot;,\n    \&quot;status\&quot;: \&quot;completed\&quot;,\n    \&quot;type\&quot;: \&quot;message\&quot;\n  }\n],\n\&quot;parallel_tool_calls\&quot;: true,\n\&quot;temperature\&quot;: 1.0,\n\&quot;tool_choice\&quot;: \&quot;auto\&quot;,\n\&quot;tools\&quot;: [],\n\&quot;top_p\&quot;: 1.0,\n\&quot;background\&quot;: false,\n\&quot;max_output_tokens\&quot;: null,\n\&quot;previous_response_id\&quot;: null,\n\&quot;reasoning\&quot;: {\n  \&quot;effort\&quot;: null,\n  \&quot;generate_summary\&quot;: null,\n  \&quot;summary\&quot;: null\n},\n\&quot;service_tier\&quot;: \&quot;scale\&quot;,\n\&quot;status\&quot;: \&quot;completed\&quot;,\n\&quot;text\&quot;: {\n  \&quot;format\&quot;: {\n    \&quot;type\&quot;: \&quot;text\&quot;\n  }\n},\n\&quot;truncation\&quot;: \&quot;disabled\&quot;,\n\&quot;usage\&quot;: {\n  \&quot;input_tokens\&quot;: 17,\n  \&quot;input_tokens_details\&quot;: {\n    \&quot;cached_tokens\&quot;: 0\n  },\n  \&quot;output_tokens\&quot;: 150,\n  \&quot;output_tokens_details\&quot;: {\n    \&quot;reasoning_tokens\&quot;: 0\n  },\n  \&quot;total_tokens\&quot;: 167\n},\n\&quot;user\&quot;: null,\n\&quot;max_tool_calls\&quot;: null,\n\&quot;store\&quot;: true,\n\&quot;top_logprobs\&quot;: 0\n}\n&quot;],&quot;title&quot;:[0,&quot;Response object&quot;]}]]]}" ssr client="load" opts="{&quot;name&quot;:&quot;CodeComparison&quot;,&quot;value&quot;:true}" await-children><div class="code-comparison"><div class="code-sample not-prose _root_1x2h7_2 light-mode"><div class="_header_1x2h7_34"><div class="_title_1x2h7_42 body-small">Run object</div></div><div class="_body_1x2h7_59 _bodySmall_1x2h7_151 _bodyWithHeader_1x2h7_139"><pre class="hljs syntax-highlighter light-mode _pre_1x2h7_62" data-1p-ignore="true" data-copy-ignore="true"><code data-1p-ignore="true" data-language="python" style="white-space:pre"><code style="float:left;padding-right:10px"><span class="react-syntax-highlighter-line-number">1
</span><span class="react-syntax-highlighter-line-number">2
</span><span class="react-syntax-highlighter-line-number">3
</span><span class="react-syntax-highlighter-line-number">4
</span><span class="react-syntax-highlighter-line-number">5
</span><span class="react-syntax-highlighter-line-number">6
</span><span class="react-syntax-highlighter-line-number">7
</span><span class="react-syntax-highlighter-line-number">8
</span><span class="react-syntax-highlighter-line-number">9
</span><span class="react-syntax-highlighter-line-number">10
</span><span class="react-syntax-highlighter-line-number">11
</span><span class="react-syntax-highlighter-line-number">12
</span><span class="react-syntax-highlighter-line-number">13
</span><span class="react-syntax-highlighter-line-number">14
</span><span class="react-syntax-highlighter-line-number">15
</span><span class="react-syntax-highlighter-line-number">16
</span><span class="react-syntax-highlighter-line-number">17
</span><span class="react-syntax-highlighter-line-number">18
</span><span class="react-syntax-highlighter-line-number">19
</span><span class="react-syntax-highlighter-line-number">20
</span><span class="react-syntax-highlighter-line-number">21
</span><span class="react-syntax-highlighter-line-number">22
</span><span class="react-syntax-highlighter-line-number">23
</span><span class="react-syntax-highlighter-line-number">24
</span><span class="react-syntax-highlighter-line-number">25
</span><span class="react-syntax-highlighter-line-number">26
</span><span class="react-syntax-highlighter-line-number">27
</span><span class="react-syntax-highlighter-line-number">28
</span><span class="react-syntax-highlighter-line-number">29
</span><span class="react-syntax-highlighter-line-number">30
</span><span class="react-syntax-highlighter-line-number">31
</span><span class="react-syntax-highlighter-line-number">32
</span><span class="react-syntax-highlighter-line-number">33
</span><span class="react-syntax-highlighter-line-number">34
</span><span class="react-syntax-highlighter-line-number">35
</span><span class="react-syntax-highlighter-line-number">36
</span><span class="react-syntax-highlighter-line-number">37
</span><span class="react-syntax-highlighter-line-number">38
</span><span class="react-syntax-highlighter-line-number">39
</span><span class="react-syntax-highlighter-line-number">40
</span><span class="react-syntax-highlighter-line-number">41
</span><span class="react-syntax-highlighter-line-number">42
</span><span class="react-syntax-highlighter-line-number">43
</span><span class="react-syntax-highlighter-line-number">44
</span></code><span><span>{
</span></span><span><span></span><span class="hljs-string">&quot;id&quot;</span><span>: </span><span class="hljs-string">&quot;run_FKIpcs5ECSwuCmehBqsqkORj&quot;</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;assistant_id&quot;</span><span>: </span><span class="hljs-string">&quot;asst_8fVY45hU3IM6creFkVi5MBKB&quot;</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;cancelled_at&quot;</span><span>: null,
</span></span><span><span></span><span class="hljs-string">&quot;completed_at&quot;</span><span>: </span><span class="hljs-number">1752857327</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;created_at&quot;</span><span>: </span><span class="hljs-number">1752857322</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;expires_at&quot;</span><span>: null,
</span></span><span><span></span><span class="hljs-string">&quot;failed_at&quot;</span><span>: null,
</span></span><span><span></span><span class="hljs-string">&quot;incomplete_details&quot;</span><span>: null,
</span></span><span><span></span><span class="hljs-string">&quot;instructions&quot;</span><span>: null,
</span></span><span><span></span><span class="hljs-string">&quot;last_error&quot;</span><span>: null,
</span></span><span><span></span><span class="hljs-string">&quot;max_completion_tokens&quot;</span><span>: null,
</span></span><span><span></span><span class="hljs-string">&quot;max_prompt_tokens&quot;</span><span>: null,
</span></span><span><span></span><span class="hljs-string">&quot;metadata&quot;</span><span>: {},
</span></span><span><span></span><span class="hljs-string">&quot;model&quot;</span><span>: </span><span class="hljs-string">&quot;gpt-4.1&quot;</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;object&quot;</span><span>: </span><span class="hljs-string">&quot;thread.run&quot;</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;parallel_tool_calls&quot;</span><span>: true,
</span></span><span><span></span><span class="hljs-string">&quot;required_action&quot;</span><span>: null,
</span></span><span><span></span><span class="hljs-string">&quot;response_format&quot;</span><span>: </span><span class="hljs-string">&quot;auto&quot;</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;started_at&quot;</span><span>: </span><span class="hljs-number">1752857324</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;status&quot;</span><span>: </span><span class="hljs-string">&quot;completed&quot;</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;thread_id&quot;</span><span>: </span><span class="hljs-string">&quot;thread_CrXtCzcyEQbkAcXuNmVSKFs1&quot;</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;tool_choice&quot;</span><span>: </span><span class="hljs-string">&quot;auto&quot;</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;tools&quot;</span><span>: [],
</span></span><span><span></span><span class="hljs-string">&quot;truncation_strategy&quot;</span><span>: {
</span></span><span><span>  </span><span class="hljs-string">&quot;type&quot;</span><span>: </span><span class="hljs-string">&quot;auto&quot;</span><span>,
</span></span><span><span>  </span><span class="hljs-string">&quot;last_messages&quot;</span><span>: null
</span></span><span>},
</span><span><span></span><span class="hljs-string">&quot;usage&quot;</span><span>: {
</span></span><span><span>  </span><span class="hljs-string">&quot;completion_tokens&quot;</span><span>: </span><span class="hljs-number">130</span><span>,
</span></span><span><span>  </span><span class="hljs-string">&quot;prompt_tokens&quot;</span><span>: </span><span class="hljs-number">34</span><span>,
</span></span><span><span>  </span><span class="hljs-string">&quot;total_tokens&quot;</span><span>: </span><span class="hljs-number">164</span><span>,
</span></span><span><span>  </span><span class="hljs-string">&quot;prompt_token_details&quot;</span><span>: {
</span></span><span><span>    </span><span class="hljs-string">&quot;cached_tokens&quot;</span><span>: </span><span class="hljs-number">0</span><span>
</span></span><span>  },
</span><span><span>  </span><span class="hljs-string">&quot;completion_tokens_details&quot;</span><span>: {
</span></span><span><span>    </span><span class="hljs-string">&quot;reasoning_tokens&quot;</span><span>: </span><span class="hljs-number">0</span><span>
</span></span><span>  }
</span><span>},
</span><span><span></span><span class="hljs-string">&quot;temperature&quot;</span><span>: </span><span class="hljs-number">1.0</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;top_p&quot;</span><span>: </span><span class="hljs-number">1.0</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;tool_resources&quot;</span><span>: {},
</span></span><span><span></span><span class="hljs-string">&quot;reasoning_effort&quot;</span><span>: null
</span></span><span>}</span></code></pre></div></div><div class="code-sample not-prose _root_1x2h7_2 light-mode"><div class="_header_1x2h7_34"><div class="_title_1x2h7_42 body-small">Response object</div></div><div class="_body_1x2h7_59 _bodySmall_1x2h7_151 _bodyWithHeader_1x2h7_139"><pre class="hljs syntax-highlighter light-mode _pre_1x2h7_62" data-1p-ignore="true" data-copy-ignore="true"><code data-1p-ignore="true" data-language="python" style="white-space:pre"><code style="float:left;padding-right:10px"><span class="react-syntax-highlighter-line-number">1
</span><span class="react-syntax-highlighter-line-number">2
</span><span class="react-syntax-highlighter-line-number">3
</span><span class="react-syntax-highlighter-line-number">4
</span><span class="react-syntax-highlighter-line-number">5
</span><span class="react-syntax-highlighter-line-number">6
</span><span class="react-syntax-highlighter-line-number">7
</span><span class="react-syntax-highlighter-line-number">8
</span><span class="react-syntax-highlighter-line-number">9
</span><span class="react-syntax-highlighter-line-number">10
</span><span class="react-syntax-highlighter-line-number">11
</span><span class="react-syntax-highlighter-line-number">12
</span><span class="react-syntax-highlighter-line-number">13
</span><span class="react-syntax-highlighter-line-number">14
</span><span class="react-syntax-highlighter-line-number">15
</span><span class="react-syntax-highlighter-line-number">16
</span><span class="react-syntax-highlighter-line-number">17
</span><span class="react-syntax-highlighter-line-number">18
</span><span class="react-syntax-highlighter-line-number">19
</span><span class="react-syntax-highlighter-line-number">20
</span><span class="react-syntax-highlighter-line-number">21
</span><span class="react-syntax-highlighter-line-number">22
</span><span class="react-syntax-highlighter-line-number">23
</span><span class="react-syntax-highlighter-line-number">24
</span><span class="react-syntax-highlighter-line-number">25
</span><span class="react-syntax-highlighter-line-number">26
</span><span class="react-syntax-highlighter-line-number">27
</span><span class="react-syntax-highlighter-line-number">28
</span><span class="react-syntax-highlighter-line-number">29
</span><span class="react-syntax-highlighter-line-number">30
</span><span class="react-syntax-highlighter-line-number">31
</span><span class="react-syntax-highlighter-line-number">32
</span><span class="react-syntax-highlighter-line-number">33
</span><span class="react-syntax-highlighter-line-number">34
</span><span class="react-syntax-highlighter-line-number">35
</span><span class="react-syntax-highlighter-line-number">36
</span><span class="react-syntax-highlighter-line-number">37
</span><span class="react-syntax-highlighter-line-number">38
</span><span class="react-syntax-highlighter-line-number">39
</span><span class="react-syntax-highlighter-line-number">40
</span><span class="react-syntax-highlighter-line-number">41
</span><span class="react-syntax-highlighter-line-number">42
</span><span class="react-syntax-highlighter-line-number">43
</span><span class="react-syntax-highlighter-line-number">44
</span><span class="react-syntax-highlighter-line-number">45
</span><span class="react-syntax-highlighter-line-number">46
</span><span class="react-syntax-highlighter-line-number">47
</span><span class="react-syntax-highlighter-line-number">48
</span><span class="react-syntax-highlighter-line-number">49
</span><span class="react-syntax-highlighter-line-number">50
</span><span class="react-syntax-highlighter-line-number">51
</span><span class="react-syntax-highlighter-line-number">52
</span><span class="react-syntax-highlighter-line-number">53
</span><span class="react-syntax-highlighter-line-number">54
</span><span class="react-syntax-highlighter-line-number">55
</span><span class="react-syntax-highlighter-line-number">56
</span><span class="react-syntax-highlighter-line-number">57
</span><span class="react-syntax-highlighter-line-number">58
</span><span class="react-syntax-highlighter-line-number">59
</span><span class="react-syntax-highlighter-line-number">60
</span><span class="react-syntax-highlighter-line-number">61
</span><span class="react-syntax-highlighter-line-number">62
</span><span class="react-syntax-highlighter-line-number">63
</span><span class="react-syntax-highlighter-line-number">64
</span><span class="react-syntax-highlighter-line-number">65
</span><span class="react-syntax-highlighter-line-number">66
</span><span class="react-syntax-highlighter-line-number">67
</span><span class="react-syntax-highlighter-line-number">68
</span><span class="react-syntax-highlighter-line-number">69
</span><span class="react-syntax-highlighter-line-number">70
</span><span class="react-syntax-highlighter-line-number">71
</span><span class="react-syntax-highlighter-line-number">72
</span><span class="react-syntax-highlighter-line-number">73
</span><span class="react-syntax-highlighter-line-number">74
</span><span class="react-syntax-highlighter-line-number">75
</span><span class="react-syntax-highlighter-line-number">76
</span></code><span><span>{
</span></span><span><span></span><span class="hljs-string">&quot;id&quot;</span><span>: </span><span class="hljs-string">&quot;resp_687a7b53036c819baad6012d58b39bcb074adcd9e24850fc&quot;</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;created_at&quot;</span><span>: </span><span class="hljs-number">1752857427</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;conversation&quot;</span><span>: {
</span></span><span><span>  </span><span class="hljs-string">&quot;id&quot;</span><span>: </span><span class="hljs-string">&quot;conv_689667905b048191b4740501625afd940c7533ace33a2dab&quot;</span><span>
</span></span><span>},
</span><span><span></span><span class="hljs-string">&quot;error&quot;</span><span>: null,
</span></span><span><span></span><span class="hljs-string">&quot;incomplete_details&quot;</span><span>: null,
</span></span><span><span></span><span class="hljs-string">&quot;instructions&quot;</span><span>: null,
</span></span><span><span></span><span class="hljs-string">&quot;metadata&quot;</span><span>: {},
</span></span><span><span></span><span class="hljs-string">&quot;model&quot;</span><span>: </span><span class="hljs-string">&quot;gpt-5.5&quot;</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;object&quot;</span><span>: </span><span class="hljs-string">&quot;response&quot;</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;output&quot;</span><span>: [
</span></span><span>  {
</span><span><span>    </span><span class="hljs-string">&quot;id&quot;</span><span>: </span><span class="hljs-string">&quot;msg_687a7b542948819ba79e77e14791ef83074adcd9e24850fc&quot;</span><span>,
</span></span><span><span>    </span><span class="hljs-string">&quot;content&quot;</span><span>: [
</span></span><span>      {
</span><span><span>        </span><span class="hljs-string">&quot;annotations&quot;</span><span>: [],
</span></span><span><span>        </span><span class="hljs-string">&quot;text&quot;</span><span>: </span><span class="hljs-string">&quot;The \&quot;5 Ds of Dodgeball\&quot; are a humorous set of rules made famous by the 2004 comedy film **\&quot;Dodgeball: A True Underdog Story.\&quot;** In the movie, dodgeball coach Patches O’Houlihan teaches these basics to his team. The **5 Ds** are:
</span></span><span class="hljs-string">
</span><span class="hljs-string">1. **Dodge**
</span><span class="hljs-string">2. **Duck**
</span><span class="hljs-string">3. **Dip**
</span><span class="hljs-string">4. **Dive**
</span><span class="hljs-string">5. **Dodge** (yes, dodge is listed twice for emphasis!)
</span><span class="hljs-string">
</span><span class="hljs-string">In summary:  
</span><span class="hljs-string">&gt; **“If you can dodge a wrench, you can dodge a ball!”**
</span><span class="hljs-string">
</span><span><span class="hljs-string">These 5 Ds are not official competitive rules, but have become a fun and memorable pop culture reference for the sport of dodgeball.&quot;</span><span>,
</span></span><span><span>        </span><span class="hljs-string">&quot;type&quot;</span><span>: </span><span class="hljs-string">&quot;output_text&quot;</span><span>,
</span></span><span><span>        </span><span class="hljs-string">&quot;logprobs&quot;</span><span>: []
</span></span><span>      }
</span><span>    ],
</span><span><span>    </span><span class="hljs-string">&quot;role&quot;</span><span>: </span><span class="hljs-string">&quot;assistant&quot;</span><span>,
</span></span><span><span>    </span><span class="hljs-string">&quot;status&quot;</span><span>: </span><span class="hljs-string">&quot;completed&quot;</span><span>,
</span></span><span><span>    </span><span class="hljs-string">&quot;type&quot;</span><span>: </span><span class="hljs-string">&quot;message&quot;</span><span>
</span></span><span>  }
</span><span>],
</span><span><span></span><span class="hljs-string">&quot;parallel_tool_calls&quot;</span><span>: true,
</span></span><span><span></span><span class="hljs-string">&quot;temperature&quot;</span><span>: </span><span class="hljs-number">1.0</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;tool_choice&quot;</span><span>: </span><span class="hljs-string">&quot;auto&quot;</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;tools&quot;</span><span>: [],
</span></span><span><span></span><span class="hljs-string">&quot;top_p&quot;</span><span>: </span><span class="hljs-number">1.0</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;background&quot;</span><span>: false,
</span></span><span><span></span><span class="hljs-string">&quot;max_output_tokens&quot;</span><span>: null,
</span></span><span><span></span><span class="hljs-string">&quot;previous_response_id&quot;</span><span>: null,
</span></span><span><span></span><span class="hljs-string">&quot;reasoning&quot;</span><span>: {
</span></span><span><span>  </span><span class="hljs-string">&quot;effort&quot;</span><span>: null,
</span></span><span><span>  </span><span class="hljs-string">&quot;generate_summary&quot;</span><span>: null,
</span></span><span><span>  </span><span class="hljs-string">&quot;summary&quot;</span><span>: null
</span></span><span>},
</span><span><span></span><span class="hljs-string">&quot;service_tier&quot;</span><span>: </span><span class="hljs-string">&quot;scale&quot;</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;status&quot;</span><span>: </span><span class="hljs-string">&quot;completed&quot;</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;text&quot;</span><span>: {
</span></span><span><span>  </span><span class="hljs-string">&quot;format&quot;</span><span>: {
</span></span><span><span>    </span><span class="hljs-string">&quot;type&quot;</span><span>: </span><span class="hljs-string">&quot;text&quot;</span><span>
</span></span><span>  }
</span><span>},
</span><span><span></span><span class="hljs-string">&quot;truncation&quot;</span><span>: </span><span class="hljs-string">&quot;disabled&quot;</span><span>,
</span></span><span><span></span><span class="hljs-string">&quot;usage&quot;</span><span>: {
</span></span><span><span>  </span><span class="hljs-string">&quot;input_tokens&quot;</span><span>: </span><span class="hljs-number">17</span><span>,
</span></span><span><span>  </span><span class="hljs-string">&quot;input_tokens_details&quot;</span><span>: {
</span></span><span><span>    </span><span class="hljs-string">&quot;cached_tokens&quot;</span><span>: </span><span class="hljs-number">0</span><span>
</span></span><span>  },
</span><span><span>  </span><span class="hljs-string">&quot;output_tokens&quot;</span><span>: </span><span class="hljs-number">150</span><span>,
</span></span><span><span>  </span><span class="hljs-string">&quot;output_tokens_details&quot;</span><span>: {
</span></span><span><span>    </span><span class="hljs-string">&quot;reasoning_tokens&quot;</span><span>: </span><span class="hljs-number">0</span><span>
</span></span><span>  },
</span><span><span>  </span><span class="hljs-string">&quot;total_tokens&quot;</span><span>: </span><span class="hljs-number">167</span><span>
</span></span><span>},
</span><span><span></span><span class="hljs-string">&quot;user&quot;</span><span>: null,
</span></span><span><span></span><span class="hljs-string">&quot;max_tool_calls&quot;</span><span>: null,
</span></span><span><span></span><span class="hljs-string">&quot;store&quot;</span><span>: true,
</span></span><span><span></span><span class="hljs-string">&quot;top_logprobs&quot;</span><span>: </span><span class="hljs-number">0</span><span>
</span></span><span>}</span></code></pre></div></div></div><!--astro:end--></astro-island>
<hr/>
<h2 id="migrating-your-integration" class="group flex items-center gap-2 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">Migrating your integration</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="migrating-your-integration" aria-label="Copy link to migrating your integration" title="Copy link to migrating your integration"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h2>
<p>Follow the migration steps below to move from the Assistants API to the Responses API, without losing any feature support.</p>
<h3 id="1-create-prompts-from-your-assistants" class="group flex items-center gap-1 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">1. Create prompts from your assistants</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="1-create-prompts-from-your-assistants" aria-label="Copy link to 1 create prompts from your assistants" title="Copy link to 1 create prompts from your assistants"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h3>
<ol>
<li>Identify the most important assistant objects in your application.</li>
<li>Find these in the dashboard and click <code>Create prompt</code>.</li>
</ol>
<p>This will create a prompt object out of each existing assistant object.</p>
<div class="_Notice_wyxfv_1"><div class="_Alert_1bpiz_1" data-variant="outline" data-color="warning" data-actions-placement="end"><div class="_Indicator_1bpiz_159"><svg width="1em" height="1em" viewBox="0 0 24 24" fill="currentColor"><path d="M10.42 2.006a4 4 0 0 1 3.159 0c.674.29 1.188.822 1.667 1.456.474.627 1 1.473 1.653 2.523l3.542 5.696c.72 1.16 1.3 2.09 1.682 2.854.384.766.654 1.517.59 2.292a4 4 0 0 1-1.604 2.886c-.625.463-1.405.63-2.258.709-.85.078-1.945.078-3.311.078H8.46c-1.366 0-2.46 0-3.31-.078-.854-.078-1.634-.246-2.26-.71a4 4 0 0 1-1.603-2.885c-.064-.775.206-1.526.59-2.292.383-.764.961-1.694 1.682-2.854l3.542-5.696c.653-1.05 1.18-1.896 1.653-2.523.48-.634.993-1.166 1.667-1.456Zm2.37 1.838a2 2 0 0 0-1.58 0c-.192.083-.448.28-.86.825-.413.544-.891 1.312-1.577 2.415l-3.488 5.61c-.755 1.214-1.283 2.066-1.62 2.737-.34.678-.402 1.02-.385 1.232a2 2 0 0 0 .802 1.443c.171.127.494.255 1.25.324.748.069 1.75.07 3.18.07h6.976c1.43 0 2.432-.001 3.18-.07.756-.069 1.079-.197 1.25-.324a2 2 0 0 0 .802-1.443c.017-.212-.045-.554-.385-1.232-.337-.671-.865-1.523-1.62-2.737l-3.488-5.61c-.686-1.103-1.164-1.87-1.576-2.415-.413-.546-.67-.742-.861-.825"></path><path d="M12 7.5a1 1 0 0 1 1 1v3a1 1 0 1 1-2 0v-3a1 1 0 0 1 1-1M10.851 15a1.15 1.15 0 1 1 2.3 0 1.15 1.15 0 0 1-2.3 0"></path></svg></div><div class="_Content_1bpiz_147"><div class="_Message_1bpiz_166"><div class="_Description_1bpiz_176"><p>Reusable prompt objects are also being deprecated. If you use this migration
path, review the <a href="/api/docs/deprecations#2026-06-03-reusable-prompts">prompts deprecation
timeline</a> before adopting
prompt objects in a long-lived integration.</p></div></div></div></div></div>
<h3 id="2-move-new-user-chats-over-to-conversations-and-responses" class="group flex items-center gap-1 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">2. Move new user chats over to conversations and responses</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="2-move-new-user-chats-over-to-conversations-and-responses" aria-label="Copy link to 2 move new user chats over to conversations and responses" title="Copy link to 2 move new user chats over to conversations and responses"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h3>
<p>We will not provide an automated tool for migrating Threads to Conversations. Instead, we recommend migrating new user threads onto conversations and backfilling old ones as necessary.</p>
<p>Here’s an example for how you might backfill a thread:</p>
<div class="code-sample not-prose _root_1x2h7_2 light-mode"><div class="_body_1x2h7_59 _bodySmall_1x2h7_151 _bodyWithCopyFloat_1x2h7_145"><div class="_copyFloat_1x2h7_157"><button type="button" class="_Button_6dmow_1 _copyButton_1x2h7_168" data-color="primary" data-variant="ghost" data-size="sm" data-gutter-size="xs" data-icon-size="sm"><span class="_ButtonInner_6dmow_4"><span class="block relative w-[var(--button-icon-size)] h-[var(--button-icon-size)]" data-transition-position="absolute" style="--tg-will-change:transform, opacity;--tg-enter-opacity:1;--tg-enter-transform:scale(1);--tg-enter-filter:none;--tg-enter-duration:300ms;--tg-enter-delay:150ms;--tg-enter-timing-function:var(--cubic-enter);--tg-exit-opacity:0;--tg-exit-transform:scale(0.6);--tg-exit-filter:none;--tg-exit-duration:150ms;--tg-exit-delay:0ms;--tg-exit-timing-function:var(--cubic-exit);--tg-initial-opacity:0;--tg-initial-transform:scale(0.6);--tg-initial-filter:none"><span class="_TransitionItem_1lpir_1 _TransitionGroupChild_1d6a5_1"><svg width="1em" height="1em" viewBox="0 0 24 24" fill="currentColor"><path d="M12.7587 2H16.2413C17.0463 1.99999 17.7106 1.99998 18.2518 2.04419C18.8139 2.09012 19.3306 2.18868 19.816 2.43597C20.5686 2.81947 21.1805 3.43139 21.564 4.18404C21.8113 4.66937 21.9099 5.18608 21.9558 5.74817C22 6.28936 22 6.95372 22 7.75868V11.2413C22 12.0463 22 12.7106 21.9558 13.2518C21.9099 13.8139 21.8113 14.3306 21.564 14.816C21.1805 15.5686 20.5686 16.1805 19.816 16.564C19.3306 16.8113 18.8139 16.9099 18.2518 16.9558C17.8906 16.9853 17.4745 16.9951 16.9984 16.9984C16.9951 17.4745 16.9853 17.8906 16.9558 18.2518C16.9099 18.8139 16.8113 19.3306 16.564 19.816C16.1805 20.5686 15.5686 21.1805 14.816 21.564C14.3306 21.8113 13.8139 21.9099 13.2518 21.9558C12.7106 22 12.0463 22 11.2413 22H7.75868C6.95372 22 6.28936 22 5.74818 21.9558C5.18608 21.9099 4.66937 21.8113 4.18404 21.564C3.43139 21.1805 2.81947 20.5686 2.43597 19.816C2.18868 19.3306 2.09012 18.8139 2.04419 18.2518C1.99998 17.7106 1.99999 17.0463 2 16.2413V12.7587C1.99999 11.9537 1.99998 11.2894 2.04419 10.7482C2.09012 10.1861 2.18868 9.66937 2.43597 9.18404C2.81947 8.43139 3.43139 7.81947 4.18404 7.43598C4.66937 7.18868 5.18608 7.09012 5.74817 7.04419C6.10939 7.01468 6.52548 7.00487 7.00162 7.00162C7.00487 6.52548 7.01468 6.10939 7.04419 5.74817C7.09012 5.18608 7.18868 4.66937 7.43598 4.18404C7.81947 3.43139 8.43139 2.81947 9.18404 2.43597C9.66937 2.18868 10.1861 2.09012 10.7482 2.04419C11.2894 1.99998 11.9537 1.99999 12.7587 2ZM9.00176 7L11.2413 7C12.0463 6.99999 12.7106 6.99998 13.2518 7.04419C13.8139 7.09012 14.3306 7.18868 14.816 7.43598C15.5686 7.81947 16.1805 8.43139 16.564 9.18404C16.8113 9.66937 16.9099 10.1861 16.9558 10.7482C17 11.2894 17 11.9537 17 12.7587V14.9982C17.4455 14.9951 17.7954 14.9864 18.089 14.9624C18.5274 14.9266 18.7516 14.8617 18.908 14.782C19.2843 14.5903 19.5903 14.2843 19.782 13.908C19.8617 13.7516 19.9266 13.5274 19.9624 13.089C19.9992 12.6389 20 12.0566 20 11.2V7.8C20 6.94342 19.9992 6.36113 19.9624 5.91104C19.9266 5.47262 19.8617 5.24842 19.782 5.09202C19.5903 4.7157 19.2843 4.40973 18.908 4.21799C18.7516 4.1383 18.5274 4.07337 18.089 4.03755C17.6389 4.00078 17.0566 4 16.2 4H12.8C11.9434 4 11.3611 4.00078 10.911 4.03755C10.4726 4.07337 10.2484 4.1383 10.092 4.21799C9.7157 4.40973 9.40973 4.7157 9.21799 5.09202C9.1383 5.24842 9.07337 5.47262 9.03755 5.91104C9.01357 6.20463 9.00489 6.55447 9.00176 7ZM5.91104 9.03755C5.47262 9.07337 5.24842 9.1383 5.09202 9.21799C4.7157 9.40973 4.40973 9.7157 4.21799 10.092C4.1383 10.2484 4.07337 10.4726 4.03755 10.911C4.00078 11.3611 4 11.9434 4 12.8V16.2C4 17.0566 4.00078 17.6389 4.03755 18.089C4.07337 18.5274 4.1383 18.7516 4.21799 18.908C4.40973 19.2843 4.7157 19.5903 5.09202 19.782C5.24842 19.8617 5.47262 19.9266 5.91104 19.9624C6.36113 19.9992 6.94342 20 7.8 20H11.2C12.0566 20 12.6389 19.9992 13.089 19.9624C13.5274 19.9266 13.7516 19.8617 13.908 19.782C14.2843 19.5903 14.5903 19.2843 14.782 18.908C14.8617 18.7516 14.9266 18.5274 14.9624 18.089C14.9992 17.6389 15 17.0566 15 16.2V12.8C15 11.9434 14.9992 11.3611 14.9624 10.911C14.9266 10.4726 14.8617 10.2484 14.782 10.092C14.5903 9.7157 14.2843 9.40973 13.908 9.21799C13.7516 9.1383 13.5274 9.07337 13.089 9.03755C12.6389 9.00078 12.0566 9 11.2 9H7.8C6.94342 9 6.36113 9.00078 5.91104 9.03755Z" fill="currentColor"></path></svg></span></span></span></button></div><pre class="hljs syntax-highlighter light-mode _pre_1x2h7_62" data-1p-ignore="true" data-copy-ignore="true"><code data-1p-ignore="true" data-language="python" style="white-space:pre"><code style="float:left;padding-right:10px"><span class="react-syntax-highlighter-line-number">1
</span><span class="react-syntax-highlighter-line-number">2
</span><span class="react-syntax-highlighter-line-number">3
</span><span class="react-syntax-highlighter-line-number">4
</span><span class="react-syntax-highlighter-line-number">5
</span><span class="react-syntax-highlighter-line-number">6
</span><span class="react-syntax-highlighter-line-number">7
</span><span class="react-syntax-highlighter-line-number">8
</span><span class="react-syntax-highlighter-line-number">9
</span><span class="react-syntax-highlighter-line-number">10
</span><span class="react-syntax-highlighter-line-number">11
</span><span class="react-syntax-highlighter-line-number">12
</span><span class="react-syntax-highlighter-line-number">13
</span><span class="react-syntax-highlighter-line-number">14
</span><span class="react-syntax-highlighter-line-number">15
</span><span class="react-syntax-highlighter-line-number">16
</span><span class="react-syntax-highlighter-line-number">17
</span><span class="react-syntax-highlighter-line-number">18
</span><span class="react-syntax-highlighter-line-number">19
</span><span class="react-syntax-highlighter-line-number">20
</span><span class="react-syntax-highlighter-line-number">21
</span><span class="react-syntax-highlighter-line-number">22
</span><span class="react-syntax-highlighter-line-number">23
</span><span class="react-syntax-highlighter-line-number">24
</span><span class="react-syntax-highlighter-line-number">25
</span><span class="react-syntax-highlighter-line-number">26
</span><span class="react-syntax-highlighter-line-number">27
</span><span class="react-syntax-highlighter-line-number">28
</span><span class="react-syntax-highlighter-line-number">29
</span></code><span><span>thread_id = </span><span class="hljs-string">&quot;thread_EIpHrTAVe0OzoLQg3TXfvrkG&quot;</span><span>
</span></span><span>
</span><span><span></span><span class="hljs-keyword">for</span><span> page </span><span class="hljs-keyword">in</span><span> openai.beta.threads.messages.</span><span class="hljs-built_in">list</span><span>(thread_id=thread_id, order=</span><span class="hljs-string">&quot;asc&quot;</span><span>).iter_pages():
</span></span><span>    messages += page.data
</span><span>
</span><span>items = []
</span><span><span></span><span class="hljs-keyword">for</span><span> m </span><span class="hljs-keyword">in</span><span> messages:
</span></span><span><span>    item = {</span><span class="hljs-string">&quot;role&quot;</span><span>: m.role}
</span></span><span>    item_content = []
</span><span>
</span><span><span>    </span><span class="hljs-keyword">for</span><span> content </span><span class="hljs-keyword">in</span><span> m.content:
</span></span><span><span>        match content.</span><span class="hljs-built_in">type</span><span>:
</span></span><span><span>            case </span><span class="hljs-string">&quot;text&quot;</span><span>:
</span></span><span><span>                item_content_type = </span><span class="hljs-string">&quot;input_text&quot;</span><span> </span><span class="hljs-keyword">if</span><span> m.role == </span><span class="hljs-string">&quot;user&quot;</span><span> </span><span class="hljs-keyword">else</span><span> </span><span class="hljs-string">&quot;output_text&quot;</span><span>
</span></span><span><span>                item_content += [{</span><span class="hljs-string">&quot;type&quot;</span><span>: item_content_type, </span><span class="hljs-string">&quot;text&quot;</span><span>: content.text.value}]
</span></span><span><span>            case </span><span class="hljs-string">&quot;image_url&quot;</span><span>:
</span></span><span>                item_content + [
</span><span>                    {
</span><span><span>                        </span><span class="hljs-string">&quot;type&quot;</span><span>: </span><span class="hljs-string">&quot;input_image&quot;</span><span>,
</span></span><span><span>                        </span><span class="hljs-string">&quot;image_url&quot;</span><span>: content.image_url.url,
</span></span><span><span>                        </span><span class="hljs-string">&quot;detail&quot;</span><span>: content.image_url.detail,
</span></span><span>                    }
</span><span>                ]
</span><span>
</span><span><span>    item |= {</span><span class="hljs-string">&quot;content&quot;</span><span>: item_content}
</span></span><span>    items.append(item)
</span><span>
</span><span><span></span><span class="hljs-comment"># create a conversation with your converted items</span><span>
</span></span><span>conversation = openai.conversations.create(items=items)</span></code></pre></div></div>
<h2 id="comparing-full-examples" class="group flex items-center gap-2 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">Comparing full examples</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="comparing-full-examples" aria-label="Copy link to comparing full examples" title="Copy link to comparing full examples"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h2>
<p>Here’s a few simple examples of integrations using both the Assistants API and the Responses API so you can see how they compare.</p>
<h3 id="user-chat-app" class="group flex items-center gap-1 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">User chat app</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="user-chat-app" aria-label="Copy link to user chat app" title="Copy link to user chat app"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h3>
<div id="content-switcher-user-chat-app" class="content-switcher-root astro-cr4aci74" data-content-switcher-root data-content-switcher-id="user-chat-app" data-content-switcher-initial="assistants" data-content-switcher-value="assistants"> <div class="content-switcher-selector astro-cr4aci74"> <style>astro-island,astro-slot,astro-static-slot{display:contents}</style><script>(()=>{var e=async t=>{await(await t())()};(self.Astro||(self.Astro={})).load=e;window.dispatchEvent(new Event("astro:load"));})();</script><script>(()=>{var A=Object.defineProperty;var g=(i,o,a)=>o in i?A(i,o,{enumerable:!0,configurable:!0,writable:!0,value:a}):i[o]=a;var d=(i,o,a)=>g(i,typeof o!="symbol"?o+"":o,a);{let i={0:t=>m(t),1:t=>a(t),2:t=>new RegExp(t),3:t=>new Date(t),4:t=>new Map(a(t)),5:t=>new Set(a(t)),6:t=>BigInt(t),7:t=>new URL(t),8:t=>new Uint8Array(t),9:t=>new Uint16Array(t),10:t=>new Uint32Array(t),11:t=>Number.POSITIVE_INFINITY*t},o=t=>{let[l,e]=t;return l in i?i[l](e):void 0},a=t=>t.map(o),m=t=>typeof t!="object"||t===null?t:Object.fromEntries(Object.entries(t).map(([l,e])=>[l,o(e)]));class y extends HTMLElement{constructor(){super(...arguments);d(this,"Component");d(this,"hydrator");d(this,"hydrate",async()=>{var b;if(!this.hydrator||!this.isConnected)return;let e=(b=this.parentElement)==null?void 0:b.closest("astro-island[ssr]");if(e){e.addEventListener("astro:hydrate",this.hydrate,{once:!0});return}let c=this.querySelectorAll("astro-slot"),n={},h=this.querySelectorAll("template[data-astro-template]");for(let r of h){let s=r.closest(this.tagName);s!=null&&s.isSameNode(this)&&(n[r.getAttribute("data-astro-template")||"default"]=r.innerHTML,r.remove())}for(let r of c){let s=r.closest(this.tagName);s!=null&&s.isSameNode(this)&&(n[r.getAttribute("name")||"default"]=r.innerHTML)}let p;try{p=this.hasAttribute("props")?m(JSON.parse(this.getAttribute("props"))):{}}catch(r){let s=this.getAttribute("component-url")||"<unknown>",v=this.getAttribute("component-export");throw v&&(s+=` (export ${v})`),console.error(`[hydrate] Error parsing props for component ${s}`,this.getAttribute("props"),r),r}let u;await this.hydrator(this)(this.Component,p,n,{client:this.getAttribute("client")}),this.removeAttribute("ssr"),this.dispatchEvent(new CustomEvent("astro:hydrate"))});d(this,"unmount",()=>{this.isConnected||this.dispatchEvent(new CustomEvent("astro:unmount"))})}disconnectedCallback(){document.removeEventListener("astro:after-swap",this.unmount),document.addEventListener("astro:after-swap",this.unmount,{once:!0})}connectedCallback(){if(!this.hasAttribute("await-children")||document.readyState==="interactive"||document.readyState==="complete")this.childrenConnectedCallback();else{let e=()=>{document.removeEventListener("DOMContentLoaded",e),c.disconnect(),this.childrenConnectedCallback()},c=new MutationObserver(()=>{var n;((n=this.lastChild)==null?void 0:n.nodeType)===Node.COMMENT_NODE&&this.lastChild.nodeValue==="astro:end"&&(this.lastChild.remove(),e())});c.observe(this,{childList:!0}),document.addEventListener("DOMContentLoaded",e)}}async childrenConnectedCallback(){let e=this.getAttribute("before-hydration-url");e&&await import(e),this.start()}async start(){let e=JSON.parse(this.getAttribute("opts")),c=this.getAttribute("client");if(Astro[c]===void 0){window.addEventListener(`astro:${c}`,()=>this.start(),{once:!0});return}try{await Astro[c](async()=>{let n=this.getAttribute("renderer-url"),[h,{default:p}]=await Promise.all([import(this.getAttribute("component-url")),n?import(n):()=>()=>{}]),u=this.getAttribute("component-export")||"default";if(!u.includes("."))this.Component=h[u];else{this.Component=h;for(let f of u.split("."))this.Component=this.Component[f]}return this.hydrator=p,this.hydrate},e,this)}catch(n){console.error(`[astro-island] Error hydrating ${this.getAttribute("component-url")}`,n)}}attributeChangedCallback(){this.hydrate()}}d(y,"observedAttributes",["props"]),customElements.get("astro-island")||customElements.define("astro-island",y)}})();</script><astro-island uid="2w2JsV" prefix="r114" component-url="/_astro/SwitcherSelector.react.Cu1TxTjN.js" component-export="default" renderer-url="/_astro/client.BWriqC1y.js" props="{&quot;rootId&quot;:[0,&quot;content-switcher-user-chat-app&quot;],&quot;id&quot;:[0,&quot;user-chat-app&quot;],&quot;options&quot;:[1,[[0,{&quot;label&quot;:[0,&quot;Assistants API&quot;],&quot;tooltip&quot;:[0],&quot;value&quot;:[0,&quot;assistants&quot;]}],[0,{&quot;label&quot;:[0,&quot;Responses API&quot;],&quot;tooltip&quot;:[0],&quot;value&quot;:[0,&quot;responses&quot;]}]]],&quot;initialValue&quot;:[0,&quot;assistants&quot;]}" ssr client="load" opts="{&quot;name&quot;:&quot;SwitcherSelector&quot;,&quot;value&quot;:true}" await-children><div role="group" dir="ltr" class="_SegmentedControl_16x8u_1" data-size="md" aria-label="Content switcher" tabindex="-1" style="outline:none"><div class="_SegmentedControlThumb_16x8u_226"></div><button type="button" data-state="on" role="radio" aria-checked="true" class="_SegmentedControlOption_16x8u_142" data-content-switcher-option="true" data-value="assistants" tabindex="-1" data-radix-collection-item=""><span class="relative">Assistants API</span></button><button type="button" data-state="off" role="radio" aria-checked="false" class="_SegmentedControlOption_16x8u_142" data-content-switcher-option="true" data-value="responses" tabindex="-1" data-radix-collection-item=""><span class="relative">Responses API</span></button></div><!--astro:end--></astro-island> </div> <div class="content-switcher-panes astro-cr4aci74"> <div data-content-switcher-pane="true" data-value="assistants"><div class="hidden">Assistants API</div><astro-island uid="Z1KikcF" prefix="r121" component-url="/_astro/CodeSample.react.DGgkDblh.js" component-export="CodeSample" renderer-url="/_astro/client.BWriqC1y.js" props="{&quot;defaultLanguage&quot;:[0,&quot;python&quot;],&quot;code&quot;:[0,&quot;thread = openai.threads.create()\n\n    @app.post(\&quot;/messages\&quot;)\n    async def message(message: Message):\n        openai.beta.threads.messages.create(\n            role=\&quot;user\&quot;,\n            content=message.content\n        )\n\n        run = openai.beta.threads.runs.create(\n            assistant_id=os.getenv(\&quot;ASSISTANT_ID\&quot;),\n            thread_id=thread.id\n        )\n        while run.status in (\&quot;queued\&quot;, \&quot;in_progress\&quot;):\n            await asyncio.sleep(1)\n            run = openai.beta.threads.runs.retrieve(thread_id=thread_id, run_id=run.id)\n\n        messages = openai.beta.threads.messages.list(\n            order=\&quot;desc\&quot;, limit=1, thread_id=thread.id\n        )\n\n        return { \&quot;content\&quot;: messages[-1].content }&quot;]}" ssr client="load" opts="{&quot;name&quot;:&quot;CodeSample&quot;,&quot;value&quot;:true}" await-children><div class="code-sample not-prose _root_1x2h7_2 light-mode"><div class="_body_1x2h7_59 _bodySmall_1x2h7_151 _bodyWithCopyFloat_1x2h7_145"><div class="_copyFloat_1x2h7_157"><button type="button" class="_Button_6dmow_1 _copyButton_1x2h7_168" data-color="primary" data-variant="ghost" data-size="sm" data-gutter-size="xs" data-icon-size="sm"><span class="_ButtonInner_6dmow_4"><span class="block relative w-[var(--button-icon-size)] h-[var(--button-icon-size)]" data-transition-position="absolute" style="--tg-will-change:transform, opacity;--tg-enter-opacity:1;--tg-enter-transform:scale(1);--tg-enter-filter:none;--tg-enter-duration:300ms;--tg-enter-delay:150ms;--tg-enter-timing-function:var(--cubic-enter);--tg-exit-opacity:0;--tg-exit-transform:scale(0.6);--tg-exit-filter:none;--tg-exit-duration:150ms;--tg-exit-delay:0ms;--tg-exit-timing-function:var(--cubic-exit);--tg-initial-opacity:0;--tg-initial-transform:scale(0.6);--tg-initial-filter:none"><span class="_TransitionItem_1lpir_1 _TransitionGroupChild_1d6a5_1"><svg width="1em" height="1em" viewBox="0 0 24 24" fill="currentColor"><path d="M12.7587 2H16.2413C17.0463 1.99999 17.7106 1.99998 18.2518 2.04419C18.8139 2.09012 19.3306 2.18868 19.816 2.43597C20.5686 2.81947 21.1805 3.43139 21.564 4.18404C21.8113 4.66937 21.9099 5.18608 21.9558 5.74817C22 6.28936 22 6.95372 22 7.75868V11.2413C22 12.0463 22 12.7106 21.9558 13.2518C21.9099 13.8139 21.8113 14.3306 21.564 14.816C21.1805 15.5686 20.5686 16.1805 19.816 16.564C19.3306 16.8113 18.8139 16.9099 18.2518 16.9558C17.8906 16.9853 17.4745 16.9951 16.9984 16.9984C16.9951 17.4745 16.9853 17.8906 16.9558 18.2518C16.9099 18.8139 16.8113 19.3306 16.564 19.816C16.1805 20.5686 15.5686 21.1805 14.816 21.564C14.3306 21.8113 13.8139 21.9099 13.2518 21.9558C12.7106 22 12.0463 22 11.2413 22H7.75868C6.95372 22 6.28936 22 5.74818 21.9558C5.18608 21.9099 4.66937 21.8113 4.18404 21.564C3.43139 21.1805 2.81947 20.5686 2.43597 19.816C2.18868 19.3306 2.09012 18.8139 2.04419 18.2518C1.99998 17.7106 1.99999 17.0463 2 16.2413V12.7587C1.99999 11.9537 1.99998 11.2894 2.04419 10.7482C2.09012 10.1861 2.18868 9.66937 2.43597 9.18404C2.81947 8.43139 3.43139 7.81947 4.18404 7.43598C4.66937 7.18868 5.18608 7.09012 5.74817 7.04419C6.10939 7.01468 6.52548 7.00487 7.00162 7.00162C7.00487 6.52548 7.01468 6.10939 7.04419 5.74817C7.09012 5.18608 7.18868 4.66937 7.43598 4.18404C7.81947 3.43139 8.43139 2.81947 9.18404 2.43597C9.66937 2.18868 10.1861 2.09012 10.7482 2.04419C11.2894 1.99998 11.9537 1.99999 12.7587 2ZM9.00176 7L11.2413 7C12.0463 6.99999 12.7106 6.99998 13.2518 7.04419C13.8139 7.09012 14.3306 7.18868 14.816 7.43598C15.5686 7.81947 16.1805 8.43139 16.564 9.18404C16.8113 9.66937 16.9099 10.1861 16.9558 10.7482C17 11.2894 17 11.9537 17 12.7587V14.9982C17.4455 14.9951 17.7954 14.9864 18.089 14.9624C18.5274 14.9266 18.7516 14.8617 18.908 14.782C19.2843 14.5903 19.5903 14.2843 19.782 13.908C19.8617 13.7516 19.9266 13.5274 19.9624 13.089C19.9992 12.6389 20 12.0566 20 11.2V7.8C20 6.94342 19.9992 6.36113 19.9624 5.91104C19.9266 5.47262 19.8617 5.24842 19.782 5.09202C19.5903 4.7157 19.2843 4.40973 18.908 4.21799C18.7516 4.1383 18.5274 4.07337 18.089 4.03755C17.6389 4.00078 17.0566 4 16.2 4H12.8C11.9434 4 11.3611 4.00078 10.911 4.03755C10.4726 4.07337 10.2484 4.1383 10.092 4.21799C9.7157 4.40973 9.40973 4.7157 9.21799 5.09202C9.1383 5.24842 9.07337 5.47262 9.03755 5.91104C9.01357 6.20463 9.00489 6.55447 9.00176 7ZM5.91104 9.03755C5.47262 9.07337 5.24842 9.1383 5.09202 9.21799C4.7157 9.40973 4.40973 9.7157 4.21799 10.092C4.1383 10.2484 4.07337 10.4726 4.03755 10.911C4.00078 11.3611 4 11.9434 4 12.8V16.2C4 17.0566 4.00078 17.6389 4.03755 18.089C4.07337 18.5274 4.1383 18.7516 4.21799 18.908C4.40973 19.2843 4.7157 19.5903 5.09202 19.782C5.24842 19.8617 5.47262 19.9266 5.91104 19.9624C6.36113 19.9992 6.94342 20 7.8 20H11.2C12.0566 20 12.6389 19.9992 13.089 19.9624C13.5274 19.9266 13.7516 19.8617 13.908 19.782C14.2843 19.5903 14.5903 19.2843 14.782 18.908C14.8617 18.7516 14.9266 18.5274 14.9624 18.089C14.9992 17.6389 15 17.0566 15 16.2V12.8C15 11.9434 14.9992 11.3611 14.9624 10.911C14.9266 10.4726 14.8617 10.2484 14.782 10.092C14.5903 9.7157 14.2843 9.40973 13.908 9.21799C13.7516 9.1383 13.5274 9.07337 13.089 9.03755C12.6389 9.00078 12.0566 9 11.2 9H7.8C6.94342 9 6.36113 9.00078 5.91104 9.03755Z" fill="currentColor"></path></svg></span></span></span></button></div><pre class="hljs syntax-highlighter light-mode _pre_1x2h7_62" data-1p-ignore="true" data-copy-ignore="true"><code data-1p-ignore="true" data-language="json" style="white-space:pre"><code style="float:left;padding-right:10px"><span class="react-syntax-highlighter-line-number">1
</span><span class="react-syntax-highlighter-line-number">2
</span><span class="react-syntax-highlighter-line-number">3
</span><span class="react-syntax-highlighter-line-number">4
</span><span class="react-syntax-highlighter-line-number">5
</span><span class="react-syntax-highlighter-line-number">6
</span><span class="react-syntax-highlighter-line-number">7
</span><span class="react-syntax-highlighter-line-number">8
</span><span class="react-syntax-highlighter-line-number">9
</span><span class="react-syntax-highlighter-line-number">10
</span><span class="react-syntax-highlighter-line-number">11
</span><span class="react-syntax-highlighter-line-number">12
</span><span class="react-syntax-highlighter-line-number">13
</span><span class="react-syntax-highlighter-line-number">14
</span><span class="react-syntax-highlighter-line-number">15
</span><span class="react-syntax-highlighter-line-number">16
</span><span class="react-syntax-highlighter-line-number">17
</span><span class="react-syntax-highlighter-line-number">18
</span><span class="react-syntax-highlighter-line-number">19
</span><span class="react-syntax-highlighter-line-number">20
</span><span class="react-syntax-highlighter-line-number">21
</span><span class="react-syntax-highlighter-line-number">22
</span></code><span><span>thread = openai.threads.create()
</span></span><span>
</span><span><span>    @app.post(</span><span class="hljs-string">&quot;/messages&quot;</span><span>)
</span></span><span>    async def message(message: Message):
</span><span>        openai.beta.threads.messages.create(
</span><span><span>            role=</span><span class="hljs-string">&quot;user&quot;</span><span>,
</span></span><span>            content=message.content
</span><span>        )
</span><span>
</span><span>        run = openai.beta.threads.runs.create(
</span><span><span>            assistant_id=os.getenv(</span><span class="hljs-string">&quot;ASSISTANT_ID&quot;</span><span>),
</span></span><span>            thread_id=thread.id
</span><span>        )
</span><span><span>        while run.status in (</span><span class="hljs-string">&quot;queued&quot;</span><span>, </span><span class="hljs-string">&quot;in_progress&quot;</span><span>):
</span></span><span><span>            await asyncio.sleep(</span><span class="hljs-number">1</span><span>)
</span></span><span>            run = openai.beta.threads.runs.retrieve(thread_id=thread_id, run_id=run.id)
</span><span>
</span><span>        messages = openai.beta.threads.messages.list(
</span><span><span>            order=</span><span class="hljs-string">&quot;desc&quot;</span><span>, limit=</span><span class="hljs-number">1</span><span>, thread_id=thread.id
</span></span><span>        )
</span><span>
</span><span><span>        return { </span><span class="hljs-attr">&quot;content&quot;</span><span>: messages[</span><span class="hljs-number">-1</span><span>].content }</span></span></code></pre></div></div><!--astro:end--></astro-island></div><div data-content-switcher-pane="true" data-value="responses" hidden><div class="hidden">Responses API</div><div class="code-sample not-prose _root_1x2h7_2 light-mode"><div class="_body_1x2h7_59 _bodySmall_1x2h7_151 _bodyWithCopyFloat_1x2h7_145"><div class="_copyFloat_1x2h7_157"><button type="button" class="_Button_6dmow_1 _copyButton_1x2h7_168" data-color="primary" data-variant="ghost" data-size="sm" data-gutter-size="xs" data-icon-size="sm"><span class="_ButtonInner_6dmow_4"><span class="block relative w-[var(--button-icon-size)] h-[var(--button-icon-size)]" data-transition-position="absolute" style="--tg-will-change:transform, opacity;--tg-enter-opacity:1;--tg-enter-transform:scale(1);--tg-enter-filter:none;--tg-enter-duration:300ms;--tg-enter-delay:150ms;--tg-enter-timing-function:var(--cubic-enter);--tg-exit-opacity:0;--tg-exit-transform:scale(0.6);--tg-exit-filter:none;--tg-exit-duration:150ms;--tg-exit-delay:0ms;--tg-exit-timing-function:var(--cubic-exit);--tg-initial-opacity:0;--tg-initial-transform:scale(0.6);--tg-initial-filter:none"><span class="_TransitionItem_1lpir_1 _TransitionGroupChild_1d6a5_1"><svg width="1em" height="1em" viewBox="0 0 24 24" fill="currentColor"><path d="M12.7587 2H16.2413C17.0463 1.99999 17.7106 1.99998 18.2518 2.04419C18.8139 2.09012 19.3306 2.18868 19.816 2.43597C20.5686 2.81947 21.1805 3.43139 21.564 4.18404C21.8113 4.66937 21.9099 5.18608 21.9558 5.74817C22 6.28936 22 6.95372 22 7.75868V11.2413C22 12.0463 22 12.7106 21.9558 13.2518C21.9099 13.8139 21.8113 14.3306 21.564 14.816C21.1805 15.5686 20.5686 16.1805 19.816 16.564C19.3306 16.8113 18.8139 16.9099 18.2518 16.9558C17.8906 16.9853 17.4745 16.9951 16.9984 16.9984C16.9951 17.4745 16.9853 17.8906 16.9558 18.2518C16.9099 18.8139 16.8113 19.3306 16.564 19.816C16.1805 20.5686 15.5686 21.1805 14.816 21.564C14.3306 21.8113 13.8139 21.9099 13.2518 21.9558C12.7106 22 12.0463 22 11.2413 22H7.75868C6.95372 22 6.28936 22 5.74818 21.9558C5.18608 21.9099 4.66937 21.8113 4.18404 21.564C3.43139 21.1805 2.81947 20.5686 2.43597 19.816C2.18868 19.3306 2.09012 18.8139 2.04419 18.2518C1.99998 17.7106 1.99999 17.0463 2 16.2413V12.7587C1.99999 11.9537 1.99998 11.2894 2.04419 10.7482C2.09012 10.1861 2.18868 9.66937 2.43597 9.18404C2.81947 8.43139 3.43139 7.81947 4.18404 7.43598C4.66937 7.18868 5.18608 7.09012 5.74817 7.04419C6.10939 7.01468 6.52548 7.00487 7.00162 7.00162C7.00487 6.52548 7.01468 6.10939 7.04419 5.74817C7.09012 5.18608 7.18868 4.66937 7.43598 4.18404C7.81947 3.43139 8.43139 2.81947 9.18404 2.43597C9.66937 2.18868 10.1861 2.09012 10.7482 2.04419C11.2894 1.99998 11.9537 1.99999 12.7587 2ZM9.00176 7L11.2413 7C12.0463 6.99999 12.7106 6.99998 13.2518 7.04419C13.8139 7.09012 14.3306 7.18868 14.816 7.43598C15.5686 7.81947 16.1805 8.43139 16.564 9.18404C16.8113 9.66937 16.9099 10.1861 16.9558 10.7482C17 11.2894 17 11.9537 17 12.7587V14.9982C17.4455 14.9951 17.7954 14.9864 18.089 14.9624C18.5274 14.9266 18.7516 14.8617 18.908 14.782C19.2843 14.5903 19.5903 14.2843 19.782 13.908C19.8617 13.7516 19.9266 13.5274 19.9624 13.089C19.9992 12.6389 20 12.0566 20 11.2V7.8C20 6.94342 19.9992 6.36113 19.9624 5.91104C19.9266 5.47262 19.8617 5.24842 19.782 5.09202C19.5903 4.7157 19.2843 4.40973 18.908 4.21799C18.7516 4.1383 18.5274 4.07337 18.089 4.03755C17.6389 4.00078 17.0566 4 16.2 4H12.8C11.9434 4 11.3611 4.00078 10.911 4.03755C10.4726 4.07337 10.2484 4.1383 10.092 4.21799C9.7157 4.40973 9.40973 4.7157 9.21799 5.09202C9.1383 5.24842 9.07337 5.47262 9.03755 5.91104C9.01357 6.20463 9.00489 6.55447 9.00176 7ZM5.91104 9.03755C5.47262 9.07337 5.24842 9.1383 5.09202 9.21799C4.7157 9.40973 4.40973 9.7157 4.21799 10.092C4.1383 10.2484 4.07337 10.4726 4.03755 10.911C4.00078 11.3611 4 11.9434 4 12.8V16.2C4 17.0566 4.00078 17.6389 4.03755 18.089C4.07337 18.5274 4.1383 18.7516 4.21799 18.908C4.40973 19.2843 4.7157 19.5903 5.09202 19.782C5.24842 19.8617 5.47262 19.9266 5.91104 19.9624C6.36113 19.9992 6.94342 20 7.8 20H11.2C12.0566 20 12.6389 19.9992 13.089 19.9624C13.5274 19.9266 13.7516 19.8617 13.908 19.782C14.2843 19.5903 14.5903 19.2843 14.782 18.908C14.8617 18.7516 14.9266 18.5274 14.9624 18.089C14.9992 17.6389 15 17.0566 15 16.2V12.8C15 11.9434 14.9992 11.3611 14.9624 10.911C14.9266 10.4726 14.8617 10.2484 14.782 10.092C14.5903 9.7157 14.2843 9.40973 13.908 9.21799C13.7516 9.1383 13.5274 9.07337 13.089 9.03755C12.6389 9.00078 12.0566 9 11.2 9H7.8C6.94342 9 6.36113 9.00078 5.91104 9.03755Z" fill="currentColor"></path></svg></span></span></span></button></div><pre class="hljs syntax-highlighter light-mode _pre_1x2h7_62" data-1p-ignore="true" data-copy-ignore="true"><code data-1p-ignore="true" data-language="json" style="white-space:pre"><code style="float:left;padding-right:10px"><span class="react-syntax-highlighter-line-number">1
</span><span class="react-syntax-highlighter-line-number">2
</span><span class="react-syntax-highlighter-line-number">3
</span><span class="react-syntax-highlighter-line-number">4
</span><span class="react-syntax-highlighter-line-number">5
</span><span class="react-syntax-highlighter-line-number">6
</span><span class="react-syntax-highlighter-line-number">7
</span><span class="react-syntax-highlighter-line-number">8
</span><span class="react-syntax-highlighter-line-number">9
</span><span class="react-syntax-highlighter-line-number">10
</span></code><span><span>conversation = openai.conversations.create()
</span></span><span>
</span><span><span>    @app.post(</span><span class="hljs-string">&quot;/messages&quot;</span><span>)
</span></span><span>    async def message(message: Message):
</span><span>        response = openai.responses.create(
</span><span><span>            prompt={ </span><span class="hljs-attr">&quot;id&quot;</span><span>: os.getenv(</span><span class="hljs-string">&quot;PROMPT_ID&quot;</span><span>) },
</span></span><span><span>            input=[{ </span><span class="hljs-attr">&quot;role&quot;</span><span>: </span><span class="hljs-string">&quot;user&quot;</span><span>, </span><span class="hljs-attr">&quot;content&quot;</span><span>: message.content }]
</span></span><span>        )
</span><span>
</span><span><span>        return { </span><span class="hljs-attr">&quot;content&quot;</span><span>: response.output_text }</span></span></code></pre></div></div></div> </div> <script>
    if (!window.__contentSwitcherInit) {
      window.__contentSwitcherInit = true;

      var updateButtons = function (root, value) {
        if (!root || !value) return;
        // Avoid mutating React-managed segmented controls before hydration.
        if (!root.hasAttribute("data-react-hydrated")) return;
        var buttons = root.querySelectorAll("[data-content-switcher-option]");
        var activeButton = null;
        buttons.forEach(function (button) {
          var isActive = button.dataset.value === value;
          button.setAttribute("data-state", isActive ? "on" : "off");
          button.setAttribute("aria-checked", isActive ? "true" : "false");
          if (isActive) {
            activeButton = button;
          }
        });

        var control = root.querySelector(
          '[role="group"][aria-label="Content switcher"]'
        );
        var thumb = control
          ? control.querySelector('[class*="SegmentedControlThumb"]')
          : null;
        if (thumb && activeButton && control) {
          var targetWidth = Math.floor(activeButton.clientWidth);
          var targetOffset = activeButton.offsetLeft;
          if (control.clientWidth - (targetWidth + targetOffset) < 2) {
            targetWidth = targetWidth - 1;
          }
          thumb.style.width = targetWidth + "px";
          thumb.style.transform = "translateX(" + targetOffset + "px)";
        }
      };

      var refreshToc = function () {
        requestAnimationFrame(function () {
          document.dispatchEvent(new CustomEvent("toc:refresh"));
        });
      };

      var setValue = function (root, value) {
        if (!root || !value) return;
        root.dataset.contentSwitcherValue = value;
        var panes = root.querySelectorAll("[data-content-switcher-pane]");
        panes.forEach(function (pane) {
          if (pane.dataset.value === value) {
            pane.removeAttribute("hidden");
          } else {
            pane.setAttribute("hidden", "");
          }
        });
        updateButtons(root, value);
        refreshToc();
      };

      var getQueryValue = function (root) {
        if (!root) return null;
        var id = root.dataset.contentSwitcherId;
        if (!id) return null;
        var params = new URLSearchParams(window.location.search);
        var value = params.get(id);
        if (!value) return null;
        var panes = root.querySelectorAll("[data-content-switcher-pane]");
        var hasMatch = false;
        panes.forEach(function (pane) {
          if (pane.dataset.value === value) {
            hasMatch = true;
          }
        });
        return hasMatch ? value : null;
      };

      var initRoot = function (root) {
        if (!root) return;
        var queryValue = getQueryValue(root);
        var initial = root.dataset.contentSwitcherInitial;
        var nextValue = queryValue || initial;
        if (nextValue) {
          setValue(root, nextValue);
        }
      };

      document
        .querySelectorAll("[data-content-switcher-root]")
        .forEach(initRoot);

      document.addEventListener("content-switcher:set", function (event) {
        var detail = event?.detail || {};
        var target = event.target;
        var root =
          target && target.closest
            ? target.closest("[data-content-switcher-root]")
            : null;
        if (!root && detail.id) {
          root = document.querySelector(
            '[data-content-switcher-root][data-content-switcher-id="' +
              detail.id +
              '"]'
          );
        }
        if (root && typeof detail.value === "string") {
          setValue(root, detail.value);
        }
      });

      window.addEventListener("popstate", function () {
        document
          .querySelectorAll("[data-content-switcher-root]")
          .forEach(initRoot);
      });

      document.addEventListener("click", function (event) {
        var target = event.target;
        if (!target || !target.closest) return;
        var button = target.closest("[data-content-switcher-option]");
        if (!button) return;
        var root = button.closest("[data-content-switcher-root]");
        if (!root) return;
        var value = button.dataset.value;
        if (value) {
          setValue(root, value);
        }
      });

      document.addEventListener("astro:page-load", function () {
        document
          .querySelectorAll("[data-content-switcher-root]")
          .forEach(initRoot);
      });
    }
  </script> </div>  </article>  </div> <div></div> </div> </div> <script>
    const copyHeadingLink = async (slug) => {
      const url = `${location.origin}${location.pathname}#${slug}`;
      if (navigator.clipboard && navigator.clipboard.writeText) {
        try {
          await navigator.clipboard.writeText(url);
          return;
        } catch (error) {
          console.warn("Copy to clipboard failed", error);
        }
      }

      window.prompt("Copy link", url);
    };

    document.addEventListener("click", (event) => {
      const target = event.target;
      if (!(target instanceof Element)) return;

      const button = target.closest("[data-anchor-id]");
      if (!button) return;

      const slug = button.getAttribute("data-anchor-id");
      if (!slug) return;

      event.preventDefault();
      copyHeadingLink(slug);
      const heading = document.getElementById(slug);
      if (heading) {
        heading.scrollIntoView({ behavior: "smooth", block: "start" });
      }
      history.replaceState(null, "", `#${slug}`);
    });
  </script>  <div class="mx-4 sm:mx-8 md:mx-auto md:w-full md:max-w-6xl px-4 md:px-12 xl:px-4"> <div class="grid grid-cols-1 gap-12 xl:grid-cols-[minmax(0,1fr)_200px]">  <div class="hidden xl:block"></div> </div> </div> </main> </div> </div> <script>(()=>{var e=async t=>{await(await t())()};(self.Astro||(self.Astro={})).only=e;window.dispatchEvent(new Event("astro:only"));})();</script><astro-island uid="DQ4jb" component-url="/_astro/Analytics.rv0FwEeX.js" component-export="default" renderer-url="/_astro/client.DjvmFpsL.js" props="{}" ssr client="only" opts="{&quot;name&quot;:&quot;VercelAnalyticsClient&quot;,&quot;value&quot;:&quot;solid-js&quot;}"></astro-island> <vercel-speed-insights data-props="{}" data-params="{&#34;slug&#34;:&#34;assistants/migration&#34;}" data-pathname="/api/docs/assistants/migration/"></vercel-speed-insights> <script type="module">var o="@vercel/speed-insights",u="1.3.1",f=()=>{window.si||(window.si=function(...r){(window.siq=window.siq||[]).push(r)})};function l(){return typeof window<"u"}function h(){try{const e="production"}catch{}return"production"}function d(){return h()==="development"}function v(e,r){if(!e||!r)return e;let n=e;try{const t=Object.entries(r);for(const[s,i]of t)if(!Array.isArray(i)){const a=c(i);a.test(n)&&(n=n.replace(a,`/[${s}]`))}for(const[s,i]of t)if(Array.isArray(i)){const a=c(i.join("/"));a.test(n)&&(n=n.replace(a,`/[...${s}]`))}return n}catch{return e}}function c(e){return new RegExp(`/${g(e)}(?=[/?#]|$)`)}function g(e){return e.replace(/[.*+?^${}()|[\]\\]/g,"\\$&")}function m(e){return e.scriptSrc?e.scriptSrc:d()?"https://va.vercel-scripts.com/v1/speed-insights/script.debug.js":e.dsn?"https://va.vercel-scripts.com/v1/speed-insights/script.js":e.basePath?`${e.basePath}/speed-insights/script.js`:"/_vercel/speed-insights/script.js"}function w(e={}){var r;if(!l()||e.route===null)return null;f();const n=m(e);if(document.head.querySelector(`script[src*="${n}"]`))return null;e.beforeSend&&((r=window.si)==null||r.call(window,"beforeSend",e.beforeSend));const t=document.createElement("script");return t.src=n,t.defer=!0,t.dataset.sdkn=o+(e.framework?`/${e.framework}`:""),t.dataset.sdkv=u,e.sampleRate&&(t.dataset.sampleRate=e.sampleRate.toString()),e.route&&(t.dataset.route=e.route),e.endpoint?t.dataset.endpoint=e.endpoint:e.basePath&&(t.dataset.endpoint=`${e.basePath}/speed-insights/vitals`),e.dsn&&(t.dataset.dsn=e.dsn),d()&&e.debug===!1&&(t.dataset.debug="false"),t.onerror=()=>{console.log(`[Vercel Speed Insights] Failed to load script from ${n}. Please check if any content blockers are enabled and try again.`)},document.head.appendChild(t),{setRoute:s=>{t.dataset.route=s??void 0}}}function p(){try{return}catch{}}customElements.define("vercel-speed-insights",class extends HTMLElement{constructor(){super();try{const r=JSON.parse(this.dataset.props??"{}"),n=JSON.parse(this.dataset.params??"{}"),t=v(this.dataset.pathname??"",n);w({route:t,...r,framework:"astro",basePath:p(),beforeSend:window.speedInsightsBeforeSend})}catch(r){throw new Error(`Failed to parse SpeedInsights properties: ${r}`)}}});</script> <div data-docs-agent-root data-chatkit-api-url="/api/docs-agent/chatkit" data-chatkit-domain-key="domain_pk_69f4ea0d87748194b9ad4d8ba39fc5710f6f8241026056cb" data-chatkit-greeting="What can I help you with?" data-chatkit-start-prompts-by-route="{&#34;home&#34;:[{&#34;label&#34;:&#34;Ask a question&#34;,&#34;prompt&#34;:&#34;What is the Docs MCP server?&#34;,&#34;icon&#34;:&#34;circle-question&#34;},{&#34;label&#34;:&#34;Find a page&#34;,&#34;prompt&#34;:&#34;Show me OpenAI models&#34;,&#34;icon&#34;:&#34;search&#34;},{&#34;label&#34;:&#34;Build a custom app&#34;,&#34;prompt&#34;:&#34;I want to build an interactive webapp that has a huge microphone in the center allowing to chat in Realtime&#34;,&#34;icon&#34;:&#34;square-code&#34;}],&#34;api&#34;:[{&#34;label&#34;:&#34;Ask a question&#34;,&#34;prompt&#34;:&#34;What are the recommended prompting best practices for building with the latest model?&#34;,&#34;icon&#34;:&#34;circle-question&#34;},{&#34;label&#34;:&#34;Find a page&#34;,&#34;prompt&#34;:&#34;show me a page to compare models&#34;,&#34;icon&#34;:&#34;search&#34;},{&#34;label&#34;:&#34;Build a custom app&#34;,&#34;prompt&#34;:&#34;I want to build a customer support app with realtime voice&#34;,&#34;icon&#34;:&#34;square-code&#34;}],&#34;codex&#34;:[{&#34;label&#34;:&#34;Ask a question&#34;,&#34;prompt&#34;:&#34;What is Codex app server?&#34;,&#34;icon&#34;:&#34;circle-question&#34;},{&#34;label&#34;:&#34;Find a page&#34;,&#34;prompt&#34;:&#34;Show me the Codex changelog&#34;,&#34;icon&#34;:&#34;search&#34;},{&#34;label&#34;:&#34;Build a custom app&#34;,&#34;prompt&#34;:&#34;I want to build an internal dashboard that gets updated with data from slack and spreadsheets and which allows to visualize weekly progress&#34;,&#34;icon&#34;:&#34;square-code&#34;}],&#34;chatgpt&#34;:[{&#34;label&#34;:&#34;Ask a question&#34;,&#34;prompt&#34;:&#34;What are best practices for building a ChatGPT app?&#34;,&#34;icon&#34;:&#34;circle-question&#34;},{&#34;label&#34;:&#34;Find a page&#34;,&#34;prompt&#34;:&#34;Show me UI guidelines for building ChatGPT apps&#34;,&#34;icon&#34;:&#34;search&#34;},{&#34;label&#34;:&#34;Build a custom app&#34;,&#34;prompt&#34;:&#34;Help me build an app in ChatGPT that proposes a quiz to users to find the best match from my list of products&#34;,&#34;icon&#34;:&#34;square-code&#34;}],&#34;resources&#34;:[{&#34;label&#34;:&#34;Ask a question&#34;,&#34;prompt&#34;:&#34;What is the Docs MCP server?&#34;,&#34;icon&#34;:&#34;circle-question&#34;},{&#34;label&#34;:&#34;Find a page&#34;,&#34;prompt&#34;:&#34;Show me the Codex meetups page&#34;,&#34;icon&#34;:&#34;search&#34;},{&#34;label&#34;:&#34;Build a custom app&#34;,&#34;prompt&#34;:&#34;I want to build an interactive webapp that has a huge microphone in the center allowing to chat in Realtime&#34;,&#34;icon&#34;:&#34;square-code&#34;}]}" data-astro-transition-persist="docs-agent-launcher" class="docs-agent-root"><button type="button" data-docs-agent-open aria-haspopup="dialog" aria-expanded="false" aria-controls="docs-agent-panel" class="fixed bottom-5 right-5 z-50 inline-flex h-11 items-center justify-center whitespace-nowrap rounded-full border border-transparent bg-primary-solid px-4 text-sm font-medium text-primary-solid shadow-[0_16px_48px_-18px_rgba(15,23,42,0.45)] transition-colors hover:bg-primary-solid-hover active:bg-primary-solid-active focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary-soft-active focus-visible:ring-offset-2 focus-visible:ring-offset-surface"><span>Ask AI</span></button><div id="docs-agent-panel" data-docs-agent-panel role="dialog" aria-labelledby="docs-agent-title" class="fixed inset-x-0 bottom-0 z-[80] flex h-[var(--docs-agent-drawer-height)] flex-col overflow-hidden rounded-t-2xl border border-subtle bg-surface transition-transform duration-300 ease-out md:inset-y-0 md:left-auto md:right-0 md:h-auto md:w-[var(--docs-agent-panel-width)] md:rounded-none md:border-y-0 md:border-r-0"><header class="flex h-16 shrink-0 items-center justify-between border-b border-subtle px-4"><h2 id="docs-agent-title" class="text-sm font-semibold text-default">
Docs agent
</h2><div class="flex items-center gap-1.5"><button type="button" data-docs-agent-new aria-label="Start a new docs agent thread" title="Start a new thread" class="inline-flex h-8 w-8 items-center justify-center rounded-md text-secondary transition-colors hover:bg-primary-soft-alpha hover:text-default"><svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" viewBox="0 0 24 24" class="h-4 w-4 " ><path fill-rule="evenodd" d="M16.793 2.793a3.121 3.121 0 1 1 4.414 4.414l-8.5 8.5A1 1 0 0 1 12 16H9a1 1 0 0 1-1-1v-3a1 1 0 0 1 .293-.707l8.5-8.5Zm3 1.414a1.121 1.121 0 0 0-1.586 0L10 12.414V14h1.586l8.207-8.207a1.121 1.121 0 0 0 0-1.586ZM6 5a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-4a1 1 0 1 1 2 0v4a3 3 0 0 1-3 3H6a3 3 0 0 1-3-3V6a3 3 0 0 1 3-3h4a1 1 0 1 1 0 2H6Z" clip-rule="evenodd"></path></svg></button><button type="button" data-docs-agent-close aria-label="Close docs agent" class="inline-flex h-8 w-8 items-center justify-center rounded-md text-secondary transition-colors hover:bg-primary-soft-alpha hover:text-default"><svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="h-4 w-4 " ><path d="M18 6 6 18"></path><path d="m6 6 12 12"></path></svg></button></div></header><div class="relative min-h-0 flex-1"><p data-docs-agent-status class="absolute inset-x-4 top-4 rounded-lg border border-subtle bg-surface-secondary p-3 text-sm text-secondary">
Loading docs agent...
</p><openai-chatkit id="docs-agent-chatkit" class="block h-full w-full"></openai-chatkit></div></div></div><script>(() => {
  const registry = window.customElements;
  if (!registry || window.__docsAgentChatKitMoveGuardInstalled) return;
  window.__docsAgentChatKitMoveGuardInstalled = true;

  // Astro preserves the launcher with Element.moveBefore(). Registering this
  // callback before ChatKit is defined prevents its reconnect hooks from
  // replacing the live message-bridge iframe during that move.
  const registryPrototype = Object.getPrototypeOf(registry);
  const defineDescriptor = Object.getOwnPropertyDescriptor(
    registryPrototype,
    "define"
  );
  if (!defineDescriptor?.value) return;

  Object.defineProperty(registryPrototype, "define", {
    ...defineDescriptor,
    value(name, constructor, options) {
      if (
        name === "openai-chatkit" &&
        !("connectedMoveCallback" in constructor.prototype)
      ) {
        Object.defineProperty(
          constructor.prototype,
          "connectedMoveCallback",
          {
            configurable: true,
            value() {},
          }
        );
      }

      const result = defineDescriptor.value.call(
        this,
        name,
        constructor,
        options
      );
      if (name === "openai-chatkit") {
        Object.defineProperty(registryPrototype, "define", defineDescriptor);
      }
      return result;
    },
  });
})();</script><script src="https://cdn.platform.openai.com/deployments/chatkit/chatkit.js" async></script><script type="module" src="/_astro/DocsAgentLauncher.astro_astro_type_script_index_0_lang.BMJQtiwO.js"></script><script>
  function initializeDocsAgentLauncher() {
    const root = document.querySelector("[data-docs-agent-root]");
    if (!root || root.dataset.initialized === "true") return;
    if (typeof window.__createDocsAgentNavigationQueue !== "function") return;

    const mobileOpenButton = root.querySelector("button[data-docs-agent-open]");
    const closeButton = root.querySelector("[data-docs-agent-close]");
    const newButton = root.querySelector("[data-docs-agent-new]");
    const panel = root.querySelector("[data-docs-agent-panel]");
    const status = root.querySelector("[data-docs-agent-status]");
    let chatkit = root.querySelector("openai-chatkit");
    const apiURL = root.dataset.chatkitApiUrl;
    const domainKey = root.dataset.chatkitDomainKey || "local-dev";
    const startGreeting =
      root.dataset.chatkitGreeting || "OpenAI developer docs";
    const startPromptsByParentRoute = (() => {
      try {
        const parsed = JSON.parse(
          root.dataset.chatkitStartPromptsByRoute || "{}"
        );
        return parsed && typeof parsed === "object" && !Array.isArray(parsed)
          ? parsed
          : {};
      } catch {
        return {};
      }
    })();
    const docsAgentSessionStorageKey = "docs-agent.chatkit-session-id";
    const uuidPattern =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

    const randomUuid = () => {
      if (window.crypto?.randomUUID) {
        return window.crypto.randomUUID();
      }

      const bytes = new Uint8Array(16);
      if (window.crypto?.getRandomValues) {
        window.crypto.getRandomValues(bytes);
      } else {
        for (let index = 0; index < bytes.length; index += 1) {
          bytes[index] = Math.floor(Math.random() * 256);
        }
      }
      bytes[6] = (bytes[6] & 0x0f) | 0x40;
      bytes[8] = (bytes[8] & 0x3f) | 0x80;

      const hex = Array.from(bytes, (byte) =>
        byte.toString(16).padStart(2, "0")
      );
      return [
        hex.slice(0, 4).join(""),
        hex.slice(4, 6).join(""),
        hex.slice(6, 8).join(""),
        hex.slice(8, 10).join(""),
        hex.slice(10, 16).join(""),
      ].join("-");
    };

    let docsAgentSessionIdValue = null;

    const storeDocsAgentSessionId = (sessionId) => {
      docsAgentSessionIdValue = sessionId;
      try {
        window.sessionStorage.setItem(docsAgentSessionStorageKey, sessionId);
      } catch {
        // Ignore storage failures.
      }
      return sessionId;
    };

    const resetDocsAgentSessionId = () =>
      storeDocsAgentSessionId(randomUuid().toLowerCase());

    const docsAgentSessionId = () => {
      if (
        docsAgentSessionIdValue &&
        uuidPattern.test(docsAgentSessionIdValue)
      ) {
        return docsAgentSessionIdValue.toLowerCase();
      }
      try {
        const stored = window.sessionStorage.getItem(
          docsAgentSessionStorageKey
        );
        if (stored && uuidPattern.test(stored)) {
          docsAgentSessionIdValue = stored.toLowerCase();
          return docsAgentSessionIdValue;
        }
      } catch {
        // Fall through and create an in-memory session id.
      }
      return resetDocsAgentSessionId();
    };

    if (
      !mobileOpenButton ||
      !closeButton ||
      !newButton ||
      !(panel instanceof HTMLElement) ||
      !chatkit ||
      !apiURL
    ) {
      return;
    }

    let chatkitInitialized = false;
    let chatkitResponseActive = false;
    let chatkitTurnActive = false;
    let docsAgentNavigationInProgress = false;
    let chatkitReplacement = null;
    let desiredPathname = window.location.pathname || "/";
    let previousFocus = null;
    let lastPageSelection = { text: "", capturedAt: 0 };
    let conversationStartedTracked = false;

    const selectedTextLimit = 3000;
    const staleSelectionMs = 2 * 60 * 1000;
    const docsAgentRequestTimeoutMs = 40 * 1000;
    const docsAgentNavigationTimeoutMs = 8 * 1000;
    const docsAgentTransitionWaitTimeoutMs = 15 * 1000;
    const docsAgentInitializationTimeoutMs = 15 * 1000;
    const docsAgentUnavailableMessage =
      "The docs agent couldn't complete the request. Please retry.";
    const chatKitUserTurnTypes = new Set([
      "threads.create",
      "threads.add_user_message",
      "threads.retry_after_item",
    ]);
    const desktopPanelMedia = window.matchMedia("(min-width: 768px)");

    const withTimeout = (operation, timeoutMs, message) =>
      new Promise((resolve, reject) => {
        const timeout = window.setTimeout(
          () => reject(new Error(message)),
          timeoutMs
        );
        Promise.resolve(operation).then(
          (value) => {
            window.clearTimeout(timeout);
            resolve(value);
          },
          (error) => {
            window.clearTimeout(timeout);
            reject(error);
          }
        );
      });

    const requestDeadlineSignal = (existingSignal) => {
      const controller = new AbortController();
      const abort = (signal) => controller.abort(signal?.reason);
      if (existingSignal) {
        if (existingSignal.aborted) {
          abort(existingSignal);
        } else {
          existingSignal.addEventListener(
            "abort",
            () => abort(existingSignal),
            {
              once: true,
            }
          );
        }
      }
      window.setTimeout(
        () => controller.abort(new Error("Docs agent request timed out")),
        docsAgentRequestTimeoutMs
      );
      return controller.signal;
    };

    const chatKitErrorFrame = (message = docsAgentUnavailableMessage) =>
      new TextEncoder().encode(
        `data: ${JSON.stringify({
          type: "error",
          code: "custom",
          message,
          allow_retry: true,
        })}\n\n`
      );

    const chatKitErrorResponse = (message = docsAgentUnavailableMessage) =>
      new Response(chatKitErrorFrame(message), {
        status: 200,
        headers: {
          "content-type": "text/event-stream; charset=utf-8",
          "cache-control": "no-cache",
        },
      });

    const chatKitFrameHasTerminalEvent = (frame) => {
      const data = frame
        .split("\n")
        .filter((line) => line.startsWith("data: "))
        .map((line) => line.slice("data: ".length))
        .join("\n");
      if (!data) return false;
      try {
        const payload = JSON.parse(data);
        if (payload?.type === "error") return true;
        return (
          payload?.type === "thread.item.done" &&
          payload?.item?.type === "assistant_message" &&
          Array.isArray(payload.item.content) &&
          payload.item.content.some(
            (part) =>
              typeof part?.text === "string" && Boolean(part.text.trim())
          )
        );
      } catch {
        return false;
      }
    };

    const observeChatKitTerminalEvents = (state, chunk, final = false) => {
      state.buffer += chunk
        ? state.decoder.decode(chunk, { stream: !final })
        : state.decoder.decode();
      state.buffer = state.buffer.replace(/\r\n/g, "\n");
      const frames = state.buffer.split("\n\n");
      const trailingFrame = frames.pop() || "";
      state.buffer = final ? "" : trailingFrame;
      for (const frame of frames) {
        if (chatKitFrameHasTerminalEvent(frame)) state.emitted = true;
      }
      if (
        final &&
        trailingFrame &&
        chatKitFrameHasTerminalEvent(trailingFrame)
      ) {
        state.emitted = true;
      }
    };

    const ensureUserTurnTerminalResponse = (response) => {
      if (!response.body) return chatKitErrorResponse();
      const reader = response.body.getReader();
      const state = {
        decoder: new TextDecoder(),
        buffer: "",
        emitted: false,
      };
      const body = new ReadableStream({
        async pull(controller) {
          try {
            const result = await reader.read();
            if (result.done) {
              observeChatKitTerminalEvents(state, null, true);
              if (!state.emitted) controller.enqueue(chatKitErrorFrame());
              controller.close();
              return;
            }
            observeChatKitTerminalEvents(state, result.value);
            controller.enqueue(result.value);
          } catch {
            if (!state.emitted) controller.enqueue(chatKitErrorFrame());
            controller.close();
          }
        },
        cancel(reason) {
          void reader.cancel(reason).catch(() => undefined);
        },
      });
      return new Response(body, {
        status: response.status,
        statusText: response.statusText,
        headers: response.headers,
      });
    };
    const syncOpenButtons = (expanded) => {
      document
        .querySelectorAll("button[data-docs-agent-open]")
        .forEach((button) => {
          button.setAttribute("aria-expanded", expanded);
        });
    };

    const syncLayoutTargets = () => {
      const isOpen = root.dataset.open === "true";
      const isDesktopPanel = desktopPanelMedia.matches;
      document.body.classList.toggle("docs-agent-open", isOpen);
      if (isOpen) {
        document.body.dataset.docsAgentOpen = "true";
      } else {
        delete document.body.dataset.docsAgentOpen;
      }
      syncOpenButtons(isOpen ? "true" : "false");
      document.querySelectorAll("[data-docs-agent-page]").forEach((page) => {
        if (page instanceof HTMLElement) {
          page.classList.toggle("is-docs-agent-open", isOpen);
          page.style.width =
            isOpen && isDesktopPanel
              ? "calc(100% - var(--docs-agent-panel-width))"
              : "";
          page.style.transform = isOpen
            ? isDesktopPanel
              ? "none"
              : "translateY(calc(-1 * var(--docs-agent-drawer-height)))"
            : "";
        }
      });

      const header = document.getElementById("header");
      header?.classList.toggle("is-docs-agent-open", isOpen);
      if (header) {
        const headerInner = header.firstElementChild;
        const headerNav = header.querySelector("nav");
        const headerSearchButton = header.querySelector(
          "[data-header-search-button]"
        );
        header.style.width =
          isOpen && isDesktopPanel
            ? "calc(100% - var(--docs-agent-panel-width))"
            : "";
        if (headerInner instanceof HTMLElement) {
          headerInner.style.gridTemplateColumns =
            isOpen && isDesktopPanel ? "auto minmax(0, 1fr) auto" : "";
        }
        if (headerNav instanceof HTMLElement) {
          headerNav.style.minWidth = isOpen && isDesktopPanel ? "0" : "";
          headerNav.style.overflow = "";
        }
        if (headerSearchButton instanceof HTMLElement) {
          headerSearchButton.style.display =
            isOpen && isDesktopPanel ? "none" : "";
        }
      }

      panel.classList.toggle("is-open", isOpen);
      panel.style.transform = isOpen
        ? isDesktopPanel
          ? "translateX(0)"
          : "translateY(0)"
        : "";
    };

    const normalizeAnalyticsText = (value) =>
      typeof value === "string" ? value.replace(/\s+/g, " ").trim() : "";

    const analyticsSlug = (value, fallback) => {
      const slug = normalizeAnalyticsText(value)
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "_")
        .replace(/^_+|_+$/g, "");
      return slug || fallback;
    };

    const normalizePathname = (pathname) => {
      if (!pathname || pathname === "/") return "/";
      return pathname.replace(/\/+$/, "") || "/";
    };

    const docsAgentParentRoute = (pathname) => {
      const normalized = normalizePathname(pathname);

      if (normalized === "/") return "home";
      if (normalized === "/api" || normalized.startsWith("/api/")) {
        return "api";
      }
      if (normalized === "/codex" || normalized.startsWith("/codex/")) {
        return "codex";
      }
      if (
        normalized === "/chatgpt" ||
        normalized.startsWith("/chatgpt/") ||
        normalized === "/apps-sdk" ||
        normalized.startsWith("/apps-sdk/") ||
        normalized === "/commerce" ||
        normalized.startsWith("/commerce/")
      ) {
        return "chatgpt";
      }
      if (
        normalized === "/learn" ||
        normalized.startsWith("/learn/") ||
        normalized === "/community" ||
        normalized.startsWith("/community/") ||
        normalized === "/cookbook" ||
        normalized.startsWith("/cookbook/") ||
        normalized === "/showcase" ||
        normalized.startsWith("/showcase/") ||
        normalized === "/tracks" ||
        normalized.startsWith("/tracks/") ||
        normalized === "/blog" ||
        normalized.startsWith("/blog/")
      ) {
        return "resources";
      }

      return "home";
    };

    const startPromptsForRoute = (
      pathname = window.location.pathname || "/"
    ) => {
      const parentRoute = docsAgentParentRoute(pathname);
      const prompts = startPromptsByParentRoute[parentRoute];

      if (Array.isArray(prompts)) return prompts;
      return Array.isArray(startPromptsByParentRoute.home)
        ? startPromptsByParentRoute.home
        : [];
    };

    const startPromptAnalyticsForRoute = (pathname) =>
      startPromptsForRoute(pathname)
        .map((prompt, index) => {
          const promptText = normalizeAnalyticsText(prompt?.prompt);
          if (!promptText) return null;
          return {
            id: analyticsSlug(prompt?.label, `prompt_${index + 1}`),
            label:
              normalizeAnalyticsText(prompt?.label) || `Prompt ${index + 1}`,
            position: index + 1,
            text: promptText,
          };
        })
        .filter(Boolean);

    const normalizeSelectedText = (value) =>
      value.replace(/\r\n?/g, "\n").trim().slice(0, selectedTextLimit);

    const nodeIsInDocsAgent = (node) => {
      if (!node) return false;
      const element =
        node.nodeType === Node.ELEMENT_NODE ? node : node.parentElement;
      return element instanceof Element && root.contains(element);
    };

    const currentPageSelectionText = () => {
      const selection = window.getSelection?.();
      if (!selection || selection.isCollapsed) return "";
      if (
        nodeIsInDocsAgent(selection.anchorNode) ||
        nodeIsInDocsAgent(selection.focusNode)
      ) {
        return "";
      }

      return normalizeSelectedText(selection.toString());
    };

    const rememberPageSelection = () => {
      const text = currentPageSelectionText();
      if (!text) return;
      lastPageSelection = {
        text,
        capturedAt: Date.now(),
      };
    };

    const selectedTextForAgentContext = () => {
      const text = currentPageSelectionText();
      if (text) {
        lastPageSelection = {
          text,
          capturedAt: Date.now(),
        };
        return text;
      }

      if (Date.now() - lastPageSelection.capturedAt <= staleSelectionMs) {
        return lastPageSelection.text;
      }
      return "";
    };

    const docsAgentPageContext = () => {
      const context = {
        route: window.location.pathname || "/",
      };
      const selectedText = selectedTextForAgentContext();
      if (selectedText) {
        context.selectedText = selectedText;
      }
      return context;
    };

    const hasPageSelectionForAnalytics = () => {
      if (currentPageSelectionText()) return true;
      return Date.now() - lastPageSelection.capturedAt <= staleSelectionMs
        ? Boolean(lastPageSelection.text)
        : false;
    };

    const chatKitRequestInputText = (body) => {
      const content = body?.params?.input?.content;
      if (!Array.isArray(content)) return "";

      return content
        .map((part) =>
          part?.type === "input_text" && typeof part.text === "string"
            ? part.text
            : ""
        )
        .filter(Boolean)
        .join("\n")
        .trim();
    };

    const defaultPromptMatch = (body) => {
      const text = normalizeAnalyticsText(chatKitRequestInputText(body));
      if (!text) return null;

      const startPromptByText = new Map(
        startPromptAnalyticsForRoute(window.location.pathname || "/").map(
          (prompt) => [prompt.text, prompt]
        )
      );
      return startPromptByText.get(text) || null;
    };

    const promptAnalyticsData = (prompt) =>
      prompt
        ? {
            prompt_id: prompt.id,
            prompt_label: prompt.label,
            prompt_position: prompt.position,
          }
        : {};

    const isDocsAgentApiRequest = (input) => {
      try {
        const requestUrl =
          typeof input === "string" || input instanceof URL
            ? new URL(input, window.location.href)
            : new URL(input.url);
        const configuredUrl = new URL(apiURL, window.location.href);
        return requestUrl.href === configuredUrl.href;
      } catch {
        return false;
      }
    };

    const docsAgentFetch = async (input, init) => {
      if (!isDocsAgentApiRequest(input)) {
        return window.fetch(input, init);
      }

      const nextInit = init ? { ...init } : {};
      if (typeof nextInit.body === "string") {
        try {
          const body = JSON.parse(nextInit.body);
          if (body && typeof body === "object" && !Array.isArray(body)) {
            if (body.type === "threads.create" && !conversationStartedTracked) {
              const prompt = defaultPromptMatch(body);
              const promptData = promptAnalyticsData(prompt);
              conversationStartedTracked = true;
              trackDocsAgentEvent("docs_agent_conversation_started", {
                entry_point: prompt ? "default_prompt" : "composer",
                request_type: body.type,
                has_page_selection: hasPageSelectionForAnalytics(),
                ...promptData,
              });
              if (prompt) {
                trackDocsAgentEvent("docs_agent_default_prompt_selected", {
                  request_type: body.type,
                  ...promptData,
                });
              }
            }

            const metadata =
              body.metadata &&
              typeof body.metadata === "object" &&
              !Array.isArray(body.metadata)
                ? body.metadata
                : {};
            body.metadata = {
              ...metadata,
              pageContext: docsAgentPageContext(),
            };
            nextInit.body = JSON.stringify(body);
          }
        } catch {
          // Preserve the original body if it is not JSON.
        }
      }

      const headers = new Headers(
        nextInit.headers ||
          (input instanceof Request ? input.headers : undefined)
      );
      headers.set("x-docs-agent-user", docsAgentSessionId());
      nextInit.headers = headers;
      nextInit.signal = requestDeadlineSignal(
        nextInit.signal || (input instanceof Request ? input.signal : null)
      );

      let requestType = "";
      if (typeof nextInit.body === "string") {
        try {
          requestType = JSON.parse(nextInit.body)?.type || "";
        } catch {
          // The proxy will return the protocol validation error.
        }
      }
      const requireTerminalEvent = chatKitUserTurnTypes.has(requestType);
      if (requireTerminalEvent) {
        chatkitTurnActive = true;
      }

      try {
        const response = await window.fetch(input, nextInit);
        return requireTerminalEvent
          ? ensureUserTurnTerminalResponse(response)
          : response;
      } catch (error) {
        if (requireTerminalEvent) return chatKitErrorResponse();
        throw error;
      }
    };

    const clearLegacyStoredState = () => {
      try {
        window.localStorage.removeItem("docs-agent.panel-open");
        window.localStorage.removeItem("docs-agent.thread-id");
        window.localStorage.removeItem("docs-agent.user-id");
      } catch {
        // Ignore storage failures.
      }
    };

    const showStatus = (message) => {
      if (!status) return;
      status.textContent = message;
      status.hidden = false;
    };

    const hideStatus = () => {
      if (status) status.hidden = true;
    };

    const getColorTheme = () => {
      const html = document.documentElement;
      return html.dataset.theme === "dark" || html.classList.contains("dark")
        ? "dark"
        : "light";
    };

    const normalizeClientToolArgs = (args) => {
      if (!args) return {};
      if (typeof args === "string") {
        try {
          return JSON.parse(args);
        } catch {
          return {};
        }
      }
      return args;
    };

    const analyticsViewport = () =>
      window.matchMedia("(min-width: 768px)").matches ? "desktop" : "mobile";

    const trackDocsAgentEvent = (name, data = {}) => {
      try {
        window.__docsAgentTrackEvent?.(name, {
          surface: "docs_agent",
          route: window.location.pathname || "/",
          viewport: analyticsViewport(),
          ...data,
        });
      } catch {
        // Ignore analytics failures.
      }
    };

    const navigationTarget = (href) => {
      if (typeof href !== "string" || !href.trim()) {
        return { ok: false, error: "Missing href." };
      }

      let url;
      try {
        url = new URL(href, window.location.origin);
      } catch {
        return { ok: false, error: "Invalid href." };
      }
      const originalHost = url.host;
      const allowedHosts = new Set([
        window.location.host,
        "developers.openai.com",
      ]);

      if (!allowedHosts.has(originalHost)) {
        return { ok: false, error: "Navigation host is not allowed." };
      }

      return {
        ok: true,
        href:
          originalHost === window.location.host ||
          originalHost === "developers.openai.com"
            ? `${url.pathname}${url.search}${url.hash}`
            : url.toString(),
      };
    };

    const navigateToHref = async (href) => {
      const target = navigationTarget(href);
      if (!target.ok) return target;
      const routeHref = target.href;

      if (
        routeHref.startsWith("/") &&
        typeof window.__docsAgentNavigate === "function"
      ) {
        docsAgentNavigationInProgress = true;
        try {
          await withTimeout(
            window.__docsAgentNavigate(routeHref, { history: "push" }),
            docsAgentNavigationTimeoutMs,
            "Docs agent navigation timed out"
          );
        } catch (error) {
          console.error("Docs agent navigation failed", error);
          return { ok: false, error: "Navigation failed or timed out." };
        } finally {
          docsAgentNavigationInProgress = false;
        }
      } else {
        window.location.assign(routeHref);
      }

      return { ok: true, href: routeHref };
    };

    const navigationQueue =
      window.__createDocsAgentNavigationQueue(navigateToHref);

    const queueNavigationToHref = (href) => {
      const target = navigationTarget(href);
      if (!target.ok) return target;
      navigationQueue.queue(target.href);
      return target;
    };

    const chatKitTurnSettledCallbacks = new Set();

    const chatKitTurnIsActive = () =>
      chatkitResponseActive ||
      chatkitTurnActive ||
      navigationQueue.hasPending();

    const notifyChatKitTurnSettled = () => {
      if (chatKitTurnIsActive()) return;
      for (const callback of chatKitTurnSettledCallbacks) {
        callback();
      }
      chatKitTurnSettledCallbacks.clear();
    };

    const waitForChatKitTurnToSettle = (signal) => {
      if (signal.aborted) return Promise.resolve("aborted");
      if (!chatKitTurnIsActive()) return Promise.resolve("settled");

      return new Promise((resolve) => {
        let timeout;
        const finish = (result) => {
          window.clearTimeout(timeout);
          signal.removeEventListener("abort", onAbort);
          chatKitTurnSettledCallbacks.delete(onSettled);
          resolve(result);
        };
        const onAbort = () => finish("aborted");
        const onSettled = () => finish("settled");

        signal.addEventListener("abort", onAbort, { once: true });
        chatKitTurnSettledCallbacks.add(onSettled);
        timeout = window.setTimeout(
          () => finish("timed-out"),
          docsAgentTransitionWaitTimeoutMs
        );
      });
    };

    const deferPageTransitionDuringChatKitTurn = (event) => {
      if (docsAgentNavigationInProgress || !chatKitTurnIsActive()) return;
      const loadPage = event.loader;
      event.loader = async () => {
        const result = await waitForChatKitTurnToSettle(event.signal);
        if (result === "aborted" || event.signal.aborted) return;
        if (result === "timed-out") {
          // Asking Astro to cancel here makes it fall back to a full load. That
          // is safer than moving a ChatKit frame whose turn did not terminate.
          event.preventDefault();
          return;
        }
        await loadPage();
      };
    };

    const bindChatKitLifecycle = () => {
      if (chatkit.dataset.docsAgentLifecycleBound === "true") return;
      chatkit.dataset.docsAgentLifecycleBound = "true";
      chatkit.addEventListener("chatkit.thread.change", (event) => {
        const threadId = event?.detail?.threadId;
        if (threadId === null) {
          conversationStartedTracked = false;
        }
      });
      chatkit.addEventListener("chatkit.response.start", () => {
        chatkitResponseActive = true;
        navigationQueue.onResponseStart();
      });
      chatkit.addEventListener("chatkit.response.end", () => {
        chatkitResponseActive = false;
        void navigationQueue
          .onResponseEnd()
          .then(() => {
            if (!navigationQueue.hasPending()) {
              chatkitTurnActive = false;
              notifyChatKitTurnSettled();
            }
          })
          .catch((error) => {
            console.error("Docs agent navigation failed", error);
          });
      });
      chatkit.addEventListener("chatkit.error", () => {
        chatkitResponseActive = false;
        chatkitTurnActive = false;
        navigationQueue.clear();
        notifyChatKitTurnSettled();
      });
    };

    const buildChatKitOptions = () => ({
      api: {
        url: apiURL,
        domainKey,
        fetch: docsAgentFetch,
      },
      theme: {
        colorScheme: getColorTheme(),
      },
      header: { enabled: false },
      onClientTool(toolCall) {
        const args = normalizeClientToolArgs(
          toolCall?.params || toolCall?.arguments
        );

        if (toolCall?.name === "navigate_to_page") {
          return queueNavigationToHref(args.href);
        }

        if (toolCall?.name === "open_custom_guide") {
          const guideHref =
            args.href ||
            (args.generated_id ? `/custom-guide/${args.generated_id}` : "");
          trackDocsAgentEvent("docs_agent_custom_guide_opened", {
            source: "client_tool",
            guide_id: args.generated_id || "",
            href: guideHref,
          });
          return queueNavigationToHref(guideHref);
        }

        return {
          ok: false,
          error: `Unknown client tool: ${toolCall?.name || "unknown"}.`,
        };
      },
      widgets: {
        onAction(action) {
          const payload = normalizeClientToolArgs(action?.payload);

          if (action?.type === "custom_guide.view") {
            const guideHref =
              payload.href ||
              payload.url ||
              (payload.generated_id
                ? `/custom-guide/${payload.generated_id}`
                : "");
            trackDocsAgentEvent("docs_agent_custom_guide_opened", {
              source: "widget_action",
              guide_id: payload.generated_id || "",
              href: guideHref,
            });

            return navigateToHref(guideHref);
          }

          if (action?.type === "docs_agent.navigate") {
            const href = payload.href || payload.url || "";
            trackDocsAgentEvent("docs_agent_suggested_page_opened", {
              source: "widget_action",
              href,
              suggestion_title: payload.title || "",
              suggestion_type: payload.type || "",
            });

            return navigateToHref(href);
          }

          return {
            ok: false,
            error: `Unknown widget action: ${action?.type || "unknown"}.`,
          };
        },
      },
      composer: {
        placeholder: "Ask about docs or what you want to build",
      },
      startScreen: {
        greeting: startGreeting,
        prompts: startPromptsForRoute(desiredPathname),
      },
    });

    const applyChatKitOptions = () => {
      chatkit.setOptions(buildChatKitOptions());
    };

    // Existing ChatKit instances keep the options they were created with.
    // Route changes only select the prompts for the next explicit new thread.
    const syncDesiredPathnameForPageLoad = () => {
      desiredPathname = window.location.pathname || "/";
    };

    const syncDesiredPathnameBeforeSwap = (event) => {
      const destination = event?.to;
      if (destination instanceof URL) {
        desiredPathname = destination.pathname || "/";
      } else if (typeof destination === "string") {
        desiredPathname = new URL(destination, window.location.href).pathname;
      }
    };

    const initializeChatKit = async () => {
      if (chatkitInitialized) return;
      showStatus("Loading docs agent...");

      try {
        await withTimeout(
          customElements.whenDefined("openai-chatkit"),
          docsAgentInitializationTimeoutMs,
          "Docs agent initialization timed out"
        );

        bindChatKitLifecycle();
        applyChatKitOptions();
        chatkitInitialized = true;
        hideStatus();
      } catch (error) {
        console.error("Failed to initialize Docs Agent ChatKit", error);
        showStatus("Docs agent is unavailable.");
      }
    };

    const resetChatKit = () => {
      if (chatkitReplacement) return chatkitReplacement;
      navigationQueue.clear();

      chatkitReplacement = (async () => {
        const nextChatKit = document.createElement("openai-chatkit");
        nextChatKit.id = "docs-agent-chatkit";
        nextChatKit.className = "block h-full w-full";
        chatkit.replaceWith(nextChatKit);
        chatkit = nextChatKit;
        chatkitInitialized = false;
        chatkitResponseActive = false;
        chatkitTurnActive = false;
        conversationStartedTracked = false;
        resetDocsAgentSessionId();
        await initializeChatKit();
        notifyChatKitTurnSettled();
      })();

      void chatkitReplacement.then(
        () => {
          chatkitReplacement = null;
        },
        () => {
          chatkitReplacement = null;
        }
      );
      return chatkitReplacement;
    };

    const openPanel = () => {
      if (root.dataset.open !== "true") {
        trackDocsAgentEvent("docs_agent_panel_opened", {
          source: "ask_button",
          has_page_selection: hasPageSelectionForAnalytics(),
        });
      }
      previousFocus = document.activeElement;
      document.body.dataset.docsAgentOpen = "true";
      document.body.classList.add("docs-agent-open");
      root.dataset.open = "true";
      root.classList.add("is-open");
      syncLayoutTargets();
      initializeChatKit();
      requestAnimationFrame(() => closeButton.focus());
    };

    const closePanel = () => {
      delete document.body.dataset.docsAgentOpen;
      document.body.classList.remove("docs-agent-open");
      delete root.dataset.open;
      root.classList.remove("is-open");
      syncLayoutTargets();
      if (previousFocus instanceof HTMLElement) {
        previousFocus.focus();
      }
    };

    clearLegacyStoredState();
    desktopPanelMedia.addEventListener("change", syncLayoutTargets);
    document.addEventListener("selectionchange", rememberPageSelection);
    document.addEventListener(
      "astro:before-preparation",
      deferPageTransitionDuringChatKitTurn
    );
    document.addEventListener(
      "astro:before-swap",
      syncDesiredPathnameBeforeSwap
    );
    document.addEventListener("astro:page-load", syncLayoutTargets);
    document.addEventListener(
      "astro:page-load",
      syncDesiredPathnameForPageLoad
    );
    document.addEventListener("pointerdown", (event) => {
      if (
        event.target instanceof Element &&
        event.target.closest("button[data-docs-agent-open]")
      ) {
        rememberPageSelection();
      }
    });
    document.addEventListener("click", (event) => {
      if (
        event.target instanceof Element &&
        event.target.closest("button[data-docs-agent-open]")
      ) {
        openPanel();
      }
    });
    newButton.addEventListener("click", resetChatKit);
    closeButton.addEventListener("click", closePanel);
    window.addEventListener("docs-agent:close", closePanel);
    panel.addEventListener("keydown", (event) => {
      if (event.key === "Escape") {
        closePanel();
      }
    });

    root.dataset.initialized = "true";
    syncLayoutTargets();
  }

  document.addEventListener("astro:page-load", initializeDocsAgentLauncher);
  window.addEventListener(
    "docs-agent:helpers-ready",
    initializeDocsAgentLauncher
  );
  initializeDocsAgentLauncher();
</script> <script type="module" src="/_astro/PageLayout.astro_astro_type_script_index_0_lang.DQ_saz_7.js"></script> </body> </html>

