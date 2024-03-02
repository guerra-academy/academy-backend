import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
// Função para inserir um novo curso ou atualizar um existente
public function insertCourse(postgresql:Client db, Course course) returns error? {
     _ = check db->execute(`
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
    return;
}

// Função para buscar o total de estudantes
public function getTotalStudents(postgresql:Client db) returns TotalStudents|error {
    TotalStudents total = {
        totalStudents: 0
    };
    var result = db->queryRow(`SELECT SUM(num_students) AS sum FROM course_data`, int);
    if result is int {
        total.totalStudents = result;
        return total;
    }
    return total;
}

// Função para buscar o total de avaliações
public function getTotalReviews(postgresql:Client db) returns TotalReview|error {
    TotalReview total = {
        totalReviews: 0
    };
    var result = db->queryRow(`SELECT SUM(num_reviews) AS sum FROM course_data`, int);
    if result is int {
        total.totalReviews = result;
        return total;
    }
    return total;
}
