#!/usr/bin/env perl

# usage: $0 start_index urls*

use strict;
use warnings;

use WWW::Mechanize;

my $name = "%02d %s";

my $agent = WWW::Mechanize->new();
my $i = 0 + shift;

for (@ARGV) {
    my $content = $agent->get($_) or die "Could not get $_";
    for (split /\n/, $agent->content) {
        if (m!"(.*/(.*?\.mp4))"!) {
            system 'wget', $1, '-O', sprintf($name, $i++, $2)
        }
    }
}
