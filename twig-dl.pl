#!/usr/bin/env perl

use strict;
use warnings;
use WWW::Mechanize;
use HTML::TreeBuilder::XPath;
use autodie;

my $mech = WWW::Mechanize->new();
$mech->ssl_opts(verify_hostname => 0);
my $start_chapter = 0;
my $bookname = 'Twig by Wildbow';
my $bookurl = 'https://twigserial.wordpress.com/2014/12/24/taking-root-1-1/';

if (@ARGV == 1) {
    $start_chapter = $ARGV[0];
    open OUTFILE, '>>:encoding(UTF-8)', "$bookname.html";
} else {
    open OUTFILE, '>:encoding(UTF-8)', "$bookname.html";
}

print OUTFILE "<!DOCTYPE html>\n",
    '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />',
    "\n<title>$bookname</title>\n";

my $link;

#for my $topic ($tree->findnodes('//div[contains(@class,"entry-title")]')) {
while ($bookurl) {
    $mech->get($bookurl);
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse_content($mech->content());
    my $step = 1;
    for ($tree->findnodes_as_string('//h1[@class="entry-title"]')) {
        print "$_";
        print OUTFILE "$_\n";
        $step *= 2;
    }
    for ($tree->findnodes_as_string('//div[@class="entry-content"]/p')) {
        s!<a.*?>.*?</a>!!g;
        print OUTFILE "$_\n";
        $step *= 3;
    }
    unless ($step == 6) {
        print "failed with step: $step\n";
        exit;
    }
    print "finding next chapter...\n";
    $link = $mech->find_link(text => 'Next');
    $bookurl = eval{ $link->url() } // undef;
}
close OUTFILE;
