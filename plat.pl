#!perl

# need to allow for multiple --k parameters
# eg., --k=32 --k=48 --k=64

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

our $VERSION = 0.01;

MAIN: {
    my $rh_o = process_options();
    assemble($rh_o);
    scaffold($rh_o);
    gap_close($rh_o);
    system "count_fasta.pl out_gapClosed.fa > out_gapClosed.fa.count_fasta";
}

sub assemble {
    my $rh_o = shift;
    my $cmd = "platanus assemble -t $rh_o->{'threads'} -o $rh_o->{'out'} ";
    $cmd .= "-k $rh_o->{'k'} -m $rh_o->{'m'} -f $rh_o->{'left'} ";
    $cmd .= "$rh_o->{'right'} $rh_o->{'unp'} ";
    $cmd .= "> $rh_o->{'out'}.assemble.log ";
    system $cmd;
}

sub scaffold {
    my $rh_o = shift;
    my $cmd = "platanus scaffold -t $rh_o->{'threads'} -o $rh_o->{'out'} ";
    $cmd .= "-c $rh_o->{'out'}_contig.fa -b $rh_o->{'out'}_contigBubble.fa ";
    $cmd .= "-IP1 $rh_o->{'left'} $rh_o->{'right'} ";
    $cmd .= "> $rh_o->{'out'}.scaffold.log ";
    system $cmd;
}

sub gap_close {
    my $rh_o = shift;
    my $cmd = "platanus gap_close -t $rh_o->{'threads'} ";
    $cmd .= "-c $rh_o->{'out'}_scaffold.fa ";
    $cmd .= "-IP1 $rh_o->{'left'} $rh_o->{'right'} ";
    $cmd .= "> $rh_o->{'out'}.gap_close.log ";
    system $cmd;
}

sub process_options {
    my $rh_opts = {};
    my $opt_results = Getopt::Long::GetOptions(
                              "version" => \$rh_opts->{'version'},
                            "threads=i" => \$rh_opts->{'threads'},
                                "out=s" => \$rh_opts->{'out'},
                                  "k=i" => \$rh_opts->{'k'},
                                  "m=i" => \$rh_opts->{'m'},
                               "left=s" => \$rh_opts->{'left'},
                              "right=s" => \$rh_opts->{'right'},
                                "unp=s" => \$rh_opts->{'unp'},
                                 "help" => \$rh_opts->{'help'});
    $rh_opts->{'threads'} = 1 unless ($rh_opts->{'threads'});
    die "$VERSION\n" if ($rh_opts->{'version'});
    pod2usage({-exitval => 0, -verbose => 2}) if $rh_opts->{'help'};
    unless ($rh_opts->{'left'} && $rh_opts->{'right'} && $rh_opts->{'unp'} 
            && $rh_opts->{'out'} && $rh_opts->{'m'} && $rh_opts->{'k'}) {
        warn "missing --left\n"  unless ($rh_opts->{'left'});
        warn "missing --right\n" unless ($rh_opts->{'right'});
        warn "missing --unp\n"   unless ($rh_opts->{'unp'});
        warn "missing --out\n"   unless ($rh_opts->{'out'});
        warn "missing --k\n"     unless ($rh_opts->{'k'});
        warn "missing --m\n"     unless ($rh_opts->{'m'});
        usage();
    }
    return $rh_opts;
}

sub usage {
    die "usage: $0 --out=PREFIX_FOR_OUTFILES --k=KMER --m=MEMORY_LIMIT --left=LEFT_FASTQ --right=RIGHT_FASTQ --unp=UNPAIRED_FASTQ [--threads=NUMTHREADS] [--version] [--help]\n";
}

__END__

=head1 NAME

B<plat.pl> - run platanus assemble, scaffold, and gap_close all at once

=head1 AUTHOR

Joseph F. Ryan <joseph.ryan@whitney.ufl.edu>

=head1 SYNOPSIS

blah

=head1 DESCRIPTION

blah

=head1 BUGS

Please report them to <joseph.ryan@whitney.ufl.edu>

=head1 OPTIONS

=over 2

=item B<--out>

Prefix for outfiles

=item B<--left>

Left reads in fastq format (can be compressed with gz suffix or not)

=item B<--right>

Right reads in fastq format (can be compressed with gz suffix or not)

=item B<--unp>

Unpaired reads in fastq format (can be compressed with gz suffix or not)
optional

=item B<--k>

K-mer value

=item B<--m>

Memory limit

=item B<--threads>

Number of threads

=item B<--version>

Print the program version and exit

=item B<--help>

Print this manual

=back

=head1 COPYRIGHT

Copyright (C) 2015 Joseph F. Ryan

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
