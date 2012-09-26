#!/usr/bin/env perl

# auteur : Dominique Dumont <ddumont@cpan.org>

use 5.10.1;
use lib 'lib';
use Mojolicious::Lite;
use Integ::Schema;
use HTML::Tiny;

# Generated automatically with HTML::FormHandler::Generator::DBIC
# Using following commandline:
# dbic_form_generator --rs_name=ProductVersion --schema_name=Integ::Schema --db_dsn=dbi:mysql:database=Integ
{
    package ProductVersionForm;
    use HTML::FormHandler::Moose;
    extends 'HTML::FormHandler::Model::DBIC';
    use namespace::autoclean;

    has '+item_class' => ( default => 'ProductVersion' );

    has_field 'status' => ( 
        type => 'Select', 
        widget => 'RadioGroup',
        options => [ map { { label => $_ , value => $_ } ;} qw/unstable testing stable/ ],
        init_value => 'unstable' ,
    );
    has_field 'log' => ( type => 'Text', # or TextArea for bigger edition area
        required => 1,
        apply => [ 
            {
                check => \&whatever,
                message => 'whatever rule was not satisfied' 
            }
        ]
    );
    has_field 'submit' => ( type => 'Submit', value => 'Save' );

    sub whatever {
        my ( $value, $field ) = @_;
        return $value =~ /whatever/ ? 1 : 0 ;
    }
    __PACKAGE__->meta->make_immutable;
    no HTML::FormHandler::Moose;
}

my $password  = 'foobar';
my $integ_dbo = 'dbi:mysql:database=Integ;host=localhost;port=3306';

my $integ_schema =
  Integ::Schema->connect( $integ_dbo, 'integ_mgr', $password,
    { RaiseError => 1, quote_names => 1 } );

my $h = HTML::Tiny->new;

# identique à la version mojo
get '/alaformhandler/' => sub {
    my $self = shift;

    $self->render( formhandler_product_list => rs => $integ_schema->resultset('Product') );
};

# identique à la version mojo
get '/alaformhandler/:name' => sub {
    my $self = shift;
    $self->render(
        template => 'formhandler_prod_v_list',
        p        => $integ_schema->resultset('Product')->find( { name => $self->stash('name') } ),
    );

};

get '/alaformhandler/:name/#version' => sub {
    my $self = shift;

    # trouver la version dans la base
    my $pv = $integ_schema
        ->resultset('Product')
        ->find( { name => $self->stash('name') } )
        ->product_versions
        ->find( { version => $self->stash('version') } );

    my $form = ProductVersionForm->new(
        action => "/alaformhandler/product_version_data_save/".$pv->id,
        item => $pv, # pour afficher la valeur courante
    ) ;

    $self->render(
        template => 'formhandler_template_mod',
        my_form  => $form ,
        pv       => $pv,
    );

};

post '/alaformhandler/product_version_data_save/:vid' => sub {
    my $self = shift;

    my $form = ProductVersionForm->new;

    # ne pas oublier de traiter les paramètres
    $form->process(  
        schema => $integ_schema ,
        item_id => $self->stash('vid') ,
        params => $self->req->params->to_hash 
    ) ;

    if ($form->has_errors) {
        # FIXME: improve display of frame creation errors
        return $self->render(text => join("\n", $form->errors )) ;
    }

    $self->render(
        'product_version_save_done',
    );
};

app->start;

__DATA__

@@ product_mod.html.ep
% layout 'default' ;
% title 'Product' ;
<h1>Product</h1>
<%== $my_form->render %>

@@ formhandler_product_list.html.ep
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
        <td><a href="/alaformhandler/<%==$name%>"><%== $name %></td>
    </tr>
% }    
</table>


@@formhandler_prod_v_list.html.ep
% layout 'default' ;
% title 'Product versions' ;
<h1>Versions of product <%== $p->name %></h1>
 <ul>
% foreach my $r ($p->product_versions) {
%   my $v = $r->version ;
 <li><a href="<%== $p->name.'/'.$v %>"><%== $v %></a>
% }
 </ul>

@@formhandler_template_mod.html.ep
% layout 'default' ;
% title 'Product status' ;
<h1>Product <%== $pv->product->name %> version <%== $pv->version %></h1>
<%== $my_form->render%> 

@@ product_version_save_done.html.ep
%title 'product  saved ' ;
%layout 'redirect', redirect_url => '/' ;
<p>Product status was saved</p>

<p><a href="/alaformhandler/">go back to product list</a></p>

