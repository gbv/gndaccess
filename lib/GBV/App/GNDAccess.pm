package GBV::App::GNDAccess;
use v5.14.1;

our $VERSION="0.0.2";
our $NAME="gndaccess";

use RDF::aREF;
use RDF::Trine;
use JSON;

use Plack::Builder;
use Plack::Request;
use parent 'Plack::Component';

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

    $self->config( grep { -f $_ } "debian/$NAME.default", "/etc/default/$NAME" );
    $self->{app} = builder {
        enable_if { $self->{PROXY} } 'XForwardedFor', trust => $self->{TRUST};
        enable 'CrossOrigin', origins => '*';
        enable 'Rewrite', rules => sub {
            s{^/$}{/index.html};
            return;
        };
        enable 'Static', path => qr{\.(html|js|ico|css|png)},
            pass_through => 1, root => './htdocs';

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
        cleanUTF8($aref);
        my $JSON = $req->param('pretty') ? JSON->new->pretty : JSON->new;
        my $json = $JSON->encode( $aref );
        return [200, ['Content-Type' => 'application/json; encoding=UTF-8'], [$json]];
    } 
    
    if ($format eq 'html') {
        return [200, ['Content-Type' => 'text/plain'], ['GND gefunden (probier mal format=aref!)']];
    }

    return [400, ['Content-Type' => 'text/plain'], ['format not supported']];
}

use Encode;

sub cleanUTF8 {
    my ($node) = @_;
=head1    
    return unless ref $node eq 'HASH';
    while (my ($key, $value) = each %$node) {
        my $type = ref $value || '';
        if ($type eq 'HASH') {
            cleanUTF($type);
            return;
        } elsif (!$type) {
            $value = [$value];
        }
        $node->{$key} = [
            map { }
            @{$node->{$key}} = encode_utf8($node->{$key});
        ];
        } else {
            $node->{$key} = encode_utf8($node->{$key});
        }
    }
=cut    
}

1;
