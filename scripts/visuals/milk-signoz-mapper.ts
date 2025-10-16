#!/usr/bin/env node
/**
 * MILK SigNoz Mapper (Phase 3C)
 * Maps SigNoz alerts to visual preset changes via WebSocket bridge
 * 
 * Lane: MILK | Budget: ≤200 LOC | Authority: BossCat OEM
 * Integration: SigNoz webhooks → MILK visuals
 */

import { readFileSync } from 'fs';
import { join } from 'path';

interface AlertSeverity {
  level: 'critical' | 'high' | 'medium' | 'low' | 'info';
  preset?: string;
  blendTime?: number;
  autoCycle?: boolean;
}

interface SigNozAlert {
  severity?: string;
  labels?: Record<string, string>;
  annotations?: Record<string, string>;
  state?: string;
  value?: number;
}

interface MilkCommand {
  cmd: 'next' | 'prev' | 'setBlendTime' | 'auto' | 'loadPreset';
  arg?: any;
}

class SigNozMapper {
  private bridgeUrl: string;
  private mappingConfig: Map<string, AlertSeverity>;
  private evidence: any[] = [];

  constructor(bridgeUrl: string = 'http://localhost:8899/api/milk') {
    this.bridgeUrl = bridgeUrl;
    this.mappingConfig = this.loadMappingConfig();
    this.logEvidence('mapper_init', { bridgeUrl, mappings: this.mappingConfig.size });
  }

  /**
   * Load preset mapping configuration
   */
  private loadMappingConfig(): Map<string, AlertSeverity> {
    const defaults = new Map<string, AlertSeverity>([
      ['critical', { level: 'critical', blendTime: 0.5, autoCycle: false }],
      ['high', { level: 'high', blendTime: 1.0, autoCycle: false }],
      ['medium', { level: 'medium', blendTime: 2.0, autoCycle: false }],
      ['low', { level: 'low', blendTime: 3.0, autoCycle: true }],
      ['info', { level: 'info', blendTime: 2.7, autoCycle: true }]
    ]);

    try {
      const configPath = join(process.cwd(), 'config', 'milk-preset-mapping.json');
      const custom = JSON.parse(readFileSync(configPath, 'utf-8'));
      Object.entries(custom).forEach(([k, v]) => defaults.set(k, v as AlertSeverity));
    } catch {
      // Use defaults if config not found
    }

    return defaults;
  }

  /**
   * Map SigNoz alert to visual command
   */
  mapAlert(alert: SigNozAlert): MilkCommand[] {
    const severity = (alert.severity || 'info').toLowerCase();
    const mapping = this.mappingConfig.get(severity);

    if (!mapping) {
      this.logEvidence('mapping_failed', { severity, reason: 'unknown severity' });
      return [];
    }

    const commands: MilkCommand[] = [];

    // Preset change (cycle to next for critical/high)
    if (severity === 'critical' || severity === 'high') {
      commands.push({ cmd: 'next' });
    }

    // Blend time adjustment
    if (mapping.blendTime !== undefined) {
      commands.push({ cmd: 'setBlendTime', arg: mapping.blendTime });
    }

    // Auto-cycle control
    if (mapping.autoCycle !== undefined) {
      commands.push({ cmd: 'auto', arg: mapping.autoCycle });
    }

    this.logEvidence('alert_mapped', { 
      severity, 
      commands: commands.length,
      blendTime: mapping.blendTime,
      autoCycle: mapping.autoCycle
    });

    return commands;
  }

  /**
   * Send command to WebSocket bridge
   */
  async sendCommand(cmd: MilkCommand): Promise<boolean> {
    try {
      const response = await fetch(this.bridgeUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(cmd)
      });

      if (response.ok) {
        const result = await response.json();
        this.logEvidence('command_sent', { cmd: cmd.cmd, arg: cmd.arg, result });
        return true;
      } else {
        this.logEvidence('command_failed', { cmd: cmd.cmd, status: response.status });
        return false;
      }
    } catch (err: any) {
      this.logEvidence('command_error', { cmd: cmd.cmd, error: err.message });
      return false;
    }
  }

  /**
   * Process SigNoz webhook payload
   */
  async processWebhook(payload: SigNozAlert): Promise<void> {
    this.logEvidence('webhook_received', { 
      severity: payload.severity,
      state: payload.state,
      value: payload.value
    });

    const commands = this.mapAlert(payload);
    
    for (const cmd of commands) {
      await this.sendCommand(cmd);
      await new Promise(resolve => setTimeout(resolve, 100)); // Throttle
    }

    console.log(`[MILK] Processed ${commands.length} commands for ${payload.severity} alert`);
  }

  /**
   * Health check bridge connectivity
   */
  async checkBridge(): Promise<boolean> {
    try {
      const healthUrl = this.bridgeUrl.replace('/api/milk', '/health');
      const response = await fetch(healthUrl);
      const ok = response.ok;
      this.logEvidence('bridge_health', { status: ok ? 'ok' : 'fail', url: healthUrl });
      return ok;
    } catch (err: any) {
      this.logEvidence('bridge_health', { status: 'error', error: err.message });
      return false;
    }
  }

  /**
   * ECRR evidence export
   */
  exportEvidence(): string {
    return JSON.stringify({
      timestamp: new Date().toISOString(),
      agent: 'milk-signoz-mapper',
      lane: 'MILK',
      authority: 'BossCat OEM',
      phase: '3C',
      events: this.evidence
    }, null, 2);
  }

  private logEvidence(event: string, data: any): void {
    this.evidence.push({ timestamp: new Date().toISOString(), event, data });
  }
}

// CLI for testing
if (require.main === module) {
  const args = process.argv.slice(2);
  const command = args[0];
  const mapper = new SigNozMapper();

  (async () => {
    switch (command) {
      case 'test':
        console.log('[MILK] Testing alert mapping...');
        const testAlert: SigNozAlert = {
          severity: 'critical',
          state: 'firing',
          value: 95.5,
          labels: { service: 'api' }
        };
        await mapper.processWebhook(testAlert);
        console.log('[MILK] Test complete');
        break;

      case 'health':
        const ok = await mapper.checkBridge();
        console.log(`[MILK] Bridge health: ${ok ? 'OK' : 'FAIL'}`);
        process.exit(ok ? 0 : 1);

      case 'evidence':
        console.log(mapper.exportEvidence());
        break;

      default:
        console.log('Usage: tsx milk-signoz-mapper.ts [test|health|evidence]');
        process.exit(1);
    }
  })();
}

export { SigNozMapper };

