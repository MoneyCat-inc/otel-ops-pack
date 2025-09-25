/**
 * ECRR Priority Calculator
 * Deterministic priority scoring based on impact, aging, and context
 */

export interface PriorityInput {
  severity: 'low' | 'medium' | 'high' | 'critical';
  discoveredAt: Date;
  blocksOthers?: boolean;
  labels?: string[];
  openTasksOnReport?: number;
  hasOwner?: boolean;
}

export interface PriorityOutput {
  priority: 1 | 2 | 3 | 4 | 5; // 1 = highest, 5 = lowest
  priorityScore: number;
  rawScore: number;
  breakdown: {
    severityWeight: number;
    ageWeight: number;
    blockerWeight: number;
    ownerWeight: number;
    taskVolumeWeight: number;
    manualBoost: number;
  };
}

/**
 * Calculate priority score using deterministic formula
 */
export function computePriority(input: PriorityInput): PriorityOutput {
  // Impact weights (higher = more urgent)
  const severityWeights = {
    critical: 10,
    high: 7,
    medium: 4,
    low: 1
  };

  // Calculate age weight (caps at 5 to prevent infinite aging)
  const ageDays = Math.max(0, (Date.now() - input.discoveredAt.getTime()) / 86400000);
  const ageWeight = Math.min(ageDays * 0.5, 5);

  // Blocker weight (if this report blocks others)
  const blockerWeight = input.blocksOthers ? 3 : 0;

  // Owner weight (missing owner increases priority)
  const ownerWeight = input.hasOwner ? 0 : 25;

  // Task volume weight (many open tasks on report increases priority)
  const taskVolumeWeight = (input.openTasksOnReport || 0) > 5 ? 10 : 0;

  // Manual boost from labels
  const manualBoost = (input.labels || []).reduce((acc, label) => {
    switch (label) {
      case 'compliance': return acc + 3;
      case 'customer_impact': return acc + 2;
      case 'security': return acc + 4;
      case 'production': return acc + 2;
      default: return acc;
    }
  }, 0);

  const breakdown = {
    severityWeight: severityWeights[input.severity],
    ageWeight,
    blockerWeight,
    ownerWeight,
    taskVolumeWeight,
    manualBoost
  };

  // Calculate raw score
  const rawScore = breakdown.severityWeight + 
                   breakdown.ageWeight + 
                   breakdown.blockerWeight + 
                   breakdown.ownerWeight + 
                   breakdown.taskVolumeWeight + 
                   breakdown.manualBoost;

  // Map raw score to priority levels
  let priority: 1 | 2 | 3 | 4 | 5;
  if (rawScore >= 12) priority = 1;
  else if (rawScore >= 9) priority = 2;
  else if (rawScore >= 6) priority = 3;
  else if (rawScore >= 3) priority = 4;
  else priority = 5;

  // Calculate final priority score (for sorting within same priority level)
  const priorityScore = (6 - priority) * 1000 + Math.floor(rawScore * 10);

  return {
    priority,
    priorityScore,
    rawScore,
    breakdown
  };
}

/**
 * Calculate SLA due date based on priority
 */
export function computeSlaDueAt(priority: 1 | 2 | 3 | 4 | 5, createdAt: Date = new Date()): Date {
  const slaDays = {
    1: 2,   // Critical: 2 business days
    2: 5,   // High: 5 business days
    3: 10,  // Medium: 10 business days
    4: 20,  // Low: 20 business days
    5: 30   // Backlog: 30 business days
  };

  const dueDate = new Date(createdAt);
  dueDate.setDate(dueDate.getDate() + slaDays[priority]);
  
  return dueDate;
}

/**
 * Check if task is approaching SLA deadline
 */
export function getSlaStatus(dueAt: Date | null, currentState: string): 'OVERDUE' | 'DUE_SOON' | 'ON_TRACK' {
  if (!dueAt || currentState === 'DONE') {
    return 'ON_TRACK';
  }

  const now = new Date();
  const hoursUntilDue = (dueAt.getTime() - now.getTime()) / (1000 * 60 * 60);

  if (hoursUntilDue < 0) {
    return 'OVERDUE';
  } else if (hoursUntilDue <= 24) {
    return 'DUE_SOON';
  } else {
    return 'ON_TRACK';
  }
}

/**
 * Get priority color for UI display
 */
export function getPriorityColor(priority: 1 | 2 | 3 | 4 | 5): string {
  switch (priority) {
    case 1: return '#dc2626'; // red
    case 2: return '#ea580c'; // orange
    case 3: return '#d97706'; // amber
    case 4: return '#16a34a'; // green
    case 5: return '#6b7280'; // gray
    default: return '#6b7280';
  }
}

/**
 * Get priority label for display
 */
export function getPriorityLabel(priority: 1 | 2 | 3 | 4 | 5): string {
  switch (priority) {
    case 1: return 'Critical';
    case 2: return 'High';
    case 3: return 'Medium';
    case 4: return 'Low';
    case 5: return 'Backlog';
    default: return 'Unknown';
  }
}
