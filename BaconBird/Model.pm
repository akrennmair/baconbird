package BaconBird::Model;
use Moose;

use Data::Dumper;

use constant CONSUMER_KEY    => "HNWGxf3exkB1mQGpM83PWw";
use constant CONSUMER_SECRET => "dcQsVwycEa6vNCMO0ljbzZfzloqBXcRDMYXRo1bsN7k";

use constant DEFAULT_WAIT_TIME => 60;
use constant MIN_WAIT_TIME     => 10;

use constant HOME_TIMELINE      => 1;
use constant MENTIONS           => 2;
use constant DIRECT_MESSAGES    => 3;
use constant SEARCH_RESULTS     => 4;
use constant USER_TIMELINE      => 5;
use constant HELP               => 6;
use constant FAVORITES_TIMELINE => 7;
use constant RT_BY_ME_TIMELINE  => 8;
use constant RT_OF_ME_TIMELINE  => 9;
use constant MY_TIMELINE        => 10;
use constant LOAD_SEARCH        => 11;
use constant SAVED_SEARCH       => 12;
use constant FOLLOWERS          => 13;
use constant FRIENDS            => 14;

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
	default => sub { return Net::Twitter->new(traits => [qw/OAuth API::REST InflateObjects RateLimit API::Search/], consumer_key => CONSUMER_KEY, consumer_secret => CONSUMER_SECRET, decode_html_entities => 1, ssl => 1); },
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

has 'search_results' => (
	is => 'rw',
	isa => 'ArrayRef',
	default => sub { [ ] },
);

has 'user_timeline' => (
	is => 'rw',
	isa => 'ArrayRef',
	default => sub { [ ] },
);

has 'current_timeline' => (
	is => 'rw',
	default => HOME_TIMELINE,
);

has 'favorites_timeline' => (
	is => 'rw',
	isa => 'ArrayRef',
	default => sub { [ ] },
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

has 'search_results_ts' => (
	is => 'rw',
	isa => 'Int',
	default => 0,
);

has 'user_timeline_ts' => (
	is => 'rw',
	isa => 'Int',
	default => 0,
);

has 'favorites_timeline_ts' => (
	is => 'rw',
	isa => 'Int',
	default => 0,
);

has 'all_messages' => (
	is => 'rw',
	isa => 'HashRef',
	default => sub { { } },
);

has 'all_dms' => (
	is => 'rw',
	isa => 'HashRef',
	default => sub { { } },
);

has 'searchphrase' => (
	is => 'rw',
	isa => 'Str',
);

has 'user_name' => (
	is => 'rw',
	isa => 'Str',
);

has 'config' => (
	is => 'rw',
	isa => 'BaconBird::Config',
);

has 'rt_by_me_timeline' => (
	is => 'rw',
	isa => 'ArrayRef',
);

has 'rt_by_me_timeline_ts' => (
	is => 'rw',
	isa => 'Int',
	default => 0,
);

has 'rt_of_me_timeline' => (
	is => 'rw',
	isa => 'ArrayRef',
	default => sub { [ ] },
);

has 'rt_of_me_timeline_ts' => (
	is => 'rw',
	isa => 'Int',
	default => 0,
);

has 'my_timeline' => (
	is => 'rw',
	isa => 'ArrayRef',
	default => sub { [ ] },
);

has 'my_timeline_ts' => (
	is => 'rw',
	isa => 'Int',
	default => 0,
);

has 'friends' => (
	is => 'rw',
	isa => 'ArrayRef',
	default => sub { [ ] },
);

has 'followers' => (
	is => 'rw',
	isa => 'ArrayRef',
	default => sub { [ ] },
);

has 'all_users' => (
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
	} elsif ($tl == SEARCH_RESULTS) {
		$self->reload_search_results;
	} elsif ($tl == USER_TIMELINE) {
		$self->reload_user_timeline;
	} elsif ($tl == FAVORITES_TIMELINE) {
		$self->reload_favorites_timeline;
	} elsif ($tl == RT_BY_ME_TIMELINE) {
		$self->reload_rt_by_me_timeline;
	} elsif ($tl == RT_OF_ME_TIMELINE) {
		$self->reload_rt_of_me_timeline;
	} elsif ($tl == MY_TIMELINE) {
		$self->reload_my_timeline;
	}
}

sub reload_home_timeline {
	my $self = shift;
	my $id = -1;
	my $count = $self->config->get_value("count");

	if (defined($self->home_timeline) && scalar(@{$self->home_timeline}) > 0) {
		$id = $self->home_timeline->[0]->{id};
	}

	eval {
		my $newdata = $self->nt->home_timeline({ since_id => $id, count => $count });
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

sub reload_my_timeline {
	my $self = shift;
	my $id = -1;
	my $count = $self->config->get_value("count");

	if (defined($self->my_timeline) && scalar(@{$self->my_timeline}) > 0) {
		$id = $self->my_timeline->[0]->{id};
	}

	eval {
		my $newdata = $self->nt->user_timeline({ since_id => $id, count => $count });
		my $olddata = $self->my_timeline || [];
		my @new_timeline = ( @$newdata, @$olddata );

		$self->add_new_messages($newdata);

		$self->my_timeline(\@new_timeline);
	};
	if (my $err = $@) {
		die "Reloading my timeline failed: " . $err->error . "\n";
	}
	$self->my_timeline_ts(time);
}

sub reload_mentions {
	my $self = shift;
	my $id = -1;
	my $count = $self->config->get_value("count");

	if (defined($self->mentions) && scalar(@{$self->mentions}) > 0) {
		$id = $self->mentions->[0]->{id};
	}

	eval {
		my $newdata = $self->nt->mentions({ since_id => $id, count => $count });
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
	my $count = $self->config->get_value("count");

	if (defined($self->direct_messages) && scalar(@{$self->direct_messages}) > 0) {
		$id = $self->direct_messages->[0]->{id};
	}

	eval {
		my $newdata = $self->nt->direct_messages({ since_id => $id, count => $count });
		my $olddata = $self->direct_messages;
		my @new_dms = ( @$newdata, @$olddata );

		$self->add_new_dms($newdata);

		$self->direct_messages(\@new_dms);
	};
	if (my $err = $@) {
		die "Reloading direct messages failed: " . $err->error . "\n";
	}
	$self->direct_messages_ts(time);
}

sub reload_user_timeline {
	my $self = shift;
	my $id = -1;
	my $count = $self->config->get_value("count");

	if (defined($self->user_timeline) && scalar(@{$self->user_timeline}) > 0) {
		$id = $self->user_timeline->[0]->{id};
	}

	eval {
		my $newdata = $self->nt->user_timeline({ since_id => $id, screen_name => $self->user_name, count => $count });
		my $olddata = $self->user_timeline;
		my @new_usertl = ( @$newdata, @$olddata );

		$self->add_new_messages($newdata);

		$self->user_timeline(\@new_usertl);
	};
	if (my $err = $@) {
		die "Reloading user timeline failed: " . $err->error . "\n";
	}
	$self->user_timeline_ts(time);
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
	my $waittime = int((($self->nt->rate_reset - time) / $self->nt->rate_remaining) * 1.5);
	$waittime = MIN_WAIT_TIME if $waittime < MIN_WAIT_TIME;
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
	my $old_timeline = $self->current_timeline;
	$self->current_timeline($timeline);
	if ($timeline == HOME_TIMELINE) {
		$self->reload_home_timeline if ($self->home_timeline_ts + DEFAULT_WAIT_TIME) < time;
	} elsif ($timeline == DIRECT_MESSAGES) {
		$self->reload_direct_messages if ($self->direct_messages_ts + DEFAULT_WAIT_TIME) < time;
	} elsif ($timeline == MENTIONS) {
		$self->reload_mentions if ($self->mentions_ts + DEFAULT_WAIT_TIME) < time;
	} elsif ($timeline == SEARCH_RESULTS) {
		if ($self->searchphrase && length($self->searchphrase) > 0) {
			$self->reload_search_results if ($self->search_results_ts + DEFAULT_WAIT_TIME) < time;
		} else {
			$self->current_timeline($old_timeline);
		}
	} elsif ($timeline == USER_TIMELINE) {
		if ($self->user_name && length($self->user_name) > 0) {
			$self->reload_user_timeline if ($self->user_timeline_ts + DEFAULT_WAIT_TIME) < time;
		} else {
			$self->current_timeline($old_timeline);
		}
	} elsif ($timeline == FAVORITES_TIMELINE) {
		$self->reload_favorites_timeline if ($self->favorites_timeline_ts + DEFAULT_WAIT_TIME) < time;
	} elsif ($timeline == RT_BY_ME_TIMELINE) {
		$self->reload_rt_by_me_timeline if ($self->rt_by_me_timeline_ts + DEFAULT_WAIT_TIME) < time;
	} elsif ($timeline == RT_OF_ME_TIMELINE) {
		$self->reload_rt_of_me_timeline if ($self->rt_of_me_timeline_ts + DEFAULT_WAIT_TIME) < time;
	} elsif ($timeline == MY_TIMELINE) {
		$self->reload_my_timeline if ($self->my_timeline_ts + DEFAULT_WAIT_TIME) < time;
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
	} elsif ($self->current_timeline == SEARCH_RESULTS) {
		return $self->search_results;
	} elsif ($self->current_timeline == USER_TIMELINE) {
		return $self->user_timeline;
	} elsif ($self->current_timeline == FAVORITES_TIMELINE) {
		return $self->favorites_timeline;
	} elsif ($self->current_timeline == RT_BY_ME_TIMELINE) {
		return $self->rt_by_me_timeline;
	} elsif ($self->current_timeline == RT_OF_ME_TIMELINE) {
		return $self->rt_of_me_timeline;
	} elsif ($self->current_timeline == MY_TIMELINE) {
		return $self->my_timeline;
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

sub add_new_dms {
	my $self = shift;
	my ($msgs) = @_;

	foreach my $dm (@$msgs) {
		$self->all_dms->{$dm->{id}} = $dm;
	}
}

sub get_message_by_id {
	my $self = shift;
	my ($id) = @_;
	return $self->all_messages->{$id} if $id;
	return undef;
}

sub get_dm_by_id {
	my $self = shift;
	my ($id) = @_;
	return $self->all_dms->{$id};
}

sub is_direct_message {
	my $self = shift;
	return $self->current_timeline == DIRECT_MESSAGES;
}

sub send_dm {
	my $self = shift;
	my ($tweet, $rcpt) = @_;
	$self->nt->new_direct_message($rcpt, $tweet);
}

sub reload_search_results {
	my $self = shift;
	my $id = -1;
	my $count = $self->config->get_value("count");

	if (defined($self->search_results) && scalar(@{$self->search_results}) > 0) {
		$id = $self->search_results->[0]->{id};
	}

	eval {
		my $newdata = $self->nt->search({ since_id => $id, q => $self->searchphrase, count => $count })->{results};
		my $olddata = $self->search_results;
		my @new_search_results = ( @$newdata, @$olddata );

		$self->add_new_messages($newdata);

		$self->search_results(\@new_search_results);
	};
	if (my $err = $@) {
		die "Reloading search results failed: " . $err->error . "\n";
	}
	$self->search_results_ts(time);
}

sub set_search_phrase {
	my $self = shift;
	my ($searchphrase) = @_;
	if (!defined($self->searchphrase) || $searchphrase ne $self->searchphrase) {
		$self->searchphrase($searchphrase);
		$self->search_results([ ]);
		$self->search_results_ts(0);
	}
}

sub get_search_phrase {
	my $self = shift;
	return $self->searchphrase;
}

sub set_user_name {
	my $self = shift;
	my ($user_name) = @_;
	if (!defined($self->user_name) || $user_name ne $self->user_name) {
		$self->user_name($user_name);
		$self->user_timeline([ ]);
		$self->user_timeline_ts(0);
	}
}

sub get_user_name {
	my $self = shift;
	return $self->user_name;
}

sub toggle_favorite {
	my $self = shift;
	my ($tweetid) = @_;
	if ($self->is_direct_message) {
		die "you can't favorite a direct message.\n";
	} else {
		my $tweet = $self->get_message_by_id($tweetid);
		if (defined($tweet)) {
			if ($tweet->{favorited}) {
				$self->nt->destroy_favorite($tweetid);
				$tweet->{favorited} = JSON::XS::false;
			} else {
				$self->nt->create_favorite($tweetid);
				$tweet->{favorited} = JSON::XS::true;
			}
		}
	}
}

sub follow_user {
	my $self = shift;
	my ($screen_name) = @_;
	$self->nt->create_friend({ screen_name => $screen_name });
}

sub unfollow_user {
	my $self = shift;
	my ($screen_name) = @_;
	$self->nt->destroy_friend({ screen_name => $screen_name });
}

sub reload_favorites_timeline {
	my $self = shift;

	eval {
		my @favorites;
		for (my $page = 1; ; ++$page) {
			my $r = $self->nt->favorites({ page => $page });
			last unless @$r;

			push @favorites, @$r;
		}

		$self->add_new_messages(\@favorites);
		$self->favorites_timeline(\@favorites);
	};
	if (my $err = $@) {
		die "Reloading favorites timeline failed: " . $err->error . "\n";
	}
	$self->favorites_timeline_ts(time);
}

sub reload_rt_by_me_timeline {
	my $self = shift;
	my $id = -1;
	my $count = $self->config->get_value("count");

	if (defined($self->rt_by_me_timeline) && scalar(@{$self->rt_by_me_timeline}) > 0) {
		$id = $self->rt_by_me_timeline->[0]->{id};
	}

	eval {
		my $newdata = $self->nt->retweeted_by_me({ since_id => $id, count => $count });
		my $olddata = $self->rt_by_me_timeline;
		$newdata ||= [ ];
		$olddata ||= [ ];
		my @new_timeline = ( @$newdata, @$olddata );

		$self->add_new_messages($newdata);
		$self->rt_by_me_timeline(\@new_timeline);
	};
	if (my $err = $@) {
		die "Reloading retweeted-by-me timeline failed: " . $err->error . "\n";
	}
	$self->rt_by_me_timeline_ts(time);
}

sub reload_rt_of_me_timeline {
	my $self = shift;
	my $id = -1;
	my $count = $self->config->get_value("count");

	if (defined($self->rt_of_me_timeline) && scalar(@{$self->rt_of_me_timeline}) > 0) {
		$id = $self->rt_of_me_timeline->[0]->{id};
	}

	eval {
		my $newdata = $self->nt->retweets_of_me({ since_id => $id, count => $count });
		my $olddata = $self->rt_of_me_timeline;
		#print STDERR Dumper($newdata);
		$newdata ||= [ ];
		$olddata ||= [ ];

		$self->fetch_retweet_info($newdata);

		my @new_timeline = ( @$newdata, @$olddata );

		$self->add_new_messages($newdata);
		$self->rt_of_me_timeline(\@new_timeline);
	};
	if (my $err = $@) {
		die "Reloading retweets-of-me timeline failed. " . $err->error . "\n";
	}
	$self->rt_of_me_timeline_ts(time);
}

sub fetch_retweet_info {
	my $self = shift;
	my ($newdata) = @_;

	foreach my $tw (@$newdata) {
		if ($tw->{retweet_count} ne '0') {
			$tw->{retweeted_by} = $self->nt->retweeted_by($tw->{id});
			#print STDERR Dumper($tw);
		}
	}
}

sub create_saved_search {
	my $self = shift;
	my $searchphrase = $self->get_search_phrase;
	if (defined($searchphrase) && $searchphrase ne "") {
		$self->nt->create_saved_search({ query => $searchphrase });
	}
}

sub saved_searches {
	my $self = shift;
	my $saved_searches = $self->nt->saved_searches;
	return $saved_searches;
}

sub destroy_saved_search {
	my $self = shift;
	my ($searchid) = @_;
	$self->nt->destroy_saved_search({ id => $searchid });
}

sub get_query_from_saved_search_id {
	my $self = shift;
	my ($searchid) = @_;
	my $query = '';

	eval {
		my $newdata = $self->nt->show_saved_search({ id => $searchid });
		$query = $newdata->query;
	};
	if (my $err = $@) {
		die "Reloading saved search failed. " . $err . "\n";
	}

	return $query;
}

sub remove_tweet {
	my $self = shift;
	my ($tweetid) = @_;

	# Remove from all messages
	delete $self->all_messages->{$tweetid};

	# Remove from timelines
	for (my $i = 0; $i < scalar @{$self->home_timeline}; $i++) {
		my $tweet = $self->home_timeline->[$i];
		if ($tweetid == $tweet->id) {
			splice @{$self->home_timeline}, $i, 1;
			last;
		}
	}

	if ($self->my_timeline and @{$self->my_timeline}) {
		for (my $i = 0; $i < scalar @{$self->my_timeline}; $i++) {
			my $tweet = $self->my_timeline->[$i];
			if ($tweetid == $tweet->id) {
				splice @{$self->my_timeline}, $i, 1;
				last;
			}
		}
	}
}

sub remove_direct_message {
	my $self = shift;
	my ($tweetid) = @_;

	# Remove from all messages
	delete $self->all_dms->{$tweetid};

	# Remove from timelines
	if ($self->direct_messages and @{$self->direct_messages}) {
		for (my $i = 0; $i < scalar @{$self->direct_messages}; $i++) {
			my $tweet = $self->direct_messages->[$i];
			if ($tweetid == $tweet->id) {
				splice @{$self->direct_messages}, $i, 1;
				last;
			}
		}
	}
}

sub destroy_status {
	my $self = shift;
	my ($tweetid) = @_;

	eval {
		$self->nt->destroy_status({ id => $tweetid });
		$self->remove_tweet($tweetid);

		$self->reload_home_timeline;
		$self->reload_my_timeline;
	};
	if (my $err = $@) {
		return 1;
	}
}

sub destroy_direct_message {
	my $self = shift;
	my ($dmid) = @_;

	eval {
		$self->nt->destroy_direct_message({ id => $dmid });
		$self->remove_direct_message($dmid);

		$self->reload_direct_messages;
	};
	if (my $err = $@) {
		return 1;
	}
}

sub list_friends {
	my $self = shift;
	my (%args) = @_;

	my @friends;
	for ( my $cursor = -1, my $r; $cursor; $cursor = $r->{next_cursor} ) {
		$r = $self->nt->friends({ cursor => $cursor });
		$self->add_new_users($r->{users});
		push @friends, @{ $r->{users} };
	}

	return \@friends;
}

sub list_followers {
	my $self = shift;
	my (%args) = @_;

	my @followers;
	for ( my $cursor = -1, my $r; $cursor; $cursor = $r->{next_cursor} ) {
		$r = $self->nt->followers({ cursor => $cursor });
		$self->add_new_users($r->{users});
		push @followers, @{ $r->{users} };
	}

	return \@followers;
}

sub add_new_users {
	my $self = shift;
	my ($users) = @_;

	foreach my $u (@$users) {
		$self->all_users->{$u->{id}} = $u;
	}
}

sub get_user_by_id {
	my $self = shift;
	my ($id) = @_;
	return $self->all_users->{$id} if $id;
	return undef;
}

no Moose;
1;
