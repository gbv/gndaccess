package GBV::App::GNDAccess;
use v5.14.1;

our $VERSION="0.0.4";
our $NAME="gndaccess";

use RDF::aREF;
use RDF::Trine;
use RDF::Trine::Serializer;
use JSON;

use Plack::Builder;
use Plack::Request;
use parent 'Plack::Component';

sub formats {
    return {
        aref => { 
            name => 'aREF', 
            type => 'application/json' 
        },
        html => { 
            name => 'HTML', 
            type => 'text/html' 
        },
        nt => { 
            name => 'NTriples', 
            type => 'application/n-triples',
            serializer => 'NTriples',
        },
        rdfxml => { 
            name => 'RDF/XML', 
            type => 'application/rdf+xml',
            serializer => 'RDFXML',
        }
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
            pass_through => 1, root => '/etc/gndaccess/htdocs';
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
    my ($self, $code, $data, $pretty) = @_;
    my $JSON = $pretty ? JSON->new->pretty : JSON->new;
    my $json = $JSON->encode($data);
    return [$code, ['Content-Type' => 'application/json; encoding=UTF-8'], [$json]];
}

sub main { 
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);

    my $id = substr($req->path,1) || '';
    # TODO: validate $id /^[0-9X-]+$/

    my $format = $env->{'negotiate.format'} || 'html';

    # MARCXML
    # my $url = "http://d-nb.info/04021477X/about/marcxml"

    my $url = "http://d-nb.info/gnd/$id";
    my $model = RDF::Trine::Model->new;
    eval {
        RDF::Trine::Parser->parse_url_into_model( $url, $model );
    };
    if ($@ || !$model->size) {
        return $self->json(404 => { error => "GND $id not found" });
    }

    if ($format eq 'aref') {
        my $aref = encode_aref $model;
        return $self->json( 200, $aref, $req->param('pretty') );
    } 
    
    if (my $f = $self->formats->{$format}) {
        if ($f->{serializer}) {
            use Encode qw(decode_utf8);
            my $rdf = RDF::Trine::Serializer->new($f->{serializer})
                    ->serialize_model_to_string($model);
            return [200,[], [decode_utf8($rdf)]];
        }
    }

    if ($format eq 'html') {
        return [200, ['Content-Type' => 'text/plain'], ['GND gefunden (probier mal format=aref!)']];
    }

    return [400, ['Content-Type' => 'text/plain'], ['format not supported']];
}

1;
