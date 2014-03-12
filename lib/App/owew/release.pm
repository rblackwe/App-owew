#!/usr/bin/perl
package App::owew::release;

use warnings;
use strict;
use MetaCPAN::API;
use Test::More;
use Data::Dumper;
use DateTime::Format::Strptime;
use DateTime;
use CHI;
use WWW::Mechanize::Cached;
use HTTP::Tiny::Mech;
use MetaCPAN::API;

__PACKAGE__->run( @ARGV ) unless caller();
sub run {

my $class       = shift;
my $cpan_author = uc shift;

BAIL_OUT("CPAN author required! Ex: %>prove release.t :: rblackwe") unless $cpan_author;

my $mcpan = MetaCPAN::API->new(
  ua => HTTP::Tiny::Mech->new(
    mechua => WWW::Mechanize::Cached->new(
      cache => CHI->new(
        driver => 'File',
        root_dir => '/tmp/metacpan-cache',
      ),
    ),
  ),
);
my $author; 
eval {
	$author = $mcpan->author($cpan_author);
};

BAIL_OUT("$cpan_author not found $@") if $@;

my $releases  = $mcpan->release(
        search => {
            q    => "author:$cpan_author",
	    fields => 'name,date'
        },
);

my $now = DateTime->now(time_zone=>'local');
my $parser = DateTime::Format::Strptime->new(
	  pattern => '%Y-%m-%d',
	  on_error => 'croak',
	);

my $contest_ok;

R: for my $release (@{ $releases->{hits}{hits} }) {
	my $date = $release->{fields}{date};
	my $name = $release->{fields}{name};
	$date =~ s/T.*$//;
	my $dt = $parser->parse_datetime($date);
	my $days = int($now->subtract_datetime_absolute($dt)->delta_seconds / (24*60*60));
	warn "$name released $days ago";
	if($days <= 7 ) {
		pass "Days $days - $date";
		$contest_ok = 1;
		last R;
	} else {
		warn "Days $days - $date";
	}
}

unless ($contest_ok) {
	fail "too many days ";
}

done_testing;
}
1;
