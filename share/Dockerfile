FROM golang:1.23-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download || true
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /out/share .

FROM gcr.io/distroless/static-debian12
COPY --from=build /out/share /share
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/share"]
