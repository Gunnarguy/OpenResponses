import Foundation

/// Runs in an isolated WebKit content world. Page scripts cannot replace our element-reference map.
enum BrowserDOM {
    static func script(action: String, arguments: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: arguments.merging(["action": action]) { _, new in new })
        guard let json = String(data: data, encoding: .utf8) else { throw ComputerUseError.invalidParameters }
        return "(() => { const args = \(json);\n" + implementation + "\n})()"
    }

    private static let implementation = #"""
    const norm = v => (v || '').replace(/\s+/g, ' ').trim();
    const lower = v => norm(v).toLowerCase();
    const controls = 'a[href],button,[role="button"],input[type="button"],input[type="submit"],summary,label';
    const fields = 'input,textarea,[contenteditable="true"],[role="textbox"],[role="searchbox"]';
    const label = el => norm(el.getAttribute('aria-label') || (el.labels && Array.from(el.labels).map(l => l.innerText).join(' ')) || el.getAttribute('placeholder') || el.getAttribute('title') || el.getAttribute('name') || el.id || '');
    const text = el => norm(el.innerText || el.getAttribute('aria-label') || el.getAttribute('title') || (['button','submit'].includes(el.type) ? el.value : '') || label(el));
    const visible = el => {
      if (!el || !el.isConnected) return false;
      const s = getComputedStyle(el), r = el.getBoundingClientRect();
      return s.display !== 'none' && s.visibility !== 'hidden' && s.pointerEvents !== 'none' && Number(s.opacity) > 0 &&
        r.width > 0 && r.height > 0 && r.bottom > 0 && r.right > 0 && r.top < innerHeight && r.left < innerWidth;
    };
    const editable = el => !el.disabled && !el.readOnly && (el.isContentEditable || el.tagName === 'TEXTAREA' ||
      (el.tagName === 'INPUT' && !['button','submit','reset','checkbox','radio','file','hidden','image','range','color'].includes(el.type)));
    const enabled = el => !el.disabled && el.getAttribute('aria-disabled') !== 'true' && !el.closest('[inert],[disabled],[aria-disabled="true"]');
    const signature = el => JSON.stringify([el.tagName, el.type, label(el), el.matches(fields) ? '' : text(el), el.href || '', el.form?.action || '', el.form?.method || '']);
    const candidates = selector => Array.from(document.querySelectorAll(selector)).filter(visible);
    const failed = message => ({ok: false, message});
    const unobscured = el => {
      const r = el.getBoundingClientRect();
      const x = Math.max(0, Math.min(innerWidth - 1, r.left + r.width / 2));
      const y = Math.max(0, Math.min(innerHeight - 1, r.top + r.height / 2));
      const top = document.elementFromPoint(x, y);
      return top && (top === el || el.contains(top));
    };

    if (args.action === 'read') {
      const refs = new Map(); let index = 0;
      const describe = el => {
        const ref = args.snapshotId + ':' + (++index);
        refs.set(ref, {el, signature: signature(el)});
        return {text: el.matches(fields) ? label(el) || el.tagName.toLowerCase() : text(el), hint: label(el),
          type: el.type || el.tagName.toLowerCase(), href: el.href || null, role: el.getAttribute('role'), ref};
      };
      const section = selector => candidates(selector).slice(0, 40).map(describe);
      const page = {url: location.href, title: document.title, readyState: document.readyState,
        visibleTextPreview: norm(document.body?.innerText).slice(0, 6000),
        headings: candidates('h1,h2,h3').slice(0, 20).map(text),
        buttons: section('button,[role="button"],input[type="button"],input[type="submit"],summary'),
        links: section('a[href]'), inputs: candidates(fields).filter(editable).slice(0, 40).map(describe), snapshotId: args.snapshotId};
      globalThis.__openResponsesSnapshot = {refs, url: location.href};
      return page;
    }

    let target;
    if (args.action.startsWith('point')) {
      if (!Number.isFinite(args.x) || !Number.isFinite(args.y) || args.x < 0 || args.y < 0 || args.x >= innerWidth || args.y >= innerHeight)
        return failed('Coordinates are outside the current viewport. Read the page again.');
      target = document.elementFromPoint(args.x, args.y);
    } else if (args.ref) {
      const snapshot = globalThis.__openResponsesSnapshot;
      const entry = snapshot?.refs.get(args.ref);
      if (!entry || snapshot.url !== location.href || !entry.el.isConnected || signature(entry.el) !== entry.signature)
        return failed('The element reference is stale. Read the page and use a current reference.');
      target = entry.el;
    } else {
      let matches = candidates(args.action === 'type' ? fields : controls).filter(enabled);
      if (args.action === 'type') matches = matches.filter(editable);
      const query = lower(args.action === 'type' ? args.hint : args.target);
      if (query) {
        const labels = el => [lower(text(el)), lower(label(el)), lower(el.getAttribute('placeholder'))];
        const exact = matches.filter(el => labels(el).includes(query));
        matches = exact.length ? exact : matches.filter(el => labels(el).some(t => t.includes(query)));
      } else if (args.action === 'type' && matches.includes(document.activeElement)) {
        matches = [document.activeElement];
      } else if (args.action === 'click' || args.focusedOnly) {
        return failed('Specify a visible element reference or focus the intended input first.');
      }
      if (!matches.length) return failed('No visible element matched. Read or scroll the page before retrying.');
      if (matches.length > 1) return failed('Multiple elements match. Use an element reference from browserRead.');
      target = matches[0];
    }
    if (!visible(target) || !enabled(target)) return failed('The target is hidden, detached, or disabled. Read the page again.');
    if (!args.action.startsWith('point') && !unobscured(target)) return failed('The target is covered by another element. Inspect the page before acting.');

    if (args.action === 'click' || args.action.startsWith('point')) {
      target.focus?.({preventScroll: true});
      const options = {bubbles: true, cancelable: true, view: window, button: args.button || 0,
        clientX: args.x || 0, clientY: args.y || 0, ctrlKey: !!args.ctrlKey, metaKey: !!args.metaKey, altKey: !!args.altKey, shiftKey: !!args.shiftKey};
      if (args.action === 'pointMove') {
        target.dispatchEvent(new PointerEvent('pointerover', {...options, pointerId: 1, pointerType: 'mouse', isPrimary: true}));
        target.dispatchEvent(new MouseEvent('mouseover', options));
        target.dispatchEvent(new PointerEvent('pointermove', {...options, pointerId: 1, pointerType: 'mouse', isPrimary: true}));
        target.dispatchEvent(new MouseEvent('mousemove', options));
        return {ok: true, message: 'Dispatched pointer movement.'};
      }
      const clicks = args.action === 'pointDoubleClick' ? 2 : 1;
      for (let i = 1; i <= clicks; i++) {
        const eventOptions = {...options, detail: i};
        target.dispatchEvent(new PointerEvent('pointerdown', {...eventOptions, pointerId: 1, pointerType: 'mouse', isPrimary: true, buttons: 1}));
        target.dispatchEvent(new MouseEvent('mousedown', eventOptions));
        target.dispatchEvent(new PointerEvent('pointerup', {...eventOptions, pointerId: 1, pointerType: 'mouse', isPrimary: true, buttons: 0}));
        target.dispatchEvent(new MouseEvent('mouseup', eventOptions));
        // Exactly one activation per click. Do not also call target.click().
        target.dispatchEvent(new MouseEvent(options.button === 2 ? 'contextmenu' : options.button === 1 ? 'auxclick' : 'click', eventOptions));
      }
      if (clicks === 2) {
        target.dispatchEvent(new MouseEvent('dblclick', {...options, detail: 2}));
        return {ok: true, message: 'Dispatched a double click. Inspect the returned page to confirm.'};
      }
      return {ok: true, message: 'Dispatched one click. Inspect the returned page to confirm the result.'};
    }
    if (args.action === 'type') {
      if (!editable(target)) return failed('The referenced element is not editable.');
      target.focus({preventScroll: true});
      if (target.isContentEditable) target.textContent = args.text;
      else {
        // Use the native setter so controlled inputs see the change through their input event.
        const proto = target.tagName === 'TEXTAREA' ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
        Object.getOwnPropertyDescriptor(proto, 'value').set.call(target, args.text);
      }
      target.dispatchEvent(new InputEvent('input', {bubbles: true, inputType: 'insertText', data: args.text}));
      target.dispatchEvent(new Event('change', {bubbles: true}));
      if ((target.isContentEditable ? target.textContent : target.value) !== args.text)
        return failed('The page did not retain the entered text. Inspect before retrying.');
      if (args.submit) {
        if (target.form) {
          if (!target.form.reportValidity()) return {ok: true, message: 'Filled the field; form validation prevented submission.'};
          target.form.requestSubmit();
        } else {
          target.dispatchEvent(new KeyboardEvent('keydown', {key: 'Enter', code: 'Enter', bubbles: true, cancelable: true}));
          target.dispatchEvent(new KeyboardEvent('keyup', {key: 'Enter', code: 'Enter', bubbles: true, cancelable: true}));
        }
      }
      return {ok: true, message: args.submit ? 'Filled the field and requested submission once. Inspect the returned page to confirm.' : 'Filled the field.'};
    }
    return failed('Unsupported browser DOM action.');
    """#
}
