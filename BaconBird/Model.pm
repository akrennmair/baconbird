package BaconBird::Model;
use Moose;

use constant CONSUMER_KEY => "HNWGxf3exkB1mQGpM83PWw";
use constant CONSUMER_SECRET => "dcQsVwycEa6vNCMO0ljbzZfzloqBXcRDMYXRo1bsN7k";

use Net::Twitter;

has 'access_token' => (
	is => 'rw',
	isa => 'Str',
);

has 'access_token_secret' => (
	is => 'rw',
	isa => 'Str',
);

has 'ctrl' => (
	is => 'rw',
	isa => 'BaconBird::Controller',
);

has 'nt' => (
	is => 'rw',
	isa => 'Net::Twitter',
	default => sub { my $self = shift; return Net::Twitter->new(traits => [qw/OAuth API::REST InflateObjects/], consumer_key => CONSUMER_KEY, consumer_secret => CONSUMER_SECRET); },
);

has 'user_id' => (
	is => 'rw',
	isa => 'Str',
);

has 'screen_name' => (
	is => 'rw',
	isa => 'Str',
);

sub login {
	my $self = shift;
	my ($at, $ats) = $self->ctrl->load_tokens();
	if ($at && $ats) {
		$self->nt->access_token($at);
		$self->nt->access_token_secret($ats);
	}
	unless ($self->nt->authorized) {
		my $pin = $self->ctrl->get_pin($self->nt->get_authorization_url);
		my ($new_at, $new_ats, $user_id, $screen_name) = $self->nt->request_access_token(verifier => $pin);
		$self->ctrl->save_tokens($new_at, $new_ats);
		$self->user_id($user_id);
		$self->screen_name($screen_name);
	}
}

sub home_timeline {
	my $self = shift;

	return $self->nt->home_timeline;
}

no Moose;
1;
