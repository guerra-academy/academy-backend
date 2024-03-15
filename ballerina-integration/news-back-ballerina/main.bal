import ballerina/email;
import ballerina/http;
import ballerina/io;
import ballerina/os;
import ballerina/sql;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;



http:CorsConfig corsConfig = {
    allowOrigins: ["*"], // Substitua pela origem da sua aplicação React
    allowCredentials: true,
    allowHeaders: ["CORELATION_ID"],
    exposeHeaders: ["X-CUSTOM-HEADER"],
    allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"] // Adicione outros métodos conforme necessário

};

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

type Newsletter record {
    string subject;
    string body;
};

configurable string dbUser = os:getEnv("DB_USER");
configurable string dbPassword = os:getEnv("DB_PASSWORD");
configurable string dbHost = os:getEnv("DB_HOSTNAME");
configurable string dbName = os:getEnv("DB_NAME");
configurable string dbPort = os:getEnv("DB_PORT");
configurable string smtpServer = os:getEnv("SMTP_SERVER");
configurable string smtpUser = os:getEnv("SMTP_USER");
configurable string smtpPass = os:getEnv("SMTP_PASS");
configurable string smtpPort = os:getEnv("SMTP_PORT");

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000", "*"],
        allowCredentials: false,
        allowHeaders: ["CORELATION_ID"],
        exposeHeaders: ["X-CUSTOM-HEADER"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        maxAge: 84900
    }
}
service /users on new http:Listener(9090) {

    private final postgresql:Client db;
    function init() returns error? {
        var intPort = int:fromString(dbPort);
        if intPort is int {
            self.db = check new (host = dbHost, username = dbUser, password = dbPassword, database = dbName, port = intPort, connectionPool = {maxOpenConnections: 1});
        } else {
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
            if (result.length() == 0) {
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
    @http:ResourceConfig {
         cors: {
            allowOrigins: ["http://localhost:3000", "*"],
            allowCredentials: false,
            allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            maxAge: 84900
        }
    }
    resource function POST sendNews(Newsletter news) returns json|error {
    
    int|error mailPort = int:fromString(smtpPort);
    if (mailPort is int) {
        email:SmtpConfiguration smtpConfig = {
            port: mailPort,
            security: "START_TLS_AUTO"
        };

        email:SmtpClient smtpClient = check new (smtpServer, smtpUser, smtpPass, smtpConfig);

        stream<User, sql:Error?> resultStream = self.db->query(`SELECT id, nome, email, subscribed, data_hora, recaptcha, cod_rec, gerou_cert FROM usuarios`);
        if resultStream is stream<User> {
            foreach var user in resultStream {
                email:Message emailMsg = {
                    to: user.email,
                    subject: news.subject,
                    contentType: "text/html",
                    'from: "noreply@guerra.academy",
                    body: news.body
                };
                check smtpClient->sendMessage(emailMsg);
            }
        }
        return null;
    } else {
        return {errorMessage: mailPort.message()};
    }
}

}
