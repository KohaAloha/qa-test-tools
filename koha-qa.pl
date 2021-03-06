#!/usr/bin/perl -w

our ($v, $d, $c, $nocolor, $help);

BEGIN {
    use Getopt::Long;
    use Pod::Usage;
    $ENV{'Smart_Comments'}  = 0;

    our $r = GetOptions(
        'v:s' => \$v,
        'c:s' => \$c,
        'd' => \$d,
        'nocolor' => \$nocolor,
        'h|help' => \$help,
    );
    pod2usage(1) if $help or not $c;

    $v = 0 if not defined $v or $v eq '';
    $c = 1 if not defined $c or $c eq '';
    $nocolor = 0 if not defined $nocolor;

    $ENV{'Smart_Comments'}  = 1 if $d;

}

use Modern::Perl;
use Getopt::Long;
use QohA::Git;
use QohA::Files;

BEGIN {
    eval "require Test::Perl::Critic::Progressive";
    die
"Test::Perl::Critic::Progressive is not installed \nrun:\ncpan install Test::Perl::Critic::Progressive\nto install it\n"
      if $@;
}

$c = 1 unless $c;
my $num_of_commits = $c;

my $git = QohA::Git->new();
our $branch = $git->branchname;
my ( $new_fails, $already_fails, $skip, $error_code, $full ) = 0;

eval {

    print QohA::Git::log_as_string($num_of_commits);

    my $modified_files = QohA::Files->new( { files => $git->log($num_of_commits) } );

    $git->delete_branch( 'qa-prev-commit' );
    $git->create_and_change_branch( 'qa-prev-commit' );
    $git->reset_hard_prev( $num_of_commits );

    my @files = $modified_files->filter( qw< perl tt xml yaml > );

    for my $f ( @files ) {
        $f->run_checks();
    }

    $git->change_branch($branch);
    $git->delete_branch( 'qa-current-commit' );
    $git->create_and_change_branch( 'qa-current-commit' );
    for my $f ( @files ) {
        $f->run_checks($num_of_commits);
    }

    for my $f ( @files ) {
        say $f->report->to_string({ verbosity => $v, color => not $nocolor });
    }
};

if ($@) {
    say "\n\nAn error occurred : $@";
}

$git->change_branch($branch);

exit(0);

__END__

=head1 NAME

koha-qa.pl

=head1 SYNOPSIS

koha-qa.pl -c NUMBER_OF_COMMITS [-v VERBOSITY_VALUE] [-d] [--nocolor] [-h]


=head1 DESCRIPTION

koha-qa.pl runs various QA tests on the last $x commits, in a Koha git repo.

refer to the ./README file for installation info

=head1 OPTIONS

=over 8

=item B<-h|--help>

prints this help message

=item B<-v>

change the verbosity of the output
    0 = default, only display the list of files
    1 = display for each file the list of tests
    2 = display for each test the list of failures

=item B<-c>

Number of commit to test from HEAD

=item B<-d>

Debug mode

=item B<--nocolor>

do not display the status with color

=back

=head1 AUTHOR

Mason James <mtj at kohaaloha.com>
Jonathan Druart <jonathan.druart at biblibre.com>

=head1 COPYRIGHT

This software is Copyright (c) 2012 by KohaAloha and BibLibre

=head1 LICENSE

This file is part of Koha.

Koha is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software
Foundation; either version 3 of the License, or (at your option) any later version.

You should have received a copy of the GNU General Public License along
with Koha; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=head1 DISCLAIMER OF WARRANTY

Koha is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

=cut
