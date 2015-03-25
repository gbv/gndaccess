package Catmandu::Fix::perlcode;

use Moo;
use Catmandu::Sane;
use Catmandu::Fix::Has;

our %CACHE;

has file => (
    fix_arg => 1
);

has code => (
    is => 'lazy',
    builder => sub {
        my $file = $_[0]->file;
        $CACHE{ $file } //= do $_[0]->file;
    }
);

sub fix {
    my ($self, $data) = @_;
    $self->code->($data);
}

1;
__END__

=head1 NAME

Catmandu::Fix::perlcode - execute Perl code as fix function

=head1 DESCRIPTION

Use this fix in the L<Catmandu> fix language to make use of a Perl script:

    perlcode(myscript.pl)

The script (here C<myscript.pl>) must return a code reference:

    sub {
        my $data = shift;
        ...
        return $data;
    }

When not using the fix language this 

    my $fixer = Catmandu::Fix->new( fixes => [ do 'myscript.pl' ] );
    $fixer->fix( $item ); 

is equivalent to:

    my $code = do 'myscript.pl';
    $item = $code->( $item )

=head1 SEE ALSO

L<Catmandu::Fix::cmd>

=cut
