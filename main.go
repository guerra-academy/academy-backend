package main

import (
	"html/template"
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type ApiResponse struct {
	SliderMenu struct {
		Data CourseData `json:"data"`
	} `json:"slider_menu"`
}

type CourseData struct {
	gorm.Model
	CourseID    int     `json:"course_id"`
	Title       string  `json:"title"`
	Rating      float64 `json:"rating"`
	NumReviews  int     `json:"num_reviews"`
	NumStudents int     `json:"num_students"`
	Hours       float64 `json:"hours"`
	DiscountURL string  `json:"discount_url"`
	ImageURL    string  `json:"image_url"`
}

type FeedItem struct {
	Title       string
	Link        string
	Description template.HTML
	ImageURL    string
	Published   string
}
type TotalStudents struct {
	Sum int
}

type TotalReviews struct {
	Sum int
}

// Suas definições de struct permanecem as mesmas...

func main() {
	logFile, err := os.OpenFile("api.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		log.Fatalf("Erro ao abrir o arquivo de log: %v", err)
	}
	defer logFile.Close()
	log.SetOutput(logFile)

	// Atualize esta string de conexão com suas credenciais de banco de dados PostgreSQL

	dsn := os.Getenv("DSN")
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Erro ao conectar ao banco de dados PostgreSQL: %v", err)
	}

	if err := db.AutoMigrate(&CourseData{}); err != nil {
		log.Fatalf("Erro ao migrar banco de dados: %v", err)
	}
	r := gin.Default()
	username := os.Getenv("BASIC_AUTH_USERNAME")
	password := os.Getenv("BASIC_AUTH_PASSWORD")

	authorized := r.Group("/")
	authorized.Use(gin.BasicAuth(gin.Accounts{
		username: password, // Garanta que username e password estão corretamente configurados
	}))
	authorized.POST("/curso", func(c *gin.Context) {
		var inputCourse CourseData
		if err := c.ShouldBindJSON(&inputCourse); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// Tenta encontrar um curso existente com o mesmo CourseID.
		var existingCourse CourseData
		result := db.First(&existingCourse, "course_id = ?", inputCourse.CourseID)

		if result.Error == gorm.ErrRecordNotFound {
			// Se o curso não existe, insere um novo.
			if result := db.Create(&inputCourse); result.Error != nil {
				log.Printf("Erro ao inserir dados no banco de dados: %v", result.Error)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao inserir dados no banco de dados"})
				return
			}
		} else {
			// Se o curso já existe, atualiza o registro existente com os novos dados.
			if result := db.Model(&existingCourse).Updates(inputCourse); result.Error != nil {
				log.Printf("Erro ao atualizar dados no banco de dados: %v", result.Error)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao atualizar dados no banco de dados"})
				return
			}
		}

		c.JSON(http.StatusOK, gin.H{"message": "Dados do curso processados com sucesso"})
	})

	r.Run() // Executar o servidor na porta 8080
}
