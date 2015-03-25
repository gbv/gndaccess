use strict;
use warnings;
use Test::More;
use Catmandu::Fix;
use Catmandu::Fix::perlcode;

for (1..2) {
    my $fixer = Catmandu::Fix->new( fixes => ['perlcode(t/script.pl)'] );
    my $data = { };
    $fixer->fix($data);
    is_deeply $data, { answer => 42 };
}

done_testing;
