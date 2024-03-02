import ballerina/http;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerina/sql;

service /curso on new http:Listener(9090) {
    
    private final postgresql:Client db;

    function init() returns error? {
        self.db = check createDbClient();
    }
    
    // Insere ou atualiza um curso
    resource function post .(http:Caller caller, http:Request req, Course course) returns error? {
        check insertCourse(self.db, course);
        check caller->respond(http:STATUS_OK);
    }

    // Busca todos os cursos
    resource function get .(http:Caller caller, http:Request req) returns error? {
        stream<Course, sql:Error?> resultStream = self.db->query(`SELECT course_id, title, rating, num_reviews, num_students, hours, discount_url, image_url FROM course_data`, Course);
        Course[] courses = [];
        error? e = resultStream.forEach(function(Course course) {
            courses.push(course);
        });
        if e is error {
            return e;
        }
        check caller->respond(courses);
    }

    // Busca o total de estudantes
    resource function get totalStudents(http:Caller caller, http:Request req) returns error? {
        var totalOrError = getTotalStudents(self.db);
        if totalOrError is TotalStudents {
            check caller->respond(totalOrError);
        } else {
            check caller->respond(http:STATUS_INTERNAL_SERVER_ERROR);
        }
    }

    // Busca o total de avaliações
    resource function get totalReviews(http:Caller caller, http:Request req) returns error? {
        var totalOrError = getTotalReviews(self.db);
        if totalOrError is TotalReview {
            check caller->respond(totalOrError);
        } else {
            check caller->respond(http:STATUS_INTERNAL_SERVER_ERROR);
        }
    }
}
