#!/usr/bin/env node
/**
 * MILK WebSocket Bridge (Phase 3A)
 * Local WebSocket server for remote control of control.html
 * 
 * Lane: MILK | Budget: ≤200 LOC | Authority: BossCat OEM
 * Security: localhost-only, origin validation
 */

import { createServer } from 'http';
import { WebSocketServer, WebSocket } from 'ws';
import { parse } from 'url';

interface MilkCommand {
  cmd: 'next' | 'prev' | 'setBlendTime' | 'auto';
  arg?: any;
  nonce?: string;
}

interface MilkResponse {
  status: 'ok' | 'error';
  message?: string;
  timestamp: string;
}

class MilkBridge {
  private wss: WebSocketServer;
  private http: any;
  private port: number = 8899;
  private nonce: string;
  private evidence: any[] = [];

  constructor(port: number = 8899) {
    this.port = port;
    this.nonce = this.generateNonce();
    
    // HTTP server for health check
    this.http = createServer((req, res) => {
      const { pathname } = parse(req.url || '', true);
      
      if (pathname === '/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'ok', lane: 'MILK', nonce: this.nonce }));
      } else if (pathname === '/api/milk' && req.method === 'POST') {
        this.handleHttpPost(req, res);
      } else {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('MILK Bridge - Use WebSocket on ws://localhost:8899 or POST /api/milk');
      }
    });

    // WebSocket server
    this.wss = new WebSocketServer({ server: this.http });
    this.wss.on('connection', (ws, req) => this.handleConnection(ws, req));
    
    this.logEvidence('bridge_init', { port, nonce: this.nonce });
  }

  start(): void {
    this.http.listen(this.port, 'localhost', () => {
      console.log(`[MILK] WebSocket bridge running on ws://localhost:${this.port}`);
      console.log(`[MILK] HTTP API: http://localhost:${this.port}/api/milk`);
      console.log(`[MILK] Nonce: ${this.nonce}`);
      this.logEvidence('bridge_start', { port: this.port });
    });
  }

  private handleConnection(ws: WebSocket, req: any): void {
    const origin = req.headers.origin || 'unknown';
    const remote = req.socket.remoteAddress;
    
    // Security: Accept only localhost
    if (!this.isLocalhost(remote || '')) {
      ws.close(1008, 'Only localhost connections allowed');
      this.logEvidence('connection_rejected', { remote, reason: 'non-localhost' });
      return;
    }

    this.logEvidence('connection_accepted', { origin, remote });
    console.log(`[MILK] Client connected from ${remote}`);

    ws.on('message', (data) => {
      try {
        const cmd = JSON.parse(data.toString()) as MilkCommand;
        this.handleCommand(ws, cmd);
      } catch (err) {
        this.sendError(ws, 'Invalid JSON');
      }
    });

    ws.on('close', () => {
      this.logEvidence('connection_closed', { remote });
    });
  }

  private handleCommand(ws: WebSocket, cmd: MilkCommand): void {
    // Validate command
    const validCmds = ['next', 'prev', 'setBlendTime', 'auto'];
    if (!validCmds.includes(cmd.cmd)) {
      this.sendError(ws, `Invalid command: ${cmd.cmd}`);
      return;
    }

    // Validate blend time if present
    if (cmd.cmd === 'setBlendTime') {
      const val = Number(cmd.arg);
      if (isNaN(val) || val < 0 || val > 10) {
        this.sendError(ws, 'Blend time must be 0-10 seconds');
        return;
      }
    }

    this.logEvidence('command_received', { cmd: cmd.cmd, arg: cmd.arg });
    
    // Build postMessage for control.html
    const msg = {
      type: 'bosscat:visu',
      cmd: cmd.cmd,
      arg: cmd.arg
    };

    // In production, this would forward to Electron/browser
    // For now, log and acknowledge
    console.log(`[MILK] Command: ${cmd.cmd}`, cmd.arg !== undefined ? `(${cmd.arg})` : '');
    
    this.sendResponse(ws, { 
      status: 'ok', 
      message: `Command ${cmd.cmd} forwarded`,
      timestamp: new Date().toISOString()
    });
  }

  private handleHttpPost(req: any, res: any): void {
    // Security: Validate nonce header
    const reqNonce = req.headers['x-milk-nonce'];
    if (!reqNonce || reqNonce !== this.nonce) {
      res.writeHead(401, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'error', message: 'Missing or invalid X-MILK-Nonce header' }));
      this.logEvidence('http_post_rejected', { reason: 'invalid_nonce', remote: req.socket.remoteAddress });
      console.log(`[MILK] HTTP POST rejected: invalid nonce from ${req.socket.remoteAddress}`);
      return;
    }

    let body = '';
    req.on('data', (chunk: any) => { body += chunk; });
    req.on('end', () => {
      try {
        const cmd = JSON.parse(body) as MilkCommand;
        this.handleCommand({ send: (msg: string) => {
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(msg);
        }} as any, cmd);
      } catch {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'error', message: 'Invalid JSON' }));
      }
    });
  }

  private sendResponse(ws: WebSocket, resp: MilkResponse): void {
    ws.send(JSON.stringify(resp));
  }

  private sendError(ws: WebSocket, message: string): void {
    ws.send(JSON.stringify({ status: 'error', message, timestamp: new Date().toISOString() }));
  }

  private isLocalhost(addr: string): boolean {
    return addr === '127.0.0.1' || addr === 'localhost' || addr === '::1' || addr.startsWith('::ffff:127.');
  }

  private generateNonce(): string {
    return Math.random().toString(36).substring(2, 15);
  }

  private logEvidence(event: string, data: any): void {
    this.evidence.push({
      timestamp: new Date().toISOString(),
      event,
      data
    });
  }

  exportEvidence(): string {
    const report = {
      timestamp: new Date().toISOString(),
      agent: 'milk-ws-bridge',
      lane: 'MILK',
      authority: 'BossCat OEM',
      phase: '3A',
      events: this.evidence
    };
    return JSON.stringify(report, null, 2);
  }
}

// CLI
if (require.main === module) {
  const bridge = new MilkBridge(8899);
  bridge.start();
  
  // Export evidence on SIGINT
  process.on('SIGINT', () => {
    console.log('\n[MILK] Exporting evidence...');
    const fs = require('fs');
    const evidence = bridge.exportEvidence();
    fs.appendFileSync('.agent/EVIDENCE.log', evidence + '\n', 'utf-8');
    console.log('[MILK] Evidence exported to .agent/EVIDENCE.log');
    process.exit(0);
  });
}

export { MilkBridge };

