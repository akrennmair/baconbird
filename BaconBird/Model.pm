package BaconBird::Model;
use Moose;

use Data::Dumper;

use constant CONSUMER_KEY => "HNWGxf3exkB1mQGpM83PWw";
use constant CONSUMER_SECRET => "dcQsVwycEa6vNCMO0ljbzZfzloqBXcRDMYXRo1bsN7k";

use constant DEFAULT_WAIT_TIME => 60;

use constant HOME_TIMELINE => 1;
use constant MENTIONS => 2;
use constant DIRECT_MESSAGES => 3;

use Net::Twitter;
use I18N::Langinfo qw(langinfo CODESET);
use Encode::Encoder;

has 'ctrl' => (
	is => 'rw',
	isa => 'BaconBird::Controller',
);

has 'nt' => (
	is => 'ro',
	isa => 'Net::Twitter',
	default => sub { return Net::Twitter->new(traits => [qw/OAuth API::REST InflateObjects RateLimit/], consumer_key => CONSUMER_KEY, consumer_secret => CONSUMER_SECRET, decode_html_entities => 1); },
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
	default => HOME_TIMELINE,
);

has 'home_timeline_ts' => (
	is => 'rw',
	isa => 'Int',
	default => 0,
);

has 'direct_messages_ts' => (
	is => 'rw',
	isa => 'Int',
	default => 0,
);

has 'mentions_ts' => (
	is => 'rw',
	isa => 'Int',
	default => 0,
);

has 'all_messages' => (
	is => 'rw',
	isa => 'HashRef',
	default => sub { { } },
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

sub reload_all {
	my $self = shift;
	my $tl = $self->current_timeline;
	if ($tl == HOME_TIMELINE) {
		$self->reload_home_timeline;
	} elsif ($tl == DIRECT_MESSAGES) {
		$self->reload_direct_messages;
	} elsif ($tl == MENTIONS) {
		$self->reload_mentions;
	}
}

sub reload_home_timeline {
	my $self = shift;
	my $id = -1;

	if (defined($self->home_timeline) && scalar(@{$self->home_timeline}) > 0) {
		$id = $self->home_timeline->[0]->{id};
	}

	eval {
		my $newdata = $self->nt->home_timeline({ since_id => $id, count => 50 });
		my $olddata = $self->home_timeline;
		my @new_timeline = ( @$newdata, @$olddata );

		$self->add_new_messages($newdata);

		$self->home_timeline(\@new_timeline);
	};
	if (my $err = $@) {
		die "Reloading home timeline failed: " . $err->error . "\n";
	}
	$self->home_timeline_ts(time);
}

sub reload_mentions {
	my $self = shift;
	my $id = -1;
	if (defined($self->mentions) && scalar(@{$self->mentions}) > 0) {
		$id = $self->mentions->[0]->{id};
	}

	eval {
		my $newdata = $self->nt->mentions({ since_id => $id, count => 50 });
		my $olddata = $self->mentions;
		my @new_mentions = ( @$newdata, @$olddata );

		$self->add_new_messages($newdata);

		$self->mentions(\@new_mentions);
	};
	if (my $err = $@) {
		die "Reloading mentions failed: " . $err->error . "\n";
	}
	$self->mentions_ts(time);
}

sub reload_direct_messages {
	my $self = shift;
	my $id = -1;
	if (defined($self->direct_messages) && scalar(@{$self->direct_messages}) > 0) {
		$id = $self->direct_messages->[0]->{id};
	}

	eval {
		my $newdata = $self->nt->direct_messages({ since_id => $id, count => 50 });
		my $olddata = $self->direct_messages;
		my @new_dms = ( @$newdata, @$olddata );
		$self->direct_messages(\@new_dms);
	};
	if (my $err = $@) {
		die "Reloading direct messages failed: " . $err->error . "\n";
	}
	$self->direct_messages_ts(time);
}

sub post_update {
	my $self = shift;
	my ($tweet, $status_id) = @_;

	my $e = Encode::Encoder->new($tweet, langinfo(CODESET()));
	$tweet = $e->iso_8859_1->data;

	$status_id = -1 if !defined($status_id);

	eval {
		$self->nt->update({ status => $tweet, in_reply_to_status_id => $status_id });
	};
	if (my $err = $@) {
		die "Posting update failed: " . $err->error . "\n";
	}
}

sub get_rate_limit {
	my $self = shift;
	return ($self->nt->rate_remaining, $self->nt->rate_limit, $self->nt->rate_reset - time);
}

sub get_wait_time {
	my $self = shift;
	my $waittime = int(($self->nt->rate_reset - time) / ($self->nt->rate_remaining * 1.5));
	#print STDERR "get_wait_time: $waittime s\n";
	return $waittime;
}

sub retweet {
	my $self = shift;
	my ($id) = @_;

	if ($self->current_timeline == DIRECT_MESSAGES) {
		die "you can't retweet a direct message.\n";
	}

	eval {
		$self->nt->retweet($id);
	};
	if (my $err = $@) {
		die "Retweet failed: " . $err->error . "\n";
	}
}

sub lookup_author {
	my $self = shift;
	my ($tweetid) = @_;
	my $tweet = $self->get_message_by_id($tweetid);
	return $tweet->{user}{screen_name} if $tweet;
	return "";
}

sub select_timeline {
	my $self = shift;
	my ($timeline) = @_;
	$self->current_timeline($timeline);
	if ($timeline == HOME_TIMELINE) {
		$self->reload_home_timeline if ($self->home_timeline_ts + DEFAULT_WAIT_TIME) < time;
	} elsif ($timeline == DIRECT_MESSAGES) {
		$self->reload_direct_messages if ($self->direct_messages_ts + DEFAULT_WAIT_TIME) < time;
	} elsif ($timeline == MENTIONS) {
		$self->reload_mentions if ($self->mentions_ts + DEFAULT_WAIT_TIME) < time;
	}
}

sub get_timeline {
	my $self = shift;
	if ($self->current_timeline == HOME_TIMELINE) {
		return $self->home_timeline;
	} elsif ($self->current_timeline == MENTIONS) {
		return $self->mentions;
	} elsif ($self->current_timeline == DIRECT_MESSAGES) {
		return $self->direct_messages;
	} else {
		# an unknown timeline type is a bug
		return undef;
	}
}

sub add_new_messages {
	my $self = shift;
	my ($msgs) = @_;

	foreach my $m (@$msgs) {
		$self->all_messages->{$m->{id}} = $m;
	}
}

sub get_message_by_id {
	my $self = shift;
	my ($id) = @_;
	return $self->all_messages->{$id};
}

no Moose;
1;
