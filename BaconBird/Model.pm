package BaconBird::Model;
use Moose;

use Data::Dumper;

use constant CONSUMER_KEY => "HNWGxf3exkB1mQGpM83PWw";
use constant CONSUMER_SECRET => "dcQsVwycEa6vNCMO0ljbzZfzloqBXcRDMYXRo1bsN7k";

use Net::Twitter;

has 'ctrl' => (
	is => 'rw',
	isa => 'BaconBird::Controller',
);

has 'nt' => (
	is => 'ro',
	isa => 'Net::Twitter',
	default => sub { return Net::Twitter->new(traits => [qw/OAuth API::REST InflateObjects RateLimit/], consumer_key => CONSUMER_KEY, consumer_secret => CONSUMER_SECRET); },
);

has 'user_id' => (
	is => 'rw',
	isa => 'Str',
);

has 'screen_name' => (
	is => 'rw',
	isa => 'Str',
);

has 'home_timeline' => (
	is => 'rw',
	isa => 'ArrayRef',
	default => sub { [ ] },
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

sub reload_home_timeline {
	my $self = shift;
	my $id = -1;

	if (defined($self->home_timeline) && scalar(@{$self->home_timeline}) > 0) {
		$id = $self->home_timeline->[0]->{id};
	}
	my $newdata = $self->nt->home_timeline({ since_id => $id, count => 50 });
	my $olddata = $self->home_timeline;
	my @new_timeline = ( @$newdata, @$olddata );

	$self->home_timeline(\@new_timeline);
}

sub post_update {
	my $self = shift;
	my ($tweet, $status_id) = @_;

	$status_id = -1 if !defined($status_id);

	$self->nt->update({ status => $tweet, in_reply_to_status_id => $status_id });
}

sub get_rate_limit {
	my $self = shift;
	return ($self->nt->rate_remaining, $self->nt->rate_limit);
}

sub get_wait_time {
	my $self = shift;
	my $ratio = $self->nt->until_rate(1.5);
	return $ratio;
}

sub retweet {
	my $self = shift;
	my ($id) = @_;
	$self->nt->retweet($id);
}

sub lookup_author {
	my $self = shift;
	my ($tweetid) = @_;
	foreach my $status (@{$self->home_timeline}) {
		print STDERR Dumper($status);
		return $status->{user}{screen_name} if $status->{id} == $tweetid;
	}
	return "";
}

no Moose;
1;
