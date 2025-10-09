# 🚀 Quick Reference for Cursor{implementer}

## 🎯 Current Build Status
```bash
# Current issues:
npm run build  # Still has TypeScript errors
# Main issues: unused parameters in scripts/agent/production-agent-system.ts
# ESLint config missing @typescript-eslint/recommended
```

## 🔧 Immediate Fixes Needed

### 1. Fix TypeScript Build
```bash
# Check specific errors
npm run build 2>&1 | grep "Type error"

# Likely fixes needed:
# - Mark unused parameters with underscore prefix (_param)
# - Fix any remaining error.message type issues
# - Resolve export type issues for isolatedModules
```

### 2. ESLint Configuration
```bash
# Install missing ESLint packages
npm install --save-dev @typescript-eslint/eslint-plugin @typescript-eslint/parser

# Update .eslintrc.js if needed
```

## 🏃‍♂️ Quick Start Commands

```bash
# 1. Fix build issues
npm run build

# 2. Start development
npm run dev

# 3. Test agent system
pwsh -File scripts/agent/simple-agent-orchestrator.ps1 -Duration 5

# 4. Check SigNoz
curl http://localhost:8080/api/v1/health
```

## 📁 Key Files to Focus On

### **IONA Flow Generator Core:**
- `app/page.tsx` - Main IONA interface
- `app/iona/` - Flow builder components (create this)
- `lib/flows/` - Flow execution engine (create this)

### **Current Issues:**
- `scripts/agent/production-agent-system.ts` - TypeScript errors
- `.eslintrc.js` - Missing TypeScript config
- `next.config.js` - Already fixed ✅

## 🎨 IONA Interface Mockup

```typescript
// Target IONA Flow Builder Structure
interface IONAFlowBuilder {
  nodes: FlowNode[];
  connections: Connection[];
  selectedNode?: string;
  executionStatus: 'idle' | 'running' | 'paused' | 'error';
}

// Example node types
type NodeType = 
  | 'input'      // Data sources
  | 'transform'  // Data processing  
  | 'condition'  // Branching logic
  | 'output'     // Destinations
  | 'loop'       // Iteration
  | 'delay'      // Timing control
```

## 🐾 BossCat Compliance Checklist

- [ ] All changes generate ECRR reports
- [ ] Evidence collection for operations
- [ ] BossCat approval for deployments
- [ ] Follow "Cat Nap Control Room" aesthetic
- [ ] Maintain observability standards

## 🎯 Success Criteria

1. **Build Success:** `npm run build` completes without errors
2. **IONA Interface:** Functional flow builder UI
3. **Flow Execution:** Basic flow execution engine
4. **SigNoz Integration:** Observability hooks working
5. **Agent System:** Background agents operational

---

**Ready to continue the IONA mission! 🐱**
