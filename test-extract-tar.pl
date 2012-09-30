#!/usr/bin/perl

# auteur : Dominique Dumont <ddumont@cpan.org>

#  DBIC_TRACE=1 DBIC_TRACE_PROFILE=console

use warnings;
use strict;
use lib 'lib';

use DBIx::Class;
use Integ::Schema;
use Archive::Peek;
use 5.10.1;

use File::Slurp;

my $password = read_file('.cred.txt') ;
chomp $password;
my $integ_dbo = 'dbi:mysql:database=Integ;host=localhost;port=3306';

my $integ_schema =
  Integ::Schema->connect( $integ_dbo, 'integ_mgr', $password,
    { RaiseError => 1, quote_names => 1 } );

my $product_rs = $integ_schema->resultset('Product');

foreach my $tarfile (@ARGV) {
    my ( $prod_name, $version ) = ( $tarfile =~ /(\w+)-([\d\.]*?)\.tar/ );

    my $product_row = $product_rs->find_or_create( { name => $prod_name } );

    my $product_version_rs = $product_row->product_versions;
    my $product_version_row =
      $product_version_rs->find_or_create( { version => '1.02', } );

    my $tarball_obj = $product_version_row->tar_balls->find_or_create(
        { url => "http://cucurbitacée.com/repo/$tarfile" } );
    $product_version_row->update;

    my $peek = Archive::Peek->new( filename => $tarfile );

    foreach my $file_name ( $peek->files() ) {
        say "Handling $file_name" ;
        # meanwhile, need to check first for the existence of the link
        my $create_link = 1;
        my $pkg_obj = $integ_schema->resultset('Package') ->find( { name => $file_name } );
        
        if ($pkg_obj) {
            my $rs = $tarball_obj->packages->search( { id => $pkg_obj->id } );
            $create_link = 0 if $rs->count;
        }

        $tarball_obj->create_related( 'tarball_packages', { package => { name => $file_name } } )
          if $create_link;
    }
}

__END__

 $tarball_obj->add_to_packages({ } ) ;
 
 my $schema = $tarball_obj->result_source->schema;
 my $pkg_obj = $schema->resultset('Package')
    ->find_or_create({name => 'concombre-1.1.el5.i386.rpm'}) ;
 $tarball_obj->add_to_package($pkg_obj) unless $rs->count ;
