# Build stage
FROM rust:1.71-slim as builder
WORKDIR /usr/src/mail-admin-api
COPY . .
RUN cargo build --release

# Runtime stage
FROM amazonlinux:2023
WORKDIR /opt/mail-admin-api
COPY --from=builder /usr/src/mail-admin-api/target/release/mail-admin-api .

# Install minimal runtime dependencies
RUN yum update -y && \
    yum install -y ca-certificates openssl && \
    yum clean all

# Create non-root user
RUN useradd -r -s /bin/false mail-admin

# Set permissions
RUN chown mail-admin:mail-admin /opt/mail-admin-api/mail-admin-api && \
    chmod 500 /opt/mail-admin-api/mail-admin-api

USER mail-admin
EXPOSE 5000

CMD ["./mail-admin-api"]
