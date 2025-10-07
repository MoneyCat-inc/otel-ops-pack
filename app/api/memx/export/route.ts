import { NextRequest, NextResponse } from "next/server";
import { loadLatest } from "@/scripts/memx/normalize";
import JSZip from "jszip";

export const dynamic = "error"; // static for security; compute on demand

export async function GET(req: NextRequest) {
  const url = new URL(req.url);
  const limit = Math.min(Math.max(parseInt(url.searchParams.get("limit") || "50", 10), 1), 500);
  const snaps = loadLatest(".artifacts/memx/snapshots", limit);
  const zip = new JSZip();
  snaps.forEach((s, i) => {
    const name = `${i.toString().padStart(3,"0")}_${s.ts.replace(/:/g,"-")}_${s.snapshot_id}.json`;
    zip.file(name, JSON.stringify(s, null, 2));
  });
  const blob = await zip.generateAsync({ type: "nodebuffer" });
  return new NextResponse(blob, {
    status: 200,
    headers: {
      "content-type": "application/zip",
      "content-disposition": `attachment; filename="memx_export_${Date.now()}.zip"`
    }
  });
}
