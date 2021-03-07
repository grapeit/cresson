FROM golang as builder

WORKDIR /
COPY * /
RUN go build -a -v -o cresson


FROM scratch

WORKDIR /
COPY --from=builder /cresson /

EXPOSE 80
CMD ["/cresson"]
