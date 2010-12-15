package BaconBird::Config;
use Moose;

use Config::General;

has 'configfile' => (
	is => 'rw',
	isa => 'Str',
	default => $ENV{'HOME'} . "/.baconbird/config",
);

sub load {
	# TODO: implement
}

no Moose;
1;
