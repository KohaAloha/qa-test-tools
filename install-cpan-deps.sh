# apt-get install libmodern-perl-perl
# cat ./perl-deps | cpanm  --installdeps --notest
#cat ./cpan-deps | cpanm  -S --installdeps 
cat ./cpan-deps | cpanm  --installdeps --notest
cat ./cpan-deps | cpanm  --notest
