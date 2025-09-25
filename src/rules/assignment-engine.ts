/**
 * ECRR Assignment Engine
 * Intelligent task assignment based on skills, WIP limits, and rotation
 */

export interface User {
  id: string;
  name: string;
  email: string;
  skills: string[];
  maxWip: number;
  oncall: boolean;
  active: boolean;
  currentWip: number; // calculated at runtime
}

export interface TaskAssignmentInput {
  taskId: string;
  reportId: string;
  requiredSkills: string[];
  priority: 1 | 2 | 3 | 4 | 5;
  category?: string;
  labels?: string[];
}

export interface AssignmentResult {
  assigneeId: string | null;
  assigneeName: string | null;
  assignmentStrategy: string;
  assignmentReason: string;
  wipRespected: boolean;
  alternatives: Array<{
    userId: string;
    userName: string;
    reason: string;
    wipAvailable: number;
  }>;
}

/**
 * Assignment strategies in order of preference
 */
export enum AssignmentStrategy {
  ONCALL_SKILLS_WIP = 'oncall-skills-wip',
  SKILLS_WIP_ROUNDROBIN = 'skills-wip-roundrobin',
  WIP_ONLY = 'wip-only',
  ANY_AVAILABLE = 'any-available',
  UNASSIGNED = 'unassigned'
}

/**
 * Main assignment logic
 */
export async function assignTask(
  users: User[],
  input: TaskAssignmentInput
): Promise<AssignmentResult> {
  
  // Filter active users only
  const activeUsers = users.filter(u => u.active);
  
  if (activeUsers.length === 0) {
    return {
      assigneeId: null,
      assigneeName: null,
      assignmentStrategy: AssignmentStrategy.UNASSIGNED,
      assignmentReason: 'No active users available',
      wipRespected: false,
      alternatives: []
    };
  }

  // Strategy 1: On-call users with required skills and WIP available
  const oncallWithSkills = findUsersWithSkills(activeUsers, input.requiredSkills)
    .filter(u => u.oncall && u.currentWip < u.maxWip)
    .sort((a, b) => a.currentWip - b.currentWip); // prefer users with fewer tasks

  if (oncallWithSkills.length > 0) {
    const assignee = oncallWithSkills[0];
    if (!assignee) return createUnassignedResult('No assignee available');
    return {
      assigneeId: assignee.id,
      assigneeName: assignee.name,
      assignmentStrategy: AssignmentStrategy.ONCALL_SKILLS_WIP,
      assignmentReason: `On-call user with required skills (${input.requiredSkills.join(', ')}) and WIP available`,
      wipRespected: true,
      alternatives: oncallWithSkills.slice(1).map(u => ({
        userId: u.id,
        userName: u.name,
        reason: 'On-call with skills',
        wipAvailable: u.maxWip - u.currentWip
      }))
    };
  }

  // Strategy 2: Users with required skills and WIP available (round-robin)
  const usersWithSkills = findUsersWithSkills(activeUsers, input.requiredSkills)
    .filter(u => u.currentWip < u.maxWip)
    .sort((a, b) => a.currentWip - b.currentWip);

  if (usersWithSkills.length > 0) {
    const assignee = usersWithSkills[0];
    if (!assignee) return createUnassignedResult('No assignee available');
    return {
      assigneeId: assignee.id,
      assigneeName: assignee.name,
      assignmentStrategy: AssignmentStrategy.SKILLS_WIP_ROUNDROBIN,
      assignmentReason: `User with required skills (${input.requiredSkills.join(', ')}) and WIP available`,
      wipRespected: true,
      alternatives: usersWithSkills.slice(1).map(u => ({
        userId: u.id,
        userName: u.name,
        reason: 'Has required skills',
        wipAvailable: u.maxWip - u.currentWip
      }))
    };
  }

  // Strategy 3: Any user with WIP available (ignore skills for now)
  const usersWithWip = activeUsers
    .filter(u => u.currentWip < u.maxWip)
    .sort((a, b) => a.currentWip - b.currentWip);

  if (usersWithWip.length > 0) {
    const assignee = usersWithWip[0];
    if (!assignee) return createUnassignedResult('No assignee available');
    return {
      assigneeId: assignee.id,
      assigneeName: assignee.name,
      assignmentStrategy: AssignmentStrategy.WIP_ONLY,
      assignmentReason: `User with WIP available (skills: ${assignee.skills.join(', ')})`,
      wipRespected: true,
      alternatives: usersWithWip.slice(1).map(u => ({
        userId: u.id,
        userName: u.name,
        reason: 'Has WIP available',
        wipAvailable: u.maxWip - u.currentWip
      }))
    };
  }

  // Strategy 4: Any available user (over WIP limit)
  const anyAvailable = activeUsers
    .sort((a, b) => a.currentWip - b.currentWip);

  if (anyAvailable.length > 0) {
    const assignee = anyAvailable[0];
    if (!assignee) return createUnassignedResult('No assignee available');
    return {
      assigneeId: assignee.id,
      assigneeName: assignee.name,
      assignmentStrategy: AssignmentStrategy.ANY_AVAILABLE,
      assignmentReason: `User assigned despite WIP limit (${assignee.currentWip}/${assignee.maxWip})`,
      wipRespected: false,
      alternatives: anyAvailable.slice(1).map(u => ({
        userId: u.id,
        userName: u.name,
        reason: 'Available but over WIP',
        wipAvailable: Math.max(0, u.maxWip - u.currentWip)
      }))
    };
  }

  // No assignment possible
  return {
    assigneeId: null,
    assigneeName: null,
    assignmentStrategy: AssignmentStrategy.UNASSIGNED,
    assignmentReason: 'No users available for assignment',
    wipRespected: false,
    alternatives: []
  };
}

/**
 * Find users who have all required skills
 */
function findUsersWithSkills(users: User[], requiredSkills: string[]): User[] {
  if (requiredSkills.length === 0) {
    return users; // No skill requirements
  }

  return users.filter(user => 
    requiredSkills.every(skill => 
      user.skills.some(userSkill => 
        userSkill.toLowerCase().includes(skill.toLowerCase()) ||
        skill.toLowerCase().includes(userSkill.toLowerCase())
      )
    )
  );
}

/**
 * Infer required skills from report category and labels
 */
export function inferRequiredSkills(category?: string, labels?: string[]): string[] {
  const skills: string[] = [];

  // Category-based skills
  if (category) {
    switch (category.toLowerCase()) {
      case 'security':
        skills.push('security', 'compliance');
        break;
      case 'performance':
        skills.push('performance', 'monitoring');
        break;
      case 'infrastructure':
        skills.push('infrastructure', 'ops');
        break;
      case 'frontend':
        skills.push('frontend', 'ui');
        break;
      case 'backend':
        skills.push('backend', 'api');
        break;
      case 'data':
        skills.push('data', 'analytics');
        break;
      default:
        skills.push('general');
    }
  }

  // Label-based skills
  if (labels) {
    labels.forEach(label => {
      switch (label.toLowerCase()) {
        case 'compliance':
          skills.push('compliance', 'legal');
          break;
        case 'customer-impact':
          skills.push('customer-support', 'sre');
          break;
        case 'security':
          skills.push('security');
          break;
        case 'production':
          skills.push('sre', 'ops');
          break;
        case 'database':
          skills.push('database', 'dba');
          break;
        case 'api':
          skills.push('backend', 'api');
          break;
        case 'frontend':
          skills.push('frontend', 'ui');
          break;
      }
    });
  }

  // Remove duplicates and return
  return [...new Set(skills)];
}

/**
 * Calculate current WIP for all users
 */
export async function calculateCurrentWip(users: User[], getTaskCount: (userId: string) => Promise<number>): Promise<User[]> {
  return Promise.all(
    users.map(async user => ({
      ...user,
      currentWip: await getTaskCount(user.id)
    }))
  );
}

/**
 * Get assignment statistics
 */
export function getAssignmentStats(users: User[]): {
  totalUsers: number;
  activeUsers: number;
  oncallUsers: number;
  usersAtWipLimit: number;
  averageWipUtilization: number;
} {
  const activeUsers = users.filter(u => u.active);
  const oncallUsers = activeUsers.filter(u => u.oncall);
  const usersAtWipLimit = activeUsers.filter(u => u.currentWip >= u.maxWip);
  
  const totalWipCapacity = activeUsers.reduce((sum, u) => sum + u.maxWip, 0);
  const totalCurrentWip = activeUsers.reduce((sum, u) => sum + u.currentWip, 0);
  const averageWipUtilization = totalWipCapacity > 0 ? (totalCurrentWip / totalWipCapacity) * 100 : 0;

  return {
    totalUsers: users.length,
    activeUsers: activeUsers.length,
    oncallUsers: oncallUsers.length,
    usersAtWipLimit: usersAtWipLimit.length,
    averageWipUtilization: Math.round(averageWipUtilization * 100) / 100
  };
}

/**
 * Helper method to create unassigned result
 */
function createUnassignedResult(reason: string): AssignmentResult {
  return {
    assigneeId: null,
    assigneeName: null,
    assignmentStrategy: AssignmentStrategy.UNASSIGNED,
    assignmentReason: reason,
    wipRespected: false,
    alternatives: []
  };
}
