import ballerina/http;
import ballerina/os;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerina/sql;
import ballerina/io;
type Course record {|
    int course_id;
    string title;
    decimal rating;
    int num_reviews;
    int num_students;
    decimal hours;
    string discount_url;
    string image_url;
|};

type TotalReview record {
    int totalReviews;
};

type TotalStudents record {
    int totalStudents;
};

configurable string dbUser = os:getEnv("DB_USER");
configurable string dbPassword = os:getEnv("DB_PASSWORD");
configurable string dbHost = os:getEnv("DB_HOSTNAME");
configurable string dbName = os:getEnv("DB_NAME");
int dbPort = 5432;
service /curso on new http:Listener(9090) {
    private final postgresql:Client db;
    function init() returns error? {
        self.db = check new (host = dbHost, username = dbUser, password = dbPassword, database = dbName, port = dbPort, connectionPool = {maxOpenConnections: 1});
    }

    resource function post .(Course course) returns Course|error {
        _ = check self.db->execute(`
            INSERT INTO course_data (course_id, title, rating, num_reviews, num_students, hours, discount_url, image_url)
            VALUES (${course.course_id}, ${course.title}, ${course.rating}, ${course.num_reviews}, ${course.num_students}, ${course.hours}, ${course.discount_url}, ${course.image_url})
            ON CONFLICT (course_id)
            DO UPDATE SET
            title = EXCLUDED.title,
            rating = EXCLUDED.rating,
            num_reviews = EXCLUDED.num_reviews,
            num_students = EXCLUDED.num_students,
            hours = EXCLUDED.hours,
            discount_url = EXCLUDED.discount_url,
            image_url = EXCLUDED.image_url;
        `);
        return course;
    }
    resource function get .() returns Course[]|error {
        // Executar a consulta SQL
        //selecionar apenas campos do type Course no select abaixo        
        stream<Course, sql:Error?> resultStream = self.db->query(`SELECT course_id, title, rating, num_reviews, num_students, hours, discount_url, image_url FROM course_data`);
        return from Course course in resultStream
            select course;
    }

    resource function get totalStudents() returns TotalStudents|http:NotFound|error{
        TotalStudents total = {
            totalStudents: 0
        };
        int|sql:Error result = self.db->queryRow(`select sum(num_students) as sum from course_data`);
        
        // Check if record is available or not
        if result is sql:NoRowsError {
            return http:NOT_FOUND;
        } else if result is int{
            total.totalStudents = result;
            io:println("result total students: ",result);
            return total;
        }else {
            io:println("result total students: ",result);
            return result;
        }
        
    }

    resource function get totalReviews() returns TotalReview|http:NotFound|error{
        TotalReview total = {
            totalReviews: 0
        };
        
        int|sql:Error result = self.db->queryRow(`select sum(num_reviews) as sum from course_data`);
        
        // Check if record is available or not
        if result is sql:NoRowsError {
            io:println("not found sql error total reviews: ",result);
            return http:NOT_FOUND;
        } else if result is int {
            total.totalReviews = result;
            io:println("result total reviews: ",result);
            return total;
        }else{
            io:println("result total reviews: ",result);
            return result;
        }
        
    }
    
}