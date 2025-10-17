#!/usr/bin/env node
// BossCat lane verification for the ANTIclickbait docs bundle.
// Budget guard: maximum 10 files and 200 non-empty lines across HTML/CSS/JS.

const fs = require('fs');
const path = require('path');

const BUNDLE_DIR = 'docs/anticlickbait';
const MAX_FILES = 10;
const MAX_LOC = 200;

function countLoc(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  return content
    .split(/\r?\n/)
    .filter(line => line.trim().length > 0)
    .length;
}

function verifyBundle() {
  console.log('BossCat Lane Verification: ANTIclickbait');
  console.log('');

  if (!fs.existsSync(BUNDLE_DIR)) {
    console.error(`Bundle directory not found: ${BUNDLE_DIR}`);
    process.exit(1);
  }

  const entries = fs.readdirSync(BUNDLE_DIR).map(name => path.join(BUNDLE_DIR, name));
  const files = entries.filter(entry => fs.statSync(entry).isFile());
  const codeFiles = files.filter(file => /\.(html|css|js)$/i.test(file));

  const locCounts = codeFiles.map(file => ({
    file: path.basename(file),
    loc: countLoc(file)
  }));
  const totalLoc = locCounts.reduce((sum, item) => sum + item.loc, 0);

  console.log('Budget summary:');
  locCounts.forEach(item => {
    console.log(`  ${item.file}: ${item.loc} LOC`);
  });
  console.log(`  Total LOC: ${totalLoc} / ${MAX_LOC}`);
  console.log(`  File count: ${files.length} / ${MAX_FILES}`);

  const dataPath = path.join(BUNDLE_DIR, 'data.json');
  if (fs.existsSync(dataPath)) {
    const data = JSON.parse(fs.readFileSync(dataPath, 'utf8'));
    const categories = new Set(data.cards.map(card => card.category));
    const averageScore = data.cards.reduce((sum, card) => sum + card.score, 0) / data.cards.length;

    console.log('');
    console.log('Data summary:');
    console.log(`  Cards: ${data.cards.length}`);
    console.log(`  Categories: ${categories.size}`);
    console.log(`  Average score: ${averageScore.toFixed(1)} / 100`);
  }

  const locPass = totalLoc <= MAX_LOC;
  const filesPass = files.length <= MAX_FILES;

  console.log('');
  console.log('Result:');
  console.log(`  LOC budget: ${locPass ? 'PASS' : 'FAIL'}`);
  console.log(`  File budget: ${filesPass ? 'PASS' : 'FAIL'}`);

  if (locPass && filesPass) {
    console.log('  Overall: PASS');
    process.exit(0);
  }

  console.log('  Overall: FAIL');
  process.exit(1);
}

verifyBundle();
