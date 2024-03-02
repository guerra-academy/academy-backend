import ballerina/os;
import ballerinax/postgresql;

configurable string dbUser = os:getEnv("DB_USER");
configurable string dbPassword = os:getEnv("DB_PASSWORD");
configurable string dbHost = os:getEnv("DB_HOSTNAME");
configurable string dbName = os:getEnv("DB_NAME");
int dbPort = 5432;

public function createDbClient() returns postgresql:Client|error {
    return new (host = dbHost, username = dbUser, password = dbPassword, database = dbName, port = dbPort, connectionPool = {maxOpenConnections: 1});
}
