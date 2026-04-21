FROM golang:latest AS builder
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


# Install UPX to compress the binary
RUN apt-get update && apt-get install -y upx \
    && upx --best --lzma --ultra-brute gatus \
    # && upx --best gatus \
    && apt-get purge -y --auto-remove upx \
    && rm -rf /var/lib/apt/lists/*


FROM scratch AS runtime

USER 1001:1001 
WORKDIR /app

COPY --from=builder /app/gatus /app/
COPY --from=builder /app/config.yaml /app/config/config.yaml

EXPOSE 8080
ENTRYPOINT ["./gatus"]