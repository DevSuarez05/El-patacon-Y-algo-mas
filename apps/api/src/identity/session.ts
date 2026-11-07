export interface SessionContext {
  sessionId: string;
  userId: string;
  organizationId: string;
  branchId: string;
  permissions: ReadonlySet<string>;
}

export const SESSION_KEY = 'session';
