#!/usr/bin/env node

/**
 * MEMX Test Script
 * 
 * Simple test to verify MEMX types and basic functionality
 */

const fs = require('fs');
const path = require('path');

console.log('🧪 MEMX Test Suite');
console.log('==================\n');

// Test 1: Check if TypeScript files exist
console.log('1. Checking file structure...');
const requiredFiles = [
  'src/engine/memx/types.ts',
  'src/engine/memx/store.ts', 
  'src/engine/memx/instrumentation.ts',
  'src/engine/memx/otelExporter.ts',
  'app/labs/memx/page.tsx'
];

let allFilesExist = true;
requiredFiles.forEach(file => {
  const filePath = path.join(__dirname, '..', file);
  if (fs.existsSync(filePath)) {
    console.log(`   ✅ ${file}`);
  } else {
    console.log(`   ❌ ${file}`);
    allFilesExist = false;
  }
});

if (allFilesExist) {
  console.log('   ✅ All required files present\n');
} else {
  console.log('   ❌ Some files missing\n');
  process.exit(1);
}

// Test 2: Check environment configuration
console.log('2. Checking environment configuration...');
const envExamplePath = path.join(__dirname, '..', 'env-example.txt');
if (fs.existsSync(envExamplePath)) {
  const envContent = fs.readFileSync(envExamplePath, 'utf8');
  const hasMemxFlags = envContent.includes('NEXT_PUBLIC_FEATURE_MEMX') &&
                      envContent.includes('NEXT_PUBLIC_MEMX_OTLP_ENDPOINT') &&
                      envContent.includes('NEXT_PUBLIC_MEMX_STREAM_DEFAULT');
  
  if (hasMemxFlags) {
    console.log('   ✅ MEMX environment variables configured');
  } else {
    console.log('   ❌ MEMX environment variables missing');
  }
} else {
  console.log('   ❌ env-example.txt not found');
}

// Test 3: Check package.json scripts
console.log('\n3. Checking package.json scripts...');
const packageJsonPath = path.join(__dirname, '..', 'package.json');
if (fs.existsSync(packageJsonPath)) {
  const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
  const requiredScripts = ['dev', 'build', 'lint', 'typecheck', 'test', 'ci'];
  
  let allScriptsExist = true;
  requiredScripts.forEach(script => {
    if (packageJson.scripts && packageJson.scripts[script]) {
      console.log(`   ✅ ${script}`);
    } else {
      console.log(`   ❌ ${script}`);
      allScriptsExist = false;
    }
  });
  
  if (allScriptsExist) {
    console.log('   ✅ All required scripts present');
  }
} else {
  console.log('   ❌ package.json not found');
}

// Test 4: Check Next.js configuration
console.log('\n4. Checking Next.js configuration...');
const nextConfigPath = path.join(__dirname, '..', 'next.config.js');
if (fs.existsSync(nextConfigPath)) {
  const nextConfig = fs.readFileSync(nextConfigPath, 'utf8');
  const hasCrossOriginIsolated = nextConfig.includes('crossOriginIsolated');
  const hasCSP = nextConfig.includes('Content-Security-Policy');
  const hasCOOP = nextConfig.includes('Cross-Origin-Opener-Policy');
  
  if (hasCrossOriginIsolated && hasCSP && hasCOOP) {
    console.log('   ✅ Next.js configured for cross-origin isolation and CSP');
  } else {
    console.log('   ❌ Next.js configuration incomplete');
  }
} else {
  console.log('   ❌ next.config.js not found');
}

// Test 5: Basic syntax check (simple regex-based)
console.log('\n5. Checking TypeScript syntax...');
const typesPath = path.join(__dirname, '..', 'src/engine/memx/types.ts');
if (fs.existsSync(typesPath)) {
  const typesContent = fs.readFileSync(typesPath, 'utf8');
  const hasExports = typesContent.includes('export type') || typesContent.includes('export interface');
  const hasMemxFrame = typesContent.includes('MemxFrame');
  const hasMemxSession = typesContent.includes('MemxSession');
  const hasConfig = typesContent.includes('MemxConfig');
  
  if (hasExports && hasMemxFrame && hasMemxSession && hasConfig) {
    console.log('   ✅ TypeScript types properly defined');
  } else {
    console.log('   ❌ TypeScript types incomplete');
  }
} else {
  console.log('   ❌ types.ts not found');
}

console.log('\n🎉 MEMX Test Suite Complete!');
console.log('\nNext steps:');
console.log('1. Run: npm install');
console.log('2. Copy env-example.txt to .env.local');
console.log('3. Set NEXT_PUBLIC_FEATURE_MEMX=1 in .env.local');
console.log('4. Run: npm run dev');
console.log('5. Visit: http://localhost:3000/labs/memx');
