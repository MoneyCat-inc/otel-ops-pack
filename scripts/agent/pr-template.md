### What changed
- [ ] Added queue configuration flags system (`lib/config/queue.ts`)
- [ ] Implemented SQLite DAL with WAL support (`scripts/agent/db.ts`)
- [ ] Created JSON to SQLite migrator (`scripts/agent/migrate/from-json.ts`)
- [ ] Added comprehensive unit tests (`scripts/agent/db.test.ts`)
- [ ] Created test script for verification (`scripts/agent/test-sqlite.ts`)

### Safety rails checked
- [ ] .agent/LOCK respected; budgets enforced
- [ ] Local-first only; CSP/COOP/COEP intact
- [ ] SSOT markers unchanged; CI summary stable

### Tests & evidence
- [ ] pnpm run ci green (link)
- [ ] SQLite DAL tests pass: `npx tsx scripts/agent/test-sqlite.ts`
- [ ] Unit tests pass: `npx jest scripts/agent/db.test.ts`
- [ ] Configuration validation works: `npx tsx -e "console.log(require('./lib/config/queue').describeQueueConfig(require('./lib/config/queue').getQueueConfig()))"`

### Rollback
- Flags: QUEUE_DRIVER=json or QUEUE_ENABLED=0
- This PR only adds shadow-only, inert SQLite support - no behavior changes until PR-B