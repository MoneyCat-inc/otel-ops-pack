import { test, expect } from "@playwright/test";

test("memx export returns zip", async ({ request }) => {
  const res = await request.get("/api/memx/export?limit=1");
  expect(res.status()).toBe(200);
  expect(res.headers()["content-type"]).toContain("application/zip");
  const buf = await res.body();
  expect(buf.byteLength).toBeGreaterThan(100); // some content
});

test("memx health endpoint", async ({ request }) => {
  const res = await request.get("/api/memx/health");
  expect(res.status()).toBe(200);
  const data = await res.json();
  expect(data).toHaveProperty("ok");
  expect(data).toHaveProperty("latest");
});

test("memx export with different limits", async ({ request }) => {
  // Test limit=1
  const res1 = await request.get("/api/memx/export?limit=1");
  expect(res1.status()).toBe(200);
  
  // Test limit=1000 (should clamp to 500)
  const res2 = await request.get("/api/memx/export?limit=1000");
  expect(res2.status()).toBe(200);
  
  // Test invalid limit (should default to 50)
  const res3 = await request.get("/api/memx/export?limit=invalid");
  expect(res3.status()).toBe(200);
});
