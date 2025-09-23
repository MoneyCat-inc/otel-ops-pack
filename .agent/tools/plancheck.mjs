import fs from 'node:fs';
const plan = fs.readFileSync(0, 'utf8');
if (!/DIFF:([\s\S]+)/.test(plan)) { 
  console.error('No DIFF section found in plan');
  process.exit(1); 
}
if (!/PLAN:([\s\S]+)/.test(plan)) { 
  console.error('No PLAN section found in plan');
  process.exit(1); 
}
if (!/TEST:([\s\S]+)/.test(plan)) { 
  console.error('No TEST section found in plan');
  process.exit(1); 
}
console.log('PLANCHECK: OK - All required sections present');

