(() => {
  if (window.__t3GuidedVideo) return { installed: true };
  const styleId = 't3-guided-video-style';
  const attribute = 'data-t3-guided-video-focus';
  const style = document.createElement('style');
  style.id = styleId;
  style.textContent = `[${attribute}] { outline: 3px solid #f59e0b !important; outline-offset: 3px !important; }`;
  document.head.appendChild(style);

  const hold = ms => new Promise(resolve => setTimeout(resolve, ms));
  const uniqueVisible = selector => {
    const matches = [...document.querySelectorAll(selector)].filter(element => {
      const css = getComputedStyle(element);
      return element.getClientRects().length > 0 && css.visibility !== 'hidden' && css.visibility !== 'collapse' && css.opacity !== '0';
    });
    if (matches.length !== 1) {
      throw new Error(`Expected one visible target for ${selector}; found ${matches.length}`);
    }
    return matches[0];
  };
  const clearFocus = () => document.querySelectorAll(`[${attribute}]`).forEach(element => element.removeAttribute(attribute));

  window.__t3GuidedVideo = {
    frame: async (selector, options = {}) => {
      const target = uniqueVisible(selector);
      const framed = options.frameSelector ? uniqueVisible(options.frameSelector) : target;
      if (framed !== target && !framed.contains(target)) {
        throw new Error('The framing container must contain the interaction target');
      }
      clearFocus();
      framed.scrollIntoView({ block: 'center', inline: 'center', behavior: 'instant' });
      framed.setAttribute(attribute, '');
      await hold(options.holdMs ?? 500);
      const rect = framed.getBoundingClientRect();
      return {
        selector,
        bounds: { x: rect.x, y: rect.y, width: rect.width, height: rect.height },
        fullyInViewport: rect.left >= 0 && rect.top >= 0 && rect.right <= innerWidth && rect.bottom <= innerHeight
      };
    },
    hold: (ms = 750) => hold(ms),
    clear: () => {
      clearFocus();
      style.remove();
      delete window.__t3GuidedVideo;
      return { cleared: true };
    }
  };
  return { installed: true };
})()
