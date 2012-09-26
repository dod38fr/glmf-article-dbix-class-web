#!/usr/bin/env perl

# auteur : Dominique Dumont <ddumont@cpan.org>

use 5.10.1;
use lib 'lib';
use Mojolicious::Lite;
use Integ::Schema;
use HTML::Tiny;

# Generated automatically with HTML::FormHandler::Generator::DBIC
# Using following commandline:
# dbic_form_generator --rs_name=Product --schema_name=Integ::Schema --db_dsn=dbi:mysql:database=Integ
{

    package ProductForm;
    use HTML::FormHandler::Moose;
    extends 'HTML::FormHandler::Model::DBIC';
    use namespace::autoclean;

    use DateTime;

    has '+item_class' => ( default => 'Product' );

    has_field 'home_page'        => ( type   => 'TextArea', );
    has_field 'name'             => ( type   => 'Text', size => 32, required => 1, );
    has_field 'product_versions' => ( type   => '+ProductVersionField', );
    has_field 'submit'           => ( widget => 'Submit', );

    __PACKAGE__->meta->make_immutable;
    no HTML::FormHandler::Moose;
}

{

    package ProductVersionField;
    use HTML::FormHandler::Moose;
    extends 'HTML::FormHandler::Field::Compound';
    use namespace::autoclean;

    has_field 'log' => ( type => 'TextArea', required => 1, );
    has_field 'date' => (
        type  => 'Compound',
        apply => [
            {
                transform => sub { DateTime->new( $_[0] ) },
                message   => "Not a valid DateTime",
            }
        ],
    );
    has_field 'date.year';
    has_field 'date.month';
    has_field 'date.day';
    has_field 'version' => ( type => 'Text', size => 32, required => 1, );
    has_field 'product' => ( type => 'Select', );

    __PACKAGE__->meta->make_immutable;
    no HTML::FormHandler::Moose;
}

my $password  = 'foobar';
my $integ_dbo = 'dbi:mysql:database=Integ;host=localhost;port=3306';

my $integ_schema =
  Integ::Schema->connect( $integ_dbo, 'integ_mgr', $password,
    { RaiseError => 1, quote_names => 1 } );

my $h = HTML::Tiny->new;

get '/' => sub {
    my $self = shift;

    my $form = ProductForm->new();

    $self->render(
        template  => 'product_mod',
        my_action => 'ok',
        my_form   => $form
    );

};

get '/alamojo/' => sub {
    my $self = shift;

    $self->render( mojo_product_list => rs => $integ_schema->resultset('Product') );
};

get '/alamojo/:name/#version' => sub {
    my $self = shift;

    # trouver la version dans la base
    my $pv =
      $integ_schema->resultset('Product')->find( { name => $self->stash('name') } )
      ->product_versions->find( { version => $self->stash('version') } );

    # construire les boutons
    my @radio_items = map {
        $h->label($_)
          . $h->input(
            {
                type  => "radio",
                name  => "v_status",
                value => "$_",
                ( $_ eq $pv->status ) ? ( checked => 'checked' ) : ()
            }
          );
    } qw/unstable testing stable/;

    $self->render(
        template => 'mojo_template_mod',
        radio_b  => \@radio_items,
        pv       => $pv,
    );

};

get '/alamojo/:name' => sub {
    my $self = shift;
    $self->render(
        template => 'mojo_prod_v_list',
        p        => $integ_schema->resultset('Product')->find( { name => $self->stash('name') } ),
    );

};

post '/alamojo/product_version_data_save/:vid' => sub {
    my $self = shift;

    my $v_obj = $integ_schema->resultset('ProductVersion')->find( { id => $self->stash('vid') } );

    my $value = $self->param('v_status');
    $v_obj->status($value);
    $v_obj->update;

    $self->render(
        'product_version_save_done',
        p => $v_obj->product,
        v => $v_obj->version
    );
};

app->start;

__DATA__

@@ product_mod.html.ep
% layout 'default' ;
% title 'Product' ;
<h1>Product</h1>
<%== $my_form->render %>

@@ mojo_product_list.html.ep
% layout 'default' ;
% title 'Product list' ;
<h1>Produits</h1>
<table>
    <tr>
        <th>Produit</th>
    </tr>
% while (my $product = $rs->next) {
%   my $name = $product-> name ;
    <tr>
        <td><a href="/alamojo/<%==$name%>"><%== $name %></td>
    </tr>
% }    
</table>


@@mojo_prod_v_list.html.ep
% layout 'default' ;
% title 'Product versions' ;
<h1>Versions of product <%== $p->name %></h1>
 <ul>
% foreach my $r ($p->product_versions) {
%   my $v = $r->version ;
 <li><a href="<%== $p->name.'/'.$v %>"><%== $v %></a>
% }
 </ul>

@@mojo_template_mod.html.ep
% layout 'default' ;
% title 'Product status' ;
<h1>Product <%== $pv->product->name %> version <%== $pv->version %></h1>
 
<form name="save_data" 
      action="/alamojo/product_version_data_save/<%= $pv->id %>"
      method="post">
status : 
   <%== join("\n",@$radio_b) ; %>
   <input type="submit" 
          name="save-product-version" 
          value="Save status"/>
</form>

@@ product_version_save_done.html.ep
%title 'product '.$p->name . ' saved ' ;
%layout 'redirect', redirect_url => '/' ;
<p>Product <%= $p->name %> version <%== $v %> was saved</p>

<p><a href="/alamojo/">go back to product list</a></p>

