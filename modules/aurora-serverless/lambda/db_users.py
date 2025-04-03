import os
import logging
from typing import Dict, Any

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_connection(db_engine: str) -> Any:
    """Create database connection based on engine type"""
    conn_params = {
        "host": os.environ["DB_CLUSTER_ENDPOINT"],
        "port": int(os.environ["DB_PORT"]),
        "database": os.environ["DB_NAME"],
        "user": os.environ["DB_MASTER_USERNAME"],
        "password": os.environ["DB_MASTER_PASSWORD"],
        "ssl": False  # Disable SSL for LocalStack
    }
    
    if db_engine == "aurora-postgresql":
        import pg8000
        return pg8000.connect(**conn_params)
    else:
        import pymysql
        return pymysql.connect(**conn_params, cursorclass=pymysql.cursors.DictCursor)

def execute_sql(conn: Any, sql: str, db_engine: str) -> None:
    """Execute SQL statement with error handling"""
    try:
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()
    except Exception as e:
        logger.error(f"Error executing SQL: {sql}")
        if db_engine == "aurora-postgresql":
            conn.rollback()
        raise e

def create_users(db_engine: str) -> None:
    """Create database users with appropriate permissions"""
    conn = get_connection(db_engine)
    
    try:
        # Create read-only user
        readonly_sql = [
            f"CREATE USER {os.environ['DB_READONLY_USER']} WITH PASSWORD '{os.environ['DB_READONLY_PASS']}';",
            f"GRANT CONNECT ON DATABASE {os.environ['DB_NAME']} TO {os.environ['DB_READONLY_USER']};",
            f"GRANT SELECT ON ALL TABLES IN SCHEMA public TO {os.environ['DB_READONLY_USER']};"
        ] if db_engine == "aurora-postgresql" else [
            f"CREATE USER '{os.environ['DB_READONLY_USER']}'@'%' IDENTIFIED BY '{os.environ['DB_READONLY_PASS']}';",
            f"GRANT SELECT ON {os.environ['DB_NAME']}.* TO '{os.environ['DB_READONLY_USER']}'@'%';"
        ]

        # Create read-write user
        readwrite_sql = [
            f"CREATE USER {os.environ['DB_READWRITE_USER']} WITH PASSWORD '{os.environ['DB_READWRITE_PASS']}';",
            f"GRANT CONNECT ON DATABASE {os.environ['DB_NAME']} TO {os.environ['DB_READWRITE_USER']};",
            f"GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO {os.environ['DB_READWRITE_USER']};"
        ] if db_engine == "aurora-postgresql" else [
            f"CREATE USER '{os.environ['DB_READWRITE_USER']}'@'%' IDENTIFIED BY '{os.environ['DB_READWRITE_PASS']}';",
            f"GRANT SELECT, INSERT, UPDATE, DELETE ON {os.environ['DB_NAME']}.* TO '{os.environ['DB_READWRITE_USER']}'@'%';"
        ]

        # Execute all SQL commands
        for sql in readonly_sql + readwrite_sql:
            execute_sql(conn, sql, db_engine)
            
    finally:
        conn.close()

def handler(event: Dict, context: Dict) -> Dict:
    """Lambda entry point"""
    try:
        db_engine = os.environ["DB_ENGINE"]
        logger.info(f"Starting user creation for {db_engine}")
        
        create_users(db_engine)
        
        return {
            "statusCode": 200,
            "body": "Users created successfully"
        }
    except Exception as e:
        logger.error(f"Error creating users: {str(e)}")
        raise e 