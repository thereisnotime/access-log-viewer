# Access Log Viewer

View Nginx and Apache access.log files in your Browser. Fork that adds security features.

<https://rolandstarke.github.io/access-log-viewer/>

![access log viewer apache and nginx](preview.jpeg)

## Features

### Visitors

Determine the amount of hits, visitors, bandwidth by the hour, or date.

### Geographical Data

Determine the visitors originating country.

### Device Data

Determine the browser and device type like desktop or mobile.

### Referral-Traffic

Determine referring websites that send traffic to your websites via direct links.

### Most Requested Files

Determine the urls with the most hits.

### Status Codes

Determine how often your server respondet with 200, 404, 500, ...  status codes.

## Docker Usage

You can run this application using Docker:

### Build the Docker image

```bash
docker build -t access-log-viewer .
```

### Run the Docker container

```bash
docker run -p 8080:8080 access-log-viewer
```

If port 8080 is already in use, you can use a different port:

```bash
docker run -p 8081:8080 access-log-viewer
```

After running these commands, you can access the application at <http://localhost:8080> (or <http://localhost:8081> if you used the alternative port)

### Note

The application has been modified to use the first column for IP addresses in log files rather than automatically detecting them.
