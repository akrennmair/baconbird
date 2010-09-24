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
	default => $ENV{'HOME'} . "/.baconbird/authcode",
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
}

sub run {
	my $self = shift;

	$self->reload_home_timeline;

	while (!$self->quit) {
		$self->view->next_event();
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
	# TODO: implement
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


no Moose;
1;
