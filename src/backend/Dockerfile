# 多階段建置 Dockerfile
FROM golang:1.24-alpine AS builder

# 安裝建置依賴
RUN apk add --no-cache git make

# 設定工作目錄
WORKDIR /app

# 複製 go mod 檔案
COPY go.mod go.sum ./

# 下載依賴
RUN go mod download

# 複製原始碼
COPY . .

# 建置應用程式
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/server/main.go

# 最終映像
FROM alpine:3.19

# 安裝 CA 憑證（用於 HTTPS）
RUN apk --no-cache add ca-certificates tzdata

# 設定時區
ENV TZ=Asia/Taipei

# 建立非 root 使用者
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# 設定工作目錄
WORKDIR /app

# 從 builder 階段複製編譯好的二進位檔
COPY --from=builder /app/main .

# 變更擁有者
RUN chown -R appuser:appgroup /app

# 切換到非 root 使用者
USER appuser

# 暴露埠號
EXPOSE 3001

# 健康檢查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3001/health || exit 1

# 執行應用程式
CMD ["./main"]


