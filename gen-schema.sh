#!/bin/bash

# auteur : Dominique Dumont <ddumont@cpan.org>

# le fichier .cred.sh contient une ligne PASS=votre_mot_de_passe
# pour le compte root de la base de données. A charge pour vous 
# de créer votre fichier pour votre base de données
. .cred.sh

perl -Ilib -S dbicdump -o dump_directory=./lib -o use_moose=1 -o components='["InflateColumn::DateTime"]' Integ::Schema dbi:mysql:Integ root $PASS
