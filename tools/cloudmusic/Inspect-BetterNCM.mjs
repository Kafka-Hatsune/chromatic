// Temporary CEF debugging: start cloudmusic.exe with --remote-debugging-port=32341.
// This helper only connects to loopback. No debugging settings are persisted.
import fs from 'node:fs';
const [mode = 'status', argument, port = '32341'] = process.argv.slice(2);
const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
const page = targets.find(target => target.type === 'page' && target.url.includes('/pub/app.html'));
if (!page) throw new Error('CloudMusic main page is not available through CEF debugging.');
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  ws.addEventListener('open', resolve, { once: true });
  ws.addEventListener('error', reject, { once: true });
});
let nextId = 0;
const pending = new Map();
ws.addEventListener('message', event => {
  const message = JSON.parse(event.data);
  const task = pending.get(message.id);
  if (!task) return;
  pending.delete(message.id);
  clearTimeout(task.timer);
  if (message.error) task.reject(new Error(JSON.stringify(message.error)));
  else task.resolve(message.result);
});
function call(method, params = {}) {
  return new Promise((resolve, reject) => {
    const id = ++nextId;
    const timer = setTimeout(() => { pending.delete(id); reject(new Error(`${method} timed out`)); }, 25000);
    pending.set(id, { resolve, reject, timer });
    ws.send(JSON.stringify({ id, method, params }));
  });
}
try {
  if (mode === 'screenshot') {
    const result = await call('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(argument, Buffer.from(result.data, 'base64'));
    console.log(argument);
  } else {
    const expression = mode === 'eval'
      ? fs.readFileSync(argument, 'utf8')
      : `JSON.stringify({
          page: location.pathname,
          appVersion: window.APP_CONF?.appver,
          nativeApi: typeof window.betterncm_native,
          framework: typeof window.betterncm,
          plugins: Object.keys(window.loadedPlugins || {}),
          manager: !!document.querySelector('.better-ncm-manager'),
          button: !!document.querySelector('[title="BetterNCM"]'),
          marketVersion: window.loadedPlugins?.PluginMarket?.manifest?.version,
          safeMode: localStorage.getItem('betterncm.safemode')
        })`;
    const result = await call('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
    if (result.exceptionDetails) throw new Error(result.exceptionDetails.exception?.description || result.exceptionDetails.text);
    console.log(typeof result.result.value === 'string' ? result.result.value : JSON.stringify(result.result.value));
  }
} finally {
  ws.close();
}
