# Guerra Academy - Backend repository

Este repositório contém dois serviços de backend e um serviço de scheduler para suportar as aplicações da Guerra Academy.

## academy-backend: API REST 

A API REST academy-backend foi escrita em Ballerina e expõe com quatro serviços. Dois deles foram criados para inserir e recuperar dados referentes aos cursos. Outros dois métodos são agragação que recupera o total de estudantes cadastrados e o total de classificações de todos os cursos da base.

## Métodos:

* GET - Recupera lista de cursos cadastrados
* POST - Adiciona cursos, utilizado pelo scheduler load-courses
* GET totalStudents - Recupera o total de estudantes matriculados nos cursos.
* GET totalReviews - Recupera o total de classificações de todos os cursos cadastrados.

## news-back-ballerina: API REST 

API REST escrita em Ballerina para administrar usuários da Newsletter. Usuários que desejam se cadastrar na newsletter devem acessar o site (repo https://github.com/guerra-academy/academy-website) e efetuar o cadastro. O cadastro deve ser feito somente via site.

## Métodos:

* GET - Retorna lista de usuários cadastrados na Newsletter.
* DELETE - Apaga usuário cadastrado na Newsletter.

# load-courses:  Scheduler 

Aplicação load-courses consulta dados dos cursos na plataforma da Udemy. Após recuperar esses dados, eles devem ser armazenados no banco de dados PostgreSQL. Esse armazenamento é feito utilizando a api academy-backend, que disponibiliza uma api REST para cadastrar cursos. Essa API é protegida via Asgardeo com OAuth2, onde é feita a chamada de recuperação de token JWT para efetuar as chamadas de forma segura para a API.