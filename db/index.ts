import { drizzle } from 'drizzle-orm/better-sqlite3';
import Database from 'better-sqlite3';
import * as schema from './schema';
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

// Initialize SQLite database
const sqlite = new Database(dbPath);

// Initialize Drizzle ORM
export const db = drizzle(sqlite, { schema });

// Export schema for use in other files
export { schema };
