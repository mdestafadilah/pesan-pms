import type { Config } from 'drizzle-kit';
import { join } from 'path';
import { existsSync, mkdirSync } from 'fs';

// Determine database path - use data directory in Docker environment
const dbPath = process.env.NODE_ENV === 'production'
  ? join(process.cwd(), 'data', 'pesan-pms.db')
  : 'pesan-pms.db';

// Ensure the data directory exists in production
if (process.env.NODE_ENV === 'production') {
  const dataDir = join(process.cwd(), 'data');
  if (!existsSync(dataDir)) {
    try {
      mkdirSync(dataDir, { recursive: true });
      console.log(`Created data directory at ${dataDir}`);
    } catch (error) {
      console.error(`Failed to create data directory: ${error}`);
    }
  }
}

export default {
  schema: './db/schema.ts',
  out: './drizzle',
  dialect: 'sqlite',
  dbCredentials: {
    url: dbPath,
  },
} satisfies Config;
