package GBV::App::GNDAccess;
use v5.14.1;

our $VERSION="0.0.6";
our $NAME="gndaccess";

use RDF::aREF;
use RDF::Trine;
use RDF::Trine::Serializer;
use JSON;
use Unicode::Normalize;
use Plack::Builder;
use HTTP::Tiny;
use Plack::Request;
use File::Temp qw(tempfile);
use parent 'Plack::Component';

sub formats {
    return {
        html => { 
            name => 'HTML', 
            type => 'text/html' 
        },
        aref => { 
            name => 'aREF', 
            type => 'application/json', 
            rdf  => 'aref',
        },
        jskos => { 
            name => 'JSKOS', 
            type => 'application/json', 
            rdf => 'jskos',
        },
        marcxml => {
            name => 'MARCXML',
            type => 'application/marcxml+xml',
            marc => 'marcxml'
        },
        nt => { 
            name => 'NTriples', 
            type => 'application/n-triples',
            rdf  => 'NTriples',
        },
        rdfxml => { 
            name => 'RDF/XML', 
            type => 'application/rdf+xml',
            rdf  => 'RDFXML',
        },
    }
}

sub config {
    my ($self, $file) = @_;
    return unless -f $file;

    local(@ARGV) = $file; 
    while(<>) {
        next if $_ !~ /^\s*([A-Z][_A-Z0-9]*)\s*=\s*([^#\n]*)/;
        $self->{$1} = $2;
        if ($1 eq 'PROXY' and $2 !~ /^[*]\s*$/) {
            $self->{TRUST} = [ split /\s*,\s*|\s+/, $self->{PROXY} ];
        }
    }
}    

sub prepare_app {
    my ($self) = @_;
    return if $self->{app};

    # load config file
    $self->config( grep { -f $_ } "debian/$NAME.default", "/etc/default/$NAME" );

    # build middleware stack
    $self->{app} = builder {
        enable_if { $self->{PROXY} } 'XForwardedFor', trust => $self->{TRUST};
        enable 'CrossOrigin', origins => '*';
        enable 'Rewrite', rules => sub {
            s{^/$}{/index.html}; return
        };
        enable 'Static', path => qr{\.(html|js|ico|css|png)},
            pass_through => 1, root => "/etc/$NAME/htdocs";
        enable 'Static', path => qr{\.(html|js|ico|css|png)},
            pass_through => 1, root => './htdocs';
        enable 'ContentLength';
        enable 'JSONP';
        enable 'Negotiate', 
            parameter => 'format',
            formats => $self->formats;
        builder {
            mount '/formats.json' => sub {
                $self->json(200,$self->formats);
            };
            mount '/' => sub {
                $self->main(@_) 
            };
        }
    }; 
}

sub call {
    my ($self, $env) = @_;
    $self->{app}->($env);
}

sub json {
    my ($self, $code, $data) = @_;
    my $json = JSON->new->utf8->pretty->encode($data);
    return [$code, ['Content-Type' => 'application/json; encoding=UTF-8'], [$json]];
}

sub main { 
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);

    my $path = substr($req->path,1) || ''; 
    if ( $path !~ qr{^(http://d-nb\.info/gnd/)?([0-9X-]+)$}) {
        return [404, ['Content-Type' => 'text/plain'], ['invalid GND identifier'. $path]];
    }
    my ($uri,$id) = ("http://d-nb.info/gnd/$2",$2);

    my $format = $env->{'negotiate.format'} || 'html';

    unless ($format = $self->formats->{$format}) {
        return [400, ['Content-Type' => 'text/plain'], ['format not supported']];
    }

    # RDF-based formats
    if ($format->{rdf}) {
        my $model = eval { getRDF($uri) };
        if ($@ || !$model || !$model->size) {
            return $self->json(404 => { error => "GND not found via $uri" });
        }

        if ($format->{rdf} eq 'aref') {
            my $aref = encode_aref $model, NFC => 1;
            return $self->json( 200, $aref );
        } elsif ($format->{rdf} eq 'jskos') {
            my $aref = encode_aref $model, NFC => 1;
            my $jskos = gndaref2jskos($aref, $uri);
            return $self->json( 200, $jskos );
        } elsif ($format->{rdf}) {
            use Encode qw(decode_utf8);
            my $rdf = RDF::Trine::Serializer->new($format->{rdf})
                    ->serialize_model_to_string($model);
            return [200,[], [$rdf]];
        }

    # MARC-based formats
    } elsif ($format->{marc}) {
        my $url = "http://d-nb.info/gnd/$id/about/marcxml";
        my $res = HTTP::Tiny->new->get($url) || {};
        my $marcxml = $res->{content};
        unless ( $res->{success} and length $marcxml) {
            return $self->json(404 => { error => "GND not found via $url" });
        }
        $marcxml =~ s/^\s+//m;
        if ($marcxml !~ qr{^<\?xml}) {
            $marcxml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n$marcxml";
        }

        if ($format->{marc} eq 'marcxml') {
            return [200,['Content-Type' => 'application/marcxml+xml'],[$marcxml]];
        }
    }

    # html
    return [200, ['Content-Type' => 'text/plain'], ['GND gefunden (probier mal format=aref!)']];
}

sub getRDF {
    my ($uri) = @_;
    my $model = RDF::Trine::Model->new;

    # This nasty fix makes sure that RDF is loaded as Unicode.
    # We could add caching here
    my $rdfxml;
    my $parser = RDF::Trine::Parser::RDFXML->new;
    $parser->parse_url( $uri, sub { }, content_cb => sub { 
        $rdfxml = $_[1] } 
    );
    my ($fh, $filename) = tempfile();
    say $fh $rdfxml;
    close $fh;
    $parser->parse_file_into_model( $uri, $filename, $model );

    return $model;
}

sub gndaref2jskos {
    my ($aref, $uri) = @_;
    my $jskos = {
        uri => $uri,
        type => ['http://www.w3.org/2004/02/skos/core#Concept'],
        '@context' => 'https://gbv.github.io/jskos/context.json',
    };
    my $tmp = aref_query_map $aref, $uri, {
        'gnd_homepage.' => 'url',
        'foaf_page.' => 'subjectOf',
        'gnd_associatedDate^xs_date' =>  'relatedDate',
        'gnd_beginningOfPeriod^xs_date' =>  'startDate',
        'gnd_biographicalOrHistoricalInformation@' => 'scopeNote',
        'gnd_dateOfBirth^xs_date' =>  'startDate',
        'gnd_dateOfDeath^xs_date' =>  'endDate',
        'gnd_preferredNameForThePerson@' => 'prefLabel',
        'gnd_variantNameForTheSubjectHeading' => 'altLabel',
        'owl_sameAs.' => 'identifier',
        'gnd_broader.' => 'broader',
        'gnd_broaderTermInstantial.' => 'broader',
        'gnd_corporateBodyIsMember' => 'broader',
        'gnd_dateOfEstablishment' => 'startDate',
        'gnd_dateOfProduction' => 'startDate',
        'gnd_dateOfPublication' => 'startDate',
        'gnd_dateOfTermination' => 'endDate',
        'gnd_endOfPeriod' => 'endDate',
        'gnd_definition' => 'definition',
        'gnd_preferredNameForTheSubjectHeading@' => 'prefLabel',
        'gnd_relatedPlaceOrGeographicName' => 'related',
        'gnd_preferredNameForThePlaceOrGeographicName@' => 'prefLabel',
        'gnd_variantNameForThePlaceOrGeographicName@' => 'altLabel',
    };
    my $list  = sub { (ref $_[0] or !defined $_[0]) ? $_[0] : [$_[0]] };  # get a list
    my $value = sub { ref $_[0] ? $_[0][0] : $_[0] }; # get a single value

    foreach (qw(url startDate endDate relatedDate)) {
        $jskos->{$_} = $value->($tmp->{$_});
    }

    foreach (qw(altLabel scopeNote)) {
        my $values = $list->($tmp->{$_}) // next;
        $jskos->{$_} = { "de" => [ sort @$values ] };
    }

    foreach (qw(identifier)) {
        my $values = $list->($tmp->{$_}) // next;
        $jskos->{$_} = [ sort @$values ];
    }

    foreach (qw(broader related narrower previous next)) {
        my $values = $list->($tmp->{$_}) // next;
        $jskos->{$_} = [ map { { uri => $_ } } sort @$values ];
    }

    foreach (qw(subjectOf)) {
        my $values = $list->($tmp->{$_}) // next;
        $jskos->{$_} = [ map { { url => $_ } } sort @$values ];
    }
    
    $jskos->{prefLabel} = { "de" => $value->($tmp->{prefLabel}) } if defined $tmp->{prefLabel};


    delete $jskos->{$_} for grep { !defined $jskos->{$_} } keys %$jskos;

    return $jskos;
}

1;
