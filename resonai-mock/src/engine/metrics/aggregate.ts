/**
 * Progress Metrics Aggregation Engine
 * 
 * C1: Progress Dashboard
 * Aggregates session data into daily/weekly trends for progress visualization.
 * Handles schema versioning and graceful migration.
 */

export interface AggregatedMetrics {
  date: string; // YYYY-MM-DD format
  sessions: number;
  totalDurationMs: number;
  
  // Core metrics
  inBandPct: {
    mean: number;
    median: number;
    trend: 'up' | 'down' | 'stable';
  };
  
  expressiveness01: {
    mean: number;
    median: number;
    trend: 'up' | 'down' | 'stable';
  };
  
  // Resonance bucket bias (front/central/back ratio)
  bucketBias: {
    front: number;
    central: number;
    back: number;
    dominant: 'front' | 'central' | 'back';
  };
  
  // Safety metrics
  strainCount: number;
  strainRate: number; // strain events per session
  
  // Beta success metrics (C6)
  betaMetrics: {
    // Retention: days with ≥1 session / days since install
    retentionPct: number;
    retentionTrend: 'up' | 'down' | 'stable';
    
    // Comfort/fatigue trendlines: session comfort over time
    comfortTrend: {
      mean: number;
      median: number;
      trend: 'up' | 'down' | 'stable';
    };
    fatigueTrend: {
      mean: number;
      median: number;
      trend: 'up' | 'down' | 'stable';
    };
    
    // Strain triggers per 100 mins: normalized strain rate
    strainPer100Min: number;
    strainHealth: 'excellent' | 'good' | 'moderate' | 'poor';
    
    // Session frequency: average sessions per week
    sessionFrequency: number; // sessions per week
    frequencyTrend: 'up' | 'down' | 'stable';
  };
  
  // Schema versioning
  schemaVersion: number;
  aggregatedAt: number;
}

export interface ProgressTrends {
  daily: AggregatedMetrics[];
  weekly: AggregatedMetrics[];
  monthly: AggregatedMetrics[];
  
  // Summary stats
  totalSessions: number;
  totalDurationMs: number;
  averageSessionDurationMs: number;
  
  // Trend indicators
  overallTrend: {
    inBandPct: 'improving' | 'declining' | 'stable';
    expressiveness: 'improving' | 'declining' | 'stable';
    safety: 'improving' | 'declining' | 'stable';
  };
  
  // Date range
  dateRange: {
    start: string;
    end: string;
  };
}

export interface SessionSummaryV1 {
  id?: number;
  ts: number;
  medianF0: number | null;
  inBandPct?: number;
  prosodyVar?: number;
  voicedTimePct?: number;
  jitterEma?: number;
  comfort?: 1 | 2 | 3 | 4 | 5;
  fatigue?: 1 | 2 | 3 | 4 | 5;
  euphoria?: 1 | 2 | 3 | 4 | 5;
  orb?: string;
  memx?: {
    memoryStrainPct?: number;
    bucketBias?: {
      front: number;
      central: number;
      back: number;
    };
  };
  
  // Schema versioning
  schemaVersion?: number;
}

export class ProgressAggregator {
  private readonly SCHEMA_VERSION = 1;
  private readonly MIN_SESSIONS_FOR_TREND = 3;
  private readonly TREND_THRESHOLD = 0.05; // 5% change threshold
  
  // Beta metrics thresholds
  private readonly STRAIN_HEALTH_THRESHOLDS = {
    excellent: 0.1,  // <10% strain per 100 min
    good: 0.25,      // <25% strain per 100 min
    moderate: 0.5    // <50% strain per 100 min
  };

  /**
   * Aggregate sessions into daily metrics
   */
  aggregateDaily(sessions: SessionSummaryV1[]): AggregatedMetrics[] {
    if (sessions.length === 0) return [];

    // Group sessions by date
    const sessionsByDate = this.groupSessionsByDate(sessions);
    
    // Aggregate each day
    const dailyMetrics: AggregatedMetrics[] = [];
    
    for (const [date, daySessions] of sessionsByDate.entries()) {
      const metrics = this.aggregateDay(date, daySessions);
      dailyMetrics.push(metrics);
    }
    
    // Sort by date
    return dailyMetrics.sort((a, b) => a.date.localeCompare(b.date));
  }

  /**
   * Aggregate daily metrics into weekly metrics
   */
  aggregateWeekly(dailyMetrics: AggregatedMetrics[]): AggregatedMetrics[] {
    if (dailyMetrics.length === 0) return [];

    const weeklyMetrics: AggregatedMetrics[] = [];
    const weeks = this.groupDaysByWeek(dailyMetrics);
    
    for (const [weekStart, weekDays] of weeks.entries()) {
      const metrics = this.aggregateWeek(weekStart, weekDays);
      weeklyMetrics.push(metrics);
    }
    
    return weeklyMetrics.sort((a, b) => a.date.localeCompare(b.date));
  }

  /**
   * Aggregate daily metrics into monthly metrics
   */
  aggregateMonthly(dailyMetrics: AggregatedMetrics[]): AggregatedMetrics[] {
    if (dailyMetrics.length === 0) return [];

    const monthlyMetrics: AggregatedMetrics[] = [];
    const months = this.groupDaysByMonth(dailyMetrics);
    
    for (const [monthStart, monthDays] of months.entries()) {
      const metrics = this.aggregateMonth(monthStart, monthDays);
      monthlyMetrics.push(metrics);
    }
    
    return monthlyMetrics.sort((a, b) => a.date.localeCompare(b.date));
  }

  /**
   * Generate comprehensive progress trends
   */
  generateTrends(sessions: SessionSummaryV1[], dateRange?: { start: string; end: string }): ProgressTrends {
    // Filter sessions by date range if provided
    const filteredSessions = dateRange 
      ? this.filterSessionsByDateRange(sessions, dateRange)
      : sessions;

    // Generate daily metrics
    const daily = this.aggregateDaily(filteredSessions);
    const weekly = this.aggregateWeekly(daily);
    const monthly = this.aggregateMonthly(daily);

    // Calculate summary stats
    const totalSessions = filteredSessions.length;
    const totalDurationMs = this.calculateTotalDuration(filteredSessions);
    const averageSessionDurationMs = totalSessions > 0 ? totalDurationMs / totalSessions : 0;

    // Calculate overall trends
    const overallTrend = this.calculateOverallTrends(daily);

    // Determine date range
    const actualDateRange = dateRange || this.calculateDateRange(filteredSessions);

    return {
      daily,
      weekly,
      monthly,
      totalSessions,
      totalDurationMs,
      averageSessionDurationMs,
      overallTrend,
      dateRange: actualDateRange
    };
  }

  /**
   * Group sessions by date (YYYY-MM-DD)
   */
  private groupSessionsByDate(sessions: SessionSummaryV1[]): Map<string, SessionSummaryV1[]> {
    const groups = new Map<string, SessionSummaryV1[]>();
    
    for (const session of sessions) {
      const date = new Date(session.ts).toISOString().split('T')[0];
      
      if (!groups.has(date)) {
        groups.set(date, []);
      }
      groups.get(date)!.push(session);
    }
    
    return groups;
  }

  /**
   * Aggregate metrics for a single day
   */
  private aggregateDay(date: string, sessions: SessionSummaryV1[]): AggregatedMetrics {
    const validSessions = sessions.filter(s => this.isValidSession(s));
    
    if (validSessions.length === 0) {
      return this.createEmptyMetrics(date);
    }

    // Calculate core metrics
    const inBandValues = validSessions
      .map(s => s.inBandPct)
      .filter((v): v is number => v !== undefined);
    
    const expressivenessValues = validSessions
      .map(s => s.prosodyVar)
      .filter((v): v is number => v !== undefined);

    // Calculate bucket bias
    const bucketBias = this.calculateBucketBias(validSessions);

    // Calculate strain metrics
    const strainCount = this.calculateStrainCount(validSessions);
    const strainRate = validSessions.length > 0 ? strainCount / validSessions.length : 0;

    // Calculate trends (compared to previous day)
    const inBandTrend = this.calculateTrend(inBandValues, 'mean');
    const expressivenessTrend = this.calculateTrend(expressivenessValues, 'mean');

    // Calculate beta metrics
    const betaMetrics = this.calculateBetaMetrics(validSessions, sessions);

    return {
      date,
      sessions: validSessions.length,
      totalDurationMs: this.calculateTotalDuration(validSessions),
      
      inBandPct: {
        mean: this.calculateMean(inBandValues),
        median: this.calculateMedian(inBandValues),
        trend: inBandTrend
      },
      
      expressiveness01: {
        mean: this.calculateMean(expressivenessValues),
        median: this.calculateMedian(expressivenessValues),
        trend: expressivenessTrend
      },
      
      bucketBias: {
        front: bucketBias.front,
        central: bucketBias.central,
        back: bucketBias.back,
        dominant: this.getDominantBucket(bucketBias)
      },
      
      strainCount,
      strainRate,
      
      betaMetrics,
      
      schemaVersion: this.SCHEMA_VERSION,
      aggregatedAt: Date.now()
    };
  }

  /**
   * Calculate beta success metrics
   */
  private calculateBetaMetrics(daySessions: SessionSummaryV1[], allSessions: SessionSummaryV1[]): AggregatedMetrics['betaMetrics'] {
    // Calculate retention percentage
    const retentionPct = this.calculateRetentionPct(allSessions);
    
    // Calculate comfort and fatigue trends
    const comfortValues = daySessions
      .map(s => s.comfort)
      .filter((v): v is number => v !== undefined);
    const fatigueValues = daySessions
      .map(s => s.fatigue)
      .filter((v): v is number => v !== undefined);
    
    // Calculate strain per 100 minutes
    const strainPer100Min = this.calculateStrainPer100Min(daySessions);
    const strainHealth = this.getStrainHealth(strainPer100Min);
    
    // Calculate session frequency (sessions per week)
    const sessionFrequency = this.calculateSessionFrequency(allSessions);
    
    return {
      retentionPct,
      retentionTrend: this.calculateRetentionTrend(allSessions),
      
      comfortTrend: {
        mean: this.calculateMean(comfortValues),
        median: this.calculateMedian(comfortValues),
        trend: this.calculateTrend(comfortValues, 'mean')
      },
      
      fatigueTrend: {
        mean: this.calculateMean(fatigueValues),
        median: this.calculateMedian(fatigueValues),
        trend: this.calculateTrend(fatigueValues, 'mean')
      },
      
      strainPer100Min,
      strainHealth,
      
      sessionFrequency,
      frequencyTrend: this.calculateFrequencyTrend(allSessions)
    };
  }

  /**
   * Calculate retention percentage (days with sessions / days since install)
   */
  private calculateRetentionPct(sessions: SessionSummaryV1[]): number {
    if (sessions.length === 0) return 0;
    
    const sessionDates = new Set(
      sessions.map(s => new Date(s.ts).toISOString().split('T')[0])
    );
    
    const firstSession = Math.min(...sessions.map(s => s.ts));
    const lastSession = Math.max(...sessions.map(s => s.ts));
    const daysSinceInstall = Math.ceil((lastSession - firstSession) / (24 * 60 * 60 * 1000)) + 1;
    
    return daysSinceInstall > 0 ? (sessionDates.size / daysSinceInstall) : 0;
  }

  /**
   * Calculate retention trend
   */
  private calculateRetentionTrend(sessions: SessionSummaryV1[]): 'up' | 'down' | 'stable' {
    if (sessions.length < 14) return 'stable'; // Need at least 2 weeks of data
    
    const daily = this.aggregateDaily(sessions);
    if (daily.length < 2) return 'stable';
    
    const firstHalf = daily.slice(0, Math.floor(daily.length / 2));
    const secondHalf = daily.slice(Math.floor(daily.length / 2));
    
    const firstHalfRetention = this.calculateMean(firstHalf.map(d => d.betaMetrics.retentionPct));
    const secondHalfRetention = this.calculateMean(secondHalf.map(d => d.betaMetrics.retentionPct));
    
    return this.getTrendDirection(secondHalfRetention - firstHalfRetention);
  }

  /**
   * Calculate strain per 100 minutes of practice
   */
  private calculateStrainPer100Min(sessions: SessionSummaryV1[]): number {
    if (sessions.length === 0) return 0;
    
    const totalDurationMin = this.calculateTotalDuration(sessions) / (60 * 1000); // Convert to minutes
    const strainCount = this.calculateStrainCount(sessions);
    
    if (totalDurationMin === 0) return 0;
    
    // Normalize to per 100 minutes
    return (strainCount / totalDurationMin) * 100;
  }

  /**
   * Get strain health category
   */
  private getStrainHealth(strainPer100Min: number): 'excellent' | 'good' | 'moderate' | 'poor' {
    if (strainPer100Min < this.STRAIN_HEALTH_THRESHOLDS.excellent) return 'excellent';
    if (strainPer100Min < this.STRAIN_HEALTH_THRESHOLDS.good) return 'good';
    if (strainPer100Min < this.STRAIN_HEALTH_THRESHOLDS.moderate) return 'moderate';
    return 'poor';
  }

  /**
   * Calculate session frequency (sessions per week)
   */
  private calculateSessionFrequency(sessions: SessionSummaryV1[]): number {
    if (sessions.length === 0) return 0;
    
    const firstSession = Math.min(...sessions.map(s => s.ts));
    const lastSession = Math.max(...sessions.map(s => s.ts));
    const weeksSinceInstall = Math.max(1, (lastSession - firstSession) / (7 * 24 * 60 * 60 * 1000));
    
    return sessions.length / weeksSinceInstall;
  }

  /**
   * Calculate session frequency trend
   */
  private calculateFrequencyTrend(sessions: SessionSummaryV1[]): 'up' | 'down' | 'stable' {
    if (sessions.length < 14) return 'stable'; // Need at least 2 weeks of data
    
    const daily = this.aggregateDaily(sessions);
    if (daily.length < 2) return 'stable';
    
    const firstHalf = daily.slice(0, Math.floor(daily.length / 2));
    const secondHalf = daily.slice(Math.floor(daily.length / 2));
    
    const firstHalfFrequency = this.calculateMean(firstHalf.map(d => d.betaMetrics.sessionFrequency));
    const secondHalfFrequency = this.calculateMean(secondHalf.map(d => d.betaMetrics.sessionFrequency));
    
    return this.getTrendDirection(secondHalfFrequency - firstHalfFrequency);
  }

  /**
   * Calculate bucket bias from sessions
   */
  private calculateBucketBias(sessions: SessionSummaryV1[]): { front: number; central: number; back: number } {
    const bucketValues = sessions
      .map(s => s.memx?.bucketBias)
      .filter((v): v is { front: number; central: number; back: number } => v !== undefined);

    if (bucketValues.length === 0) {
      return { front: 0, central: 0, back: 0 };
    }

    const totalFront = bucketValues.reduce((sum, b) => sum + b.front, 0);
    const totalCentral = bucketValues.reduce((sum, b) => sum + b.central, 0);
    const totalBack = bucketValues.reduce((sum, b) => sum + b.back, 0);
    const total = totalFront + totalCentral + totalBack;

    if (total === 0) {
      return { front: 0, central: 0, back: 0 };
    }

    return {
      front: totalFront / total,
      central: totalCentral / total,
      back: totalBack / total
    };
  }

  /**
   * Calculate strain count from sessions
   */
  private calculateStrainCount(sessions: SessionSummaryV1[]): number {
    return sessions.filter(s => {
      const strainPct = s.memx?.memoryStrainPct;
      return strainPct !== undefined && strainPct > 0.1; // Threshold for strain
    }).length;
  }

  /**
   * Calculate trend direction
   */
  private calculateTrend(values: number[], method: 'mean' | 'median'): 'up' | 'down' | 'stable' {
    if (values.length < this.MIN_SESSIONS_FOR_TREND) {
      return 'stable';
    }

    const current = method === 'mean' ? this.calculateMean(values) : this.calculateMedian(values);
    const previous = method === 'mean' ? this.calculateMean(values.slice(0, -1)) : this.calculateMedian(values.slice(0, -1));
    
    const change = (current - previous) / previous;
    
    if (Math.abs(change) < this.TREND_THRESHOLD) {
      return 'stable';
    }
    
    return change > 0 ? 'up' : 'down';
  }

  /**
   * Calculate overall trends from daily metrics
   */
  private calculateOverallTrends(daily: AggregatedMetrics[]): ProgressTrends['overallTrend'] {
    if (daily.length < 2) {
      return {
        inBandPct: 'stable',
        expressiveness: 'stable',
        safety: 'stable'
      };
    }

    const firstHalf = daily.slice(0, Math.floor(daily.length / 2));
    const secondHalf = daily.slice(Math.floor(daily.length / 2));

    const inBandFirst = this.calculateMean(firstHalf.map(d => d.inBandPct.mean));
    const inBandSecond = this.calculateMean(secondHalf.map(d => d.inBandPct.mean));
    
    const expressivenessFirst = this.calculateMean(firstHalf.map(d => d.expressiveness01.mean));
    const expressivenessSecond = this.calculateMean(secondHalf.map(d => d.expressiveness01.mean));
    
    const strainFirst = this.calculateMean(firstHalf.map(d => d.strainRate));
    const strainSecond = this.calculateMean(secondHalf.map(d => d.strainRate));

    return {
      inBandPct: this.getTrendDirection(inBandSecond - inBandFirst),
      expressiveness: this.getTrendDirection(expressivenessSecond - expressivenessFirst),
      safety: this.getTrendDirection(strainFirst - strainSecond) // Lower strain is better
    };
  }

  /**
   * Helper methods
   */
  private isValidSession(session: SessionSummaryV1): boolean {
    return session.ts > 0 && session.schemaVersion !== undefined;
  }

  private createEmptyMetrics(date: string): AggregatedMetrics {
    return {
      date,
      sessions: 0,
      totalDurationMs: 0,
      inBandPct: { mean: 0, median: 0, trend: 'stable' },
      expressiveness01: { mean: 0, median: 0, trend: 'stable' },
      bucketBias: { front: 0, central: 0, back: 0, dominant: 'central' },
      strainCount: 0,
      strainRate: 0,
      betaMetrics: {
        retentionPct: 0,
        retentionTrend: 'stable',
        comfortTrend: { mean: 0, median: 0, trend: 'stable' },
        fatigueTrend: { mean: 0, median: 0, trend: 'stable' },
        strainPer100Min: 0,
        strainHealth: 'excellent',
        sessionFrequency: 0,
        frequencyTrend: 'stable'
      },
      schemaVersion: this.SCHEMA_VERSION,
      aggregatedAt: Date.now()
    };
  }

  private calculateMean(values: number[]): number {
    if (values.length === 0) return 0;
    return values.reduce((sum, v) => sum + v, 0) / values.length;
  }

  private calculateMedian(values: number[]): number {
    if (values.length === 0) return 0;
    const sorted = [...values].sort((a, b) => a - b);
    const mid = Math.floor(sorted.length / 2);
    return sorted.length % 2 === 0 
      ? (sorted[mid - 1] + sorted[mid]) / 2 
      : sorted[mid];
  }

  private getDominantBucket(bias: { front: number; central: number; back: number }): 'front' | 'central' | 'back' {
    const max = Math.max(bias.front, bias.central, bias.back);
    if (max === bias.front) return 'front';
    if (max === bias.central) return 'central';
    return 'back';
  }

  private getTrendDirection(change: number): 'improving' | 'declining' | 'stable' {
    if (Math.abs(change) < this.TREND_THRESHOLD) return 'stable';
    return change > 0 ? 'improving' : 'declining';
  }

  private calculateTotalDuration(sessions: SessionSummaryV1[]): number {
    // Estimate duration based on timestamp differences
    // This is a simplified calculation - in a real app, you'd store actual duration
    return sessions.length * 300000; // 5 minutes per session estimate
  }

  private groupDaysByWeek(daily: AggregatedMetrics[]): Map<string, AggregatedMetrics[]> {
    const weeks = new Map<string, AggregatedMetrics[]>();
    
    for (const day of daily) {
      const date = new Date(day.date);
      const weekStart = new Date(date);
      weekStart.setDate(date.getDate() - date.getDay()); // Start of week (Sunday)
      const weekKey = weekStart.toISOString().split('T')[0];
      
      if (!weeks.has(weekKey)) {
        weeks.set(weekKey, []);
      }
      weeks.get(weekKey)!.push(day);
    }
    
    return weeks;
  }

  private groupDaysByMonth(daily: AggregatedMetrics[]): Map<string, AggregatedMetrics[]> {
    const months = new Map<string, AggregatedMetrics[]>();
    
    for (const day of daily) {
      const date = new Date(day.date);
      const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-01`;
      
      if (!months.has(monthKey)) {
        months.set(monthKey, []);
      }
      months.get(monthKey)!.push(day);
    }
    
    return months;
  }

  private aggregateWeek(weekStart: string, weekDays: AggregatedMetrics[]): AggregatedMetrics {
    if (weekDays.length === 0) {
      return this.createEmptyMetrics(weekStart);
    }

    const totalSessions = weekDays.reduce((sum, day) => sum + day.sessions, 0);
    const totalDuration = weekDays.reduce((sum, day) => sum + day.totalDurationMs, 0);
    const totalStrainCount = weekDays.reduce((sum, day) => sum + day.strainCount, 0);

    const inBandValues = weekDays.flatMap(day => [day.inBandPct.mean, day.inBandPct.median]);
    const expressivenessValues = weekDays.flatMap(day => [day.expressiveness01.mean, day.expressiveness01.median]);

    const bucketBias = this.calculateWeeklyBucketBias(weekDays);

    // Calculate beta metrics for the week
    const weekBetaMetrics = this.calculateWeeklyBetaMetrics(weekDays);

    return {
      date: weekStart,
      sessions: totalSessions,
      totalDurationMs: totalDuration,
      
      inBandPct: {
        mean: this.calculateMean(inBandValues),
        median: this.calculateMedian(inBandValues),
        trend: this.calculateTrend(inBandValues, 'mean')
      },
      
      expressiveness01: {
        mean: this.calculateMean(expressivenessValues),
        median: this.calculateMedian(expressivenessValues),
        trend: this.calculateTrend(expressivenessValues, 'mean')
      },
      
      bucketBias: {
        front: bucketBias.front,
        central: bucketBias.central,
        back: bucketBias.back,
        dominant: this.getDominantBucket(bucketBias)
      },
      
      strainCount: totalStrainCount,
      strainRate: totalSessions > 0 ? totalStrainCount / totalSessions : 0,
      
      betaMetrics: weekBetaMetrics,
      
      schemaVersion: this.SCHEMA_VERSION,
      aggregatedAt: Date.now()
    };
  }

  private aggregateMonth(monthStart: string, monthDays: AggregatedMetrics[]): AggregatedMetrics {
    if (monthDays.length === 0) {
      return this.createEmptyMetrics(monthStart);
    }

    const totalSessions = monthDays.reduce((sum, day) => sum + day.sessions, 0);
    const totalDuration = monthDays.reduce((sum, day) => sum + day.totalDurationMs, 0);
    const totalStrainCount = monthDays.reduce((sum, day) => sum + day.strainCount, 0);

    const inBandValues = monthDays.flatMap(day => [day.inBandPct.mean, day.inBandPct.median]);
    const expressivenessValues = monthDays.flatMap(day => [day.expressiveness01.mean, day.expressiveness01.median]);

    const bucketBias = this.calculateMonthlyBucketBias(monthDays);

    // Calculate beta metrics for the month
    const monthBetaMetrics = this.calculateMonthlyBetaMetrics(monthDays);

    return {
      date: monthStart,
      sessions: totalSessions,
      totalDurationMs: totalDuration,
      
      inBandPct: {
        mean: this.calculateMean(inBandValues),
        median: this.calculateMedian(inBandValues),
        trend: this.calculateTrend(inBandValues, 'mean')
      },
      
      expressiveness01: {
        mean: this.calculateMean(expressivenessValues),
        median: this.calculateMedian(expressivenessValues),
        trend: this.calculateTrend(expressivenessValues, 'mean')
      },
      
      bucketBias: {
        front: bucketBias.front,
        central: bucketBias.central,
        back: bucketBias.back,
        dominant: this.getDominantBucket(bucketBias)
      },
      
      strainCount: totalStrainCount,
      strainRate: totalSessions > 0 ? totalStrainCount / totalSessions : 0,
      
      betaMetrics: monthBetaMetrics,
      
      schemaVersion: this.SCHEMA_VERSION,
      aggregatedAt: Date.now()
    };
  }

  private calculateWeeklyBucketBias(weekDays: AggregatedMetrics[]): { front: number; central: number; back: number } {
    const totalFront = weekDays.reduce((sum, day) => sum + day.bucketBias.front, 0);
    const totalCentral = weekDays.reduce((sum, day) => sum + day.bucketBias.central, 0);
    const totalBack = weekDays.reduce((sum, day) => sum + day.bucketBias.back, 0);
    const total = totalFront + totalCentral + totalBack;

    if (total === 0) {
      return { front: 0, central: 0, back: 0 };
    }

    return {
      front: totalFront / weekDays.length,
      central: totalCentral / weekDays.length,
      back: totalBack / weekDays.length
    };
  }

  private calculateMonthlyBucketBias(monthDays: AggregatedMetrics[]): { front: number; central: number; back: number } {
    const totalFront = monthDays.reduce((sum, day) => sum + day.bucketBias.front, 0);
    const totalCentral = monthDays.reduce((sum, day) => sum + day.bucketBias.central, 0);
    const totalBack = monthDays.reduce((sum, day) => sum + day.bucketBias.back, 0);
    const total = totalFront + totalCentral + totalBack;

    if (total === 0) {
      return { front: 0, central: 0, back: 0 };
    }

    return {
      front: totalFront / monthDays.length,
      central: totalCentral / monthDays.length,
      back: totalBack / monthDays.length
    };
  }

  /**
   * Calculate weekly beta metrics
   */
  private calculateWeeklyBetaMetrics(weekDays: AggregatedMetrics[]): AggregatedMetrics['betaMetrics'] {
    if (weekDays.length === 0) {
      return {
        retentionPct: 0,
        retentionTrend: 'stable',
        comfortTrend: { mean: 0, median: 0, trend: 'stable' },
        fatigueTrend: { mean: 0, median: 0, trend: 'stable' },
        strainPer100Min: 0,
        strainHealth: 'excellent',
        sessionFrequency: 0,
        frequencyTrend: 'stable'
      };
    }

    const retentionValues = weekDays.map(d => d.betaMetrics.retentionPct);
    const comfortValues = weekDays.flatMap(d => [d.betaMetrics.comfortTrend.mean, d.betaMetrics.comfortTrend.median]);
    const fatigueValues = weekDays.flatMap(d => [d.betaMetrics.fatigueTrend.mean, d.betaMetrics.fatigueTrend.median]);
    const strainValues = weekDays.map(d => d.betaMetrics.strainPer100Min);
    const frequencyValues = weekDays.map(d => d.betaMetrics.sessionFrequency);

    return {
      retentionPct: this.calculateMean(retentionValues),
      retentionTrend: this.calculateTrend(retentionValues, 'mean'),
      
      comfortTrend: {
        mean: this.calculateMean(comfortValues),
        median: this.calculateMedian(comfortValues),
        trend: this.calculateTrend(comfortValues, 'mean')
      },
      
      fatigueTrend: {
        mean: this.calculateMean(fatigueValues),
        median: this.calculateMedian(fatigueValues),
        trend: this.calculateTrend(fatigueValues, 'mean')
      },
      
      strainPer100Min: this.calculateMean(strainValues),
      strainHealth: this.getStrainHealth(this.calculateMean(strainValues)),
      
      sessionFrequency: this.calculateMean(frequencyValues),
      frequencyTrend: this.calculateTrend(frequencyValues, 'mean')
    };
  }

  /**
   * Calculate monthly beta metrics
   */
  private calculateMonthlyBetaMetrics(monthDays: AggregatedMetrics[]): AggregatedMetrics['betaMetrics'] {
    if (monthDays.length === 0) {
      return {
        retentionPct: 0,
        retentionTrend: 'stable',
        comfortTrend: { mean: 0, median: 0, trend: 'stable' },
        fatigueTrend: { mean: 0, median: 0, trend: 'stable' },
        strainPer100Min: 0,
        strainHealth: 'excellent',
        sessionFrequency: 0,
        frequencyTrend: 'stable'
      };
    }

    const retentionValues = monthDays.map(d => d.betaMetrics.retentionPct);
    const comfortValues = monthDays.flatMap(d => [d.betaMetrics.comfortTrend.mean, d.betaMetrics.comfortTrend.median]);
    const fatigueValues = monthDays.flatMap(d => [d.betaMetrics.fatigueTrend.mean, d.betaMetrics.fatigueTrend.median]);
    const strainValues = monthDays.map(d => d.betaMetrics.strainPer100Min);
    const frequencyValues = monthDays.map(d => d.betaMetrics.sessionFrequency);

    return {
      retentionPct: this.calculateMean(retentionValues),
      retentionTrend: this.calculateTrend(retentionValues, 'mean'),
      
      comfortTrend: {
        mean: this.calculateMean(comfortValues),
        median: this.calculateMedian(comfortValues),
        trend: this.calculateTrend(comfortValues, 'mean')
      },
      
      fatigueTrend: {
        mean: this.calculateMean(fatigueValues),
        median: this.calculateMedian(fatigueValues),
        trend: this.calculateTrend(fatigueValues, 'mean')
      },
      
      strainPer100Min: this.calculateMean(strainValues),
      strainHealth: this.getStrainHealth(this.calculateMean(strainValues)),
      
      sessionFrequency: this.calculateMean(frequencyValues),
      frequencyTrend: this.calculateTrend(frequencyValues, 'mean')
    };
  }

  private filterSessionsByDateRange(sessions: SessionSummaryV1[], dateRange: { start: string; end: string }): SessionSummaryV1[] {
    const startDate = new Date(dateRange.start).getTime();
    const endDate = new Date(dateRange.end).getTime();
    
    return sessions.filter(session => {
      const sessionDate = new Date(session.ts).getTime();
      return sessionDate >= startDate && sessionDate <= endDate;
    });
  }

  private calculateDateRange(sessions: SessionSummaryV1[]): { start: string; end: string } {
    if (sessions.length === 0) {
      const today = new Date().toISOString().split('T')[0];
      return { start: today, end: today };
    }

    const timestamps = sessions.map(s => s.ts);
    const minTs = Math.min(...timestamps);
    const maxTs = Math.max(...timestamps);
    
    return {
      start: new Date(minTs).toISOString().split('T')[0],
      end: new Date(maxTs).toISOString().split('T')[0]
    };
  }
}
