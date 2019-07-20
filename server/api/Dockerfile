FROM cresson-api-builder as builder

WORKDIR /
COPY *.go /
RUN CGO_ENABLED=0 go build -a -ldflags '-s' -v -o cresson


FROM scratch

WORKDIR /
COPY --from=builder /cresson /

EXPOSE 80
CMD ["/cresson"]
