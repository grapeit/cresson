FROM golang as builder

WORKDIR /
COPY * /
RUN CGO_ENABLED=0 go build -a -v -o cresson


FROM scratch

WORKDIR /
COPY --from=builder /cresson /

EXPOSE 80
CMD ["/cresson"]
