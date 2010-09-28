package BaconBird::Model;
use Moose;

use Data::Dumper;

use constant CONSUMER_KEY => "HNWGxf3exkB1mQGpM83PWw";
use constant CONSUMER_SECRET => "dcQsVwycEa6vNCMO0ljbzZfzloqBXcRDMYXRo1bsN7k";

use constant DEFAULT_WAIT_TIME => 60;

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

has 'mentions' => (
	is => 'rw',
	isa => 'ArrayRef',
	default => sub { [ ] },
);

has 'direct_messages' => (
	is => 'rw',
	isa => 'ArrayRef',
	default => sub { [ ] },
);

has 'current_timeline' => (
	is => 'rw',
	default => "home_timeline",
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

sub reload_mentions {
	my $self = shift;
	my $id = -1;
	if (defined($self->mentions) && scalar(@{$self->mentions}) > 0) {
		$id = $self->mentions->[0]->{id};
	}

	my $newdata = $self->nt->mentions({ since_id => $id, count => 50 });
	my $olddata = $self->mentions;
	my @new_mentions = ( @$newdata, @$olddata );

	$self->mentions(\@new_mentions);
}

sub reload_direct_messages {
	my $self = shift;
	my $id = -1;
	if (defined($self->direct_messages) && scalar(@{$self->direct_messages}) > 0) {
		$id = $self->direct_messages->[0]->{id};
	}

	my $newdata = $self->nt->direct_messages({ since_id => $id, count => 50 });
	my $olddata = $self->direct_messages;
	my @new_dms = ( @$newdata, @$olddata );

	$self->direct_messages(\@new_dms);
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
	#my $ratio = $self->nt->until_rate(1.5);
	#return $ratio;
	return DEFAULT_WAIT_TIME;
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
		#print STDERR Dumper($status);
		return $status->{user}{screen_name} if $status->{id} == $tweetid;
	}
	return "";
}

sub select_timeline {
	my $self = shift;
	my ($timeline) = @_;
	$self->current_timeline($timeline);
}

sub get_timeline {
	my $self = shift;
	if ($self->current_timeline eq "home_timeline") {
		return $self->home_timeline;
	} elsif ($self->current_timeline eq "mentions") {
		return $self->mentions;
	} elsif ($self->current_timeline eq "direct_messages") {
		return $self->direct_messages;
	} else {
		# an unknown timeline type is a bug
		return undef;
	}
}

no Moose;
1;
