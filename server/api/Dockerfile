FROM golang as builder

WORKDIR /
COPY *.go /
RUN go get -v \
    github.com/pkg/errors \
    github.com/gin-gonic/gin \
    github.com/dgrijalva/jwt-go \
    github.com/go-sql-driver/mysql
RUN CGO_ENABLED=0 go build -a -ldflags '-s' -v -o cresson


FROM scratch

WORKDIR /
COPY --from=builder /cresson /

EXPOSE 80
CMD ["/cresson"]
