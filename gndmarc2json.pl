use v5.14;
use Catmandu::Fix;
use Catmandu::Fix::marc_map as => 'marc_map';

# general fix
my $fixer = Catmandu::Fix->new( fixes => [ <<'FIX' ]);
marc_map(024a,uri)
marc_map(079b,type)
FIX

my $TYPES = {
    p => {  # Person (individualisiert)
        uri => 'http://xmlns.com/foaf/0.1/Person',
        fix => <<'FIX'
            marc_map(100a,prefLabel.de)
FIX
    },
    b => {  # Körperschaft
        uri => 'http://xmlns.com/foaf/0.1/Organization',
        fix => <<'FIX'
            marc_map(110ab, prefLabel.de, -join => ', ')
FIX
    },
    f => {  # Konferenz oder Veranstaltung
        uri => 'http://d-nb.info/standards/elementset/gnd#ConferenceOrEvent',
        fix => <<'FIX'
            marc_map(111a, prefLabel.de)
            # TODO 111d und c (Jahr: Ort)
FIX
    },
    g => {  # Geografikum
        uri => 'http://d-nb.info/standards/elementset/gnd#PlaceOrGeographicName',
        fix => <<'FIX'
            marc_map(151a,prefLabel.de)
            marc_map(451a,altLabel.de.$append)
FIX
    },
    s => {  # Sachbegriff
        uri => 'http://d-nb.info/standards/elementset/gnd#SubjectHeading',
        fix => <<'FIX'
            marc_map(150ax, prefLabel.de, -join => ' / ')
            # TODO: append $g $x etc. (multiple cases)
FIX
    },
    u => {  # Werk
        uri => 'http://d-nb.info/standards/elementset/gnd#Work',
        fix => <<'FIX'
            marc_map(100t,prefLabel.de)
FIX
    }
};

# compile fixes
for (keys %$TYPES) {
    $TYPES->{$_}->{fix} = Catmandu::Fix->new( fixes => [ $TYPES->{$_}->{fix} ] )
        if $TYPES->{$_}->{fix};
}

sub {
    my $data = shift;

    # general fix
    $fixer->fix($data);
    
    $data->{uri} =~ qr{^http://d-nb.info/gnd/(.+)} or return;
    $data->{_id} = $1;
    $data->{notation} = $1;


    my $type = $TYPES->{ $data->{type} } or return;
    $data->{type} = ['http://www.w3.org/2004/02/skos/core#Concept', $type->{uri} ];

    # type-specific fix
    $type->{fix}->fix($data) if $type->{fix};

    # TODO: type-specific code
    
    delete $data->{record};
    return $data;
}

__END__

=head1 DOCUMENTATION

http://nbn-resolving.de/urn:nbn:de:101-2014070111
http://www.loc.gov/marc/authority/
http://d-nb.info/standards/elementset/gnd#

=back
