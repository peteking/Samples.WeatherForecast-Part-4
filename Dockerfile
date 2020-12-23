ARG VERSION=5.0-alpine

FROM mcr.microsoft.com/dotnet/sdk:${VERSION} AS build
WORKDIR /app

# Copy and restore as distinct layers
COPY . .
WORKDIR /app/src/Samples.WeatherForecast.Api
RUN dotnet restore Samples.WeatherForecast.Api.csproj -r linux-musl-x64

FROM build AS publish
RUN dotnet publish \
    -c Release \
    -o /out \
    -r linux-musl-x64 \
    --self-contained=true \
    -- no-restore \
    -p:PublishReadyToRun=true \
    -p:PublishTrimmed=true

# Final stage/image
FROM mcr.microsoft.com/dotnet/runtime-deps:${VERSION}

RUN addgroup -S dotnetgroup && \
    adduser -S dotnet
USER dotnet

WORKDIR /app
COPY --chown=dotnet:dotnetgroup --from=publish /out .

EXPOSE 8080
ENTRYPOINT ["./Samples.WeatherForecast.Api"]