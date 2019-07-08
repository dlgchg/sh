#!/bin/sh

read -p "Enter Golang Project Name:" projectName
read -p "Select VSCode(code) or GoLand(goland) open $projectName:" ide
echo $GOPATH/src
echo "create project ..."

cd $GOPATH/src
mkdir $projectName
cd $projectName

# 配置包
mkdir "conf"
# http包
mkdir "http"
# 数据量关联的model和普通的model类
mkdir "model"
# 路由
mkdir "server"
# 服务操作
mkdir "service"
# api
mkdir "api"
# jwt
mkdir "middleware"

# 数据库初始化
touch "$GOPATH/src/$projectName/model/init.go"
cat>"$GOPATH/src/$projectName/model/init.go"<<EOF
package model

import (
    _ "github.com/go-sql-driver/mysql"
    "github.com/jinzhu/gorm"
    "os"
)  

var DB *gorm.DB 

func InitDatabase() {
    db, err := gorm.Open("mysql", os.Getenv("MYSQL_DSN"))
    if err != nil {
        panic(err)
    }
    DB = db
}
EOF

# 写入index路由
touch "$GOPATH/src/$projectName/api/api.go"
cat>"$GOPATH/src/$projectName/api/api.go"<<EOF
package api

import "github.com/gin-gonic/gin"

func Index(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Hello ngt",
	})
}
EOF

# 配置文件
touch "$GOPATH/src/$projectName/.env"
cat>"$GOPATH/src/$projectName/.env"<<EOF
MYSQL_DSN="db_username:db_password@/db_database?charset=utf8&parseTime=True&loc=Local"
REDIS_ADDR="127.0.0.1:6379"
REDIS_PW=""
REDIS_DB=""
SESSION_SECRE=""
GIN_MODE="debug"
EOF

# 写入文件配置
touch "$GOPATH/src/$projectName/conf/conf.go"
cat>"$GOPATH/src/$projectName/conf/conf.go"<<EOF
package conf

import (
	"github.com/joho/godotenv"
	"log"
	"$projectName/model"
)

func Init() {
	err := godotenv.Load()
	if err != nil {
		log.Panicln(err)
	}

	model.InitDatabase()
}

EOF

# 写入中间件
touch "$GOPATH/src/$projectName/middleware/logger.go"
cat>"$GOPATH/src/$projectName/middleware/logger.go"<<EOF
package middleware

import (
	"github.com/gin-gonic/gin"
	"log"
	"time"
)

func Logger() gin.HandlerFunc {
	return func(c *gin.Context) {
		t := time.Now()
		log.Printf("%s -- %s", t.String(), c.Request.Method)
		c.Next()
	}
}

EOF

# 初始化路由组
touch "$GOPATH/src/$projectName/server/router.go"
cat>"$GOPATH/src/$projectName/server/router.go"<<EOF
package server

import (
	"$projectName/api"
	"$projectName/middleware"
	"os"

	"github.com/gin-gonic/gin"
)

func NewRouter() *gin.Engine {

	if os.Getenv("GIN_MODE") == "debug" {
		gin.SetMode(gin.DebugMode)
	}

	r := gin.New()

	r.Use(gin.Logger())
	r.Use(middleware.Logger())
	r.Use(gin.Recovery())

	r.GET("/index", api.Index)

	return r
}

EOF

# main.go
touch "$GOPATH/src/$projectName/main.go"
cat>"$GOPATH/src/$projectName/main.go"<<EOF
package main

import (
	"log"
	"$projectName/conf"
	"$projectName/server"
)

func main() {

	conf.Init()

	r := server.NewRouter()
	err := r.Run(":8999")
	if err != nil {
		log.Println(err)
	}
}

EOF

cd "$GOPATH/src/$projectName"
dep init
dep ensure
$ide .
