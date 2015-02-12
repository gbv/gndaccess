package GBV::App::GNDAccess;
use v5.14.1;

use RDF::aREF;
use RDF::Trine;
use JSON;

use Plack::Builder;#?
use Plack::Request;
use parent 'Plack::Component';

use Data::Dumper;

sub prepare_app {
    my ($self) = @_;
    $self->{app} ||= builder {
        enable 'CrossOrigin', origins => '*';
        enable 'JSONP';
        # TODO: jsonp
        sub { $self->main(@_) }
    }; 
}

sub call {
    my ($self, $env) = @_;
    $self->{app}->($env);
}

# if no id provided
sub index {
    my ($self, $env) = @_;
    return [200,[],["hier kommt noch eine Startseite hin"]];
}

sub main { 
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);

    my $id = substr($req->path,1) || '';
    if ($id eq '') {
        return $self->index($env);
    }

    # TODO: validate $id

    # TODO: Content negotiation
    my $format = $req->param('format');

    say "# FORMAT: $format\n";

    # MARCXML
    # my $url = "http://d-nb.info/04021477X/about/marcxml"

    my $url = "http://d-nb.info/gnd/$id";
    my $model = RDF::Trine::Model->new;
    eval {
        RDF::Trine::Parser->parse_url_into_model( $url, $model );
    };
    if ($@) {
        return [404,[],["GND $id not found"]];
    }

    say "# SIZE: ". $model->size;

    my $aref = encode_aref $model;

    my $json = encode_json( $aref );

    return [200, ['Content-Type' => 'application/json'], [$json]];
}

1;
