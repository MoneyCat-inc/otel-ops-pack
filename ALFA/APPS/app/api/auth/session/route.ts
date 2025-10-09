// API Auth Session Endpoint
// GET /api/auth/session

import { NextRequest, NextResponse } from 'next/server';

export async function GET(_request: NextRequest) {
  try {
    // For now, return a mock session
    // In production, this would validate JWT tokens or session cookies
    const session = {
      user: {
        id: 'demo-user-123',
        email: 'demo@resonai.com',
        name: 'Demo User',
      },
      expires: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // 24 hours
      isAuthenticated: true,
    };

    return NextResponse.json(session, { status: 200 });
  } catch (error) {
    return NextResponse.json(
      { 
        error: 'Session validation failed',
        message: error instanceof Error ? error.message : 'Unknown error'
      }, 
      { status: 401 }
    );
  }
}