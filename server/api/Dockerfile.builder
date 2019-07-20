FROM golang

WORKDIR /
RUN go get -v \
    github.com/pkg/errors \
    github.com/gin-gonic/gin \
    github.com/gin-contrib/cors \
    github.com/dgrijalva/jwt-go \
    github.com/go-sql-driver/mysql
