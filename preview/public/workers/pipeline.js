self.addEventListener('message', (event) => {
  if (event.data?.type === 'ping') {
    self.postMessage({ type: 'pong' });
  }
});
