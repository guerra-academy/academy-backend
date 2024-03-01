import ballerina/http;
import ballerina/os;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;

http:JwtValidatorConfig config = {
   issuer: "https://api.asgardeo.io/t/mycomp/oauth2/token",
   audience: "zW8yXa5L9k0napib5nEeFchmCLAa",
   signatureConfig: {
       jwksConfig: {
           url: "https://api.asgardeo.io/t/mycomp/oauth2/jwks"
       }
   }
};
type Course record {|
    int course_id;
    string title;
    float rating;
    int num_reviews;
    int num_students;
    float hours;
    string discount_url;
    string image_url;
|};

configurable string dbUser = os:getEnv("DB_USER");
configurable string dbPassword = os:getEnv("DB_PASSWORD");
configurable string dbHost = os:getEnv("DB_HOSTNAME");
configurable string dbName = os:getEnv("DB_NAME");
int dbPort = 5432;
service /curso on new http:Listener(9090) {
    private final postgresql:Client db;
    function init() returns error? {
        self.db = check new (host = dbHost, username = dbUser, password = dbPassword, database = dbName, port = dbPort, connectionPool = {maxOpenConnections: 2});
    }

    resource function post .(Course course) returns Course|error {
        _ = check self.db->execute(`
            INSERT INTO course_data (course_id, title, rating, num_reviews, num_students, hours, discount_url, image_url)
            VALUES (${course.course_id}, ${course.title}, ${course.rating}, ${course.num_reviews}, ${course.num_students}, ${course.hours}, ${course.discount_url}, ${course.image_url});`);
        return course;
    }
}
