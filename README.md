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

The application is packaged as Debian package and installed at
`/srv/gndaccess/`. Log files are located at `/var/log/gndaccess/`.

# CONFIGURATION

See `/etc/default/gndaccess` for basic configuration (port number). Restart is
needed after changes. 

# SEE ALSO

Changelog is located in `debian/changelog` in the source code repository.

Source code and issue tracker at <https://github.com/gbv/gndaccess>

