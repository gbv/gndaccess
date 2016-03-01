*See `README.md` for general introduction and usage documentation.*

# Infrastructure

## Git repository

The source code of gndaccess is managed in a public git repository at
<https://github.com/gbv/gndaccess>.

## Issue tracker

Bug reports and feature requests are managed as GitHub issues at
<https://github.com/gbv/gndaccess/issues>.

# Technology

Libsites is mainly written in Perl.

The application is build and released as Debian package for Ubuntu 14.04 LTS.

# Development

## First steps

For local usage and development clone the git repository and install
dependencies:

    sudo make dependencies
    make local

Locally run the web application on port 5000 for testing:

    make run

## Sources

Relevant source code is located in

* `lib/` - application sources (Perl modules)
* `debian/` - Debian package control files 
    * `changelog` - version number and changes 
      (use `dch` to update)
    * `control` - includes required Debian packages
    * `gndaccess.default` - default config file 
      (only installed with first installation)
    * `install` - lists which files to install
* `cpanfile` - lists required Perl modules
* `htdocs/` - static HTML/CSS/JS/... files

Additional files should not need to be modified unless there is a bug in the
Debian packaging or an upgrade requires some maintainance steps.

## Tests

Run all tests located in directory `t`. 

    make tests

To run a selected test, for instance `t/app.t`: 

    perl -Ilib -Ilocal/lib/perl5 t/app.t

Black-box tests are only run if `TEST_URL` is set to a port number or URL.

## Continuous Integration

[![Build Status](https://travis-ci.org/gbv/gndaccess.svg)](https://travis-ci.org/gbv/gndaccess)

After pushing to GitHub tests are also run automatically twice 
[at travis-ci](https://travis-ci.org/gbv/gndaccess). The first 
run is done via `make tests`, the second is run after packaging
against an instance installed at localhost.

## Packaging and Release

Create a Debian package

    make package

Make sure to run this on the target OS version (Ubuntu 14.04)!

Travis-ci is configured to release build packages on tagged 
versions.

# License

gndaccess is made available under the terms of GNU Affero General Public
License (AGPL).

