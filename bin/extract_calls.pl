#!/usr/bin/env perl
use strict;
use warnings;
use List::Util qw(max);

my $threshold = 240;

while (<>) {
    chomp;
    my ($read_id, $seq, $mm, $ml) = split /\t/;
    my @prob_values = split /,/, $ml;

    my @mod_groups = split /;/, $mm;

    my $prob_index = 0;  # cumulative index across groups

    foreach my $group (@mod_groups) {
        next if $group eq '';
        
        if ($group =~ /^([ACGT])([\+\-])([a-z]),(.+)$/) {
            my $base = $1;
            my @rel_positions = split /,/, $4;
            
            my $n_positions = scalar @rel_positions;
            my @group_probs = @prob_values[$prob_index .. $prob_index + $n_positions - 1];
            $prob_index += $n_positions;
            
            my $max = max(@group_probs);
            next unless $max >= $threshold;

            # Find base positions in seq
            my @base_pos; 
            while ($seq =~/$base/g){
                push @base_pos, pos($seq);
            }

            
            my $cumsum = 0;
            my @pass_positions = ();

            for (my $i=0; $i < $n_positions; $i++) {
                $cumsum += $rel_positions[$i] + 1;

                my $prob = $group_probs[$i];
                if (defined $prob && $prob >= $threshold) {
                    push @pass_positions, $base_pos[$cumsum - 1];
                    #print "$cumsum\n";
                }
            }
            if (@pass_positions) {
                print join("\t", $read_id, $base, join(",", @pass_positions)), "\n";
            }
        }
    }
}

