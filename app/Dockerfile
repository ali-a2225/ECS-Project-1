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


## adds 10-30s to pipeline with normal compression has 0.8MB reduction on ECR but 
## adds 14mins to pipeline with extreme compression and cache disabled (or enabled but something been changed in the layers) -3.44MB reduction on ECR
## Install UPX to compress the binary
# RUN apk add --no-cache upx \
#     && upx --best --lzma --ultra-brute gatus \
#     && apk del upx 

FROM scratch AS runtime

USER 1001:1001
WORKDIR /app

COPY --from=builder /app/gatus /app/
COPY --from=builder /app/config.yaml /app/config/config.yaml
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

EXPOSE 8080
ENTRYPOINT ["./gatus"]

