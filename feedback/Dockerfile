FROM golang:1.23-alpine AS build
WORKDIR /src
COPY go.mod ./
RUN go mod download || true
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /out/feedback .

FROM gcr.io/distroless/static-debian12
COPY --from=build /out/feedback /feedback
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/feedback"]
