use v5.14.1;
use Test::More;
use RDF::aREF;
use RDF::Trine;
use GBV::App::GNDAccess;
use JSON;

my $parser = RDF::Trine::Parser::RDFXML->new;

foreach my $rdfxml (glob "t/jskos/*.xml") {
    next unless $rdfxml =~ qr{^t/jskos/([a-z]+)-([0-9X-]+)\.xml$};
    my $jskosfile = "t/jskos/$1-$2.json";
    my $uri = "http://d-nb.info/gnd/$2";

    my $rdf = RDF::Trine::Model->new;
    $parser->parse_file_into_model( "file:///$rdfxml", $rdfxml, $rdf);
    my $aref = encode_aref $rdf, NFC => 1;
    my $jskos = GBV::App::GNDAccess::gndaref2jskos($aref, $uri);

    unless (-f $jskosfile) {
        note(JSON->new->utf8->canonical->pretty->encode($jskos));
        next;
    }
    my $expect = decode_json( do { local (@ARGV, $/) = ($jskosfile); <> } );

    is_deeply $expect, $jskos, $rdfxml;
}

done_testing;
