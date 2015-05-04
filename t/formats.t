use v5.14.1;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON;
use Plack::Util::Load;
my $app = load_app( $ENV{TEST_URL} || 'GBV::App::GNDAccess', verbose => 1 );

use GBV::App::GNDAccess;

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "/formats.json");
    is $res->code, '200', "/formats.json";

    my $formats = JSON->new->decode($res->content);
    is_deeply $formats, GBV::App::GNDAccess::formats(), 'formats ok';
};

done_testing;
