const { Client: PGClient } = require('pg');
const mysql = require('mysql2/promise');

exports.handler = async (event) => {
    try {
        const dbEngine = process.env.DB_ENGINE;
        console.log(`Starting user creation for ${dbEngine}`);
        
        await createUsers(dbEngine);
        
        return {
            statusCode: 200,
            body: "Users created successfully"
        };
    } catch (err) {
        console.error("Error creating users:", err);
        throw err;
    }
};

async function createUsers(dbEngine) {
    let connection;
    try {
        // First connect without database specified
        connection = await getInitialConnection(dbEngine);
        const dbName = process.env.DB_NAME;
        
        if (dbEngine === 'aurora-mysql') {
            // Create database if doesn't exist
            await executeSQL(connection, 
                `CREATE DATABASE IF NOT EXISTS ${dbName}`, 
                dbEngine
            );
            
            // Grant global privileges to admin before anything else
            await executeSQL(connection, 
                `GRANT ALL PRIVILEGES ON *.* TO '${process.env.DB_MASTER_USERNAME}'@'%' WITH GRANT OPTION`, 
                dbEngine
            );
            
            // Also grant specific DB privileges
            await executeSQL(connection, 
                `GRANT ALL PRIVILEGES ON ${dbName}.* TO '${process.env.DB_MASTER_USERNAME}'@'%'`, 
                dbEngine
            );
            
            await executeSQL(connection, "FLUSH PRIVILEGES", dbEngine);
        }

        // Close initial connection and reconnect with database specified
        await connection.end();
        connection = await getConnection(dbEngine);
        
        const readonlyUser = process.env.DB_READONLY_USER;
        const readonlyPass = process.env.DB_READONLY_PASS;
        const readwriteUser = process.env.DB_READWRITE_USER;
        const readwritePass = process.env.DB_READWRITE_PASS;

        // Create read-only user
        const readonlySQL = dbEngine === 'aurora-postgresql' ? [
            `DO $$ 
            BEGIN
                IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = '${readonlyUser}') THEN
                    CREATE USER ${readonlyUser} WITH PASSWORD '${readonlyPass}';
                END IF;
            END $$;`,
            `GRANT CONNECT ON DATABASE ${dbName} TO ${readonlyUser};`,
            `GRANT SELECT ON ALL TABLES IN SCHEMA public TO ${readonlyUser};`
        ] : [
            `CREATE USER IF NOT EXISTS '${readonlyUser}'@'%' IDENTIFIED BY '${readonlyPass}';`,
            `GRANT SELECT ON ${dbName}.* TO '${readonlyUser}'@'%';`
        ];

        // Create read-write user
        const readwriteSQL = dbEngine === 'aurora-postgresql' ? [
            `DO $$ 
            BEGIN
                IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = '${readwriteUser}') THEN
                    CREATE USER ${readwriteUser} WITH PASSWORD '${readwritePass}';
                END IF;
            END $$;`,
            `GRANT CONNECT ON DATABASE ${dbName} TO ${readwriteUser};`,
            `GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${readwriteUser};`
        ] : [
            `CREATE USER IF NOT EXISTS '${readwriteUser}'@'%' IDENTIFIED BY '${readwritePass}';`,
            `GRANT SELECT, INSERT, UPDATE, DELETE ON ${dbName}.* TO '${readwriteUser}'@'%';`
        ];

        // Execute all queries
        for (const sql of [...readonlySQL, ...readwriteSQL]) {
            await executeSQL(connection, sql, dbEngine);
        }
    } finally {
        if (connection) await connection.end();
    }
}

async function getConnection(dbEngine) {
    const config = {
        host: process.env.DB_CLUSTER_ENDPOINT,
        port: parseInt(process.env.DB_PORT),
        database: process.env.DB_NAME,
        user: process.env.DB_MASTER_USERNAME,
        password: process.env.DB_MASTER_PASSWORD,
        ssl: false
    };

    return dbEngine === 'aurora-postgresql' 
        ? new PGClient(config).connect()
        : mysql.createConnection(config);
}

async function executeSQL(connection, sql, dbEngine) {
    try {
        if (dbEngine === 'aurora-postgresql') {
            await connection.query(sql);
        } else {
            await connection.execute(sql);
        }
    } catch (err) {
        console.error(`Error executing SQL: ${sql}`, err);
        // Continue execution rather than failing
        console.log("Continuing despite error");
    }
}

// Helper function for initial connection without database
async function getInitialConnection(dbEngine) {
    const config = {
        host: process.env.DB_CLUSTER_ENDPOINT,
        port: parseInt(process.env.DB_PORT),
        user: process.env.DB_MASTER_USERNAME,
        password: process.env.DB_MASTER_PASSWORD,
        ssl: false
    };

    return dbEngine === 'aurora-postgresql' 
        ? new PGClient(config).connect()
        : mysql.createConnection(config);
} 