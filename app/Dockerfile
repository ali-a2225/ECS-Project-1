FROM golang:alpine AS builder
RUN apk --update add ca-certificates
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod tidy

COPY . .

# Build optimized binary
## Output binary named "gatus", target Linux OS, -trmipath to remove file system paths, -ldflags to strip debug info and symbol tables, CGO_ENABLED=0 turns off all C linking and makes it pure Go,and builds a static binary which doesn't depend on external libraries
RUN CGO_ENABLED=0 GOOS=linux \
    go build -a -installsuffix cgo \
    -trimpath -ldflags="-s -w" \
    -o gatus .


# # Install UPX to compress the binary
# RUN apt-get update && apt-get install -y upx \
#     && upx --best --lzma --ultra-brute gatus
  
Install UPX to compress the binary
RUN apk add --no-cache upx \
    # && upx --best --lzma --ultra-brute gatus \
    && upx --best gatus \
    && apk del upx 
    # for debian
    # && apk add purge -y --auto-remove upx \
    # && rm -rf /var/lib/apt/lists/*

FROM scratch AS runtime
# FROM golang:latest AS runtime

# USER 1001:1001
WORKDIR /app

COPY --from=builder /app/gatus /app/
COPY --from=builder /app/config.yaml /app/config/config.yaml
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

EXPOSE 8080
ENTRYPOINT ["./gatus"]


# # Build the go application into a binary
# FROM golang:alpine AS builder
# RUN apk --update add ca-certificates
# WORKDIR /app
# COPY . ./
# RUN go mod tidy -diff
# RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gatus .

# # Run Tests inside docker image if you don't have a configured go environment
# #RUN apk update && apk add --virtual build-dependencies build-base gcc
# #RUN go test ./... -mod vendor

# # Run the binary on an empty container
# FROM scratch

# COPY --from=builder /app/gatus .
# COPY --from=builder /app/config.yaml ./config/config.yaml
# COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
# ENV GATUS_CONFIG_PATH=""
# ENV GATUS_LOG_LEVEL="INFO"
# ENV PORT="8080"
# EXPOSE ${PORT}
# ENTRYPOINT ["/gatus"]