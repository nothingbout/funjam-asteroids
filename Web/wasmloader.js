// loadWasmModule does the same as init() in wasm/index.js but is a streaming loader with progress reporting
import { instantiate } from './wasm/instantiate.js';
import { defaultBrowserSetup } from './wasm/platforms/browser.js';

const fetchWithProgress = async (url, fallbackContentLength, progressCallback) => {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Failed to fetch wasm module: ${response.status} ${response.statusText}`);
    }

    const contentLengthHeader = response.headers.get("Content-Length");
    let contentLength = contentLengthHeader ? Number(contentLengthHeader) : null;

    if (!response.body || !contentLength || Number.isNaN(contentLength)) {
        contentLength = fallbackContentLength;
    }

    const reader = response.body.getReader();
    const chunks = [];
    let received = 0;

    while (true) {
      const { done, value } = await reader.read();
      if (done) {
        break;
      }
      if (value) {
        chunks.push(value);
        received += value.length;
        progressCallback(received / contentLength);
      }
    }

    const totalBytes = received;
    const result = new Uint8Array(totalBytes);
    let offset = 0;
    for (const chunk of chunks) {
      result.set(chunk, offset);
      offset += chunk.length;
    } 

    progressCallback(1.0);
    return result.buffer;
};

export async function loadWasmModule(modulePath, fallbackContentLength, instantiateDelay, progressCallback) {
    progressCallback(0.0);
    let module = await fetchWithProgress(new URL(modulePath, import.meta.url), fallbackContentLength, progressCallback);
    progressCallback(1.0);
    await new Promise(resolve => setTimeout(resolve, instantiateDelay));
    const instantiateOptions = await defaultBrowserSetup({
        module,
    })
    return await instantiate(instantiateOptions);
}
