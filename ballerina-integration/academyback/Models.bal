public type Course record {|
    int course_id;
    string title;
    decimal rating;
    int num_reviews;
    int num_students;
    decimal hours;
    string discount_url;
    string image_url;
|};

public type TotalReview record {
    int totalReviews;
};

public type TotalStudents record {
    int totalStudents;
};
