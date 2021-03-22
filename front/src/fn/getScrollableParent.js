export function getScrollableParent(node) {
  const isElement = node instanceof HTMLElement;
  const overflowY = isElement && window.getComputedStyle(node).overflowY;
  const isScrollable = overflowY !== 'visible' && overflowY !== 'hidden';

  if (!node) {
    return null;
  } else if (isScrollable && node.scrollHeight >= node.clientHeight) {
    return node;
  }

  return getScrollableParent(node.parentNode) || document.body;
}
