package BaconBird::Shortener;
use Moose;

use WWW::Shorten 'IsGd', ':short';
use URI::Find;

has 'finder' => (
	is => 'rw',
	isa => 'URI::Find',
	default => sub { URI::Find->new(\&replace_uri) },
);

has 'cache' => (
	is => 'rw',
	isa => 'HashRef',
	default => sub { { } },
);

sub shorten_text {
	my $self = shift;
	my ($text) = @_;

	my $finder = URI::Find->new(sub {
		my ($uri_obj, $uri_text) = @_;

		if ($self->cache->{$uri_text}) {
			return $uri_text;
		}

		my $shorturl = short_link($uri_text);
		if (defined($shorturl) && length($shorturl) <= length($uri_text)) {
			$self->cache->{$shorturl} = 1;
			return $shorturl;
		}
		return $uri_text;
	});

	$finder->find(\$text);

	return $text;
}

no Moose;
1;
