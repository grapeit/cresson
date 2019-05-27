package main

import (
	"encoding/json"
	"os"
)

type Configuration struct {
	Listen          string `json:"listen"`
	AuthSecret      string `json:"auth_secret"`
	DbDriverName    string `json:"db_driver"`
	DbConnectString string `json:"db_address"`
	Debug           bool   `json:"debug"`
}
var config Configuration


func initConfig() {
	configFile, err := os.Open("cresson.conf")
	if err != nil {
		panic(err.Error())
	}
	jsonParser := json.NewDecoder(configFile)
	err = jsonParser.Decode(&config)
	_ = configFile.Close()
	if err != nil {
		panic(err.Error())
	}
}
