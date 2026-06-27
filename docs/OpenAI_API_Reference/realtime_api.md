Title: Live Content

Description: Fetched live

Source: https://platform.openai.com/docs/guides/realtime

---

<!DOCTYPE html><html lang="en"> <head><!-- Global Metadata --><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="icon" type="image/png" href="/favicon.png"><meta name="generator" content="Astro v6.0.4"><link rel="preload" href="/fonts/OpenAISans-Regular.woff" as="font" type="font/woff" crossorigin><link rel="preload" href="/fonts/OpenAISans-Bold.woff" as="font" type="font/woff" crossorigin><style>
  @layer theme, base, components, utilities;
</style><!-- Canonical URL --><link rel="canonical" href="https://developers.openai.com/api/docs/guides/realtime"><!-- Primary Meta Tags --><title>Realtime and audio | OpenAI API</title><meta name="title" content="Realtime and audio | OpenAI API"><meta name="description" content="Learn which realtime and audio guide to use for each speech application."><!-- Open Graph / Facebook --><meta property="og:type" content="website"><meta property="og:url" content="https://developers.openai.com/api/docs/guides/realtime"><meta property="og:title" content="Realtime and audio | OpenAI API"><meta property="og:description" content="Learn which realtime and audio guide to use for each speech application."><meta property="og:image" content="https://developers.openai.com/og/api/docs/guides/realtime.png"><!-- Twitter --><meta name="twitter:card" content="summary_large_image"><meta name="twitter:site" content="@OpenAIDevs"><meta name="twitter:url" content="https://developers.openai.com/api/docs/guides/realtime"><meta name="twitter:title" content="Realtime and audio | OpenAI API"><meta name="twitter:description" content="Learn which realtime and audio guide to use for each speech application."><meta name="twitter:image" content="https://developers.openai.com/og/api/docs/guides/realtime.png"><meta name="twitter:image:alt" content="Realtime and audio | OpenAI API"><!-- Sitemap --><link rel="sitemap" href="/sitemap-index.xml"><!-- RSS Feed --><link rel="alternate" type="application/rss+xml" title="Realtime and audio | OpenAI API" href="https://developers.openai.com/rss.xml"><!-- Global Scripts --><script src="/js/theme.js"></script><script src="/js/scroll.js"></script><script src="/js/animate.js"></script><script defer src="/js/copy.js"></script><meta name="astro-view-transitions-enabled" content="true"><meta name="astro-view-transitions-fallback" content="swap"><script type="module" src="/_astro/ClientRouter.astro_astro_type_script_index_0_lang.BHh7hlg8.js"></script><link rel="stylesheet" href="/_astro/platform-docs.C8tKlvDz.css">
<link rel="stylesheet" href="/_astro/PageLayout.D4qwu_TR.css">
<style>.prompt-scroll:where(.astro-blfj6jyd){--prompt-scroll-gutter-x: 14px;--prompt-scroll-gutter-y: 16px;padding:0 calc(4.5rem + var(--prompt-scroll-gutter-x)) 0 1.5rem;scrollbar-gutter:stable;scrollbar-width:thin;scrollbar-color:rgb(15 23 42 / 28%) transparent}.prompt-scroll--header-actions:where(.astro-blfj6jyd){padding-right:1.5rem}.prompt-scroll-frame:where(.astro-blfj6jyd){position:relative;background:inherit}.prompt-scroll__content:where(.astro-blfj6jyd){margin-right:calc(-1 * var(--prompt-scroll-gutter-x))}.prompt-scroll--header-actions:where(.astro-blfj6jyd) .prompt-scroll__content:where(.astro-blfj6jyd){margin-right:0}.prompt-scroll-frame:where(.astro-blfj6jyd):before,.prompt-scroll-frame:where(.astro-blfj6jyd):after{content:"";position:absolute;right:0;width:calc(1.5rem + var(--prompt-scroll-gutter-x) + 8px);height:var(--prompt-scroll-gutter-y);background:inherit;pointer-events:none;z-index:1}.prompt-scroll-frame:where(.astro-blfj6jyd):before{top:0}.prompt-scroll-frame:where(.astro-blfj6jyd):after{bottom:0}.prompt-actions:where(.astro-blfj6jyd){z-index:2}.prompt-scroll:where(.astro-blfj6jyd)::-webkit-scrollbar{width:8px;height:8px}.prompt-scroll:where(.astro-blfj6jyd)::-webkit-scrollbar-track{background:transparent;margin-block:var(--prompt-scroll-gutter-y)}.prompt-scroll:where(.astro-blfj6jyd)::-webkit-scrollbar-thumb{background-color:#0f172a47;border:2px solid transparent;border-radius:9999px;background-clip:padding-box}html.dark .prompt-scroll:where(.astro-blfj6jyd),[data-theme=dark] .prompt-scroll:where(.astro-blfj6jyd){scrollbar-color:rgb(255 255 255 / 28%) transparent}html.dark .prompt-scroll:where(.astro-blfj6jyd)::-webkit-scrollbar-thumb,[data-theme=dark] .prompt-scroll:where(.astro-blfj6jyd)::-webkit-scrollbar-thumb{background-color:#ffffff47}
.page-copy-action:where(.astro-y3m22efp){display:inline-flex;min-height:26px;align-items:center;justify-content:center;gap:6px;border:1px solid var(--border-primary-outline, rgb(209 213 219));border-radius:8px;background:var(--surface-primary, #fff);padding:5px 10px;color:var(--text-primary, #202123);font-size:12px;font-weight:500;line-height:1;white-space:nowrap;transition:border-color .12s ease,background-color .12s ease,color .12s ease,opacity .12s ease}.page-copy-action:where(.astro-y3m22efp):hover:not(:disabled){background:var(--surface-primary-hover, #f7f7f8)}.page-copy-action:where(.astro-y3m22efp):focus-visible{outline:2px solid var(--border-primary, #111);outline-offset:2px}.page-copy-action:where(.astro-y3m22efp):disabled{cursor:progress;opacity:.7}.page-copy-action--cta:where(.astro-y3m22efp){min-height:42px;gap:8px;border-radius:9999px;padding:10px 18px;font-size:14px}.page-copy-action__icon:where(.astro-y3m22efp){display:inline-flex;width:14px;height:14px;align-items:center;justify-content:center}.page-copy-action__icon:where(.astro-y3m22efp) svg{width:14px;height:14px}.page-copy-action__icon--check:where(.astro-y3m22efp),.page-copy-action:where(.astro-y3m22efp)[data-copied=true] .page-copy-action__icon--copy:where(.astro-y3m22efp){display:none}.page-copy-action:where(.astro-y3m22efp)[data-copied=true] .page-copy-action__icon--check:where(.astro-y3m22efp){display:inline-flex}
@layer components{._Arrow_t2o77_1{--arrow-size: 6px;position:absolute;width:0;height:0}._Arrow_t2o77_1[data-side=top]{bottom:0;left:50%;border-top:var(--arrow-size) solid var(--gray-700);border-right:var(--arrow-size) solid transparent;border-left:var(--arrow-size) solid transparent;margin-right:-8px;transform:translate(-50%) translateY(100%)}._Arrow_t2o77_1[data-side=bottom]{top:0;left:50%;border-right:var(--arrow-size) solid transparent;border-bottom:var(--arrow-size) solid var(--gray-700);border-left:var(--arrow-size) solid transparent;margin-left:-8px;transform:translate(-50%) translateY(-100%)}._Arrow_t2o77_1[data-side=left]{top:50%;right:0;border-top:var(--arrow-size) solid transparent;border-bottom:var(--arrow-size) solid transparent;border-left:var(--arrow-size) solid var(--gray-700);margin-right:-8px;transform:translate(100%) translateY(-50%)}._Arrow_t2o77_1[data-side=right]{top:50%;left:0;border-top:var(--arrow-size) solid transparent;border-right:var(--arrow-size) solid var(--gray-700);border-bottom:var(--arrow-size) solid transparent;margin-left:-8px;transform:translate(-100%) translateY(-50%)}}
@layer components.base{._root_1x2h7_2{position:relative;display:flex;flex-direction:column;margin:20px 0;border:.5px solid var(--color-border-primary-surface);border-radius:8px;background:var(--code-snippet-bg)}._root_1x2h7_2+._root_1x2h7_2{margin-top:1em}._flush_1x2h7_16{width:100%;border:0;background:transparent;background-color:transparent;color:var(--color-text-emphasis);line-height:20px}._flush_1x2h7_16 code>code{padding-right:20px!important}._flush_1x2h7_16 .syntax-highlighter{background:transparent;font-size:13px;letter-spacing:var(--font-tracking-wide)}._flush_1x2h7_16 ._header_1x2h7_34{position:relative;z-index:1;justify-content:space-between;padding-left:8px;border-bottom:none;background:transparent}._flush_1x2h7_16 ._header_1x2h7_34 ._title_1x2h7_42{display:none}._flush_1x2h7_16 ._header_1x2h7_34 .code-sample-select-val{font-size:12px;letter-spacing:var(--font-tracking-wide)}._flush_1x2h7_16 ._header_1x2h7_34 .code-sample-select-wrap{margin-bottom:4px;margin-left:12px;font-size:12px;letter-spacing:var(--font-tracking-wide)}._flush_1x2h7_16 ._body_1x2h7_59{background:transparent}._flush_1x2h7_16 ._body_1x2h7_59 ._pre_1x2h7_62{padding-top:0}._root_1x2h7_2 .python-upgrade-banner{display:flex;padding:2px;background:var(--card-gradient);color:#fff;font-size:.8em;font-weight:var(--font-weight-bold);text-align:center}._root_1x2h7_2 .python-upgrade-banner svg{margin-top:6px;margin-right:8px;margin-left:8px}._root_1x2h7_2 .python-upgrade-banner path{stroke:#fff}._header_1x2h7_34{overflow:auto;display:flex;align-items:center;gap:4px;flex-shrink:0;padding:4px 8px 4px 14px;border-bottom:.5px solid var(--color-border-primary-surface);border-top-left-radius:8px;border-top-right-radius:8px}._title_1x2h7_42{overflow:hidden;flex:1 1 auto;margin-right:12px;color:var(--color-text);font-family:var(--monospace);font-size:12px;font-weight:var(--font-weight-normal);letter-spacing:var(--font-tracking-wide);text-overflow:ellipsis;white-space:nowrap}._sep_1x2h7_113{flex:0 0 auto;min-width:1px;height:22px;padding-left:8px;border-left:1px solid var(--color-background-primary-soft);margin-left:8px}._body_1x2h7_59{position:relative;flex-grow:1;flex-shrink:0}._body_1x2h7_59 ._pre_1x2h7_62{height:100%;min-height:44px;padding:12px 16px;border-radius:8px;margin:0;font-size:14px;line-height:20px;white-space:pre;background:var(--code-snippet-bg)}._body_1x2h7_59._bodyWithHeader_1x2h7_139 ._pre_1x2h7_62{border-top-left-radius:0;border-top-right-radius:0}._bodyWithCopyFloat_1x2h7_145 ._pre_1x2h7_62{padding-right:56px}._copyFloat_1x2h7_157{position:absolute;top:6px;right:6px}._oneliner_1x2h7_162 ._copyFloat_1x2h7_157{top:50%;transform:translateY(-50%)}._copyButton_1x2h7_168{height:1.75rem;padding:0 .5rem;border-radius:.375rem}}
</style>
<link rel="stylesheet" href="/_astro/index.avIh2ZpK.css">
<style>@layer base{.syntax-highlighter{background:transparent;color:var(--color-text);overflow-x:auto}.syntax-highlighter>code{border:none;box-shadow:none;font-family:var(--monospace)}.syntax-highlighter>code>code{padding-right:16px;border:none;box-shadow:none;float:left;font-family:var(--monospace);line-height:20px}.syntax-highlighter .react-syntax-highlighter-line-number{color:var(--color-text-disabled);line-height:20px;opacity:.5;text-align:right;-webkit-user-select:none;-moz-user-select:none;user-select:none}.syntax-highlighter [data-highlighted-row=true]{display:block;width:150%;margin-left:-25%;background-color:var(--pill-success-bg)}.syntax-highlighter [data-highlighted-row-subtle=true]{background-color:rgba(var(--sh-fg),.08)}.hljs-comment{color:rgba(var(--sh-fg),.5)}.hljs-meta{color:rgba(var(--sh-fg),.6)}.hljs-built_in,.hljs-class .hljs-title{color:var(--syntax1)}.hljs-doctag,.hljs-keyword,.hljs-formula,.hljs-literal{color:var(--syntax2)}.hljs-string,.hljs-regexp,.hljs-addition,.hljs-attribute,.hljs-meta-string{color:var(--syntax3)}.hljs-attr,.hljs-variable,.hljs-template-variable,.hljs-type,.hljs-selector-class,.hljs-selector-attr,.hljs-selector-pseudo,.hljs-number{color:var(--syntax4)}.hljs-symbol,.hljs-bullet,.hljs-link,.hljs-selector-id,.hljs-title{color:var(--syntax5)}}
</style><script type="module" src="/_astro/page.C1AneYUt.js"></script><style>@layer base{.icon-item{cursor:pointer;border-radius:8px;align-items:flex-start;text-decoration:none;transition:opacity .15s;display:flex}.icon-item:hover .pointer{opacity:1;transform:translate(0)}.icon-item:hover .icon-item-icon{background:var(--card-gradient-hover);color:var(--color-text-emphasis)}.icon-item-icon{box-sizing:border-box;border:1px solid var(--color-background-primary-soft);background:var(--card-gradient-hover);width:48px;height:48px;color:var(--color-text);border-radius:8px;flex-shrink:0;justify-content:center;align-items:center;font-size:24px;line-height:0;transition:background .2s;display:flex}:where(html.dark,html[data-theme=dark]) .icon-item-icon{background:linear-gradient(90deg,#56586980,#56586999,#565869b3)}:where(html.dark,html[data-theme=dark]) .icon-item:hover .icon-item-icon{background:linear-gradient(90deg,#56586999,#565869b3,#565869cc)}.icon-item-right{padding-left:16px}.icon-item-title{color:var(--color-text-emphasis);align-items:center;font-weight:500;transition:color .15s;display:flex}.pointer{opacity:0;justify-content:center;transition:opacity .15s ease-in-out,transform .15s ease-in-out;display:flex;transform:translate(-4px)}.icon-item-tag{background-color:var(--color-background-primary-soft);color:var(--gray-700);font-size:12px;font-weight:var(--font-weight-bold);letter-spacing:var(--font-tracking-wide);border-radius:8px;margin-left:8px;padding:2px 6px;line-height:16px;display:inline-block;transform:translateY(-2px)}.icon-item-tag.icon-item-tag-green{background-color:var(--green-100);color:var(--green-700)}.icon-item-desc{color:var(--color-text-secondary);text-overflow:ellipsis;white-space:normal;margin-bottom:15px;overflow:hidden}.icon-item *{text-decoration:none}}
</style><style>@layer components{._TextLink_ssta1_1{display:inline-flex;align-items:center;gap:var(--link-gap);border-radius:var(--link-radius);color:currentcolor;cursor:pointer;font-weight:var(--link-font-weight);overflow-wrap:anywhere;transition-duration:var(--transition-duration-basic);transition-property:opacity,color,box-shadow,text-decoration-color;transition-timing-function:var(--transition-ease-basic)}@media(hover:hover)and (pointer:fine){._TextLink_ssta1_1:hover{color:color-mix(in oklab,currentcolor 80%,transparent)}.text-secondary ._TextLink_ssta1_1:hover{color:var(--color-text)}.text-tertiary ._TextLink_ssta1_1:hover{color:var(--color-text-secondary)}}._TextLink_ssta1_1:focus-visible{outline:2px solid var(--color-ring);outline-offset:1px}._TextLink_ssta1_1[data-underline=always]{text-decoration:underline;text-decoration-color:color-mix(in oklab,currentcolor 70%,transparent);text-underline-offset:var(--link-underline-decoration-offset)}@media(hover:hover)and (pointer:fine){._TextLink_ssta1_1[data-underline=hover]:hover{text-decoration:underline;text-decoration-color:color-mix(in oklab,currentcolor 70%,transparent);text-underline-offset:var(--link-underline-decoration-offset)}}._TextLink_ssta1_1[data-primary]{color:var(--link-primary-text-color)}@media(hover:hover)and (pointer:fine){._TextLink_ssta1_1[data-primary]:hover{color:var(--link-primary-text-color-hover)}}}
</style><style>@layer components{._Notice_wyxfv_1{margin-top:24px;margin-bottom:24px}._Notice_wyxfv_1 p,._Notice_wyxfv_1 code{margin:0!important;line-height:18px!important}._Notice_wyxfv_1 p code{font-size:.875em}}
</style><style>@layer components{._DocLink_106al_1{display:flex;flex-direction:column;flex:1;transition:opacity .3s ease}@media(hover:hover)and (pointer:fine){._DocLink_106al_1:hover{opacity:.8}}}
</style><style>@layer components{._Tooltip_purug_1{max-width:300px;border-radius:var(--tooltip-border-radius);animation-duration:.25s;animation-name:_scale-in_purug_1;animation-timing-function:var(--cubic-enter);background:var(--tooltip-background-color);box-shadow:var(--tooltip-box-shadow);color:var(--tooltip-text-color);font-size:var(--tooltip-font-size);font-weight:var(--tooltip-font-weight);line-height:var(--tooltip-line-height);transform-origin:var(--radix-tooltip-content-transform-origin);transition:background-color .15s ease}._Tooltip_purug_1[data-state=closed]{animation:_scale-out_purug_1 .25s var(--cubic-enter)}._Tooltip_purug_1[data-clickable=false]{cursor:default}._Tooltip_purug_1[data-clickable=true]{cursor:pointer}@media(hover:hover)and (pointer:fine){._Tooltip_purug_1[data-compact=true][data-clickable=true]:hover{background:var(--tooltip-compact-interactive-background-color-hover);color:var(--tooltip-compact-interactive-text-color-hover)}}._Tooltip_purug_1[data-gutter-size=sm]{padding:var(--tooltip-padding-sm)}._Tooltip_purug_1[data-gutter-size=md]{padding:var(--tooltip-padding-md)}._Tooltip_purug_1[data-gutter-size=lg]{padding:var(--tooltip-padding-lg)}._Tooltip_purug_1[data-compact=true]{padding:var(--tooltip-compact-padding);background:var(--tooltip-compact-background-color);color:var(--tooltip-compact-text-color);font-size:var(--tooltip-compact-font-size);font-weight:var(--tooltip-compact-font-weight)}@keyframes _scale-in_purug_1{0%{opacity:0;transform:scale(.95)}to{opacity:1;transform:scale(1)}}@keyframes _scale-out_purug_1{0%{opacity:1;transform:scale(1)}to{opacity:0;transform:scale(.97)}}._TriggerDecorator_purug_84{display:inline-flex;cursor:pointer;-webkit-text-decoration:underline dotted;text-decoration:underline dotted;text-decoration-color:transparent;transition:-webkit-text-decoration .2s var(--cubic-exit);transition:text-decoration .2s var(--cubic-exit);transition:text-decoration .2s var(--cubic-exit),-webkit-text-decoration .2s var(--cubic-exit)}._TriggerDecorator_purug_84:focus{outline:0}._TriggerDecorator_purug_84[data-state*=open]{text-decoration-color:var(--color-text-tertiary);transition-timing-function:var(--cubic-enter)}}
</style><link rel="stylesheet" href="/_astro/Alert.Dl332ZUE.css"></head> <body class="overflow-x-hidden" data-pagefind-filter="section:api"> <header id="header" class="fixed top-0 w-full h-16 z-50 bg-white dark:bg-black border-b border-primary-surface astro-3ef6ksr2"> <div class="flex items-center h-full px-4 md:px-8 md:grid md:grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)] md:gap-6 astro-3ef6ksr2"> <!-- Logo --> <a href="/" class="flex items-center font-semibold ml-0 md:-ml-2 md:justify-self-start astro-3ef6ksr2"> <img src="/OpenAI_Developers.svg" alt="OpenAI Developers" class="h-6 w-48 md:h-6 dark:invert astro-3ef6ksr2"> </a> <!-- Links --> <nav class="hidden md:flex items-center justify-center gap-1 astro-3ef6ksr2"> <div class="relative group astro-3ef6ksr2"> <a href="/" class="flex items-center gap-1 text-sm px-2.5 py-1 rounded-md text-primary-soft hover:text-default hover:bg-primary-soft-alpha astro-3ef6ksr2"> Home  </a>  </div><div class="relative group astro-3ef6ksr2"> <a href="/api" class="flex items-center gap-1 text-sm px-2.5 py-1 rounded-md text-default bg-primary-soft astro-3ef6ksr2" aria-haspopup="menu"> API <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-tertiary astro-3ef6ksr2 " ><path d="M11.2929 16.2929C11.6834 16.6834 12.3166 16.6834 12.7071 16.2929L18.7071 10.2929C19.0976 9.90237 19.0976 9.26921 18.7071 8.87868C18.3166 8.48816 17.6834 8.48816 17.2929 8.87868L12 14.1716L6.70711 8.87868C6.31658 8.48816 5.68342 8.48816 5.29289 8.87868C4.90237 9.26921 4.90237 9.90237 5.29289 10.2929L11.2929 16.2929Z" fill="currentColor"></path></svg> </a> <div class="invisible opacity-0 absolute left-0 top-full z-50 mt-2 min-w-full w-max transition-opacity duration-150 group-hover:visible group-hover:opacity-100 group-focus-within:visible group-focus-within:opacity-100 before:content-[''] before:absolute before:-top-2 before:left-0 before:right-0 before:h-2 astro-3ef6ksr2" role="menu"> <div class="overflow-hidden rounded-md border border-primary-surface bg-surface shadow-md ring-1 ring-black/5 dark:ring-white/10 astro-3ef6ksr2"> <a role="menuitem" href="/api/docs" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Docs</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Guides and concepts for the OpenAI API </div> </div> </a><a role="menuitem" href="/api/reference/overview" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">API reference</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Endpoints, parameters, and responses </div> </div> </a> </div> </div> </div><div class="relative group astro-3ef6ksr2"> <a href="/codex" class="flex items-center gap-1 text-sm px-2.5 py-1 rounded-md text-primary-soft hover:text-default hover:bg-primary-soft-alpha astro-3ef6ksr2" aria-haspopup="menu"> Codex <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-tertiary astro-3ef6ksr2 " ><path d="M11.2929 16.2929C11.6834 16.6834 12.3166 16.6834 12.7071 16.2929L18.7071 10.2929C19.0976 9.90237 19.0976 9.26921 18.7071 8.87868C18.3166 8.48816 17.6834 8.48816 17.2929 8.87868L12 14.1716L6.70711 8.87868C6.31658 8.48816 5.68342 8.48816 5.29289 8.87868C4.90237 9.26921 4.90237 9.90237 5.29289 10.2929L11.2929 16.2929Z" fill="currentColor"></path></svg> </a> <div class="invisible opacity-0 absolute left-0 top-full z-50 mt-2 min-w-full w-max transition-opacity duration-150 group-hover:visible group-hover:opacity-100 group-focus-within:visible group-focus-within:opacity-100 before:content-[''] before:absolute before:-top-2 before:left-0 before:right-0 before:h-2 astro-3ef6ksr2" role="menu"> <div class="overflow-hidden rounded-md border border-primary-surface bg-surface shadow-md ring-1 ring-black/5 dark:ring-white/10 astro-3ef6ksr2"> <a role="menuitem" href="/codex" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Docs</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Guides, concepts, and product docs for Codex </div> </div> </a><a role="menuitem" href="/codex/use-cases" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Use cases</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Example workflows and tasks teams hand to Codex </div> </div> </a> </div> </div> </div><div class="relative group astro-3ef6ksr2"> <a href="/chatgpt" class="flex items-center gap-1 text-sm px-2.5 py-1 rounded-md text-primary-soft hover:text-default hover:bg-primary-soft-alpha astro-3ef6ksr2" aria-haspopup="menu"> ChatGPT <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-tertiary astro-3ef6ksr2 " ><path d="M11.2929 16.2929C11.6834 16.6834 12.3166 16.6834 12.7071 16.2929L18.7071 10.2929C19.0976 9.90237 19.0976 9.26921 18.7071 8.87868C18.3166 8.48816 17.6834 8.48816 17.2929 8.87868L12 14.1716L6.70711 8.87868C6.31658 8.48816 5.68342 8.48816 5.29289 8.87868C4.90237 9.26921 4.90237 9.90237 5.29289 10.2929L11.2929 16.2929Z" fill="currentColor"></path></svg> </a> <div class="invisible opacity-0 absolute left-0 top-full z-50 mt-2 min-w-full w-max transition-opacity duration-150 group-hover:visible group-hover:opacity-100 group-focus-within:visible group-focus-within:opacity-100 before:content-[''] before:absolute before:-top-2 before:left-0 before:right-0 before:h-2 astro-3ef6ksr2" role="menu"> <div class="overflow-hidden rounded-md border border-primary-surface bg-surface shadow-md ring-1 ring-black/5 dark:ring-white/10 astro-3ef6ksr2"> <a role="menuitem" href="/apps-sdk" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Apps SDK</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Build apps to extend ChatGPT </div> </div> </a><a role="menuitem" href="/workspace-agents" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Workspace Agents</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Trigger published ChatGPT workspace agents </div> </div> </a><a role="menuitem" href="/commerce" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Commerce</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Build commerce flows in ChatGPT </div> </div> </a><a role="menuitem" href="/ads" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Ads</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Publish and measure ads in ChatGPT </div> </div> </a> </div> </div> </div><div class="relative group astro-3ef6ksr2"> <a href="/learn" class="flex items-center gap-1 text-sm px-2.5 py-1 rounded-md text-primary-soft hover:text-default hover:bg-primary-soft-alpha astro-3ef6ksr2" aria-haspopup="menu"> Resources <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-tertiary astro-3ef6ksr2 " ><path d="M11.2929 16.2929C11.6834 16.6834 12.3166 16.6834 12.7071 16.2929L18.7071 10.2929C19.0976 9.90237 19.0976 9.26921 18.7071 8.87868C18.3166 8.48816 17.6834 8.48816 17.2929 8.87868L12 14.1716L6.70711 8.87868C6.31658 8.48816 5.68342 8.48816 5.29289 8.87868C4.90237 9.26921 4.90237 9.90237 5.29289 10.2929L11.2929 16.2929Z" fill="currentColor"></path></svg> </a> <div class="invisible opacity-0 absolute left-0 top-full z-50 mt-2 min-w-full w-max transition-opacity duration-150 group-hover:visible group-hover:opacity-100 group-focus-within:visible group-focus-within:opacity-100 before:content-[''] before:absolute before:-top-2 before:left-0 before:right-0 before:h-2 astro-3ef6ksr2" role="menu"> <div class="overflow-hidden rounded-md border border-primary-surface bg-surface shadow-md ring-1 ring-black/5 dark:ring-white/10 astro-3ef6ksr2"> <a role="menuitem" href="/showcase" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Showcase</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Demo apps to get inspired </div> </div> </a><a role="menuitem" href="/blog" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Blog</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Learnings and experiences from developers </div> </div> </a><a role="menuitem" href="/cookbook" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Cookbook</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Notebook examples for building with OpenAI models </div> </div> </a><a role="menuitem" href="/learn" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Learn</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Docs, videos, and demo apps for building with OpenAI </div> </div> </a><a role="menuitem" href="/community" class="block px-4 py-3 text-sm text-default transition-colors hover:bg-primary-soft-alpha dark:hover:bg-alpha-10 hover:text-default astro-3ef6ksr2"> <div class="flex flex-col gap-1 astro-3ef6ksr2"> <div class="font-medium astro-3ef6ksr2">Community</div> <div class="text-sm text-secondary astro-3ef6ksr2"> Programs, meetups, and support for builders </div> </div> </a> </div> </div> </div>  </nav> <!-- Theme Toggle, Mobile Menu --> <div class="ml-auto flex items-center gap-4 md:gap-5 md:ml-0 md:justify-end md:justify-self-end astro-3ef6ksr2"> <button type="button" data-header-search-button aria-controls="header-search-overlay" aria-expanded="false" class="hidden min-w-52 items-center justify-between gap-3 rounded-full border border-primary-surface bg-surface px-4 py-2 text-sm text-secondary transition-colors hover:bg-primary-soft-alpha hover:text-default xl:flex astro-3ef6ksr2"> <span class="truncate astro-3ef6ksr2">Start searching</span> <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="h-4 w-4 shrink-0 astro-3ef6ksr2 " ><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg> </button> <div class="hidden md:flex astro-3ef6ksr2"> <div class="flex items-center gap-2"><a target="_blank" rel="noopener noreferrer" href="https://platform.openai.com/login" class="_Button_6dmow_1 not-prose !h-9 !w-9 justify-center !px-0 min-[1000px]:!w-auto min-[1000px]:!px-4" data-color="primary" data-variant="solid" data-pill="" data-size="md"><span class="_ButtonInner_6dmow_4"><span class="sr-only min-[1000px]:not-sr-only">API Dashboard</span><svg width="1em" height="1em" viewBox="0 0 24 24" fill="currentColor" class="shrink-0"><path fill-rule="evenodd" d="M16.243 6.757a1 1 0 0 1 1 1v7.072a1 1 0 0 1-2 0v-4.657L8.464 16.95a1 1 0 0 1-1.414-1.414l6.778-6.779H9.172a1 1 0 0 1 0-2h7.07Z" clip-rule="evenodd"></path></svg></span></a></div> </div> <button id="header-theme-button" aria-label="Toggle light and dark theme" class="hidden md:flex text-secondary hover:text-default transition-colors astro-3ef6ksr2"> <svg width="22" height="22" viewBox="0 0 22 22" fill="none" xmlns="http://www.w3.org/2000/svg" class="block dark:hidden w-4 h-4 astro-3ef6ksr2 " ><path fill-rule="evenodd" clip-rule="evenodd" d="M11 0C11.5523 0 12 0.447715 12 1V3C12 3.55228 11.5523 4 11 4C10.4477 4 10 3.55228 10 3V1C10 0.447715 10.4477 0 11 0ZM3.22183 3.22183C3.61235 2.8313 4.24551 2.8313 4.63604 3.22183L6.05025 4.63604C6.44078 5.02656 6.44078 5.65973 6.05025 6.05025C5.65973 6.44078 5.02656 6.44078 4.63604 6.05025L3.22183 4.63604C2.8313 4.24551 2.8313 3.61235 3.22183 3.22183ZM18.7782 3.22183C19.1687 3.61235 19.1687 4.24551 18.7782 4.63604L17.364 6.05025C16.9734 6.44078 16.3403 6.44078 15.9497 6.05025C15.5592 5.65973 15.5592 5.02656 15.9497 4.63604L17.364 3.22183C17.7545 2.8313 18.3876 2.8313 18.7782 3.22183ZM11 8C9.34315 8 8 9.34315 8 11C8 12.6569 9.34315 14 11 14C12.6569 14 14 12.6569 14 11C14 9.34315 12.6569 8 11 8ZM6 11C6 8.23858 8.23858 6 11 6C13.7614 6 16 8.23858 16 11C16 13.7614 13.7614 16 11 16C8.23858 16 6 13.7614 6 11ZM0 11C0 10.4477 0.447715 10 1 10H3C3.55228 10 4 10.4477 4 11C4 11.5523 3.55228 12 3 12H1C0.447715 12 0 11.5523 0 11ZM18 11C18 10.4477 18.4477 10 19 10H21C21.5523 10 22 10.4477 22 11C22 11.5523 21.5523 12 21 12H19C18.4477 12 18 11.5523 18 11ZM6.05025 15.9497C6.44078 16.3403 6.44078 16.9734 6.05025 17.364L4.63604 18.7782C4.24551 19.1687 3.61235 19.1687 3.22183 18.7782C2.8313 18.3876 2.8313 17.7545 3.22183 17.364L4.63604 15.9497C5.02656 15.5592 5.65973 15.5592 6.05025 15.9497ZM15.9497 15.9497C16.3403 15.5592 16.9734 15.5592 17.364 15.9497L18.7782 17.364C19.1687 17.7545 19.1687 18.3876 18.7782 18.7782C18.3877 19.1687 17.7545 19.1687 17.364 18.7782L15.9497 17.364C15.5592 16.9734 15.5592 16.3403 15.9497 15.9497ZM11 18C11.5523 18 12 18.4477 12 19V21C12 21.5523 11.5523 22 11 22C10.4477 22 10 21.5523 10 21V19C10 18.4477 10.4477 18 11 18Z" fill="currentColor"></path></svg> <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg" class="hidden dark:block w-4 h-4 astro-3ef6ksr2 " ><path d="M10.7836 0.470481C10.9676 0.765118 10.9855 1.13415 10.8309 1.44525C10.2994 2.51497 10 3.7211 10 5.00001C10 9.41829 13.5817 13 18 13L18.0575 12.9998C18.4049 12.9974 18.7287 13.1754 18.9127 13.47C19.0968 13.7647 19.1147 14.1337 18.9601 14.4448C17.325 17.7352 13.9279 20 10 20C4.47715 20 0 15.5229 0 10C0 4.50107 4.43841 0.038857 9.92838 0.000268937C10.2758 -0.00217271 10.5995 0.175844 10.7836 0.470481ZM8.40989 2.15803C4.75344 2.8954 2 6.12619 2 10C2 14.4183 5.58172 18 10 18C12.587 18 14.8886 16.7721 16.3516 14.8648C11.6131 14.0789 8 9.96139 8 5.00001C8 4.01361 8.1431 3.05953 8.40989 2.15803Z" fill="currentColor"></path></svg> </button> <button type="button" data-header-search-button aria-label="Search the API docs" aria-controls="header-search-overlay" aria-expanded="false" class="text-secondary hover:text-default transition-colors md:inline-flex xl:hidden astro-3ef6ksr2"> <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="w-4 h-4 text-secondary hover:text-default transition-colors astro-3ef6ksr2 " ><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg> </button> <!-- Mobile Menu Button --> <button id="header-drawer-button" type="button" aria-label="Toggle menu" aria-controls="drawer" aria-expanded="false" class="md:hidden relative right-1 text-secondary hover:text-default transition-colors astro-3ef6ksr2"> <svg width="18" height="10" viewBox="0 0 18 10" fill="none" xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 text-secondary hover:text-default transition-colors astro-3ef6ksr2 " ><path d="M0 1C0 0.447715 0.447715 0 1 0H17C17.5523 0 18 0.447715 18 1C18 1.55228 17.5523 2 17 2H1C0.447715 2 0 1.55228 0 1ZM0 9C0 8.44772 0.447715 8 1 8H11C11.5523 8 12 8.44772 12 9C12 9.55229 11.5523 10 11 10H1C0.447715 10 0 9.55229 0 9Z" fill="currentColor"></path></svg> </button> </div> </div> </header> <div id="header-search-overlay" role="dialog" aria-modal="true" aria-labelledby="header-search-title" aria-hidden="true" data-open="false" class="fixed inset-0 z-[60] hidden items-start justify-center px-4 pt-20 pb-10 md:px-6 md:pt-24 astro-3ef6ksr2"> <div class="absolute inset-0 bg-black/35 backdrop-blur-xs transition-opacity dark:bg-black/70 astro-3ef6ksr2" data-header-search-dismiss></div> <div class="relative z-10 w-full max-w-4xl overflow-hidden rounded-[28px] bg-surface shadow-[0_36px_120px_-48px_rgba(15,23,42,0.55)] ring-1 ring-black/10 dark:ring-white/10 astro-3ef6ksr2" data-header-search-panel> <div data-header-search-body class="p-0 astro-3ef6ksr2"> <h2 id="header-search-title" class="sr-only astro-3ef6ksr2"> Search the API docs </h2> <div class="relative flex min-h-0 flex-1 flex-col astro-3ef6ksr2"> <button type="button" data-header-search-close aria-label="Close search" class="absolute right-5 top-7 z-20 inline-flex h-8 w-8 shrink-0 appearance-none items-center justify-center rounded-md border-0 bg-transparent p-0 leading-none text-tertiary shadow-none transition-colors hover:text-default focus-visible:outline-none focus-visible:ring-0 md:right-7 astro-3ef6ksr2"> <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="h-[18px] w-[18px] shrink-0 astro-3ef6ksr2 " ><path d="M18 6 6 18"></path><path d="m6 6 12 12"></path></svg> </button> <style>astro-island,astro-slot,astro-static-slot{display:contents}</style><script>(()=>{var e=async t=>{await(await t())()};(self.Astro||(self.Astro={})).load=e;window.dispatchEvent(new Event("astro:load"));})();</script><script>(()=>{var A=Object.defineProperty;var g=(i,o,a)=>o in i?A(i,o,{enumerable:!0,configurable:!0,writable:!0,value:a}):i[o]=a;var d=(i,o,a)=>g(i,typeof o!="symbol"?o+"":o,a);{let i={0:t=>m(t),1:t=>a(t),2:t=>new RegExp(t),3:t=>new Date(t),4:t=>new Map(a(t)),5:t=>new Set(a(t)),6:t=>BigInt(t),7:t=>new URL(t),8:t=>new Uint8Array(t),9:t=>new Uint16Array(t),10:t=>new Uint32Array(t),11:t=>Number.POSITIVE_INFINITY*t},o=t=>{let[l,e]=t;return l in i?i[l](e):void 0},a=t=>t.map(o),m=t=>typeof t!="object"||t===null?t:Object.fromEntries(Object.entries(t).map(([l,e])=>[l,o(e)]));class y extends HTMLElement{constructor(){super(...arguments);d(this,"Component");d(this,"hydrator");d(this,"hydrate",async()=>{var b;if(!this.hydrator||!this.isConnected)return;let e=(b=this.parentElement)==null?void 0:b.closest("astro-island[ssr]");if(e){e.addEventListener("astro:hydrate",this.hydrate,{once:!0});return}let c=this.querySelectorAll("astro-slot"),n={},h=this.querySelectorAll("template[data-astro-template]");for(let r of h){let s=r.closest(this.tagName);s!=null&&s.isSameNode(this)&&(n[r.getAttribute("data-astro-template")||"default"]=r.innerHTML,r.remove())}for(let r of c){let s=r.closest(this.tagName);s!=null&&s.isSameNode(this)&&(n[r.getAttribute("name")||"default"]=r.innerHTML)}let p;try{p=this.hasAttribute("props")?m(JSON.parse(this.getAttribute("props"))):{}}catch(r){let s=this.getAttribute("component-url")||"<unknown>",v=this.getAttribute("component-export");throw v&&(s+=` (export ${v})`),console.error(`[hydrate] Error parsing props for component ${s}`,this.getAttribute("props"),r),r}let u;await this.hydrator(this)(this.Component,p,n,{client:this.getAttribute("client")}),this.removeAttribute("ssr"),this.dispatchEvent(new CustomEvent("astro:hydrate"))});d(this,"unmount",()=>{this.isConnected||this.dispatchEvent(new CustomEvent("astro:unmount"))})}disconnectedCallback(){document.removeEventListener("astro:after-swap",this.unmount),document.addEventListener("astro:after-swap",this.unmount,{once:!0})}connectedCallback(){if(!this.hasAttribute("await-children")||document.readyState==="interactive"||document.readyState==="complete")this.childrenConnectedCallback();else{let e=()=>{document.removeEventListener("DOMContentLoaded",e),c.disconnect(),this.childrenConnectedCallback()},c=new MutationObserver(()=>{var n;((n=this.lastChild)==null?void 0:n.nodeType)===Node.COMMENT_NODE&&this.lastChild.nodeValue==="astro:end"&&(this.lastChild.remove(),e())});c.observe(this,{childList:!0}),document.addEventListener("DOMContentLoaded",e)}}async childrenConnectedCallback(){let e=this.getAttribute("before-hydration-url");e&&await import(e),this.start()}async start(){let e=JSON.parse(this.getAttribute("opts")),c=this.getAttribute("client");if(Astro[c]===void 0){window.addEventListener(`astro:${c}`,()=>this.start(),{once:!0});return}try{await Astro[c](async()=>{let n=this.getAttribute("renderer-url"),[h,{default:p}]=await Promise.all([import(this.getAttribute("component-url")),n?import(n):()=>()=>{}]),u=this.getAttribute("component-export")||"default";if(!u.includes("."))this.Component=h[u];else{this.Component=h;for(let f of u.split("."))this.Component=this.Component[f]}return this.hydrator=p,this.hydrate},e,this)}catch(n){console.error(`[astro-island] Error hydrating ${this.getAttribute("component-url")}`,n)}}attributeChangedCallback(){this.hydrate()}}d(y,"observedAttributes",["props"]),customElements.get("astro-island")||customElements.define("astro-island",y)}})();</script><astro-island uid="Z19tmGq" prefix="r106" component-url="/_astro/AlgoliaSearch.react.DMaHK7Vr.js" component-export="default" renderer-url="/_astro/client.BWriqC1y.js" props="{&quot;id&quot;:[0,&quot;header-site-search&quot;],&quot;className&quot;:[0,&quot;pagefind-header-ui pagefind-desktop-ui oai-site-search-overlay astro-3ef6ksr2&quot;],&quot;query&quot;:[0,&quot;&quot;],&quot;scope&quot;:[0,&quot;api&quot;],&quot;uiOptions&quot;:[0,{&quot;showImages&quot;:[0,false],&quot;showSubResults&quot;:[0,false],&quot;translations&quot;:[0,{&quot;placeholder&quot;:[0,&quot;Start searching&quot;],&quot;zeroResults&quot;:[0,&quot;No matches yet. Try a different keyword.&quot;]}]}]}" ssr client="load" opts="{&quot;name&quot;:&quot;AlgoliaSearchReact&quot;,&quot;value&quot;:true}" await-children><div id="header-site-search" class="pagefind-header-ui pagefind-desktop-ui oai-site-search-overlay astro-3ef6ksr2 _root_1wztd_1" data-site-search-root="true" data-site-search-provider="algolia" data-site-search-variant="overlay" data-query="" data-scope="api"><div class="flex h-full min-h-0 flex-col gap-0"><div class="shrink-0 border-b border-primary-surface px-4 py-4 md:px-6 md:py-5"><label class="sr-only" for="header-site-search-input">Search docs</label><input id="header-site-search-input" type="text" placeholder="Start searching" autoComplete="off" spellCheck="false" data-site-search-input="true" class="w-full outline-none transition-colors rounded-none border-0 bg-transparent py-0 pl-0 pr-14 text-[18px] leading-tight text-default placeholder:text-tertiary focus:ring-0 md:text-[18px]" value=""/></div><div class="flex min-h-0 flex-1 flex-col gap-4 px-4 py-4 md:px-6 md:py-5"><div data-site-search-empty-state="true" class="flex flex-col gap-4"><section class="_emptySection_1wztd_68"><h3 class="_emptyHeading_1wztd_74">Suggested</h3><div class="flex flex-wrap gap-2"><button type="button" class="_emptyChip_1wztd_81" data-search-query-button="true" data-search-query="responses create">responses create</button><button type="button" class="_emptyChip_1wztd_81" data-search-query-button="true" data-search-query="reasoning_effort">reasoning_effort</button><button type="button" class="_emptyChip_1wztd_81" data-search-query-button="true" data-search-query="realtime">realtime</button><button type="button" class="_emptyChip_1wztd_81" data-search-query-button="true" data-search-query="prompt caching">prompt caching</button></div></section></div></div></div></div><!--astro:end--></astro-island> </div> </div> </div> </div> <div id="drawer" data-default-tab-id="mobile-nav-tab-api" data-default-search-placeholder="Start searching" data-default-search-scope="api" class="fixed inset-0 z-40 flex flex-col bg-surface transform translate-x-full transition-transform duration-300 md:hidden astro-3ef6ksr2"> <div class="flex flex-col h-full w-full astro-3ef6ksr2"> <div class="px-6 pt-6 w-full mt-16 astro-3ef6ksr2"> <span id="mobile-nav-primary-label" class="sr-only astro-3ef6ksr2">Primary navigation</span> <div class="flex items-center gap-2 astro-3ef6ksr2"> <nav class="min-w-0 flex-1 flex items-center gap-2 overflow-x-auto pb-2 -mx-1 px-1 astro-3ef6ksr2" role="tablist" aria-labelledby="mobile-nav-primary-label"> <button type="button" role="tab" data-mobile-nav-tab data-tab-id="mobile-nav-tab-api" data-has-nav="true" data-href="/api/docs" data-label="API" data-search-placeholder="Start searching" data-search-scope="api" data-selected="true" aria-selected="true" class="shrink-0 rounded-full border border-primary-surface px-3.5 py-1.5 text-sm text-secondary transition-colors duration-150 data-[selected=true]:bg-primary-soft data-[selected=true]:text-default hover:bg-primary-soft-alpha hover:text-default focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-surface astro-3ef6ksr2"> API </button><button type="button" role="tab" data-mobile-nav-tab data-tab-id="mobile-nav-tab-api-reference" data-has-nav="false" data-href="/api/reference/overview" data-label="API Reference" data-search-placeholder="Start searching" data-search-scope="api" data-selected="false" aria-selected="false" class="shrink-0 rounded-full border border-primary-surface px-3.5 py-1.5 text-sm text-secondary transition-colors duration-150 data-[selected=true]:bg-primary-soft data-[selected=true]:text-default hover:bg-primary-soft-alpha hover:text-default focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-surface astro-3ef6ksr2"> API Reference </button><button type="button" role="tab" data-mobile-nav-tab data-tab-id="mobile-nav-tab-2" data-has-nav="true" data-href="/codex" data-label="Codex" data-search-placeholder="Start searching" data-search-scope="codex" data-selected="false" aria-selected="false" class="shrink-0 rounded-full border border-primary-surface px-3.5 py-1.5 text-sm text-secondary transition-colors duration-150 data-[selected=true]:bg-primary-soft data-[selected=true]:text-default hover:bg-primary-soft-alpha hover:text-default focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-surface astro-3ef6ksr2"> Codex </button><button type="button" role="tab" data-mobile-nav-tab data-tab-id="mobile-nav-tab-3" data-has-nav="true" data-href="/chatgpt" data-label="ChatGPT" data-search-placeholder="Start searching" data-search-scope="chatgpt" data-selected="false" aria-selected="false" class="shrink-0 rounded-full border border-primary-surface px-3.5 py-1.5 text-sm text-secondary transition-colors duration-150 data-[selected=true]:bg-primary-soft data-[selected=true]:text-default hover:bg-primary-soft-alpha hover:text-default focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-surface astro-3ef6ksr2"> ChatGPT </button><button type="button" role="tab" data-mobile-nav-tab data-tab-id="mobile-nav-tab-4" data-has-nav="true" data-href="/learn" data-label="Resources" data-search-placeholder="Start searching" data-search-scope="learn" data-selected="false" aria-selected="false" class="shrink-0 rounded-full border border-primary-surface px-3.5 py-1.5 text-sm text-secondary transition-colors duration-150 data-[selected=true]:bg-primary-soft data-[selected=true]:text-default hover:bg-primary-soft-alpha hover:text-default focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-surface astro-3ef6ksr2"> Resources </button> </nav> <button id="drawer-theme-button" type="button" aria-label="Toggle light and dark theme" class="shrink-0 mb-2 rounded-full border border-primary-surface p-2 text-secondary transition-colors hover:text-default astro-3ef6ksr2"> <svg width="22" height="22" viewBox="0 0 22 22" fill="none" xmlns="http://www.w3.org/2000/svg" class="block dark:hidden w-5 h-5 astro-3ef6ksr2 " ><path fill-rule="evenodd" clip-rule="evenodd" d="M11 0C11.5523 0 12 0.447715 12 1V3C12 3.55228 11.5523 4 11 4C10.4477 4 10 3.55228 10 3V1C10 0.447715 10.4477 0 11 0ZM3.22183 3.22183C3.61235 2.8313 4.24551 2.8313 4.63604 3.22183L6.05025 4.63604C6.44078 5.02656 6.44078 5.65973 6.05025 6.05025C5.65973 6.44078 5.02656 6.44078 4.63604 6.05025L3.22183 4.63604C2.8313 4.24551 2.8313 3.61235 3.22183 3.22183ZM18.7782 3.22183C19.1687 3.61235 19.1687 4.24551 18.7782 4.63604L17.364 6.05025C16.9734 6.44078 16.3403 6.44078 15.9497 6.05025C15.5592 5.65973 15.5592 5.02656 15.9497 4.63604L17.364 3.22183C17.7545 2.8313 18.3876 2.8313 18.7782 3.22183ZM11 8C9.34315 8 8 9.34315 8 11C8 12.6569 9.34315 14 11 14C12.6569 14 14 12.6569 14 11C14 9.34315 12.6569 8 11 8ZM6 11C6 8.23858 8.23858 6 11 6C13.7614 6 16 8.23858 16 11C16 13.7614 13.7614 16 11 16C8.23858 16 6 13.7614 6 11ZM0 11C0 10.4477 0.447715 10 1 10H3C3.55228 10 4 10.4477 4 11C4 11.5523 3.55228 12 3 12H1C0.447715 12 0 11.5523 0 11ZM18 11C18 10.4477 18.4477 10 19 10H21C21.5523 10 22 10.4477 22 11C22 11.5523 21.5523 12 21 12H19C18.4477 12 18 11.5523 18 11ZM6.05025 15.9497C6.44078 16.3403 6.44078 16.9734 6.05025 17.364L4.63604 18.7782C4.24551 19.1687 3.61235 19.1687 3.22183 18.7782C2.8313 18.3876 2.8313 17.7545 3.22183 17.364L4.63604 15.9497C5.02656 15.5592 5.65973 15.5592 6.05025 15.9497ZM15.9497 15.9497C16.3403 15.5592 16.9734 15.5592 17.364 15.9497L18.7782 17.364C19.1687 17.7545 19.1687 18.3876 18.7782 18.7782C18.3877 19.1687 17.7545 19.1687 17.364 18.7782L15.9497 17.364C15.5592 16.9734 15.5592 16.3403 15.9497 15.9497ZM11 18C11.5523 18 12 18.4477 12 19V21C12 21.5523 11.5523 22 11 22C10.4477 22 10 21.5523 10 21V19C10 18.4477 10.4477 18 11 18Z" fill="currentColor"></path></svg> <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg" class="hidden dark:block w-5 h-5 astro-3ef6ksr2 " ><path d="M10.7836 0.470481C10.9676 0.765118 10.9855 1.13415 10.8309 1.44525C10.2994 2.51497 10 3.7211 10 5.00001C10 9.41829 13.5817 13 18 13L18.0575 12.9998C18.4049 12.9974 18.7287 13.1754 18.9127 13.47C19.0968 13.7647 19.1147 14.1337 18.9601 14.4448C17.325 17.7352 13.9279 20 10 20C4.47715 20 0 15.5229 0 10C0 4.50107 4.43841 0.038857 9.92838 0.000268937C10.2758 -0.00217271 10.5995 0.175844 10.7836 0.470481ZM8.40989 2.15803C4.75344 2.8954 2 6.12619 2 10C2 14.4183 5.58172 18 10 18C12.587 18 14.8886 16.7721 16.3516 14.8648C11.6131 14.0789 8 9.96139 8 5.00001C8 4.01361 8.1431 3.05953 8.40989 2.15803Z" fill="currentColor"></path></svg> </button> </div> </div> <div class="flex-1 w-full overflow-y-auto px-6 py-4 flex flex-col gap-6 astro-3ef6ksr2" data-mobile-nav-panels> <div data-mobile-search class="astro-3ef6ksr2"> <astro-island uid="2m9xLh" prefix="r107" component-url="/_astro/AlgoliaSearch.react.DMaHK7Vr.js" component-export="default" renderer-url="/_astro/client.BWriqC1y.js" props="{&quot;id&quot;:[0,&quot;header-mobile-search&quot;],&quot;className&quot;:[0,&quot;pagefind-header-ui pagefind-mobile-ui astro-3ef6ksr2&quot;],&quot;query&quot;:[0,&quot;&quot;],&quot;scope&quot;:[0,&quot;api&quot;],&quot;uiOptions&quot;:[0,{&quot;showImages&quot;:[0,false],&quot;showSubResults&quot;:[0,false],&quot;translations&quot;:[0,{&quot;placeholder&quot;:[0,&quot;Start searching&quot;],&quot;zeroResults&quot;:[0,&quot;No matches yet. Try a different keyword.&quot;]}]}]}" ssr client="load" opts="{&quot;name&quot;:&quot;AlgoliaSearchReact&quot;,&quot;value&quot;:true}" await-children><div id="header-mobile-search" class="pagefind-header-ui pagefind-mobile-ui astro-3ef6ksr2 _root_1wztd_1" data-site-search-root="true" data-site-search-provider="algolia" data-site-search-variant="default" data-query="" data-scope="api"><div class="flex h-full min-h-0 flex-col gap-4"><div class=""><label class="sr-only" for="header-mobile-search-input">Search docs</label><input id="header-mobile-search-input" type="text" placeholder="Start searching" autoComplete="off" spellCheck="false" data-site-search-input="true" class="w-full outline-none transition-colors rounded-[18px] border border-transparent bg-primary-soft-alpha py-4 pl-6 pr-14 text-[18px] leading-tight text-default placeholder:text-tertiary focus:border-transparent focus:ring-0" value=""/></div><div class="flex min-h-0 flex-1 flex-col gap-4"><div data-site-search-empty-state="true" class="flex flex-col gap-4"><section class="_emptySection_1wztd_68"><h3 class="_emptyHeading_1wztd_74">Suggested</h3><div class="flex flex-wrap gap-2"><button type="button" class="_emptyChip_1wztd_81" data-search-query-button="true" data-search-query="responses create">responses create</button><button type="button" class="_emptyChip_1wztd_81" data-search-query-button="true" data-search-query="reasoning_effort">reasoning_effort</button><button type="button" class="_emptyChip_1wztd_81" data-search-query-button="true" data-search-query="realtime">realtime</button><button type="button" class="_emptyChip_1wztd_81" data-search-query-button="true" data-search-query="prompt caching">prompt caching</button></div></section></div></div></div></div><!--astro:end--></astro-island> </div> <div id="mobile-nav-panel-api" data-mobile-nav-content data-tab-id="mobile-nav-tab-api" data-default-variant-id="mobile-nav-tab-api-variant-default" class="flex flex-col gap-4 pb-8 astro-3ef6ksr2">  <div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-api-variant-default" class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Get started </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/api/docs/quickstart" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Quickstart   </a> </li><li> <a href="/api/docs/models" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Models   </a> </li><li> <a href="/api/docs/pricing" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Pricing   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <a href="/api/docs/libraries" class="flex-1 " data-mobile-nav-link> SDKs and CLI  </a> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/libraries" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> OpenAI SDK   </a> </li><li> <a href="/api/docs/guides/agents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Agents SDK   </a> </li><li> <a href="/api/docs/libraries/openai-cli" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> OpenAI CLI   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/latest-model" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Latest: GPT-5.5   </a> </li><li> <a href="/api/docs/guides/prompt-guidance" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Prompt guidance   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Core concepts </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/text" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Text generation   </a> </li><li> <a href="/api/docs/guides/code-generation" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Code generation   </a> </li><li> <a href="/api/docs/guides/images-vision" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Images and vision   </a> </li><li> <a href="/api/docs/guides/audio" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Audio and speech   </a> </li><li> <a href="/api/docs/guides/structured-outputs" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Structured output   </a> </li><li> <a href="/api/docs/guides/function-calling" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Function calling   </a> </li><li> <a href="/api/docs/guides/migrate-to-responses" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Responses API   </a> </li><li> <a href="/api/docs/guides/tools" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Using tools   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Agents SDK </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/agents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/api/docs/guides/agents/quickstart" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Quickstart   </a> </li><li> <a href="/api/docs/guides/agents/define-agents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Agent definitions   </a> </li><li> <a href="/api/docs/guides/agents/models" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Models and providers   </a> </li><li> <a href="/api/docs/guides/agents/running-agents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Running agents   </a> </li><li> <a href="/api/docs/guides/agents/sandboxes" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Sandbox agents   </a> </li><li> <a href="/api/docs/guides/agents/orchestration" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Orchestration   </a> </li><li> <a href="/api/docs/guides/agents/guardrails-approvals" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Guardrails   </a> </li><li> <a href="/api/docs/guides/agents/results" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Results and state   </a> </li><li> <a href="/api/docs/guides/agents/integrations-observability" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Integrations and observability   </a> </li><li> <a href="/api/docs/guides/agent-evals" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Evaluate agent workflows   </a> </li><li> <a href="/api/docs/guides/voice-agents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Voice agents   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">ChatKit</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/chatkit" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/api/docs/guides/chatkit-themes" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Customize   </a> </li><li> <a href="/api/docs/guides/chatkit-widgets" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Widgets   </a> </li><li> <a href="/api/docs/guides/chatkit-actions" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Actions   </a> </li><li> <a href="/api/docs/guides/custom-chatkit" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Advanced integrations   </a> </li> </ul> </details> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Tools </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/tools-web-search" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Web search   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <a href="/api/docs/guides/tools-connectors-mcp" class="flex-1 " data-mobile-nav-link> MCP and Connectors  </a> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/secure-mcp-tunnels" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Secure MCP Tunnel   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/tools-skills" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Skills   </a> </li><li> <a href="/api/docs/guides/tools-shell" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Shell   </a> </li><li> <a href="/api/docs/guides/tools-computer-use" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Computer use   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">File search and retrieval</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/tools-file-search" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> File search   </a> </li><li> <a href="/api/docs/guides/retrieval" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Retrieval   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/tools-tool-search" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Tool search   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">More tools</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/tools-apply-patch" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Apply Patch   </a> </li><li> <a href="/api/docs/guides/tools-local-shell" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Local shell   </a> </li><li> <a href="/api/docs/guides/tools-image-generation" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Image generation   </a> </li><li> <a href="/api/docs/guides/tools-code-interpreter" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Code interpreter   </a> </li> </ul> </details> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Run and scale </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/conversation-state" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Conversation state   </a> </li><li> <a href="/api/docs/guides/background" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Background mode   </a> </li><li> <a href="/api/docs/guides/streaming-responses" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Streaming   </a> </li><li> <a href="/api/docs/guides/websocket-mode" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> WebSocket mode   </a> </li><li> <a href="/api/docs/guides/webhooks" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Webhooks   </a> </li><li> <a href="/api/docs/guides/file-inputs" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> File inputs   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Context management</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/compaction" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Compaction   </a> </li><li> <a href="/api/docs/guides/token-counting" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Counting tokens   </a> </li><li> <a href="/api/docs/guides/prompt-caching" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Prompt caching   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Prompting</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/prompting" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/api/docs/guides/prompt-engineering" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Prompt engineering   </a> </li><li> <a href="/api/docs/guides/citation-formatting" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Citation formatting   </a> </li><li> <a href="/api/docs/guides/prompting/migrate-from-prompt-object" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Migration guide   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Reasoning</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/reasoning" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Reasoning models   </a> </li><li> <a href="/api/docs/guides/reasoning-best-practices" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Reasoning best practices   </a> </li> </ul> </details> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Evaluation </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/red-teaming" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Red teaming   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Realtime and audio </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/realtime" class="px-3 py-1.5 rounded-lg transition-colors block text-default bg-primary-ghost-active " data-mobile-nav-link> Overview   </a> </li><li> <a href="/api/docs/guides/voice-agents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Voice agents   </a> </li><li> <a href="/api/docs/guides/realtime-translation" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Live translation   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Transcription</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/realtime-transcription" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Realtime transcription   </a> </li><li> <a href="/api/docs/guides/speech-to-text" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Speech to text   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/text-to-speech" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Speech generation   </a> </li><li> <a href="/api/docs/guides/realtime-models-prompting" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Realtime prompting guide   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Connection methods</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/realtime-webrtc" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> WebRTC   </a> </li><li> <a href="/api/docs/guides/realtime-websocket" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> WebSocket   </a> </li><li> <a href="/api/docs/guides/realtime-sip" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> SIP   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Realtime sessions</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/realtime-conversations" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Managing conversations   </a> </li><li> <a href="/api/docs/guides/realtime-vad" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Voice activity detection   </a> </li><li> <a href="/api/docs/guides/realtime-mcp" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Realtime with tools   </a> </li><li> <a href="/api/docs/guides/realtime-server-controls" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Webhooks and server-side controls   </a> </li><li> <a href="/api/docs/guides/realtime-costs" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Managing costs   </a> </li> </ul> </details> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Specialized models </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/image-generation" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Image generation   </a> </li><li> <a href="/api/docs/guides/video-generation" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Video generation   </a> </li><li> <a href="/api/docs/guides/deep-research" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Deep research   </a> </li><li> <a href="/api/docs/guides/embeddings" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Embeddings   </a> </li><li> <a href="/api/docs/guides/moderation" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Moderation   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Going live </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/production-best-practices" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Production best practices   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <a href="/api/docs/guides/workload-identity-federation" class="flex-1 " data-mobile-nav-link> Workload identity federation  </a> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/workload-identity-federation" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/kubernetes" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Kubernetes   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/aws" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> AWS   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/microsoft-azure" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Microsoft Azure   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/google-cloud" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Google Cloud   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/github-actions" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> GitHub Actions   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/spiffe" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> SPIFFE   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/deployment-checklist" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Deployment checklist   </a> </li><li> <a href="/api/docs/guides/amazon-bedrock" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Amazon Bedrock   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Latency optimization</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/latency-optimization" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/api/docs/guides/predicted-outputs" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Predicted Outputs   </a> </li><li> <a href="/api/docs/guides/priority-processing" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Priority processing   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Cost optimization</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/cost-optimization" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/api/docs/guides/batch" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Batch   </a> </li><li> <a href="/api/docs/guides/flex-processing" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Flex processing   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/optimizing-llm-accuracy" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Accuracy optimization   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Safety</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/safety-best-practices" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Safety best practices   </a> </li><li> <a href="/api/docs/guides/safety-checks" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Safety checks   </a> </li><li> <a href="/api/docs/guides/safety-checks/cybersecurity" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Cybersecurity checks   </a> </li><li> <a href="/api/docs/guides/safety-checks/under-18-api-guidance" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Under 18 API Guidance   </a> </li> </ul> </details> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Legacy APIs </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Agent Builder</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/agent-builder" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/api/docs/guides/agent-builder/migrate-from-agent-builder" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Migration guide   </a> </li><li> <a href="/api/docs/guides/node-reference" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Node reference   </a> </li><li> <a href="/api/docs/guides/agent-builder-safety" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Safety in building agents   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Evals</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/evaluation-getting-started" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Getting started   </a> </li><li> <a href="/api/docs/guides/evals" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Working with evals   </a> </li><li> <a href="/api/docs/guides/prompt-optimizer" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Prompt optimizer   </a> </li><li> <a href="/api/docs/guides/external-models" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> External models   </a> </li><li> <a href="/api/docs/guides/evaluation-best-practices" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Best practices   </a> </li><li> <a href="/api/docs/guides/graders" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Graders   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Fine-tuning</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/guides/model-optimization" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Optimization cycle   </a> </li><li> <a href="/api/docs/guides/supervised-fine-tuning" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Supervised fine-tuning   </a> </li><li> <a href="/api/docs/guides/vision-fine-tuning" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Vision fine-tuning   </a> </li><li> <a href="/api/docs/guides/direct-preference-optimization" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Direct preference optimization   </a> </li><li> <a href="/api/docs/guides/reinforcement-fine-tuning" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Reinforcement fine-tuning   </a> </li><li> <a href="/api/docs/guides/rft-use-cases" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> RFT use cases   </a> </li><li> <a href="/api/docs/guides/fine-tuning-best-practices" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Best practices   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Assistants API</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/assistants/migration" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Migration guide   </a> </li><li> <a href="/api/docs/assistants/deep-dive" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Deep dive   </a> </li><li> <a href="/api/docs/assistants/tools" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Tools   </a> </li> </ul> </details> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Resources </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="https://openai.com/policies" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover flex items-center justify-between gap-2" target="_blank" rel="noopener noreferrer" data-mobile-nav-link> Terms and policies  <svg viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg" class="w-2 h-2 inline-block ml-1 text-gray-600 dark:text-gray-300 " ><path d="M10.2426 0.757385C10.7949 0.757385 11.2426 1.2051 11.2426 1.75738V8.82845C11.2426 9.38074 10.7949 9.82845 10.2426 9.82845C9.69035 9.82845 9.24264 9.38074 9.24264 8.82845V4.1716L2.46446 10.9498C2.07394 11.3403 1.44077 11.3403 1.05025 10.9498C0.659724 10.5592 0.659723 9.92608 1.05025 9.53556L7.82842 2.75739H3.17157C2.61928 2.75739 2.17157 2.30967 2.17157 1.75738C2.17157 1.2051 2.61928 0.757385 3.17157 0.757385H10.2426Z" fill="currentColor"></path></svg> </a> </li><li> <a href="/api/docs/changelog" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Changelog   </a> </li><li> <a href="/api/docs/guides/your-data" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Your data   </a> </li><li> <a href="/api/docs/guides/rbac" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Permissions   </a> </li><li> <a href="/api/docs/guides/rate-limits" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Rate limits   </a> </li><li> <a href="/api/docs/guides/ip-addresses" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> IP egress ranges   </a> </li><li> <a href="/api/docs/guides/admin-apis" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Admin APIs   </a> </li><li> <a href="/api/docs/deprecations" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Deprecations   </a> </li><li> <a href="/api/docs/mcp" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> MCP for deep research   </a> </li><li> <a href="/api/docs/guides/developer-mode" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Developer mode   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">ChatGPT Actions</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/api/docs/actions/introduction" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Introduction   </a> </li><li> <a href="/api/docs/actions/getting-started" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Getting started   </a> </li><li> <a href="/api/docs/actions/actions-library" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Actions library   </a> </li><li> <a href="/api/docs/actions/authentication" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Authentication   </a> </li><li> <a href="/api/docs/actions/production" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Production   </a> </li><li> <a href="/api/docs/actions/data-retrieval" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Data retrieval   </a> </li><li> <a href="/api/docs/actions/sending-files" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Sending files   </a> </li> </ul> </details> </li> </ul> </div> </div> </div><div id="mobile-nav-panel-2" data-mobile-nav-content data-tab-id="mobile-nav-tab-2" data-default-variant-id="mobile-nav-tab-2-variant-0" hidden class="flex flex-col gap-4 pb-8 astro-3ef6ksr2"> <div class="group flex flex-col gap-1 astro-3ef6ksr2" data-mobile-context-options data-context-active="false"> <button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-2-variant-0" data-context-label="Docs" data-context-href="/codex" data-context-is-home="false" data-selected="true"> Docs </button><button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-2-variant-1" data-context-label="Use cases" data-context-href="/codex/use-cases" data-context-is-home="false" data-selected="false"> Use cases </button> </div> <div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-2-variant-0" class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Getting Started </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/codex/quickstart" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Quickstart   </a> </li><li> <a href="/codex/use-cases" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Explore use cases   </a> </li><li> <a href="/codex/import" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Import to Codex   </a> </li><li> <a href="/codex/pricing" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Pricing   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Concepts</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/prompting" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Prompting   </a> </li><li> <a href="/codex/concepts/customization" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Customization   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <a href="/codex/memories" class="flex-1 " data-mobile-nav-link> Memories  </a> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/memories/chronicle" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Chronicle   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <a href="/codex/concepts/sandboxing" class="flex-1 " data-mobile-nav-link> Sandboxing  </a> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/concepts/sandboxing/auto-review" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Auto-review   </a> </li> </ul> </details> </li><li> <a href="/codex/concepts/subagents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Subagents   </a> </li><li> <a href="/codex/workflows" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Workflows   </a> </li><li> <a href="/codex/models" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Models   </a> </li><li> <a href="/codex/concepts/cyber-safety" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Cyber Safety   </a> </li><li> <a href="/codex/glossary" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Glossary   </a> </li> </ul> </details> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Using Codex </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">App</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/app" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/codex/app/features" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Features   </a> </li><li> <a href="/codex/app/settings" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Settings   </a> </li><li> <a href="/codex/app/review" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Review   </a> </li><li> <a href="/codex/app/automations" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Automations   </a> </li><li> <a href="/codex/app/worktrees" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Worktrees   </a> </li><li> <a href="/codex/app/local-environments" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Local Environments   </a> </li><li> <a href="/codex/app/browser" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> In-app browser   </a> </li><li> <a href="/codex/app/chrome-extension" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Chrome extension   </a> </li><li> <a href="/codex/app/computer-use" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Computer Use   </a> </li><li> <a href="/codex/appshots" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Appshots   </a> </li><li> <a href="/codex/app/commands" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Commands   </a> </li><li> <a href="/codex/app/windows" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Windows   </a> </li><li> <a href="/codex/app/troubleshooting" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Troubleshooting   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">IDE Extension</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/ide" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/codex/ide/features" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Features   </a> </li><li> <a href="/codex/ide/settings" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Settings   </a> </li><li> <a href="/codex/ide/commands" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> IDE Commands   </a> </li><li> <a href="/codex/ide/slash-commands" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Slash commands   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">CLI</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/cli" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/codex/cli/features" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Features   </a> </li><li> <a href="/codex/cli/reference" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Command Line Options   </a> </li><li> <a href="/codex/cli/slash-commands" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Slash commands   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Web</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/cloud" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/codex/cloud/environments" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Environments   </a> </li><li> <a href="/codex/cloud/internet-access" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Internet Access   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Integrations</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/integrations/github" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> GitHub   </a> </li><li> <a href="/codex/integrations/slack" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Slack   </a> </li><li> <a href="/codex/integrations/linear" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Linear   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Codex Security</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/security" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Codex Security plugin</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/security/plugin" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Quickstart   </a> </li><li> <a href="/codex/security/plugin/scans" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Run a security scan   </a> </li><li> <a href="/codex/security/plugin/deep-scans" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Run a deep scan   </a> </li><li> <a href="/codex/security/plugin/code-changes" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Review code changes   </a> </li><li> <a href="/codex/security/plugin/triage-backlog" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Triage a backlog   </a> </li><li> <a href="/codex/security/plugin/fix-findings" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Fix findings   </a> </li><li> <a href="/codex/security/plugin/export-findings" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Export and track findings   </a> </li><li> <a href="/codex/security/plugin/changelog" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Changelog   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Codex Security cloud</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/security/setup" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Setup   </a> </li><li> <a href="/codex/security/threat-model" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Improving the threat model   </a> </li> </ul> </details> </li><li> <a href="/codex/security/faq" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> FAQ   </a> </li> </ul> </details> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Configuration </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Config File</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/config-basic" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Config Basics   </a> </li><li> <a href="/codex/config-advanced" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Advanced Config   </a> </li><li> <a href="/codex/config-reference" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Config Reference   </a> </li><li> <a href="/codex/environment-variables" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Environment Variables   </a> </li><li> <a href="/codex/config-sample" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Sample Config   </a> </li> </ul> </details> </li><li> <a href="/codex/permissions" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Permissions   </a> </li><li> <a href="/codex/speed" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Speed   </a> </li><li> <a href="/codex/rules" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Rules   </a> </li><li> <a href="/codex/hooks" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Hooks   </a> </li><li> <a href="/codex/guides/agents-md" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> AGENTS.md   </a> </li><li> <a href="/codex/mcp" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> MCP   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Plugins</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/plugins" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/codex/plugins/build" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Build plugins   </a> </li> </ul> </details> </li><li> <a href="/codex/sites" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Sites   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Skills</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/skills" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/codex/record-and-replay" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Record &amp; Replay   </a> </li> </ul> </details> </li><li> <a href="/codex/subagents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Subagents   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Administration </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Authentication</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/auth" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/codex/enterprise/access-tokens" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Access tokens   </a> </li> </ul> </details> </li><li> <a href="/codex/agent-approvals-security" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Agent approvals &amp; security   </a> </li><li> <a href="/codex/remote-connections" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Remote connections   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Deployment</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/amazon-bedrock" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Amazon Bedrock   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Enterprise</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/enterprise/admin-setup" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Admin Setup   </a> </li><li> <a href="/codex/enterprise/governance" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Governance   </a> </li><li> <a href="/codex/enterprise/managed-configuration" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Managed configuration   </a> </li> </ul> </details> </li><li> <a href="/codex/windows" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Windows   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Automation </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/noninteractive" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Non-interactive Mode   </a> </li><li> <a href="/codex/sdk" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Codex SDK   </a> </li><li> <a href="/codex/app-server" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> App Server   </a> </li><li> <a href="/codex/guides/agents-sdk" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> MCP Server   </a> </li><li> <a href="/codex/github-action" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> GitHub Action   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Learn </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/learn/best-practices" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Best practices   </a> </li><li> <a href="/codex/videos" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Videos   </a> </li><li> <a href="/community" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Community   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Blog</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/blog/mastering-codex-remote-for-engineering" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Mastering Codex Remote for engineering   </a> </li><li> <a href="/blog/skills-agents-sdk" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Using skills to accelerate OSS maintenance   </a> </li><li> <a href="/blog/topic/codex" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> View all   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-2 rounded-lg transition-colors flex items-center justify-between gap-2 hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1">Cookbooks</span> <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block text-secondary transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/cookbook/examples/agents_sdk/agent_improvement_loop" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Build an Agent Improvement Loop with Traces, Evals, and Codex   </a> </li><li> <a href="/cookbook/examples/codex/build_iterative_repair_loops_with_codex" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Build iterative repair loops with Codex   </a> </li><li> <a href="/cookbook/topic/codex" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> View all   </a> </li> </ul> </details> </li><li> <a href="/codex/guides/build-ai-native-engineering-team" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Building AI Teams   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Releases </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/changelog" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Changelog   </a> </li><li> <a href="/codex/feature-maturity" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Feature Maturity   </a> </li><li> <a href="/codex/open-source" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Open Source   </a> </li> </ul> </div> </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-2-variant-1" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/codex/use-cases" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Home   </a> </li><li> <a href="/codex/use-cases/collections" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Collections   </a> </li> </ul> </div> </div> </div><div id="mobile-nav-panel-3" data-mobile-nav-content data-tab-id="mobile-nav-tab-3" data-default-variant-id="mobile-nav-tab-3-variant-0" hidden class="flex flex-col gap-4 pb-8 astro-3ef6ksr2"> <div class="group flex flex-col gap-1 astro-3ef6ksr2" data-mobile-context-options data-context-active="false"> <button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-3-variant-1" data-context-label="Apps SDK" data-context-href="/apps-sdk" data-context-is-home="false" data-selected="false"> Apps SDK </button><button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-3-variant-2" data-context-label="Workspace Agents" data-context-href="/workspace-agents" data-context-is-home="false" data-selected="false"> Workspace Agents </button><button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-3-variant-3" data-context-label="Commerce" data-context-href="/commerce" data-context-is-home="false" data-selected="false"> Commerce </button><button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-3-variant-4" data-context-label="Ads" data-context-href="/ads" data-context-is-home="false" data-selected="false"> Ads </button> </div> <div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-3-variant-0" class="flex flex-col gap-6 astro-3ef6ksr2">  </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-3-variant-1" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/apps-sdk" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Home   </a> </li><li> <a href="/apps-sdk/quickstart" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Quickstart   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Core Concepts </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/apps-sdk/mcp-apps-in-chatgpt" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> MCP Apps in ChatGPT   </a> </li><li> <a href="/apps-sdk/concepts/mcp-server" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> MCP Server   </a> </li><li> <a href="/apps-sdk/concepts/ux-principles" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> UX principles   </a> </li><li> <a href="/apps-sdk/concepts/ui-guidelines" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> UI guidelines   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Plan </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/apps-sdk/plan/use-case" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Research use cases   </a> </li><li> <a href="/apps-sdk/plan/tools" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Define tools   </a> </li><li> <a href="/apps-sdk/plan/components" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Design components   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Build </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/apps-sdk/build/mcp-server" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Set up your server   </a> </li><li> <a href="/apps-sdk/build/chatgpt-ui" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Build your ChatGPT UI   </a> </li><li> <a href="/apps-sdk/build/auth" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Authenticate users   </a> </li><li> <a href="/apps-sdk/build/state-management" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Manage state   </a> </li><li> <a href="/apps-sdk/build/monetization" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Monetize your app   </a> </li><li> <a href="/apps-sdk/build/examples" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Examples   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Deploy </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/apps-sdk/deploy" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Deploy your app   </a> </li><li> <a href="/apps-sdk/deploy/connect-chatgpt" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Connect from ChatGPT   </a> </li><li> <a href="/apps-sdk/deploy/testing" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Test your integration   </a> </li><li> <a href="/apps-sdk/deploy/submission" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Submit your app   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Conversion apps </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/apps-sdk/guides/restaurant-reservation-conversion-spec" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Restaurant reservation spec   </a> </li><li> <a href="/apps-sdk/guides/product-checkout-conversion-spec" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Product checkout spec   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Guides </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/apps-sdk/guides/optimize-metadata" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Optimize Metadata   </a> </li><li> <a href="/apps-sdk/guides/security-privacy" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Security &amp; Privacy   </a> </li><li> <a href="/apps-sdk/deploy/troubleshooting" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Troubleshooting   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Resources </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/apps-sdk/changelog" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Changelog   </a> </li><li> <a href="/apps-sdk/app-submission-guidelines" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> App submission guidelines   </a> </li><li> <a href="/apps-sdk/reference" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Reference   </a> </li> </ul> </div> </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-3-variant-2" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/workspace-agents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Home   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Get started </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/workspace-agents/trigger-runs" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Trigger workspace agent runs   </a> </li><li> <a href="/workspace-agents/authentication" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Authenticate with Workspace Agent access tokens   </a> </li> </ul> </div> </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-3-variant-3" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/commerce" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Home   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Guides </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/commerce/guides/get-started" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Get started   </a> </li><li> <a href="/commerce/guides/best-practices" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Best practices   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> File Upload </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/commerce/specs/file-upload/overview" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/commerce/specs/file-upload/products" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Products   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> API </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/commerce/specs/api/overview" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/commerce/specs/api/feeds" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Feeds   </a> </li><li> <a href="/commerce/specs/api/products" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Products   </a> </li><li> <a href="/commerce/specs/api/promotions" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Promotions   </a> </li> </ul> </div> </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-3-variant-4" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/ads" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Ads Overview   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Measurement </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/ads/measurement-pixel" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> JavaScript Pixel   </a> </li><li> <a href="/ads/image-tag" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Image tag   </a> </li><li> <a href="/ads/conversions-api" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Conversions API   </a> </li><li> <a href="/ads/supported-events" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Supported events   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Advertiser API </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/ads/api-overview" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Overview   </a> </li><li> <a href="/ads/api-quickstart" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Quickstart   </a> </li><li> <a href="/ads/product-feeds" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Product feeds   </a> </li><li> <a href="/ads/campaign-targeting" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Campaign Targeting   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> API Reference </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/ads/api-reference/authentication" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Authentication   </a> </li><li> <a href="/ads/api-reference/campaigns" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Campaigns   </a> </li><li> <a href="/ads/api-reference/ad-groups" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Ad Groups   </a> </li><li> <a href="/ads/api-reference/ads" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Ads   </a> </li><li> <a href="/ads/api-reference/ad-account" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Ad Account   </a> </li><li> <a href="/ads/api-reference/insights" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Insights   </a> </li><li> <a href="/ads/api-reference/files" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Files   </a> </li> </ul> </div> </div> </div><div id="mobile-nav-panel-4" data-mobile-nav-content data-tab-id="mobile-nav-tab-4" data-default-variant-id="mobile-nav-tab-4-variant-0" hidden class="flex flex-col gap-4 pb-8 astro-3ef6ksr2"> <div class="group flex flex-col gap-1 astro-3ef6ksr2" data-mobile-context-options data-context-active="false"> <button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-4-variant-1" data-context-label="Showcase" data-context-href="/showcase" data-context-is-home="false" data-selected="false"> Showcase </button><button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-4-variant-2" data-context-label="Blog" data-context-href="/blog" data-context-is-home="false" data-selected="false"> Blog </button><button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-4-variant-3" data-context-label="Cookbook" data-context-href="/cookbook" data-context-is-home="false" data-selected="false"> Cookbook </button><button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-4-variant-4" data-context-label="Learn" data-context-href="/learn" data-context-is-home="false" data-selected="false"> Learn </button><button type="button" class="w-full rounded-lg px-3 py-2 text-left text-sm font-normal text-secondary transition-colors hover:bg-primary-ghost-hover hover:text-default data-[selected=true]:bg-primary-ghost-active data-[selected=true]:text-default group-data-[context-active=true]:font-semibold astro-3ef6ksr2" data-mobile-context-option data-context-id="mobile-nav-tab-4-variant-5" data-context-label="Community" data-context-href="/community" data-context-is-home="false" data-selected="false"> Community </button> </div> <div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-4-variant-0" class="flex flex-col gap-6 astro-3ef6ksr2">  </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-4-variant-1" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/showcase" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Home   </a> </li><li> <a href="/showcase/api-examples" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> API examples   </a> </li><li> <a href="/showcase/sites" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Sites   </a> </li> </ul> </div> </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-4-variant-2" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/blog" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> All posts   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Recent </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/blog/mastering-codex-remote-for-engineering" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Mastering Codex Remote for engineering   </a> </li><li> <a href="/blog/realtime-perplexity-computer" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> How Perplexity Brought Voice Search to Millions Using the Realtime API   </a> </li><li> <a href="/blog/designing-delightful-frontends-with-gpt-5-4" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Designing delightful frontends with GPT-5.4   </a> </li><li> <a href="/blog/one-year-of-responses" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> From prompts to products: One year of Responses   </a> </li><li> <a href="/blog/skills-agents-sdk" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Using skills to accelerate OSS maintenance   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Topics </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/blog/topic/general" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> General   </a> </li><li> <a href="/blog/topic/api" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> API   </a> </li><li> <a href="/blog/topic/apps-sdk" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Apps SDK   </a> </li><li> <a href="/blog/topic/audio" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Audio   </a> </li><li> <a href="/blog/topic/codex" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Codex   </a> </li> </ul> </div> </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-4-variant-3" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/cookbook" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Home   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Topics </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/cookbook/topic/agents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Agents   </a> </li><li> <a href="/cookbook/topic/evals" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Evals   </a> </li><li> <a href="/cookbook/topic/multimodal" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Multimodal   </a> </li><li> <a href="/cookbook/topic/text" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Text   </a> </li><li> <a href="/cookbook/topic/guardrails" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Guardrails   </a> </li><li> <a href="/cookbook/topic/optimization" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Optimization   </a> </li><li> <a href="/cookbook/topic/chatgpt" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> ChatGPT   </a> </li><li> <a href="/cookbook/topic/codex" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Codex   </a> </li><li> <a href="/cookbook/topic/gpt-oss" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> gpt-oss   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Contribute </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="https://github.com/openai/openai-cookbook" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover flex items-center justify-between gap-2" target="_blank" rel="noopener noreferrer" data-mobile-nav-link> Cookbook on GitHub  <svg viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg" class="w-2 h-2 inline-block ml-1 text-gray-600 dark:text-gray-300 " ><path d="M10.2426 0.757385C10.7949 0.757385 11.2426 1.2051 11.2426 1.75738V8.82845C11.2426 9.38074 10.7949 9.82845 10.2426 9.82845C9.69035 9.82845 9.24264 9.38074 9.24264 8.82845V4.1716L2.46446 10.9498C2.07394 11.3403 1.44077 11.3403 1.05025 10.9498C0.659724 10.5592 0.659723 9.92608 1.05025 9.53556L7.82842 2.75739H3.17157C2.61928 2.75739 2.17157 2.30967 2.17157 1.75738C2.17157 1.2051 2.61928 0.757385 3.17157 0.757385H10.2426Z" fill="currentColor"></path></svg> </a> </li> </ul> </div> </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-4-variant-4" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/learn" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Home   </a> </li><li> <a href="/learn/developers-codex-plugin" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> OpenAI Developers plugin   </a> </li><li> <a href="/learn/docs-mcp" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Docs MCP   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Categories </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/learn/code" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Demo apps   </a> </li><li> <a href="/learn/videos" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Videos   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Topics </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/learn/agents" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Agents   </a> </li><li> <a href="/learn/audio" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Audio &amp; Voice   </a> </li><li> <a href="/learn/cua" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Computer Use   </a> </li><li> <a href="/learn/codex" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Codex   </a> </li><li> <a href="/learn/evals" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Evals   </a> </li><li> <a href="/learn/gpt-oss" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> gpt-oss   </a> </li><li> <a href="/learn/fine-tuning" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Fine-tuning   </a> </li><li> <a href="/learn/imagegen" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Image generation   </a> </li><li> <a href="/learn/scaling" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Scaling   </a> </li><li> <a href="/learn/tools" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Tools   </a> </li><li> <a href="/learn/videogen" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Video generation   </a> </li> </ul> </div> </div><div data-mobile-nav-variant-content data-variant-id="mobile-nav-tab-4-variant-5" hidden class="flex flex-col gap-6 astro-3ef6ksr2"> <div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/community" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Community   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Programs </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/community/codex-ambassadors" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Codex Ambassadors   </a> </li><li> <a href="/community/students" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Codex for Students   </a> </li><li> <a href="/community/codex-for-oss" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Codex for Open Source   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2"> <h3 class="text-xs tracking-wide text-secondary astro-3ef6ksr2"> Events </h3> <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="/community/meetups" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Meetups   </a> </li><li> <a href="/community/hackathons" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover " data-mobile-nav-link> Hackathon Support   </a> </li> </ul> </div><div class="flex flex-col gap-3 astro-3ef6ksr2">  <ul class="flex flex-col gap-1 text-sm text-default w-full"> <li> <a href="https://community.openai.com/" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover flex items-center justify-between gap-2" target="_blank" rel="noopener noreferrer" data-mobile-nav-link> Forum  <svg viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg" class="w-2 h-2 inline-block ml-1 text-gray-600 dark:text-gray-300 " ><path d="M10.2426 0.757385C10.7949 0.757385 11.2426 1.2051 11.2426 1.75738V8.82845C11.2426 9.38074 10.7949 9.82845 10.2426 9.82845C9.69035 9.82845 9.24264 9.38074 9.24264 8.82845V4.1716L2.46446 10.9498C2.07394 11.3403 1.44077 11.3403 1.05025 10.9498C0.659724 10.5592 0.659723 9.92608 1.05025 9.53556L7.82842 2.75739H3.17157C2.61928 2.75739 2.17157 2.30967 2.17157 1.75738C2.17157 1.2051 2.61928 0.757385 3.17157 0.757385H10.2426Z" fill="currentColor"></path></svg> </a> </li><li> <a href="https://discord.com/invite/openai" class="px-3 py-1.5 rounded-lg transition-colors block hover:text-default hover:bg-primary-ghost-hover flex items-center justify-between gap-2" target="_blank" rel="noopener noreferrer" data-mobile-nav-link> Discord  <svg viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg" class="w-2 h-2 inline-block ml-1 text-gray-600 dark:text-gray-300 " ><path d="M10.2426 0.757385C10.7949 0.757385 11.2426 1.2051 11.2426 1.75738V8.82845C11.2426 9.38074 10.7949 9.82845 10.2426 9.82845C9.69035 9.82845 9.24264 9.38074 9.24264 8.82845V4.1716L2.46446 10.9498C2.07394 11.3403 1.44077 11.3403 1.05025 10.9498C0.659724 10.5592 0.659723 9.92608 1.05025 9.53556L7.82842 2.75739H3.17157C2.61928 2.75739 2.17157 2.30967 2.17157 1.75738C2.17157 1.2051 2.61928 0.757385 3.17157 0.757385H10.2426Z" fill="currentColor"></path></svg> </a> </li> </ul> </div> </div> </div> </div> <div class="w-full px-6 py-6 border-t border-primary-surface astro-3ef6ksr2"> <div class="flex flex-col gap-5 astro-3ef6ksr2"> <div class="flex items-center gap-2 w-full gap-3 astro-3ef6ksr2"><a target="_blank" rel="noopener noreferrer" href="https://platform.openai.com/login" class="_Button_6dmow_1 not-prose flex-1 justify-center" data-color="primary" data-variant="solid" data-pill="" data-size="md"><span class="_ButtonInner_6dmow_4"><span class="">API Dashboard</span><svg width="1em" height="1em" viewBox="0 0 24 24" fill="currentColor" class="shrink-0"><path fill-rule="evenodd" d="M16.243 6.757a1 1 0 0 1 1 1v7.072a1 1 0 0 1-2 0v-4.657L8.464 16.95a1 1 0 0 1-1.414-1.414l6.778-6.779H9.172a1 1 0 0 1 0-2h7.07Z" clip-rule="evenodd"></path></svg></span></a></div> <div class="flex flex-wrap items-center gap-4 text-sm text-gray-700 dark:text-gray-300 astro-3ef6ksr2">  </div> </div> </div> </div> </div>  <script>
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
</script> <div data-docs-agent-page class="min-h-dvh"> <div class="flex pt-16"> <div class="hidden md:flex md:flex-col w-[218px] px-3 pb-6 pt-2 md:fixed md:top-16 md:bottom-0 md:z-40 bg-surface dark:bg-black astro-73gi4scu" data-left-nav-container><nav class="flex-1 overflow-y-auto overflow-x-visible astro-73gi4scu" data-left-nav data-left-nav-id="/api/docs"><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Get started</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="/api/docs" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Overview </span>   </a> </li><li> <a href="/api/docs/quickstart" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Quickstart </span>   </a> </li><li> <a href="/api/docs/models" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Models </span>   </a> </li><li> <a href="/api/docs/pricing" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Pricing </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <a href="/api/docs/libraries" class="flex-1 min-w-0 "> <span class="line-clamp-2 "> SDKs and CLI </span>  </a>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/libraries" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> OpenAI SDK </span>   </a> </li><li> <a href="/api/docs/guides/agents" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Agents SDK </span>   </a> </li><li> <a href="/api/docs/libraries/openai-cli" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> OpenAI CLI </span>   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/latest-model" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Latest: GPT-5.5 </span>   </a> </li><li> <a href="/api/docs/guides/prompt-guidance" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Prompt guidance </span>   </a> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Core concepts</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="/api/docs/guides/text" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Text generation </span>   </a> </li><li> <a href="/api/docs/guides/code-generation" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Code generation </span>   </a> </li><li> <a href="/api/docs/guides/images-vision" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Images and vision </span>   </a> </li><li> <a href="/api/docs/guides/audio" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Audio and speech </span>   </a> </li><li> <a href="/api/docs/guides/structured-outputs" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Structured output </span>   </a> </li><li> <a href="/api/docs/guides/function-calling" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Function calling </span>   </a> </li><li> <a href="/api/docs/guides/migrate-to-responses" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Responses API </span>   </a> </li><li> <a href="/api/docs/guides/tools" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Using tools </span>   </a> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Agents SDK</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="/api/docs/guides/agents" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Overview </span>   </a> </li><li> <a href="/api/docs/guides/agents/quickstart" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Quickstart </span>   </a> </li><li> <a href="/api/docs/guides/agents/define-agents" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Agent definitions </span>   </a> </li><li> <a href="/api/docs/guides/agents/models" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Models and providers </span>   </a> </li><li> <a href="/api/docs/guides/agents/running-agents" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Running agents </span>   </a> </li><li> <a href="/api/docs/guides/agents/sandboxes" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Sandbox agents </span>   </a> </li><li> <a href="/api/docs/guides/agents/orchestration" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Orchestration </span>   </a> </li><li> <a href="/api/docs/guides/agents/guardrails-approvals" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Guardrails </span>   </a> </li><li> <a href="/api/docs/guides/agents/results" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Results and state </span>   </a> </li><li> <a href="/api/docs/guides/agents/integrations-observability" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Integrations and observability </span>   </a> </li><li> <a href="/api/docs/guides/agent-evals" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Evaluate agent workflows </span>   </a> </li><li> <a href="/api/docs/guides/voice-agents" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Voice agents </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">ChatKit</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/chatkit" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Overview </span>   </a> </li><li> <a href="/api/docs/guides/chatkit-themes" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Customize </span>   </a> </li><li> <a href="/api/docs/guides/chatkit-widgets" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Widgets </span>   </a> </li><li> <a href="/api/docs/guides/chatkit-actions" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Actions </span>   </a> </li><li> <a href="/api/docs/guides/custom-chatkit" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Advanced integrations </span>   </a> </li> </ul> </details> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Tools</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="/api/docs/guides/tools-web-search" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Web search </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <a href="/api/docs/guides/tools-connectors-mcp" class="flex-1 min-w-0 "> <span class="line-clamp-2 "> MCP and Connectors </span>  </a>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/secure-mcp-tunnels" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Secure MCP Tunnel </span>   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/tools-skills" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Skills </span>   </a> </li><li> <a href="/api/docs/guides/tools-shell" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Shell </span>   </a> </li><li> <a href="/api/docs/guides/tools-computer-use" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Computer use </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">File search and retrieval</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/tools-file-search" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> File search </span>   </a> </li><li> <a href="/api/docs/guides/retrieval" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Retrieval </span>   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/tools-tool-search" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Tool search </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">More tools</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/tools-apply-patch" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Apply Patch </span>   </a> </li><li> <a href="/api/docs/guides/tools-local-shell" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Local shell </span>   </a> </li><li> <a href="/api/docs/guides/tools-image-generation" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Image generation </span>   </a> </li><li> <a href="/api/docs/guides/tools-code-interpreter" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Code interpreter </span>   </a> </li> </ul> </details> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Run and scale</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="/api/docs/guides/conversation-state" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Conversation state </span>   </a> </li><li> <a href="/api/docs/guides/background" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Background mode </span>   </a> </li><li> <a href="/api/docs/guides/streaming-responses" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Streaming </span>   </a> </li><li> <a href="/api/docs/guides/websocket-mode" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> WebSocket mode </span>   </a> </li><li> <a href="/api/docs/guides/webhooks" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Webhooks </span>   </a> </li><li> <a href="/api/docs/guides/file-inputs" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> File inputs </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Context management</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/compaction" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Compaction </span>   </a> </li><li> <a href="/api/docs/guides/token-counting" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Counting tokens </span>   </a> </li><li> <a href="/api/docs/guides/prompt-caching" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Prompt caching </span>   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Prompting</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/prompting" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Overview </span>   </a> </li><li> <a href="/api/docs/guides/prompt-engineering" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Prompt engineering </span>   </a> </li><li> <a href="/api/docs/guides/citation-formatting" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Citation formatting </span>   </a> </li><li> <a href="/api/docs/guides/prompting/migrate-from-prompt-object" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Migration guide </span>   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Reasoning</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/reasoning" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Reasoning models </span>   </a> </li><li> <a href="/api/docs/guides/reasoning-best-practices" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Reasoning best practices </span>   </a> </li> </ul> </details> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Evaluation</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="/api/docs/guides/red-teaming" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Red teaming </span>   </a> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Realtime and audio</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="/api/docs/guides/realtime" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block bg-primary-ghost-hover "> <span class="line-clamp-2 "> Overview </span>   </a> </li><li> <a href="/api/docs/guides/voice-agents" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Voice agents </span>   </a> </li><li> <a href="/api/docs/guides/realtime-translation" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Live translation </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Transcription</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/realtime-transcription" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Realtime transcription </span>   </a> </li><li> <a href="/api/docs/guides/speech-to-text" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Speech to text </span>   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/text-to-speech" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Speech generation </span>   </a> </li><li> <a href="/api/docs/guides/realtime-models-prompting" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Realtime prompting guide </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Connection methods</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/realtime-webrtc" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> WebRTC </span>   </a> </li><li> <a href="/api/docs/guides/realtime-websocket" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> WebSocket </span>   </a> </li><li> <a href="/api/docs/guides/realtime-sip" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> SIP </span>   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Realtime sessions</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/realtime-conversations" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Managing conversations </span>   </a> </li><li> <a href="/api/docs/guides/realtime-vad" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Voice activity detection </span>   </a> </li><li> <a href="/api/docs/guides/realtime-mcp" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Realtime with tools </span>   </a> </li><li> <a href="/api/docs/guides/realtime-server-controls" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Webhooks and server-side controls </span>   </a> </li><li> <a href="/api/docs/guides/realtime-costs" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Managing costs </span>   </a> </li> </ul> </details> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Specialized models</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="/api/docs/guides/image-generation" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Image generation </span>   </a> </li><li> <a href="/api/docs/guides/video-generation" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Video generation </span>   </a> </li><li> <a href="/api/docs/guides/deep-research" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Deep research </span>   </a> </li><li> <a href="/api/docs/guides/embeddings" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Embeddings </span>   </a> </li><li> <a href="/api/docs/guides/moderation" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Moderation </span>   </a> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Going live</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="/api/docs/guides/production-best-practices" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Production best practices </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <a href="/api/docs/guides/workload-identity-federation" class="flex-1 min-w-0 "> <span class="line-clamp-2 "> Workload identity federation </span>  </a>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/workload-identity-federation" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Overview </span>   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/kubernetes" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Kubernetes </span>   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/aws" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> AWS </span>   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/microsoft-azure" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Microsoft Azure </span>   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/google-cloud" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Google Cloud </span>   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/github-actions" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> GitHub Actions </span>   </a> </li><li> <a href="/api/docs/guides/workload-identity-federation/spiffe" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> SPIFFE </span>   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/deployment-checklist" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Deployment checklist </span>   </a> </li><li> <a href="/api/docs/guides/amazon-bedrock" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Amazon Bedrock </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Latency optimization</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/latency-optimization" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Overview </span>   </a> </li><li> <a href="/api/docs/guides/predicted-outputs" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Predicted Outputs </span>   </a> </li><li> <a href="/api/docs/guides/priority-processing" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Priority processing </span>   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Cost optimization</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/cost-optimization" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Overview </span>   </a> </li><li> <a href="/api/docs/guides/batch" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Batch </span>   </a> </li><li> <a href="/api/docs/guides/flex-processing" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Flex processing </span>   </a> </li> </ul> </details> </li><li> <a href="/api/docs/guides/optimizing-llm-accuracy" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Accuracy optimization </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Safety</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/safety-best-practices" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Safety best practices </span>   </a> </li><li> <a href="/api/docs/guides/safety-checks" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Safety checks </span>   </a> </li><li> <a href="/api/docs/guides/safety-checks/cybersecurity" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Cybersecurity checks </span>   </a> </li><li> <a href="/api/docs/guides/safety-checks/under-18-api-guidance" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Under 18 API Guidance </span>   </a> </li> </ul> </details> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Legacy APIs</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Agent Builder</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/agent-builder" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Overview </span>   </a> </li><li> <a href="/api/docs/guides/agent-builder/migrate-from-agent-builder" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Migration guide </span>   </a> </li><li> <a href="/api/docs/guides/node-reference" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Node reference </span>   </a> </li><li> <a href="/api/docs/guides/agent-builder-safety" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Safety in building agents </span>   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Evals</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/evaluation-getting-started" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Getting started </span>   </a> </li><li> <a href="/api/docs/guides/evals" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Working with evals </span>   </a> </li><li> <a href="/api/docs/guides/prompt-optimizer" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Prompt optimizer </span>   </a> </li><li> <a href="/api/docs/guides/external-models" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> External models </span>   </a> </li><li> <a href="/api/docs/guides/evaluation-best-practices" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Best practices </span>   </a> </li><li> <a href="/api/docs/guides/graders" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Graders </span>   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Fine-tuning</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/guides/model-optimization" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Optimization cycle </span>   </a> </li><li> <a href="/api/docs/guides/supervised-fine-tuning" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Supervised fine-tuning </span>   </a> </li><li> <a href="/api/docs/guides/vision-fine-tuning" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Vision fine-tuning </span>   </a> </li><li> <a href="/api/docs/guides/direct-preference-optimization" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Direct preference optimization </span>   </a> </li><li> <a href="/api/docs/guides/reinforcement-fine-tuning" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Reinforcement fine-tuning </span>   </a> </li><li> <a href="/api/docs/guides/rft-use-cases" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> RFT use cases </span>   </a> </li><li> <a href="/api/docs/guides/fine-tuning-best-practices" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Best practices </span>   </a> </li> </ul> </details> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">Assistants API</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/assistants/migration" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Migration guide </span>   </a> </li><li> <a href="/api/docs/assistants/deep-dive" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Deep dive </span>   </a> </li><li> <a href="/api/docs/assistants/tools" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Tools </span>   </a> </li> </ul> </details> </li> </ul></div><div class=" astro-73gi4scu"><h3 class="mb-2 ml-3 mt-6 text-sm font-semibold select-none astro-73gi4scu">Resources</h3><ul class="flex flex-col gap-0.25 text-sm text-default w-full"> <li> <a href="https://openai.com/policies" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover flex items-center justify-between gap-1" target="_blank" rel="noopener noreferrer"> <span class="line-clamp-2 min-w-0 flex-1"> Terms and policies </span> <svg viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg" class="w-2 h-2 inline-block shrink-0 text-current " ><path d="M10.2426 0.757385C10.7949 0.757385 11.2426 1.2051 11.2426 1.75738V8.82845C11.2426 9.38074 10.7949 9.82845 10.2426 9.82845C9.69035 9.82845 9.24264 9.38074 9.24264 8.82845V4.1716L2.46446 10.9498C2.07394 11.3403 1.44077 11.3403 1.05025 10.9498C0.659724 10.5592 0.659723 9.92608 1.05025 9.53556L7.82842 2.75739H3.17157C2.61928 2.75739 2.17157 2.30967 2.17157 1.75738C2.17157 1.2051 2.61928 0.757385 3.17157 0.757385H10.2426Z" fill="currentColor"></path></svg>  </a> </li><li> <a href="/api/docs/changelog" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Changelog </span>   </a> </li><li> <a href="/api/docs/guides/your-data" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Your data </span>   </a> </li><li> <a href="/api/docs/guides/rbac" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Permissions </span>   </a> </li><li> <a href="/api/docs/guides/rate-limits" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Rate limits </span>   </a> </li><li> <a href="/api/docs/guides/ip-addresses" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> IP egress ranges </span>   </a> </li><li> <a href="/api/docs/guides/admin-apis" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Admin APIs </span>   </a> </li><li> <a href="/api/docs/deprecations" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Deprecations </span>   </a> </li><li> <a href="/api/docs/mcp" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> MCP for deep research </span>   </a> </li><li> <a href="/api/docs/guides/developer-mode" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Developer mode </span>   </a> </li><li> <details class="nav-disclosure"> <summary class="list-none cursor-pointer select-none px-3 py-1.5 w-full rounded-[8px] transition-colors text-default pl-5 flex items-center justify-between hover:text-default hover:bg-primary-ghost-hover"> <span class="flex-1 min-w-0 line-clamp-2">ChatGPT Actions</span>  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="nav-disclosure-chevron w-3 h-3 inline-block ml-1 text-current transition-transform duration-150 " aria-hidden="true" ><path d="M8.29289 4.29289C8.68342 3.90237 9.31658 3.90237 9.70711 4.29289L16.7071 11.2929C17.0976 11.6834 17.0976 12.3166 16.7071 12.7071L9.70711 19.7071C9.31658 20.0976 8.68342 20.0976 8.29289 19.7071C7.90237 19.3166 7.90237 18.6834 8.29289 18.2929L14.5858 12L8.29289 5.70711C7.90237 5.31658 7.90237 4.68342 8.29289 4.29289Z" fill="currentColor"></path></svg> </summary> <ul class="mt-1 ml-3 max-w-[calc(100%-theme(spacing.3))] flex flex-col gap-0.5 text-sm text-default w-full mb-2 "> <li> <a href="/api/docs/actions/introduction" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Introduction </span>   </a> </li><li> <a href="/api/docs/actions/getting-started" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Getting started </span>   </a> </li><li> <a href="/api/docs/actions/actions-library" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Actions library </span>   </a> </li><li> <a href="/api/docs/actions/authentication" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Authentication </span>   </a> </li><li> <a href="/api/docs/actions/production" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Production </span>   </a> </li><li> <a href="/api/docs/actions/data-retrieval" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Data retrieval </span>   </a> </li><li> <a href="/api/docs/actions/sending-files" class="px-3 py-1.5 w-full rounded-[8px] transition-colors text-default block hover:text-default hover:bg-primary-ghost-hover "> <span class="line-clamp-2 "> Sending files </span>   </a> </li> </ul> </details> </li> </ul></div></nav></div><script>
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
</script> <main class="min-w-0 flex-1 md:pl-[240px]"> <div class="page-container md:max-w-6xl pb-12 pt-0" data-content-page-container> <div class="mx-auto md:w-full grid grid-cols-1 gap-12 max-w-7xl xl:grid-cols-[minmax(0,1fr)_200px]"> <div data-content-page-toc-rail class="hidden xl:flex fixed right-8 top-[6rem] z-30 w-[200px] h-[calc(100vh-6rem)] max-h-[calc(100vh-6rem)] flex-col pb-6"> <div class="mb-4 shrink-0">  </div> <script>window._$HY||(e=>{let t=e=>e&&e.hasAttribute&&(e.hasAttribute("data-hk")?e:t(e.host&&e.host.nodeType?e.host:e.parentNode));["click", "input"].forEach((o=>document.addEventListener(o,(o=>{if(!e.events)return;let s=t(o.composedPath&&o.composedPath()[0]||o.target);s&&!e.completed.has(s)&&e.events.push([s,o])}))))})(_$HY={events:[],completed:new WeakSet,r:{},fe(){}});</script><!--xs--><astro-island uid="1LnebC" data-solid-render-id="s0" component-url="/_astro/TableOfContents.CkwfG4zx.js" component-export="default" renderer-url="/_astro/client.DjvmFpsL.js" props="{&quot;variant&quot;:[0,&quot;static&quot;],&quot;targetSelector&quot;:[0,&quot;#mainContent&quot;],&quot;headingSelector&quot;:[0,&quot;h2&quot;],&quot;class&quot;:[0,&quot;flex-1 min-h-0 overflow-y-auto pr-1&quot;]}" ssr client="load" opts="{&quot;name&quot;:&quot;TableOfContents&quot;,&quot;value&quot;:true}" await-children><nav data-hk="s00000" class="hidden xl:block w-full overflow-y-auto flex-1 min-h-0 overflow-y-auto pr-1"><div class="relative"><div class="absolute left-0 top-0 bottom-0 w-[2.15px] bg-primary-soft"></div><div class="absolute left-0 w-[2.15px] bg-primary-solid transition-transform duration-200 ease-out" style="transform:translateY(0);height:0px"></div><ul class="relative list-none p-0 m-0 ml-3 [&amp;>*+*]:mt-3"></ul></div></nav><!--astro:end--></astro-island> <div class="mt-6 flex flex-col gap-3"> <a href="/api/docs/guides/voice-agents" class="group rounded-xl border border-subtle bg-surface px-3 py-3 transition-colors hover:border-primary-outline"> <div class="flex items-start gap-3"> <div class="mt-0.5 text-tertiary transition-colors group-hover:text-secondary [&>svg]:h-4 [&>svg]:w-4"> <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" viewBox="3 3 18 18" ><path fill-rule="evenodd" d="M16.243 6.757a1 1 0 0 1 1 1v7.072a1 1 0 0 1-2 0v-4.657L8.464 16.95a1 1 0 0 1-1.414-1.414l6.778-6.779H9.172a1 1 0 0 1 0-2h7.07Z" clip-rule="evenodd"></path></svg> </div> <div class="flex-1"> <p class="text-sm font-medium text-default"> Build voice agents </p> <p class="mt-1 text-xs text-tertiary"> Build voice agents in the browser. </p> </div> </div> </a> </div> <div class="mt-4 shrink-0"> <button type="button" class="page-copy-action astro-y3m22efp" data-page-copy-action data-page-copy-default-label="Copy Page" data-page-copy-copied-label="Copied"> <span class="page-copy-action__icon page-copy-action__icon--copy astro-y3m22efp" aria-hidden="true"> <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" viewBox="0 0 24 24" class="astro-y3m22efp " ><path fill-rule="evenodd" d="M7 5a3 3 0 0 1 3-3h9a3 3 0 0 1 3 3v9a3 3 0 0 1-3 3h-2v2a3 3 0 0 1-3 3H5a3 3 0 0 1-3-3v-9a3 3 0 0 1 3-3h2V5Zm2 2h5a3 3 0 0 1 3 3v5h2a1 1 0 0 0 1-1V5a1 1 0 0 0-1-1h-9a1 1 0 0 0-1 1v2ZM5 9a1 1 0 0 0-1 1v9a1 1 0 0 0 1 1h9a1 1 0 0 0 1-1v-9a1 1 0 0 0-1-1H5Z" clip-rule="evenodd"></path></svg> </span> <span class="page-copy-action__icon page-copy-action__icon--check astro-y3m22efp" aria-hidden="true"> <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" viewBox="0 0 24 24" class="astro-y3m22efp " ><path fill-rule="evenodd" d="M18.063 5.674a1 1 0 0 1 .263 1.39l-7.5 11a1 1 0 0 1-1.533.143l-4.5-4.5a1 1 0 1 1 1.414-1.414l3.647 3.647 6.82-10.003a1 1 0 0 1 1.39-.263Z" clip-rule="evenodd"></path></svg> </span> <span data-page-copy-label class="astro-y3m22efp">Copy Page</span> </button> <script type="module" src="/_astro/PageCopyAction.astro_astro_type_script_index_0_lang.Df1nqr2j.js"></script> </div> </div> <div class="flex flex-col relative">  <div class="flex flex-col gap-8 mb-2"> <div class="w-full max-w-xs xl:hidden mb-6">  </div> <header class="flex flex-col not-prose gap-1 pt-20 items-start text-left"> <div class="w-full">  </div> <h1 class="heading-2xl md:heading-2xl"> Realtime and audio </h1> <p class="text-lg text-secondary">Choose the right path for voice agents, translation, transcription, and speech generation.</p> <div class="w-full"> <div class="flex w-full flex-wrap items-center gap-3 justify-start">  <button type="button" class="page-copy-action astro-y3m22efp" data-page-copy-action data-page-copy-default-label="Copy Page" data-page-copy-copied-label="Copied"> <span class="page-copy-action__icon page-copy-action__icon--copy astro-y3m22efp" aria-hidden="true"> <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" viewBox="0 0 24 24" class="astro-y3m22efp " ><path fill-rule="evenodd" d="M7 5a3 3 0 0 1 3-3h9a3 3 0 0 1 3 3v9a3 3 0 0 1-3 3h-2v2a3 3 0 0 1-3 3H5a3 3 0 0 1-3-3v-9a3 3 0 0 1 3-3h2V5Zm2 2h5a3 3 0 0 1 3 3v5h2a1 1 0 0 0 1-1V5a1 1 0 0 0-1-1h-9a1 1 0 0 0-1 1v2ZM5 9a1 1 0 0 0-1 1v9a1 1 0 0 0 1 1h9a1 1 0 0 0 1-1v-9a1 1 0 0 0-1-1H5Z" clip-rule="evenodd"></path></svg> </span> <span class="page-copy-action__icon page-copy-action__icon--check astro-y3m22efp" aria-hidden="true"> <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" viewBox="0 0 24 24" class="astro-y3m22efp " ><path fill-rule="evenodd" d="M18.063 5.674a1 1 0 0 1 .263 1.39l-7.5 11a1 1 0 0 1-1.533.143l-4.5-4.5a1 1 0 1 1 1.414-1.414l3.647 3.647 6.82-10.003a1 1 0 0 1 1.39-.263Z" clip-rule="evenodd"></path></svg> </span> <span data-page-copy-label class="astro-y3m22efp">Copy Page</span> </button>  </div> </div> </header>  </div> <article id="mainContent" class="prose prose-content dark:prose-invert max-w-none pt-4 pb-0"> <p>Start with the outcome you want to build. Realtime sessions are best for live audio that needs low latency. Request-based audio APIs are best for files, bounded requests, or generated speech that doesn’t need a live session.</p>
<h2 id="common-use-cases" class="group flex items-center gap-2 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">Common use cases</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="common-use-cases" aria-label="Copy link to common use cases" title="Copy link to common use cases"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h2>
<div class="w-full max-w-full overflow-hidden"><div class="not-prose grid w-full grid-cols-1 gap-4 md:grid-cols-4"><a href="/api/docs/guides/voice-agents" class="_DocLink_106al_1"><div class="flex flex-col gap-3"><div class="relative max-h-[300px] min-h-[140px] w-full overflow-hidden rounded-lg"><img src="https://cdn.openai.com/API/docs/images/voice-agents-rounded.png" alt="Voice agents" class="h-full w-full object-cover"/><div class="absolute top-0 left-0 flex h-full w-full items-center justify-center"></div></div><div class="flex w-full flex-col"><div class="text-sm font-semibold">Voice agents</div><div class="text-xs text-secondary">Build speech-to-speech agents that listen, reason, speak, and call tools.</div></div></div></a><a href="/api/docs/guides/realtime-translation" class="_DocLink_106al_1"><div class="flex flex-col gap-3"><div class="relative max-h-[300px] min-h-[140px] w-full overflow-hidden rounded-lg"><img src="/images/platform/guides/realtime-live-translation.png" alt="Live translation" class="h-full w-full object-cover"/><div class="absolute top-0 left-0 flex h-full w-full items-center justify-center"></div></div><div class="flex w-full flex-col"><div class="text-sm font-semibold">Live translation</div><div class="text-xs text-secondary">Translate live speech with a dedicated realtime translation session.</div></div></div></a><a href="/api/docs/guides/realtime-transcription" class="_DocLink_106al_1"><div class="flex flex-col gap-3"><div class="relative max-h-[300px] min-h-[140px] w-full overflow-hidden rounded-lg"><img src="https://cdn.openai.com/API/docs/images/stt-rounded.png" alt="Transcription" class="h-full w-full object-cover"/><div class="absolute top-0 left-0 flex h-full w-full items-center justify-center"></div></div><div class="flex w-full flex-col"><div class="text-sm font-semibold">Transcription</div><div class="text-xs text-secondary">Stream live transcript deltas or process audio files into text.</div></div></div></a><a href="/api/docs/guides/text-to-speech" class="_DocLink_106al_1"><div class="flex flex-col gap-3"><div class="relative max-h-[300px] min-h-[140px] w-full overflow-hidden rounded-lg"><img src="https://cdn.openai.com/API/docs/images/tts-rounded.png" alt="Speech generation" class="h-full w-full object-cover"/><div class="absolute top-0 left-0 flex h-full w-full items-center justify-center"></div></div><div class="flex w-full flex-col"><div class="text-sm font-semibold">Speech generation</div><div class="text-xs text-secondary">Turn text into natural-sounding spoken audio.</div></div></div></a></div></div>
<h2 id="understand-different-architectures" class="group flex items-center gap-2 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">Understand different architectures</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="understand-different-architectures" aria-label="Copy link to understand different architectures" title="Copy link to understand different architectures"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h2>
<table><thead><tr><th>Goal</th><th>Model or API</th><th>Start here</th></tr></thead><tbody><tr><td>Build a low-latency voice agent</td><td class="whitespace-nowrap"><a href="/api/docs/models/gpt-realtime-2"><code>gpt-realtime-2</code></a></td><td><a href="/api/docs/guides/voice-agents">Voice agents</a></td></tr><tr><td>Translate live speech into another language</td><td class="whitespace-nowrap"><a href="/api/docs/models/gpt-realtime-translate"><code>gpt-realtime-translate</code></a></td><td><a href="/api/docs/guides/realtime-translation">Realtime translation</a></td></tr><tr><td>Transcribe live audio into streaming text</td><td class="whitespace-nowrap"><a href="/api/docs/models/gpt-realtime-whisper"><code>gpt-realtime-whisper</code></a></td><td><a href="/api/docs/guides/realtime-transcription"><p>Realtime transcription</p></a></td></tr><tr><td>Transcribe files or bounded audio requests</td><td>Audio transcription models</td><td><a href="/api/docs/guides/speech-to-text">Speech to text</a></td></tr><tr><td>Generate speech from text</td><td>Speech generation models</td><td><a href="/api/docs/guides/text-to-speech">Text to speech</a></td></tr><tr><td>Add audio to an existing Chat Completions app</td><td>Audio-capable chat models</td><td><a href="/api/docs/guides/audio#add-audio-to-your-existing-application"><p>Audio and speech</p></a></td></tr></tbody></table>
<h2 id="choose-a-realtime-session" class="group flex items-center gap-2 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">Choose a realtime session</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="choose-a-realtime-session" aria-label="Copy link to choose a realtime session" title="Copy link to choose a realtime session"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h2>
<p>Realtime sessions keep a connection open while your application sends audio, receives events, and updates session state.</p>
<table><thead><tr><th>Session type</th><th>Use when</th><th>Endpoint or pattern</th></tr></thead><tbody><tr><td>Voice-agent session</td><td><p>The model should respond to the user, call tools, and manage
conversation state.</p></td><td><p>Conversation session on <code>/v1/realtime</code></p></td></tr><tr><td>Translation session</td><td>The app should continuously translate speech as it arrives.</td><td><p>Continuous translation session on <code>/v1/realtime/translations</code></p></td></tr><tr><td>Transcription session</td><td><p>The app needs streaming transcript deltas without model-generated spoken
responses.</p></td><td>Transcription session that emits transcript deltas</td></tr></tbody></table>
<p>Use a voice-agent session when your application needs an assistant that responds to the user. Use a translation session when your application needs an interpreter that translates the speaker. Use a transcription session when your application needs text from audio without model-generated responses.</p>
<h3 id="voice-agent-sessions" class="group flex items-center gap-1 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">Voice-agent sessions</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="voice-agent-sessions" aria-label="Copy link to voice agent sessions" title="Copy link to voice agent sessions"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h3>
<p>Voice-agent sessions use the standard Realtime API conversation lifecycle. The client connects to <code>/v1/realtime</code>, sends audio or text, and listens for model responses, tool calls, and session events.</p>
<p>For most browser voice agents, start with the <a href="/api/docs/guides/voice-agents">Voice agents</a> guide. It uses the Agents SDK with WebRTC for browser audio and can connect to server-side tools.</p>
<div class="_Notice_wyxfv_1"><div class="_Alert_1bpiz_1" data-variant="outline" data-color="primary" data-actions-placement="end"><div class="_Indicator_1bpiz_159"><svg width="1em" height="1em" viewBox="0 0 24 24" fill="currentColor"><path d="M13 12a1 1 0 1 0-2 0v4a1 1 0 1 0 2 0v-4Zm-1-2.5A1.25 1.25 0 1 0 12 7a1.25 1.25 0 0 0 0 2.5Z"></path><path fill-rule="evenodd" d="M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2ZM4 12a8 8 0 1 1 16 0 8 8 0 0 1-16 0Z" clip-rule="evenodd"></path></svg></div><div class="_Content_1bpiz_147"><div class="_Message_1bpiz_166"><div class="_Description_1bpiz_176"><p>Realtime 2 adds reasoning to speech-to-speech workflows. Start with
<code>reasoning.effort</code> set to <code>low</code> for most production voice agents, then adjust
based on latency tolerance and task complexity. Use the <a href="/api/docs/guides/realtime-models-prompting">Realtime prompting
guide</a> to tune reasoning,
preambles, tool use, unclear audio, and exact entity capture.</p></div></div></div></div></div>
<h3 id="translation-sessions" class="group flex items-center gap-1 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">Translation sessions</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="translation-sessions" aria-label="Copy link to translation sessions" title="Copy link to translation sessions"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h3>
<p>Realtime translation uses a dedicated translation endpoint instead of the standard voice-agent endpoint. Translation sessions are continuous: the client streams audio into the session, and the service streams translated audio and transcript deltas out.</p>
<p>Translation sessions don’t use the normal assistant turn lifecycle. Don’t call <code>response.create</code>, and don’t wait for the client to commit a user turn before translation begins. For browser media, use WebRTC. For server media pipelines such as phone calls or broadcast ingest, use WebSockets.</p>
<p>See <a href="/api/docs/guides/realtime-translation">Realtime translation</a> for the dedicated endpoint, session configuration, and architecture patterns.</p>
<h3 id="transcription-sessions" class="group flex items-center gap-1 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">Transcription sessions</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="transcription-sessions" aria-label="Copy link to transcription sessions" title="Copy link to transcription sessions"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h3>
<p>You can transcribe audio in more than one way. Use a realtime transcription session when your application needs live transcript deltas from streaming audio. Use the <a href="/api/docs/guides/speech-to-text">Speech to text</a> guide for file uploads, request-based transcription, or diarization-focused workflows.</p>
<p>For realtime transcription, <a href="/api/docs/models/gpt-realtime-whisper"><code>gpt-realtime-whisper</code></a> gives you controllable latency. Lower delay settings produce earlier partial text, while higher delay settings can improve transcript quality. Test with your real audio conditions, target languages, accents, and domain vocabulary before choosing a production default.</p>
<p>See <a href="/api/docs/guides/realtime-transcription">Realtime transcription</a> for session configuration and event handling.</p>
<h2 id="choose-a-connection-method" class="group flex items-center gap-2 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">Choose a connection method</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="choose-a-connection-method" aria-label="Copy link to choose a connection method" title="Copy link to choose a connection method"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h2>
<p>Choose the transport based on where your application captures and plays audio:</p>
<a href="/api/docs/guides/realtime-webrtc" to="/api/docs/guides/realtime-webrtc" class="_TextLink_ssta1_1" data-underline="always"><div class="icon-item mt-2"> <div class="icon-item-icon"> <span><svg width="1em" height="1em" viewBox="0 0 24 24" fill="currentColor"><path d="M6.16146 3L17.8385 3C18.3657 2.99998 18.8205 2.99997 19.195 3.03057C19.5904 3.06287 19.9836 3.13419 20.362 3.32698C20.9265 3.6146 21.3854 4.07354 21.673 4.63803C21.8658 5.01641 21.9371 5.40963 21.9694 5.80497C22 6.17954 22 6.6343 22 7.16144V13.3386C22 13.8657 22 14.3205 21.9694 14.695C21.9371 15.0904 21.8658 15.4836 21.673 15.862C21.3854 16.4265 20.9265 16.8854 20.362 17.173C19.9836 17.3658 19.5904 17.4371 19.195 17.4694C18.8205 17.5 18.3657 17.5 17.8385 17.5H16.5V20C16.5 20.5523 16.5523 21 15.5 21H8.5C7.94772 21 7.5 20.5523 7.5 20V17.5H6.16148C5.63432 17.5 5.17955 17.5 4.80497 17.4694C4.40963 17.4371 4.01641 17.3658 3.63803 17.173C3.07354 16.8854 2.6146 16.4265 2.32698 15.862C2.13419 15.4836 2.06287 15.0904 2.03057 14.695C1.99997 14.3205 1.99998 13.8657 2 13.3385V7.16146C1.99998 6.63431 1.99997 6.17955 2.03057 5.80497C2.06287 5.40963 2.13419 5.01641 2.32698 4.63803C2.6146 4.07354 3.07354 3.6146 3.63803 3.32698C4.01641 3.13419 4.40963 3.06287 4.80497 3.03057C5.17955 2.99997 5.63431 2.99998 6.16146 3ZM9.5 17.5V19H14.5V17.5H9.5ZM4.96784 5.02393C4.69617 5.04612 4.59546 5.0838 4.54601 5.109C4.35785 5.20487 4.20487 5.35785 4.109 5.54601C4.0838 5.59546 4.04612 5.69617 4.02393 5.96784C4.00078 6.25117 4 6.62345 4 7.2V13.3C4 13.8766 4.00078 14.2488 4.02393 14.5322C4.04612 14.8038 4.0838 14.9045 4.109 14.954C4.20487 15.1422 4.35785 15.2951 4.54601 15.391C4.59546 15.4162 4.69617 15.4539 4.96784 15.4761C5.25117 15.4992 5.62345 15.5 6.2 15.5H17.8C18.3766 15.5 18.7488 15.4992 19.0322 15.4761C19.3038 15.4539 19.4045 15.4162 19.454 15.391C19.6422 15.2951 19.7951 15.1422 19.891 14.954C19.9162 14.9045 19.9539 14.8038 19.9761 14.5322C19.9992 14.2488 20 13.8766 20 13.3V7.2C20 6.62345 19.9992 6.25118 19.9761 5.96784C19.9539 5.69617 19.9162 5.59546 19.891 5.54601C19.7951 5.35785 19.6422 5.20487 19.454 5.109C19.4045 5.0838 19.3038 5.04612 19.0322 5.02393C18.7488 5.00078 18.3766 5 17.8 5H6.2C5.62345 5 5.25117 5.00078 4.96784 5.02393Z" fill="currentColor"></path></svg></span> </div> <div class="icon-item-right"> <div class="icon-item-title not-prose"> <div class="icon-item-title body-large not-prose">WebRTC</div> <div class="pointer"> <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path fill-rule="evenodd" d="M9.293 7.293a1 1 0 0 1 1.414 0l4 4a1 1 0 0 1 0 1.414l-4 4a1 1 0 0 1-1.414-1.414L12.586 12 9.293 8.707a1 1 0 0 1 0-1.414Z" clip-rule="evenodd"></path></svg> </div> </div>  <div class="icon-item-desc body-small not-prose"> <p>Use for browser and mobile clients that capture or play audio directly.</p> </div> </div> </div></a>
<a href="/api/docs/guides/realtime-websocket" to="/api/docs/guides/realtime-websocket" class="_TextLink_ssta1_1" data-underline="always"><div class="icon-item mt-2"> <div class="icon-item-icon"> <span><svg width="1em" height="1em" viewBox="0 0 24 24" fill="currentColor"><path fill-rule="evenodd" d="M12.5 3.444a1 1 0 0 0-1 0l-6.253 3.61 6.768 3.807 6.955-3.682-6.47-3.735Zm7.16 5.632L13 12.602v7.666l6.16-3.556a1 1 0 0 0 .5-.867V9.076ZM11 20.268v-7.683L4.34 8.839v7.006a1 1 0 0 0 .5.867L11 20.268Zm-.5-18.557a3 3 0 0 1 3 0l6.66 3.846a3 3 0 0 1 1.5 2.598v7.69a3 3 0 0 1-1.5 2.598L13.5 22.29a3 3 0 0 1-3 0l-6.66-3.846a3 3 0 0 1-1.5-2.598v-7.69a3 3 0 0 1 1.5-2.598L10.5 1.71Z" clip-rule="evenodd"></path></svg></span> </div> <div class="icon-item-right"> <div class="icon-item-title not-prose"> <div class="icon-item-title body-large not-prose">WebSocket</div> <div class="pointer"> <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path fill-rule="evenodd" d="M9.293 7.293a1 1 0 0 1 1.414 0l4 4a1 1 0 0 1 0 1.414l-4 4a1 1 0 0 1-1.414-1.414L12.586 12 9.293 8.707a1 1 0 0 1 0-1.414Z" clip-rule="evenodd"></path></svg> </div> </div>  <div class="icon-item-desc body-small not-prose"> <p>Use when your server already receives raw audio from a media pipeline, call
system, or worker.</p> </div> </div> </div></a>
<a href="/api/docs/guides/realtime-sip" to="/api/docs/guides/realtime-sip" class="_TextLink_ssta1_1" data-underline="always"><div class="icon-item mt-2"> <div class="icon-item-icon"> <span><svg width="1em" height="1em" viewBox="0 0 24 24" fill="currentColor"><path d="M2 5.57143C2 3.59898 3.59898 2 5.57143 2H8.625C9.0287 2 9.39281 2.24274 9.54808 2.61538L11.4231 7.11538C11.5744 7.47863 11.4987 7.89686 11.2295 8.18394L9.82741 9.67954C10.9044 11.7563 12.2732 13.2047 14.3016 14.2842L15.7929 12.7929C16.0794 12.5064 16.5106 12.4211 16.8846 12.5769L21.3846 14.4519C21.7573 14.6072 22 14.9713 22 15.375V18.4286C22 20.401 20.401 22 18.4286 22C9.35532 22 2 14.6447 2 5.57143ZM5.57143 4C4.70355 4 4 4.70355 4 5.57143C4 13.5401 10.4599 20 18.4286 20C19.2964 20 20 19.2964 20 18.4286V16.0417L16.7336 14.6807L15.2071 16.2071C14.9098 16.5044 14.4582 16.584 14.0771 16.4062C11.0315 14.9849 9.12076 12.9271 7.71882 9.92289C7.54598 9.55251 7.61592 9.11423 7.89546 8.81606L9.32824 7.28777L7.95833 4H5.57143Z" fill="currentColor"></path></svg></span> </div> <div class="icon-item-right"> <div class="icon-item-title not-prose"> <div class="icon-item-title body-large not-prose">SIP</div> <div class="pointer"> <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path fill-rule="evenodd" d="M9.293 7.293a1 1 0 0 1 1.414 0l4 4a1 1 0 0 1 0 1.414l-4 4a1 1 0 0 1-1.414-1.414L12.586 12 9.293 8.707a1 1 0 0 1 0-1.414Z" clip-rule="evenodd"></path></svg> </div> </div>  <div class="icon-item-desc body-small not-prose"> <p>Use for telephony voice agents. Confirm model support before using SIP for
translation or transcription.</p> </div> </div> </div></a>
<h2 id="safety-identifiers" class="group flex items-center gap-2 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">Safety identifiers</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="safety-identifiers" aria-label="Copy link to safety identifiers" title="Copy link to safety identifiers"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h2>
<p>If your application identifies individual end users, include a <a href="/api/docs/guides/safety-best-practices#implement-safety-identifiers">safety identifier</a> with Realtime API requests. Safety identifiers are recommended but not required. They help OpenAI monitor and detect abuse while allowing enforcement to target an individual user rather than your entire organization. Use a stable, privacy-preserving value, such as a hashed internal user ID.</p>
<p>For Realtime API requests, send the identifier in the <code>OpenAI-Safety-Identifier</code> header. When using ephemeral tokens, set the header on the server-side request that creates the client secret so the identifier is bound to that session. When connecting from a trusted server with WebSocket or the unified WebRTC interface, set the header on the connection request.</p>
<p>Safety identifiers do not carry over from Responses API requests or from other sessions. If you use the Responses API <code>safety_identifier</code> parameter elsewhere in your application, pass the same stable value separately when you create or connect each Realtime session.</p>
<h2 id="beta-to-ga-migration" class="group flex items-center gap-2 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">Beta to GA migration</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="beta-to-ga-migration" aria-label="Copy link to beta to ga migration" title="Copy link to beta to ga migration"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h2>
<p>If you still have a beta Realtime integration, migrate it to the GA interface before moving forward with new work. The most important changes are:</p>
<ul>
<li>Remove the <code>OpenAI-Beta: realtime=v1</code> header when calling the GA interface.</li>
<li>Use <a href="/api/docs/api-reference/realtime-sessions/create-realtime-client-secret"><code>POST /v1/realtime/client_secrets</code></a> to create ephemeral credentials for browser or mobile clients.</li>
<li>Use <code>/v1/realtime/calls</code> when establishing WebRTC sessions.</li>
<li>Update session and event shapes for the GA interface. In particular, set <code>session.type</code>, move output audio configuration under <code>session.audio.output</code>, and use the newer response event names like <code>response.output_text.delta</code>, <code>response.output_audio.delta</code>, and <code>response.output_audio_transcript.delta</code>.</li>
<li>If you are moving a speech-to-speech app forward, start from the <a href="/api/docs/guides/voice-agents">Voice agents</a> guide. If you are moving a transcription workflow forward, use <a href="/api/docs/guides/realtime-transcription">Realtime transcription</a>.</li>
</ul>
<p>See the <a href="/api/docs/api-reference/realtime_client_events">Realtime client events reference</a>, <a href="/api/docs/api-reference/realtime-sessions">Realtime sessions reference</a>, and <a href="/api/docs/guides/voice-agents">Voice agents</a> guide for the current GA flow.</p>
<h2 id="related-guides" class="group flex items-center gap-2 mt-7 mb-2 scroll-mt-[110px] " ><span class="min-w-0">Related guides</span><button type="button" class="shrink-0 self-center inline-flex items-center justify-center rounded-md p-0.5 opacity-0 transition-colors transition-opacity duration-200 ease-out text-info hover:text-info focus-visible:opacity-100 group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-300 group-hover:opacity-100 dark:focus-visible:outline-gray-600 motion-reduce:transition-none relative -top-0.5" data-anchor-id="related-guides" aria-label="Copy link to related guides" title="Copy link to related guides"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 "><path d="M18.2929 5.7071C16.4743 3.88849 13.5257 3.88849 11.7071 5.7071L10.7071 6.7071C10.3166 7.09763 9.68341 7.09763 9.29289 6.7071C8.90236 6.31658 8.90236 5.68341 9.29289 5.29289L10.2929 4.29289C12.8926 1.69322 17.1074 1.69322 19.7071 4.29289C22.3068 6.89255 22.3068 11.1074 19.7071 13.7071L18.7071 14.7071C18.3166 15.0976 17.6834 15.0976 17.2929 14.7071C16.9024 14.3166 16.9024 13.6834 17.2929 13.2929L18.2929 12.2929C20.1115 10.4743 20.1115 7.52572 18.2929 5.7071ZM15.7071 8.29289C16.0976 8.68341 16.0976 9.31658 15.7071 9.7071L9.7071 15.7071C9.31658 16.0976 8.68341 16.0976 8.29289 15.7071C7.90236 15.3166 7.90236 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90236 15.3166 7.90236 15.7071 8.29289ZM6.7071 9.29289C7.09763 9.68341 7.09763 10.3166 6.7071 10.7071L5.7071 11.7071C3.88849 13.5257 3.88849 16.4743 5.7071 18.2929C7.52572 20.1115 10.4743 20.1115 12.2929 18.2929L13.2929 17.2929C13.6834 16.9024 14.3166 16.9024 14.7071 17.2929C15.0976 17.6834 15.0976 18.3166 14.7071 18.7071L13.7071 19.7071C11.1074 22.3068 6.89255 22.3068 4.29289 19.7071C1.69322 17.1074 1.69322 12.8926 4.29289 10.2929L5.29289 9.29289C5.68341 8.90236 6.31658 8.90236 6.7071 9.29289Z" fill="currentColor"></path></svg></button></h2>
<ul>
<li><a href="/api/docs/guides/realtime-models-prompting">Realtime prompting guide</a>: Prompt and tune Realtime voice models.</li>
<li><a href="/api/docs/guides/realtime-conversations">Managing conversations</a>: Work with the Realtime session lifecycle.</li>
<li><a href="/api/docs/guides/realtime-translation">Realtime translation</a>: Translate live speech with a dedicated translation session.</li>
<li><a href="/api/docs/guides/realtime-transcription">Realtime transcription</a>: Stream live transcript deltas from audio.</li>
<li><a href="/api/docs/guides/realtime-mcp">Realtime with tools</a>: Connect function tools, MCP servers, and connectors to a Realtime session.</li>
<li><a href="/api/docs/guides/realtime-server-controls">Webhooks and server-side controls</a>: Control Realtime sessions from your server.</li>
<li><a href="/api/docs/guides/realtime-costs">Managing costs</a>: Track and optimize Realtime API usage.</li>
</ul>
<div class="_Notice_wyxfv_1"><div class="_Alert_1bpiz_1" data-variant="outline" data-color="primary" data-actions-placement="end"><div class="_Indicator_1bpiz_159"><svg width="1em" height="1em" viewBox="0 0 24 24" fill="currentColor"><path d="M13 12a1 1 0 1 0-2 0v4a1 1 0 1 0 2 0v-4Zm-1-2.5A1.25 1.25 0 1 0 12 7a1.25 1.25 0 0 0 0 2.5Z"></path><path fill-rule="evenodd" d="M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2ZM4 12a8 8 0 1 1 16 0 8 8 0 0 1-16 0Z" clip-rule="evenodd"></path></svg></div><div class="_Content_1bpiz_147"><div class="_Message_1bpiz_166"><div class="_Description_1bpiz_176"><p>Use <a href="/api/docs/guides/audio">Audio and speech</a> for the core concepts behind
audio input, audio output, streaming, latency, transcripts, and speech
generation. Use this overview when you are ready to choose an implementation
path.</p></div></div></div></div></div>  </article>  </div> <div></div> </div> </div> <script>
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
  </script>  <div class="mx-4 sm:mx-8 md:mx-auto md:w-full md:max-w-6xl px-4 md:px-12 xl:px-4"> <div class="grid grid-cols-1 gap-12 xl:grid-cols-[minmax(0,1fr)_200px]">  <div class="hidden xl:block"></div> </div> </div> </main> </div> </div> <script>(()=>{var e=async t=>{await(await t())()};(self.Astro||(self.Astro={})).only=e;window.dispatchEvent(new Event("astro:only"));})();</script><astro-island uid="DQ4jb" component-url="/_astro/Analytics.rv0FwEeX.js" component-export="default" renderer-url="/_astro/client.DjvmFpsL.js" props="{}" ssr client="only" opts="{&quot;name&quot;:&quot;VercelAnalyticsClient&quot;,&quot;value&quot;:&quot;solid-js&quot;}"></astro-island> <vercel-speed-insights data-props="{}" data-params="{&#34;slug&#34;:&#34;guides/realtime&#34;}" data-pathname="/api/docs/guides/realtime/"></vercel-speed-insights> <script type="module">var o="@vercel/speed-insights",u="1.3.1",f=()=>{window.si||(window.si=function(...r){(window.siq=window.siq||[]).push(r)})};function l(){return typeof window<"u"}function h(){try{const e="production"}catch{}return"production"}function d(){return h()==="development"}function v(e,r){if(!e||!r)return e;let n=e;try{const t=Object.entries(r);for(const[s,i]of t)if(!Array.isArray(i)){const a=c(i);a.test(n)&&(n=n.replace(a,`/[${s}]`))}for(const[s,i]of t)if(Array.isArray(i)){const a=c(i.join("/"));a.test(n)&&(n=n.replace(a,`/[...${s}]`))}return n}catch{return e}}function c(e){return new RegExp(`/${g(e)}(?=[/?#]|$)`)}function g(e){return e.replace(/[.*+?^${}()|[\]\\]/g,"\\$&")}function m(e){return e.scriptSrc?e.scriptSrc:d()?"https://va.vercel-scripts.com/v1/speed-insights/script.debug.js":e.dsn?"https://va.vercel-scripts.com/v1/speed-insights/script.js":e.basePath?`${e.basePath}/speed-insights/script.js`:"/_vercel/speed-insights/script.js"}function w(e={}){var r;if(!l()||e.route===null)return null;f();const n=m(e);if(document.head.querySelector(`script[src*="${n}"]`))return null;e.beforeSend&&((r=window.si)==null||r.call(window,"beforeSend",e.beforeSend));const t=document.createElement("script");return t.src=n,t.defer=!0,t.dataset.sdkn=o+(e.framework?`/${e.framework}`:""),t.dataset.sdkv=u,e.sampleRate&&(t.dataset.sampleRate=e.sampleRate.toString()),e.route&&(t.dataset.route=e.route),e.endpoint?t.dataset.endpoint=e.endpoint:e.basePath&&(t.dataset.endpoint=`${e.basePath}/speed-insights/vitals`),e.dsn&&(t.dataset.dsn=e.dsn),d()&&e.debug===!1&&(t.dataset.debug="false"),t.onerror=()=>{console.log(`[Vercel Speed Insights] Failed to load script from ${n}. Please check if any content blockers are enabled and try again.`)},document.head.appendChild(t),{setRoute:s=>{t.dataset.route=s??void 0}}}function p(){try{return}catch{}}customElements.define("vercel-speed-insights",class extends HTMLElement{constructor(){super();try{const r=JSON.parse(this.dataset.props??"{}"),n=JSON.parse(this.dataset.params??"{}"),t=v(this.dataset.pathname??"",n);w({route:t,...r,framework:"astro",basePath:p(),beforeSend:window.speedInsightsBeforeSend})}catch(r){throw new Error(`Failed to parse SpeedInsights properties: ${r}`)}}});</script> <div data-docs-agent-root data-chatkit-api-url="/api/docs-agent/chatkit" data-chatkit-domain-key="domain_pk_69f4ea0d87748194b9ad4d8ba39fc5710f6f8241026056cb" data-chatkit-greeting="What can I help you with?" data-chatkit-start-prompts-by-route="{&#34;home&#34;:[{&#34;label&#34;:&#34;Ask a question&#34;,&#34;prompt&#34;:&#34;What is the Docs MCP server?&#34;,&#34;icon&#34;:&#34;circle-question&#34;},{&#34;label&#34;:&#34;Find a page&#34;,&#34;prompt&#34;:&#34;Show me OpenAI models&#34;,&#34;icon&#34;:&#34;search&#34;},{&#34;label&#34;:&#34;Build a custom app&#34;,&#34;prompt&#34;:&#34;I want to build an interactive webapp that has a huge microphone in the center allowing to chat in Realtime&#34;,&#34;icon&#34;:&#34;square-code&#34;}],&#34;api&#34;:[{&#34;label&#34;:&#34;Ask a question&#34;,&#34;prompt&#34;:&#34;What are the recommended prompting best practices for building with the latest model?&#34;,&#34;icon&#34;:&#34;circle-question&#34;},{&#34;label&#34;:&#34;Find a page&#34;,&#34;prompt&#34;:&#34;show me a page to compare models&#34;,&#34;icon&#34;:&#34;search&#34;},{&#34;label&#34;:&#34;Build a custom app&#34;,&#34;prompt&#34;:&#34;I want to build a customer support app with realtime voice&#34;,&#34;icon&#34;:&#34;square-code&#34;}],&#34;codex&#34;:[{&#34;label&#34;:&#34;Ask a question&#34;,&#34;prompt&#34;:&#34;What is Codex app server?&#34;,&#34;icon&#34;:&#34;circle-question&#34;},{&#34;label&#34;:&#34;Find a page&#34;,&#34;prompt&#34;:&#34;Show me the Codex changelog&#34;,&#34;icon&#34;:&#34;search&#34;},{&#34;label&#34;:&#34;Build a custom app&#34;,&#34;prompt&#34;:&#34;I want to build an internal dashboard that gets updated with data from slack and spreadsheets and which allows to visualize weekly progress&#34;,&#34;icon&#34;:&#34;square-code&#34;}],&#34;chatgpt&#34;:[{&#34;label&#34;:&#34;Ask a question&#34;,&#34;prompt&#34;:&#34;What are best practices for building a ChatGPT app?&#34;,&#34;icon&#34;:&#34;circle-question&#34;},{&#34;label&#34;:&#34;Find a page&#34;,&#34;prompt&#34;:&#34;Show me UI guidelines for building ChatGPT apps&#34;,&#34;icon&#34;:&#34;search&#34;},{&#34;label&#34;:&#34;Build a custom app&#34;,&#34;prompt&#34;:&#34;Help me build an app in ChatGPT that proposes a quiz to users to find the best match from my list of products&#34;,&#34;icon&#34;:&#34;square-code&#34;}],&#34;resources&#34;:[{&#34;label&#34;:&#34;Ask a question&#34;,&#34;prompt&#34;:&#34;What is the Docs MCP server?&#34;,&#34;icon&#34;:&#34;circle-question&#34;},{&#34;label&#34;:&#34;Find a page&#34;,&#34;prompt&#34;:&#34;Show me the Codex meetups page&#34;,&#34;icon&#34;:&#34;search&#34;},{&#34;label&#34;:&#34;Build a custom app&#34;,&#34;prompt&#34;:&#34;I want to build an interactive webapp that has a huge microphone in the center allowing to chat in Realtime&#34;,&#34;icon&#34;:&#34;square-code&#34;}]}" data-astro-transition-persist="docs-agent-launcher" class="docs-agent-root"><button type="button" data-docs-agent-open aria-haspopup="dialog" aria-expanded="false" aria-controls="docs-agent-panel" class="fixed bottom-5 right-5 z-50 inline-flex h-11 items-center justify-center whitespace-nowrap rounded-full border border-transparent bg-primary-solid px-4 text-sm font-medium text-primary-solid shadow-[0_16px_48px_-18px_rgba(15,23,42,0.45)] transition-colors hover:bg-primary-solid-hover active:bg-primary-solid-active focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary-soft-active focus-visible:ring-offset-2 focus-visible:ring-offset-surface"><span>Ask AI</span></button><div id="docs-agent-panel" data-docs-agent-panel role="dialog" aria-labelledby="docs-agent-title" class="fixed inset-x-0 bottom-0 z-[80] flex h-[var(--docs-agent-drawer-height)] flex-col overflow-hidden rounded-t-2xl border border-subtle bg-surface transition-transform duration-300 ease-out md:inset-y-0 md:left-auto md:right-0 md:h-auto md:w-[var(--docs-agent-panel-width)] md:rounded-none md:border-y-0 md:border-r-0"><header class="flex h-16 shrink-0 items-center justify-between border-b border-subtle px-4"><h2 id="docs-agent-title" class="text-sm font-semibold text-default">
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

