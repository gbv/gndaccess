requires 'perl', '5.14.1';
requires 'Plack::Middleware::CrossOrigin';
requires 'Plack::Middleware::XForwardedFor';
requires 'Plack::Middleware::Rewrite';
requires 'Plack::Middleware::Negotiate', '0.10';
requires 'RDF::aREF', '0.25';

# not listed here because implied by required Debian packages:
# - Plack
# - RDF::Trine
requires 'RDF::Trine', '1.013';
# - JSON

test_requires 'Plack::Util::Load';
