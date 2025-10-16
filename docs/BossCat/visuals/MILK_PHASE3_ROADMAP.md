# MILK Phase-3 Roadmap - AI Integration

**Lane**: MILK (MilkDrop Integration Layer & Kit)  
**Authority**: BossCat OEM  
**Research-Backed**: Based on industry analysis (AI-Enhanced MilkDrop-Style Audio Vi.txt)  
**Current Phase**: Phase-2 Complete  
**Next Phase**: Phase-3 (AI Integration)

---

## Phase-2 Foundation (Complete) ✅

**Delivered**:
- ✅ Butterchurn WebGL2 control surface (control.html)
- ✅ TypeScript automation shim (visu-shim.ts, 61 LOC)
- ✅ Documentation suite (CONTROL_README.md, MILK_TETRAGRAM.md)
- ✅ postMessage automation API
- ✅ ECRR compliance (evidence logs, audit trail)

**Budget**: 4 files, 61 LOC, 100% compliant

**Validation**: ✅ Research confirms Butterchurn + postMessage is industry best practice

---

## Phase-3: AI Integration (Planned)

### 3A: WebSocket Automation Bridge (30 days)

**Objective**: Enable remote control from BossCat agents

**Research Backing**:
> "Expose a small API over WebSocket or Electron's IPC for external process control"

**Deliverables**:
- `scripts/visuals/milk-ws-bridge.ts` (≤200 LOC)
- WebSocket server: `ws://localhost:8899`
- REST-like commands over WS
- Bridge WS → postMessage to control.html

**API**:
```typescript
ws.send(JSON.stringify({ cmd: 'loadPreset', name: 'Geiss' }));
ws.send(JSON.stringify({ cmd: 'setBlend', seconds: 3.0 }));
ws.send(JSON.stringify({ cmd: 'auto', enabled: true }));
```

**Budget**: 1 job, 3 files, ≤200 LOC  
**Lane**: MILK  
**Priority**: HIGH (enables BossCat agent control)

### 3B: MilkDropLM Preset Generator (60 days)

**Objective**: AI-generated presets from natural language

**Research Backing**:
> "MilkDropLM 7B model generates .milk presets from text prompts"  
> "~1 in 24 AI presets are high quality after curation"

**Deliverables**:
- `scripts/visuals/milk-llm-gen.ts` (≤200 LOC)
- HuggingFace Inference API client
- Prompt → .milk file generation
- Auto-save to `docs/BossCat/visuals/presets/ai-generated/`
- Curation script (quality filtering)

**Workflow**:
```
1. User/BossCat: "Create a calm ocean waves preset"
2. MilkDropLM: Generate .milk code
3. Save: ai-generated/ocean-calm-001.milk
4. Test: Load in control.html
5. Curate: Keep if quality ≥threshold
```

**Budget**: 1 job, 5 files, ≤200 LOC  
**Lane**: MILK  
**Priority**: MEDIUM (creative enhancement)

**Safety**:
- ⚠️ Validate all AI outputs (shader sandboxing)
- ⚠️ Epilepsy check (flash detection)
- ⚠️ Performance test (GPU load)

### 3C: SigNoz Alert Integration (90 days)

**Objective**: Map observability events to visual states

**Research Backing**:
> "Sentiment analysis → preset switching"  
> "Alert state → visual theme"

**Deliverables**:
- `scripts/visuals/milk-signoz-mapper.ts` (≤200 LOC)
- Listen to SigNoz webhooks/API
- Map alert severity → preset selection
- Trigger via WebSocket bridge

**Mapping Schema**:
```yaml
alert_severity:
  critical: "Geiss - Strobe (Red Mix)"      # Intense, alerting
  high:     "Flexi - Rovastar Altars"       # Active, attention
  medium:   "Unchained - Plasma Drift"      # Moderate activity
  low:      "Resonai - Default (Neon Pulse)" # Calm, normal
  none:     "Krash - Gentle Ocean"          # All clear

observability_states:
  error_spike: Switch to alert preset + auto-cycle OFF
  all_clear:   Return to default + auto-cycle ON
  performance: Blend time based on queue pressure
```

**Budget**: 1 job, 4 files, ≤200 LOC  
**Lane**: MILK + DELT (integration)  
**Priority**: HIGH (core BossCat value)

### 3D: Voice Visualization (120+ days)

**Objective**: Visualize LLM voice responses in real-time

**Research Backing**:
> "Voice audio spectrum drives reactive graphics"  
> "Living avatar feel for AI voice"

**Deliverables**:
- Integration with OpenAI Realtime API
- Voice → Butterchurn audio stream
- Speech phonetics → waveform animation
- Sentiment → color palette shifts

**Use Case**:
- IONA speaks error report → voice drives visuals
- Calm explanation → smooth waves
- Urgent alert → sharp, rapid visuals

**Budget**: 2 jobs, 6 files, ≤400 LOC  
**Lane**: MILK + ALFA  
**Priority**: FUTURE (experimental)

---

## Technology Stack Evolution

### Phase-2 (Current)
```
Browser (Chrome/Edge on Win11)
  ├── control.html (Butterchurn WebGL2)
  ├── Web Audio API (mic input)
  └── postMessage API
```

### Phase-3A (WebSocket Bridge)
```
BossCat Agent
  └── WebSocket → milk-ws-bridge.ts
       └── postMessage → control.html (Butterchurn)
```

### Phase-3B (LLM Generator)
```
Natural Language Prompt
  └── MilkDropLM (HuggingFace API)
       └── .milk file → control.html preset library
```

### Phase-3C (SigNoz Integration)
```
SigNoz Alert
  └── milk-signoz-mapper.ts
       └── WebSocket Bridge
            └── control.html (preset change)
```

### Phase-3D (Voice)
```
OpenAI Realtime API (voice)
  └── Audio Stream → Butterchurn
       └── Phonetic spectrum → reactive visuals
```

---

## Budget Planning

### Total Phase-3 Budget
- **Jobs**: 5 (3A: 1, 3B: 1, 3C: 1, 3D: 2)
- **Files**: 18 total (across all sub-phases)
- **LOC**: ≤1000 total (all within per-job limits)

### Per Sub-Phase
| Phase | Jobs | Files | LOC | Priority |
|-------|------|-------|-----|----------|
| 3A (WS Bridge) | 1 | 3 | ≤200 | HIGH |
| 3B (LLM Gen) | 1 | 5 | ≤200 | MEDIUM |
| 3C (SigNoz) | 1 | 4 | ≤200 | HIGH |
| 3D (Voice) | 2 | 6 | ≤400 | FUTURE |
| **Total** | **5** | **18** | **≤1000** | - |

All within BossCat governance limits (≤10 files per phase, ≤200 LOC per job)

---

## Research Citations

### Key Technologies
1. **Butterchurn**: GitHub jberg/butterchurn - WebGL MilkDrop implementation
2. **MilkDropLM**: HuggingFace InferenceIllusionist/MilkDropLM-7b-v0.3
3. **MilkDrop3**: GitHub milkdrop2077/MilkDrop3 - Modern standalone
4. **ProjectM**: GitHub projectM-visualizer/projectm - Cross-platform library

### Integration Examples
5. **OpenAI Realtime + Visuals**: flo-bit/svelte-openai-realtime-api
6. **TouchDesigner + AI**: ChatGPT shader generation examples
7. **NestDrop OSC**: OSC remote control for VJ workflows

### Community
8. **/r/MilkDrop**: Reddit community, preset sharing
9. **Cream of the Crop**: 9,795 curated presets (2001-2019)
10. **Preset Authoring Guide**: Ryan Geiss documentation

---

## Success Criteria

### Phase-3 Gates
- ✅ WebSocket bridge: Commands execute in <100ms
- ✅ LLM presets: ≥1 in 24 quality rate (per research)
- ✅ SigNoz integration: Alert → visual change in <500ms
- ✅ Safety: No epilepsy triggers, all presets validated
- ✅ Budget: All sub-phases within limits
- ✅ ECRR: Complete evidence trail

### Quality Metrics
- Response time: <100ms (WS commands)
- Preset generation: >4% quality rate
- GPU utilization: <80% (sustained)
- Memory footprint: <500MB (browser)

---

**🐾 BossCat Seal**: MILK Phase-3 Roadmap - Research-Validated

*AI-enhanced MilkDrop automation aligned with industry best practices*

---

*Roadmap by: cursor{implementer} under BossCat OEM authority*  
*Research-backed: 10 key technology citations validated*  
*Timeline: 30-120 days across 5 sub-phases*

