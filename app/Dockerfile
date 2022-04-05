ARG GO_VERSION=1.18
FROM golang:${GO_VERSION}-bullseye AS build

WORKDIR /go/src/app
ADD . .

RUN go get -d -v ./...

RUN CGO_ENABLED=0 go build -installsuffix 'static' -o /app .

FROM gcr.io/distroless/static AS final

USER nonroot:nonroot

COPY --from=build --chown=nonroot:nonroot /app /app

ENTRYPOINT ["/app"]