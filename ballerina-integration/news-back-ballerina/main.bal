import ballerina/http;
import ballerina/os;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerina/sql;

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
int dbPort = 5432;

service /users on new http:Listener(9090) {
    private final postgresql:Client db;
    function init() returns error? {
        self.db = check new (host = dbHost, username = dbUser, password = dbPassword, database = dbName, port = dbPort, connectionPool = {maxOpenConnections: 1});
    }

    resource function get .() returns User[]|error {
        // Executar a consulta SQL
        //selecionar apenas campos do type Course no select abaixo        
        stream<User, sql:Error?> resultStream = self.db->query(`SELECT id, nome, email, subscribed, data_hora, recaptcha, cod_rec, gerou_cert FROM usuarios`);
        return from User user in resultStream
            select user;
    }
    resource function post .(User user) returns User|error {
        _ = check self.db->execute(`
            INSERT INTO course_data (id, nome, email, subscribed, data_hora, recaptcha, cod_rec, gerou_cert)
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
    
    
}