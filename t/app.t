use v5.14.1;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON;
use Plack::Util::Load;
my $app = load_app( $ENV{TEST_URL} || 'GBV::App::GNDAccess', verbose => 1 );

test_psgi $app, sub {
    my $cb = shift;
    my $id = '4021477-1';

    my $res = $cb->(GET "/$id?format=aref");
    is $res->code, '200', "/$id => 200";
    my $aref = JSON->new->decode($res->content);
    ok $aref->{"http://d-nb.info/gnd/$id"}, 'aref';
};

done_testing;
