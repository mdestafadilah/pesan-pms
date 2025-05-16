import type { Config } from 'drizzle-kit';
import { join } from 'path';

// Determine database path - use data directory in Docker environment
const dbPath = process.env.NODE_ENV === 'production'
  ? join(process.cwd(), 'data', 'pesan-pms.db')
  : 'pesan-pms.db';

export default {
  schema: './db/schema.ts',
  out: './drizzle',
  dialect: 'sqlite',
  dbCredentials: {
    url: dbPath,
  },
} satisfies Config;
