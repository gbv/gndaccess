use v5.14.1;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use lib 't';
use AppLoader;
my $app = AppLoader->new( gndaccess => 'GBV::App::GNDAccess' );

test_psgi $app, sub {
    my $cb = shift;
    my $id = '4021477-1';
    my $res = $cb->(GET "/$id");
    is $res->code, '200', "/$id => 200";
};

done_testing;
