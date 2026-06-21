import sql from 'mssql';

const sqlConfig = {
  user: process.env.DB_USER || 'sa',
  password: process.env.DB_PASSWORD || 'YourPassword123',
  database: process.env.DB_DATABASE || 'DigitalAfterlifeManager',
  server: process.env.DB_SERVER || 'localhost',
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000
  },
  options: {
    encrypt: false, // for azure set to true
    trustServerCertificate: true // set to true for local dev
  }
};

type GlobalWithSqlPool = typeof globalThis & {
  poolPromise?: Promise<sql.ConnectionPool>;
};

const globalWithSqlPool = globalThis as GlobalWithSqlPool;

function getPool() {
  if (!globalWithSqlPool.poolPromise) {
    globalWithSqlPool.poolPromise = new sql.ConnectionPool(sqlConfig)
      .connect()
      .then((pool) => {
        console.log('Connected to MSSQL');
        return pool;
      })
      .catch((err: unknown) => {
        console.error('Database connection failed:', err);
        globalWithSqlPool.poolPromise = undefined;
        throw err;
      });
  }

  return globalWithSqlPool.poolPromise;
}

export { getPool, sql };
