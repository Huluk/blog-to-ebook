#!/usr/bin/env perl

use WWW::Mechanize;
use autodie;

my $mech = WWW::Mechanize->new();
my $start_chapter = 0;

if (@ARGV == 1) {
    $start_chapter = $ARGV[0];
    open OUTFILE, '>>:encoding(UTF-8)', 'Starwalker.html';
} else {
    open OUTFILE, '>:encoding(UTF-8)', 'Starwalker.html';
}

print OUTFILE "<!DOCTYPE html>\n",
    '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />',
    "\n<title>Starwalker</title>\n";

$mech->get('http://www.starwalkerblog.com/');
my @chapter_links = $mech->find_all_links(
    text_regex => qr/\A\d\.\d:/
);
while (@chapter_links && $chapter_links[0]->text() =~ s/\A(\d\.\d).*\Z/\1/r < $start_chapter) {
    shift(@chapter_links);
}

foreach $chapter (@chapter_links) {
    $mech->get($chapter->url());
    my $topic = $chapter->text();
    print "$topic\n";
    print OUTFILE "<h1>$topic</h1>\n";

    foreach $link ($mech->find_all_links()) {
        my %attrs = %{$link->attrs()};
        next unless (defined $attrs{title} && $attrs{title} =~ /Permanent Link to/);
        $mech->get($link->url());
        $topic = $link->text();
        print "$topic\n";
        print OUTFILE "<h2>$topic</h2>\n";
        $mech->content() =~ /<div class="entry">(.*?)^<div.*?>/ms;
        print OUTFILE $1 =~ s! |\r!!rg, "\n"; # do not print \r and no break spaces
    }
}
close OUTFILE;
