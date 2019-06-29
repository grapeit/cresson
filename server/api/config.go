package main

import (
	"fmt"
	"os"
)

var defaultPort = 80
var defaultDbDriver = "mysql"

type Configuration struct {
	listen          string
	authSecret      string
	dbDriverName    string
	dbConnectString string
	debug           bool
}
var config Configuration


func initConfig() {
	port := toInt(os.Getenv("CRESSON_API_PORT"))
	if port == 0 {
		port = defaultPort
	}
	config.listen = fmt.Sprintf(":%d", port)
	config.authSecret = os.Getenv("CRESSON_API_AUTH_SECRET")
	config.dbDriverName = os.Getenv("CRESSON_API_DB_DRIVER")
	if config.dbDriverName == "" {
		config.dbDriverName = defaultDbDriver
	}
	config.dbConnectString = os.Getenv("CRESSON_API_DB_CONNECT")
	config.debug = toInt(os.Getenv("CRESSON_API_DEBUG")) != 0
}
