/* scripts/social/browser-login.ts
 * Helper to print current page snapshot for debugging
 */

console.log('Current browser MCP namespace: mcp_cursor-ide-browser');
console.log('');
console.log('To get page elements:');
console.log('  1. Call mcp_cursor-ide-browser_browser_snapshot');
console.log('  2. Check logs or response for element refs');
console.log('');
console.log('For Bluesky login:');
console.log('  - Navigate to: https://bsky.app/signin');
console.log('  - Find textbox refs in snapshot');
console.log('  - Type credentials:');
console.log('    * Handle: resonai.bsky.social');
console.log('    * Password: [from .env.socm]');
console.log('  - Click Next/Sign in button');


