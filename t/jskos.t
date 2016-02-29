use v5.14.1;
use Test::More;
use RDF::aREF;
use GBV::App::GNDAccess;
use JSON;

# load RDF from test files instead of web
local *RDF::Trine::Parser::parse_url = sub {
    my ($parser, $url, $handler) = @_;
    return $parser->parse_file("file:///$url", $url, $handler);
};

foreach my $marcfile (glob "t/jskos/*.xml") {
    next unless $marcfile =~ qr{^t/jskos/([a-z]+)-([0-9X-]+)\.xml$};
    my $jskosfile = "t/jskos/$1-$2.json";
    my $uri = "http://d-nb.info/gnd/$2";

    my $rdf = GBV::App::GNDAccess::get_rdf_NFKC($marcfile);
    my $aref = encode_aref $rdf;
    my $jskos = GBV::App::GNDAccess::gndaref2jskos($aref, $uri);

    unless (-f $jskosfile) {
        note(JSON->new->utf8->canonical->pretty->encode($jskos));
        next;
    }
    my $expect = decode_json( do { local (@ARGV, $/) = ($jskosfile); <> } );

    is_deeply $expect, $jskos, $marcfile;
}

done_testing;
