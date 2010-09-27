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

use constant DEFAULT_WAIT_TIME => 60;

sub BUILD {
	my $self = shift;
	mkdir($self->configdir, 0755);
	$self->pinfile($self->configdir . "/authcode");
}

sub run {
	my $self = shift;
	my $ts = time + DEFAULT_WAIT_TIME; #$self->model->get_wait_time;

	$self->view->set_rate_limit($self->model->get_rate_limit);
	$self->reload_home_timeline;

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
			$self->model->reload_home_timeline;
			$self->view->set_timeline($self->model->home_timeline());
			$ts = time + DEFAULT_WAIT_TIME; #$self->model->get_wait_time;
		}
	}
}

sub status_msg {
	my $self = shift;
	my ($msg) = @_;
	$self->view->status_msg($msg);
}

sub reload_home_timeline {
	my $self = shift;
	$self->status_msg("Loading home timeline...");
	$self->model->reload_home_timeline;
	$self->view->set_timeline($self->model->home_timeline());
	$self->status_msg("");
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
	my ($tweet) = @_;
	$self->model->post_update($tweet);
	$self->model->reload_home_timeline;
	$self->view->set_timeline($self->model->home_timeline());
}

sub retweet {
	my $self = shift;
	my ($tweetid) = @_;
	$self->model->retweet($tweetid);
	$self->model->reload_home_timeline;
	$self->view->set_timeline($self->model->home_timeline());
}

no Moose;
1;
