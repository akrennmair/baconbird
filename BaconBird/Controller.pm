package BaconBird::Controller;
use Moose;

has 'model' => (
	is => 'rw',
	isa => 'BaconBird::Model',
);

has 'view' => (
	is => 'rw',
	isa => 'BaconBird::View',
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


sub BUILD {
	my $self = shift;
	mkdir($self->configdir, 0755);
	$self->pinfile($self->configdir . "/authcode");
}

sub run {
	my $self = shift;
	my $ts = time + $self->model->get_wait_time;

	$self->view->set_rate_limit($self->model->get_rate_limit);
	$self->reload_all;

	while (!$self->quit) {
		$self->view->set_rate_limit($self->model->get_rate_limit);

		eval {
			$self->view->next_event();
		};
		if (my $err = $@) {
			die $@ unless blessed($err) && $err->isa("Net::Twitter::Error");
			$self->view->status_msg("Error: " . $err->error);
		}

		
		if (time >= $ts) {
			$self->reload_all_and_update_view;
			$ts = time + $self->model->get_wait_time;
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
	$self->model->reload_home_timeline;
	$self->model->reload_mentions;
	$self->view->get_timeline;
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

	print "Authorize this app at ", $auth_url, " and enter the PIN#\n";
	my $pin = <STDIN>;
	chomp($pin);
	return $pin;
}

sub login {
	my $self = shift;
	$self->model->login;
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

sub lookup_author {
	my $self = shift;
	my ($tweetid) = @_;
	return $self->model->lookup_author($tweetid);
}

sub get_timeline {
	my $self = shift;
	return $self->model->get_timeline;
}

sub select_timeline {
	my $self = shift;
	my ($timeline) = @_;
	$self->model->select_timeline($timeline);
}

no Moose;
1;
