use v5.14;

use Catmandu -all;
use File::Hotfolder;
use File::Basename;
    
# TODO: reload if config file changed

my $hotfolder = "./import";
my $importer  = "marc2gnd";
my $store     = "couchdb";
my $suffix    = qr{\.xml$};
    
#my $target    = store('couchdb');
my $target = exporter('yaml');

watch( $hotfolder, 
    filter   => $suffix,
    scan     => 1,    
    delete   => 1,
    print    => WATCH_DIR | FOUND_FILE | CATCH_ERROR,
    callback => sub {
        $target->add_many( importer($importer, file => shift) );
    },
)->loop;
