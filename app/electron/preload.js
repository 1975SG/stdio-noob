const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('ptyBridge', {
  onData: (callback) => ipcRenderer.on('pty-data', (_event, data) => callback(data)),
  write: (data) => ipcRenderer.send('pty-input', data),
  resize: (cols, rows) => ipcRenderer.send('pty-resize', cols, rows),
});
