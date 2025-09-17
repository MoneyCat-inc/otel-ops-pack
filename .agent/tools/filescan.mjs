import fs from "node:fs";
import path from "node:path";

const scanDir = (dir, excluded = []) => {
  const files = [];
  const items = fs.readdirSync(dir);
  
  for (const item of items) {
    const fullPath = path.join(dir, item);
    const stat = fs.statSync(fullPath);
    
    if (stat.isDirectory()) {
      if (!excluded.some(ex => fullPath.includes(ex))) {
        files.push(...scanDir(fullPath, excluded));
      }
    } else {
      files.push(fullPath);
    }
  }
  
  return files;
};

const manifest = scanDir(".", ["node_modules", "dist", ".git", ".agent/state"]);
console.log(`FILESCAN: Found ${manifest.length} files`);
console.log("Manifest:", manifest.slice(0, 10), manifest.length > 10 ? "..." : "");

