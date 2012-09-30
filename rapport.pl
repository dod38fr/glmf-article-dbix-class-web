#!/usr/bin/env perl

# auteur : Dominique Dumont <ddumont@cpan.org>

use 5.10.1;
use lib 'lib';
use Mojolicious::Lite;
use Integ::Schema ;
use HTML::Tiny ;

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

my $integ_db = 'DBI:mysql:database=Integ;'
    . 'host=localhost;port=3306';

my $schema = Integ::Schema->connect( 
    $integ_db, 'integ_user', '',
    { RaiseError => 1 }
);

my $h = HTML::Tiny->new ;

# tout le traitement est fait dans le template
get '/' => sub {
    my $self = shift;
    
    $self->render(product_list =>  rs => $schema-> resultset('Product') );
};

# avec HTML::Tiny
get '/:name' => sub {
    my $self = shift;
    my $p_rs = $schema -> resultset('Product');
    my $h    = HTML::Tiny->new;
    
    my $n = $self->param('name') ;
    my $p_obj = $p_rs->search({name => $n }) ->single ;
    
    my @rows ;
    foreach my $version_obj ($p_obj->product_versions->all) { 
        my $version_as_string = $version_obj->version ;
        my $v_link = $h->a({href => "$n/$version_as_string" }, $version_as_string) ;
        my @data = $h->td( $v_link , $version_obj->date->ymd ) ;
        push @rows, $h -> tr( \@data ) ;
    } 

    $self->render ( version_list => rows => join("\n",@rows), name => $n ) ;
} ;


get '/old' => sub {
    my $self = shift;
    
    my @rows ;
    foreach my $product ($schema-> resultset('Product')->all) { 
        my $home_link = $h->a({href => $product->home_page},'home page') ;
        my @data = $h->td( $product->name , $home_link ) ;
        push @rows, $h -> tr( \@data ) ;
    } 

    $self->render(product_list =>  rows => join("\n",@rows));
};

app->start;
__DATA__

@@ product_list.html.ep
% layout 'default' ;
% title 'Product list' ;
<h1>Produits</h1>
<table>
    <tr>
        <th>Produit</th>
        <th>Home page</th>
    </tr>
% while (my $product = $rs->next) {
%   my $name = $product-> name ;
    <tr>
        <td><a href="<%==$name%>"><%== $name %></td>
        <td><a href="<%== $product->home_page%>">home page</td>
    </tr>
% }    
</table>

@@ version_list.html.ep
% layout 'default' ;
% title 'Product version list' ;
<h1>Versions du produit <%== $name %></h1>
<table>
    <tr>
        <th>Version</th>
        <th>Date</th>
    </tr>
    <%== $rows %>
</table>

@@ old_product_list.html.ep
% layout 'default' ;
% title 'Product list' ;
<h1>Produits</h1>
<table>
    <tr>
        <th>Produit</th>
        <th>Home page</th>
    </tr>
    <%== $rows %>
</table>


@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title><%= title %></title>
    <link href="/css/my_style.css" rel="stylesheet" />
</head>
  <body><%= content %></body>
</html>
