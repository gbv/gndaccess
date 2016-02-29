# NAME

gndaccess - Access GND records via HTTP

[![Build Status](https://travis-ci.org/gbv/gndaccess.svg?branch=master)](https://travis-ci.org/gbv/gndaccess)
[![Latest Release](https://img.shields.io/github/release/gbv/gndaccess.svg)](https://github.com/gbv/gndaccess/releases)

# SYNOPSIS

The application is automatically started as service, listening on port 6699.

    sudo service gndaccess {status|start|stop|restart}

# DESCRIPTION

This applications provices a web service to access GND records via HTTP in
different formats. The format must be provided with URL query parameter
`format`.

* <http://localhost:6699/4021477-1?format=aref>

## Supported formats

* `aref`: aREF format (RDF in JSON for easy access, similar to JSON-LD)
* `jskos`: JSKOS format (basic support)
* `marcxml`: MARC XML format

## CORS and JSONP

Cross-Origin Resource Sharing (CORS) is enabled by default. In addition all
JSON-based formats can can be returned in JSONP with parameter `callback`:

* <http://localhost:6699/4021477-1?format=aref&callback=abc>

## HTML client

The application includes an HTML client, consisting of the following files:

* `index.html`
* `gndaccess.css`
* `gndaccess.json`
* `formats.json` (generated dynamically)

# INSTALLATION

The application is packaged as Debian package. Releases can be found at

* <https://github.com/gbv/gndaccess/releases>

No binaries are included, so the package should work on all architectures. It
is tested with Ubuntu 12.04 LTS and Ubuntu 14.04 LTS.

Files are installed at the following locations:

* `/srv/gndaccess/` - application
* `/var/log/gndaccess/` - log files `access.log` and `error.log`
* `/etc/logrotate.d/gndaccess` - logrotate configuration (compress daily, keep 14 days)
* `/etc/default/gndaccess` - server configuration
* `/etc/gndaccess/` - application configuration

# CONFIGURATION

See `/etc/default/gndaccess` for basic configuration. Settings are not modified
by updates.  Only simple key value-pairs are allowed with the following keys:

* `PORT` - port number (required, 6699 by default)

* `WORKERS` - number of parallel connections (required, 5 by default). If put 
   behind a HTTP proxy, this number is not affected by slow cient connections 
   but only by the time of processing each request.

* `PROXY` - a space-or-comma-separated list of trusted IPs or IP-ranges
   (e.g. `192.168.0.0/16`) to take from the `X-Forwarded-For` header.
   The special value `*` can be used to trust all IPs.

Restart is needed after changes.

The HTML client can be customized by putting static files into directory
`/etc/gndaccess/htdocs` to override files in `/srv/gndaccess/htdocs`.

# SEE ALSO

Changelog is located in file [`debian/changelog`](debian/changelog) in the
source code repository.

Source code and issue tracker at <https://github.com/gbv/gndaccess>. See file
[`CONTRIBUTING.md`](CONTRIBUTING.md)` for source code organization.

See <http://www.dnb.de/entityfacts> for a similar service.
