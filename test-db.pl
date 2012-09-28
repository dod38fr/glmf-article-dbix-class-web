#!/usr/bin/perl

# auteur : Dominique Dumont <ddumont@cpan.org>

#  DBIC_TRACE=1 DBIC_TRACE_PROFILE=console 

use warnings;
use strict;
use lib 'lib';

use DBIx::Class;
use Integ::Schema;
use DateTime ;
use 5.10.0;

my $password  = 'foobar';
my $integ_dbo = 'dbi:mysql:database=Integ;host=localhost;port=3306';

my $integ_schema =
  Integ::Schema->connect( $integ_dbo, 'integ_mgr', $password,
    { RaiseError => 1, quote_names => 1 } );

# remise à zéro
for (qw/TarballPackage Package TarBall ProductVersion Product/) {
    $integ_schema->resultset($_)->delete ;
}

my $product_rs = $integ_schema->resultset('Product');

# ajoute 1 produit et 2 versions pour émuler les instruction SQL de l'article
{
    my $product = $product_rs->create( { name => 'OpenCourge' } ); 
    my $v1_date = DateTime->new( qw/year 2012 month 8 day 20/ ) ;
    my $v2_date = DateTime->new( qw/year 2012 month 9 day 27/ ) ;

    # 2 façons différentes pour le un résultat similaire
    $product -> create_related('product_versions',{ version =>1.01, date => $v1_date}) ;
    $product -> add_to_product_versions({ version => 1.02, date => $v2_date}) ;
    
}

my $product_row = $product_rs->find( { name => 'OpenCourge' } );

my $product_version_rs = $product_row->product_versions;

say "Product version count ", $product_version_rs->count ;

my $v = $product_version_rs->find({version => '1.02'}) ;
say "version 1.02 date ", $v->date->ymd ;

my $v_rs = $product_version_rs->search({date => { like => '2012%' }}) ;
say "version in 2012 ", $v_rs->count, " list ", join(' ', map { $_->version } $v_rs->all) ;

say "Product version count before creation ", $product_version_rs->count ;
$product_version_rs->find_or_create( { version => '1.04', } );
say "Product version count after creation ", $product_version_rs->count ;

my $product_version_row =
  $product_version_rs->find_or_create( { version => '1.04', } );
say "Product version count after re-creation ", $product_version_rs->count ;

$product_version_row->log( "c'est mûr'" );

my $d = $product_version_row->date;
$product_version_row->date( DateTime->now ) unless $d;

# add_to_tar_balls n'est pas idempotent
my $tarball_obj = $product_version_row->tar_balls->find_or_create(
    { url => "http://cucurbitacée.com/repo/OpenCourge-i386.tar" } );
$product_version_row->update;

say "tarballs : ", $product_version_row->tar_balls->single->url ;

# 1er cas de figure, le paquest n'existe pas
$tarball_obj->add_to_packages({ name => 'concombre-1.1.el5.i386.rpm'} ) ;

my $pkg_name2 = 'courgette-1.2.el5.i386.rpm' ;

my $schema = $tarball_obj->result_source->schema;
# my $pkg_obj = $schema->resultset('Package')
     # ->find_or_create({name => $pkg_name2 }) ;

# 2e cas de figure, le paquet existe peut-être, mais la relation n'existe pas
$tarball_obj->find_or_create_related('tarball_packages', 
        { package => { name => $pkg_name2 }}) ;

# 3e cas de figure, il faut tout vérifier
if (not $tarball_obj->packages->search({name => $pkg_name2})->count) { ;
    $tarball_obj->find_or_create_related('tarball_packages', 
        { package => { name => $pkg_name2 }}) ;
}

say "package count in tarball :", $tarball_obj->tarball_packages->count ;
my @packages = map { $_->name ; } $tarball_obj->packages->all ;
say "package in tarball : @packages" ; 


