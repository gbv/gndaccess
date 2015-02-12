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
    my $format = $req->param('format') || 'html';

    # MARCXML
    # my $url = "http://d-nb.info/04021477X/about/marcxml"

    # TODO: use Plack::App::unAPI ?
    
    my $url = "http://d-nb.info/gnd/$id";
    my $model = RDF::Trine::Model->new;
    eval {
        RDF::Trine::Parser->parse_url_into_model( $url, $model );
    };
    if ($@ || !$model->size) {
        return [404,[],["GND $id not found"]];
    }

    if ($format eq 'aref') {
        my $aref = encode_aref $model;
        my $JSON = $req->param('pretty') ? JSON->new->pretty : JSON->new;
        my $json = $JSON->encode( $aref );
        return [200, ['Content-Type' => 'application/json'], [$json]];
    } 
    
    if ($format eq 'html') {
        return [200, ['Content-Type' => 'text/plain'], ['GND gefunden (probier mal format=aref!)']];
    }

    return [400, ['Content-Type' => 'text/plain'], ['format not supported']];
}

1;
