package BaconBird::Controller;
use Moose;

use IO::Handle;

has 'model' => (
	is => 'rw',
	isa => 'BaconBird::Model',
	handles => [qw(login lookup_author get_timeline select_timeline 
				get_message_by_id get_dm_by_id is_direct_message send_dm 
				set_search_phrase get_search_phrase set_user_name 
				get_user_name toggle_favorite follow_user unfollow_user 
				create_saved_search saved_searches destroy_saved_search 
				get_query_from_saved_search_id destroy_direct_message 
				destroy_status reset_followers reset_friends)
			],
);

has 'view' => (
	is => 'rw',
	isa => 'BaconBird::View',
);

has 'shortener' => (
	is => 'rw',
	isa => 'BaconBird::Shortener',
	handles => {
		shorten => 'shorten_text',
	},
);

has 'keymap' => (
	is => 'rw',
	isa => 'BaconBird::KeyMap',
	handles => [qw(key get_help_desc)],
);

has 'pinfile' => (
	is => 'rw',
	isa => 'Str',
);

has 'configdir' => (
	is => 'rw',
	isa => 'Str',
	default => $ENV{'HOME'} . "/.baconbird",
);

has 'quit' => (
	is => 'rw',
	isa => 'Bool',
);

has 'config' => (
	is => 'rw',
	isa => 'BaconBird::Config',
);

sub BUILD {
	my $self = shift;
	mkdir($self->configdir, 0755);
	$self->pinfile($self->configdir . "/authcode");
}

sub run {
	my $self = shift;
	my $ts = time + $self->model->get_wait_time;

	eval {
		$self->login;
	};
	if (my $err = $@) {
		die "Error: authorization failed.\nAre you sure you provided the correct authentication information?\n";
	}

	$self->view->set_rate_limit($self->model->get_rate_limit);
	$self->reload_all;

	$self->view->prepare;

	while (!$self->quit) {
		eval {
			$self->view->set_rate_limit($self->model->get_rate_limit);
			$self->view->next_event();

			if (time >= $ts && !$self->quit) {
				$self->reload_all_and_update_view;
				$ts = time + $self->model->get_wait_time;
			}
		};
		if (my $err = $@) {
			$self->view->status_msg("Error: $err");
		}
	}
}

sub status_msg {
	my $self = shift;
	my ($msg) = @_;
	$self->view->status_msg($msg);
}

sub reload_all {
	my $self = shift;
	$self->status_msg("Loading...");
	$self->reload_all_and_update_view;
	$self->status_msg("");
}

sub reload_all_and_update_view {
	my $self = shift;
	$self->model->reload_all;
	$self->view->get_timeline(1);
}

sub load_tokens {
	my $self = shift;
	open(my $fh, "<", $self->pinfile) or return (undef, undef);
	my $access_token = <$fh>;
	chomp($access_token);
	my $access_token_secret = <$fh>;
	chomp($access_token_secret);
	close($fh);
	return ($access_token, $access_token_secret);
}

sub save_tokens {
	my $self = shift;
	my ($access_token, $access_token_secret) = @_;
	open(my $fh,">",$self->pinfile) or die "Error: couldn't open $self->pinfile: $!\n";
	print $fh "$access_token\n$access_token_secret\n";
	close($fh);
}

sub get_pin {
	my $self = shift;
	my ($auth_url) = @_;

	print "Please authorize this app at ", $auth_url, " and enter the PIN: ";
	STDOUT->flush;
	my $pin = <STDIN>;
	chomp($pin);
	return $pin;
}

sub post_update {
	my $self = shift;
	my ($tweet, $in_reply_to_status_id) = @_;
	$self->model->post_update($tweet, $in_reply_to_status_id);
	$self->reload_all_and_update_view;
}

sub retweet {
	my $self = shift;
	my ($tweetid) = @_;
	$self->model->retweet($tweetid);
	$self->reload_all_and_update_view;
}

sub friends {
	my $self = shift;
	my (%args) = @_;
	return $self->model->list_friends(%args);
}

sub followers {
	my $self = shift;
	my (%args) = @_;
	return $self->model->list_followers(%args);
}

sub get_user_by_id {
	my $self = shift;
	my ($id) = @_;
	return $self->model->get_user_by_id($id);
}

no Moose;
1;
