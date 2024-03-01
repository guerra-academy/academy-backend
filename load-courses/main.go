package main

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"math"
	"net/http"
	"os"
	"strings"
)

type ApiResponse struct {
	SliderMenu struct {
		Data CourseData `json:"data"`
	} `json:"slider_menu"`
}

type CourseData struct {
	CourseID    int     `json:"course_id"`
	Title       string  `json:"title"`
	Rating      float64 `json:"rating"`
	NumReviews  int     `json:"num_reviews"`
	NumStudents int     `json:"num_students"`
	Hours       float64 `json:"hours"`
	DiscountURL string  `json:"discount_url"`
	ImageURL    string  `json:"image_url"`
}

type ResponseToken struct {
	AccessToken string `json:"access_token"`
}

// function que recupera token jwt
func FetchAccessToken() (string, error) {

	apiUrl := os.Getenv("TOKEN_API_URL")
	authorization := os.Getenv("AUTHORIZATION")
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	client := &http.Client{Transport: tr}
	var data = strings.NewReader(`grant_type=client_credentials`)

	req, err := http.NewRequest("POST", apiUrl, data)
	if err != nil {
		println(err)
		log.Fatal(err)
	}

	req.Header.Set("Authorization", authorization)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := client.Do(req)
	if err != nil {
		println(err)
		log.Fatal(err)
	}
	defer resp.Body.Close()

	bodyText, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Fatal(err)
	}

	var tokenResponse ResponseToken
	err = json.Unmarshal(bodyText, &tokenResponse)
	if err != nil {
		return "", err
	}
	log.Println("Token: " + tokenResponse.AccessToken)
	return tokenResponse.AccessToken, nil
}

// recupera cursos da api udemy
func fetchCourseData(courseID int) CourseData {
	var course CourseData

	url := fmt.Sprintf("https://www.udemy.com/api-2.0/course-landing-components/%d/me/?components=slider_menu", courseID)

	resp, err := http.Get(url)
	if err != nil {
		log.Println("Error fetching data for courseID", courseID, ":", err)
		return course
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Println("Error reading response body for courseID", courseID, ":", err)
		return course
	}

	var apiResponse ApiResponse
	err = json.Unmarshal(body, &apiResponse)
	if err != nil {
		log.Println("Error parsing JSON for courseID", courseID, ":", err)
		return course
	}
	course.CourseID = courseID
	course.Title = apiResponse.SliderMenu.Data.Title
	course.Rating = math.Round(apiResponse.SliderMenu.Data.Rating*10) / 10
	course.NumReviews = apiResponse.SliderMenu.Data.NumReviews
	course.NumStudents = apiResponse.SliderMenu.Data.NumStudents

	switch course.CourseID {
	case 3081950:
		course.Hours = 13.5
		course.DiscountURL = "https://www.udemy.com/course/devops-mao-na-massa/?referralCode=98502C449B1318AC77D1"
		course.ImageURL = "https://guerra.academy/static/img/devops-mao-massa.webp"
	case 4576156:
		course.Hours = 10.5
		course.DiscountURL = "https://www.udemy.com/course/programacao-go-para-devops-e-sres/?referralCode=7E8A136BE919AD355D5C"
		course.ImageURL = "https://guerra.academy/static/img/go-devops.webp"
	case 744026:
		course.Hours = 3.5
		course.DiscountURL = "https://www.udemy.com/course/apache-webserver-do-basico-ao-avancado/?referralCode=0DB8BA2BA53EFCFBBFE0"
		course.ImageURL = "https://guerra.academy/static/img/apache.webp"
	}

	return course

}

// Nova função para postar os dados do curso para a API
func postCourseData(course CourseData) {
	//recupera dados via variavel de ambiente
	token, err := FetchAccessToken()
	if err != nil {
		println("Error fetching access token:", err)
		log.Println("Error fetching access token:", err)
		return
	}
	apiUrl := os.Getenv("API_URL")

	jsonData, err := json.Marshal(course)
	if err != nil {
		println("Error encoding course data:", err)
		log.Println("Error encoding course data:", err)
		return
	}

	req, err := http.NewRequest("POST", apiUrl, bytes.NewBuffer(jsonData))
	if err != nil {
		println("Error creating request:", err)
		log.Println("Error creating request:", err)
		return
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("accept", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)
	//req.Header.Set("API-Key", token)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Println("Error sending request to API:", err)
		return
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Println("Error reading response body:", err)
		return
	}
	println("Curso: " + course.Title + " - Response from API: " + string(body))
	log.Printf("Curso: %s: Response from API: %s", course.Title, string(body))
}

func main() {
	logFile, err := os.OpenFile("load-courses.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		log.Fatal("Erro ao abrir o arquivo de log:", err)
	}
	defer logFile.Close()
	log.SetOutput(logFile)

	courseIDs := []int{4576156, 3081950, 744026}
	for _, courseID := range courseIDs {
		course := fetchCourseData(courseID)
		postCourseData(course) // Chama a nova função para enviar os dados do curso para a API
	}
}
