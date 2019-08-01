FROM golang as builder

RUN go get -v \
    github.com/pkg/errors \
    github.com/gin-gonic/gin \
    github.com/gin-contrib/cors \
    github.com/dgrijalva/jwt-go \
    github.com/go-sql-driver/mysql

WORKDIR /
COPY *.go /
RUN CGO_ENABLED=0 go build -a -ldflags '-s' -v -o cresson


FROM scratch

WORKDIR /
COPY --from=builder /cresson /

EXPOSE 80
CMD ["/cresson"]
