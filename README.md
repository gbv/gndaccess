# NAME

gndaccess - Access GND records via HTTP

[![Build Status](https://travis-ci.org/gbv/gndaccess.svg)](https://travis-ci.org/gbv/gndaccess)

# SYNOPSIS

The application is automatically started as service, listening on port 6699.

    sudo service gndaccess {status|start|stop|restart}

# DESCRIPTION

This applications provices a web service to access GND records via HTTP in
different formats. The format must be provided with URL query parameter
`format`.

The current draft only supports aREF format (RDF in JSON for easy access,
similar to JSON-LD) with `format=aref`.

All JSON-based formats can also be returned in JSONP with the `callback`
parameter:

* <http://localhost:6699/4021477-1?format=aref&callback=abc>

Cross-Origin Resource Sharing (CORS) also supported, so JSONP should not be
required.

# INSTALLATION

The application is packaged as Debian package (tested with Ubuntu >= 12.04). It
is installed at the following locations:

* `/srv/gndaccess/` - application
* `/var/log/gndaccess/` - log files
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

# SEE ALSO

Changelog is located in `debian/changelog` in the source code repository.

Source code and issue tracker at <https://github.com/gbv/gndaccess>

