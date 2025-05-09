# Use the official Go image as a parent image.
FROM golang:1.20 as builder

# Set the working directory in the container to /app.
WORKDIR /app

# Copy the go.mod and go.sum files to the container.
COPY go.mod go.sum ./

# Download all the dependencies.
RUN go mod download

# Copy the entire project directory to the working directory.
COPY . .

# Build the application for an alpine based container.
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o main .

# Use a lightweight alpine image for the final image.
FROM alpine:latest

# Add certificates to communicate over HTTPS.
RUN apk --no-cache add ca-certificates

# Set the working directory in the container to /root/.
WORKDIR /root/

# Copy the binary from the builder step.
COPY --from=builder /app/main .

# Command to run when the container starts.
CMD ["./main"]
