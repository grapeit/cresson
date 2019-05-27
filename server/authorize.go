package main

import (
	"fmt"
	"github.com/dgrijalva/jwt-go"
	"github.com/gin-gonic/gin"
	"github.com/pkg/errors"
	"strings"
	"time"
)

const validityPeriod = 30 * 24 * time.Hour
var jwtAlgorithm = jwt.SigningMethodHS512

func authorizeHandler(c *gin.Context) {
	token := jwt.NewWithClaims(jwtAlgorithm, jwt.MapClaims{
		"bike": 1,
		"exp": time.Now().Add(validityPeriod).Unix(),
	})
	tokenString, err := token.SignedString([]byte(config.AuthSecret))
	if err != nil {
		if config.Debug {
			fmt.Println("JWT error: ", err.Error())
		}
		c.JSON(500, gin.H{
			"status": "failure",
			"error": "unexpected error",
		})
		return
	}
	c.JSON(200, gin.H{
		"status": "ok",
		"token": tokenString,
	})
}

func verifyBike(c *gin.Context) (int, error) {
	auth := strings.Split(c.GetHeader("Authorization"), " ")
	if len(auth) != 2 || auth[0] != "Bearer" {
		return 0, errors.New("bad auth method")
	}
	tokenString := auth[1]
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if token.Method != jwtAlgorithm {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(config.AuthSecret), nil
	})
	if err != nil {
		return 0, err
	}
	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		bikeId := toInt(claims["bike"])
		if bikeId == 0 {
			return 0, errors.New("bad bike id")
		}
		return bikeId, nil
	} else {
		return 0, errors.New("failed getting JWT claims")
	}
}
