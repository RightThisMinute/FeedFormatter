# FeedFormatter

[![Swift][swift-badge]][swift-url]
[![Zewo][zewo-badge]][zewo-url]
[![Platform][platform-badge]][platform-url]
[![License][mit-badge]][mit-url]

Takes a feed from one sources and uses Mustache templates to customize them, making them avaialble via an HTTP server.

Currently only works with feeds (or "playlists") from [JW Platform](https://developer.jwplayer.com/jw-platform/). `config.example.yaml` is documented and a good place to start.


## Environment setup ##

### macOS ###

[Install `swiftenv`.](https://swiftenv.fuller.li/en/latest/installation.html#via-a-git-clone).

⚠️ With **homebrew** use:

```bash
brew install kylef/formulae/swiftenv --HEAD
```

Install Swift 3.0.1:

```bash
swiftenv install 3.0.1
```

Clone this repo and run `swift build`. You can generate the Xcode project with:

```bash
swift package generate-xcodeproj
```


### Linux ###

_Only tested on Ubuntu 16.04._

[Install `swiftenv`.](https://swiftenv.fuller.li/en/latest/installation.html#via-a-git-clone).

```bash
apt update
apt install libcurl3 clang
swiftenv install 3.0.1
```


#### Setup Nginx as Proxy (optional) ####

```bash
apt update
apt install nginx
```

Create the following config at [/etc/nginx/sites-available/example.com] or use `default`. This assumes SSL certificates have been setup using [letsencrypt](https://letsencrypt.org). Don't trust this to be secure or robust, it is merely a starting point.

```nginx
server {
  listen 80;
  server_name example.com localhost;
  return 301 https://example.com$request_uri;
}


# HTTPS server

server {
  listen 443;
  server_name example.com;

  root /var/www/html;
  index index.html;

  ssl on;
  ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

  ssl_session_timeout 5m;

  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers "HIGH:!aNULL:!MD5 or HIGH:!aNULL:!MD5:!3DES";
  ssl_prefer_server_ciphers on;

  location / {
    root /var/www/html;
    try_files $uri $uri/ @FeedFormatter;

    # Uncomment to enable naxsi on this location
    # include /etc/nginx/naxsi.rules
    # auth_basic "Private Property";
    # auth_basic_user_file /etc/nginx/.htpasswd;

    #expires 30d;
    #add_header Pragma public;
    #add_header Cache-Control "public";
  }

  location @FeedFormatter {
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded_for $proxy_add_x_forwarded_for;
    proxy_pass http://127.0.0.1:8080;
  }
}
```

Be sure to switch out `example.com` with your sites domain, `/var/www/html` with the path to static files to be served directly by nginx, and `8080` with the port you set in the `your_config.yaml`.


## Running ##

Copy `config.example.yaml` and `example.mrss.xml` to get started. Be sure to point to the directory where your templates are, and set defualt template name, as well as configure a feed.

Run with `$ ./.build/debug/FeedFormatter --config your_config.yaml`


[swift-badge]: https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat
[swift-url]: https://swift.org
[zewo-badge]: https://img.shields.io/badge/Zewo-0.14-FF7565.svg?style=flat
[zewo-url]: http://zewo.io
[platform-badge]: https://img.shields.io/badge/Platforms-OS%20X%20--%20Linux-lightgray.svg?style=flat
[platform-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
