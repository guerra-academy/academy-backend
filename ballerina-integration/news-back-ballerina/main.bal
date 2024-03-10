import ballerina/http;
import ballerina/os;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerina/sql;
import ballerina/io;

type User record {|
    int id;
    string nome;
    string email;
    int subscribed;
    string data_hora;
    string recaptcha;
    string cod_rec;
    int gerou_cert;
|};

configurable string dbUser = os:getEnv("DB_USER");
configurable string dbPassword = os:getEnv("DB_PASSWORD");
configurable string dbHost = os:getEnv("DB_HOSTNAME");
configurable string dbName = os:getEnv("DB_NAME");
configurable string dbPort = os:getEnv("DB_PORT");

service /users on new http:Listener(9090) {
    private final postgresql:Client db;
    function init() returns error? {
        var intPort = int:fromString(dbPort); 
        if intPort is int{
            self.db = check new (host = dbHost, username = dbUser, password = dbPassword, database = dbName, port = intPort, connectionPool = {maxOpenConnections: 1});
        }else{
            io:println("error: " + intPort.message());
            return intPort;

        }
    }

    resource function get .() returns User[]|error {
        stream<User, sql:Error?> resultStream = self.db->query(`SELECT id, nome, email, subscribed, data_hora, recaptcha, cod_rec, gerou_cert FROM usuarios`);
        return from User user in resultStream
            select user;
    }
    resource function post .(User user) returns User|error {
        _ = check self.db->execute(`
            INSERT INTO usuarios (id, nome, email, subscribed, data_hora, recaptcha, cod_rec, gerou_cert)
            VALUES (${user.id}, ${user.nome}, ${user.email}, ${user.subscribed}, ${user.data_hora}, ${user.recaptcha}, ${user.cod_rec}, ${user.gerou_cert})
            ON CONFLICT (email)
            DO UPDATE SET
            id = EXCLUDED.id,
            nome = EXCLUDED.nome,
            email = EXCLUDED.email,
            subscribed = EXCLUDED.subscribed,
            data_hora = EXCLUDED.data_hora,
            recaptcha = EXCLUDED.recaptcha,
            cod_rec = EXCLUDED.cod_rec,
            gerou_cert = EXCLUDED.gerou_cert
            ;
        `);
        return user;
    }
    resource function delete .(int id) returns json|error {

        if (id == 0) {
            return error("ID inválido.");
        }
        sql:ParameterizedQuery sqlQuery = `DELETE FROM usuarios WHERE id = ${id};`;
        var result = self.db->execute(sqlQuery);
        
        if (result is error) {
            return result;
        } else {
            if (result.length()==0) {
                return {message: "Error to delete user."};
            } else {
                // Obter o número de linhas afetadas
                int affectedRows = result.count();
                if (affectedRows > 0) {
                    return {message: "User deleted."};
                } else {
                    return {message: "User not found."};
                }
            }
        }
    }
    
}