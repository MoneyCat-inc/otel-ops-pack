import { NextResponse } from "next/server";
import { loadLatest, summarize } from "@/scripts/memx/normalize";

export async function GET() {
  const snaps = loadLatest(".artifacts/memx/snapshots", 1);
  const sum = summarize(snaps) ?? { ok: false, reason: "no snapshots" };
  return NextResponse.json({ ok: !!snaps.length, latest: sum });
}
