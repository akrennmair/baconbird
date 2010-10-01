package WWW::Shorten::IsGd;

use 5.006;
use strict;
use warnings;

use Data::Dumper;

use base qw( WWW::Shorten::generic Exporter );
our @EXPORT = qw( makeashorterlink makealongerlink );
our $VERSION = "1.81";

use Carp;

sub makeashorterlink ($)
{
	my $url = shift or croak 'No URL passed to makeashorterlink';
	my $ua = __PACKAGE__->ua();
	my $tinyurl = 'http://is.gd/api.php?longurl=' . $url;
	my $resp = $ua->get($tinyurl, [
	source => "PerlAPI-$VERSION",
	]);
	return undef unless $resp->is_success;
	my $content = $resp->content;
	if ($resp->content =~ m!(\Qhttp://is.gd/\E\w+)!x) {
		return $1;
	}
	return;
}

sub makealongerlink ($)
{   
    my $isgd_url = shift
        or croak 'No is.gd key / URL passed to makealongerlink';
    my $ua = __PACKAGE__->ua();

    $isgd_url = "http://is.gd/$isgd_url"
    unless $isgd_url =~ m!^http://!i;

    my $resp = $ua->get($isgd_url);

    return undef unless $resp->is_redirect;
    my $url = $resp->header('Location');
    return $url;

}

1;

__END__

=head1 NAME

WWW::Shorten::IsGd - Perl interface to is.gd

=head1 SYNOPSIS

  use WWW::Shorten::IsGd;
  use WWW::Shorten 'IsGd';

  $short_url = makeashorterlink($long_url);

  $long_url  = makealongerlink($short_url);

=head1 DESCRIPTION

A Perl interface to the web site is.gd.  is.gd simply maintains
a database of long URLs, each of which has a unique identifier.

The function C<makeashorterlink> will call the is.gd web site passing
it your long URL and will return the shorter is.gd version.

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument either the full is.gd URL or just the
is.gd identifier.

If anything goes wrong, then either function will return C<undef>.

=head2 EXPORT

makeashorterlink, makealongerlink

=head1 SUPPORT, LICENCE, THANKS and SUCH

See the main L<WWW::Shorten> docs.

=head1 AUTHOR

Andreas Krennmair <ak@synflood.at>

Based almost entirely on WWW::Shorten::TinyURL by Iain Truskett <spoon@cpan.org>

=head1 SEE ALSO

L<WWW::Shorten>, L<perl>, L<http://is.gd/>

=cut
