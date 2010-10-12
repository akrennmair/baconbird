package BaconBird::KeyMap;
use Moose;

use Data::Dumper;

use constant KEY_QUIT => 0;
use constant KEY_SEND => 1;
use constant KEY_RETWEET => 2;
use constant KEY_REPLY => 3;
use constant KEY_PUBLICREPLY => 4;
use constant KEY_SHORTEN => 5;
use constant KEY_HOME_TIMELINE => 6;
use constant KEY_MENTIONS => 7;
use constant KEY_DIRECT_MESSAGES => 8;
use constant KEY_SEARCH_RESULTS => 9;
use constant KEY_USER_TIMELINE => 10;
use constant KEY_SEARCH => 11;
use constant KEY_SHOW_USER => 12;
use constant KEY_TOGGLE_FAVORITE => 13;
use constant KEY_CANCEL => 14;
use constant KEY_ENTER => 15;

has 'keymap' => (
	is => 'rw',
	isa => 'HashRef',
);

sub BUILD {
	my $self = shift;
	$self->keymap({
		BaconBird::KeyMap::KEY_QUIT => "q",
		BaconBird::KeyMap::KEY_SEND => "ENTER",
		BaconBird::KeyMap::KEY_RETWEET => "^R",
		BaconBird::KeyMap::KEY_REPLY => "r",
		BaconBird::KeyMap::KEY_PUBLICREPLY => "R",
		BaconBird::KeyMap::KEY_SHORTEN => "O",
		BaconBird::KeyMap::KEY_HOME_TIMELINE => "1",
		BaconBird::KeyMap::KEY_MENTIONS => "2",
		BaconBird::KeyMap::KEY_DIRECT_MESSAGES => "3",
		BaconBird::KeyMap::KEY_SEARCH_RESULTS => "4",
		BaconBird::KeyMap::KEY_USER_TIMELINE => "5",
		BaconBird::KeyMap::KEY_SEARCH => "/",
		BaconBird::KeyMap::KEY_SHOW_USER => "u",
		BaconBird::KeyMap::KEY_TOGGLE_FAVORITE => "F",
		BaconBird::KeyMap::KEY_CANCEL => "ESC", # TODO: prevent that this can be redefined.
		BaconBird::KeyMap::KEY_ENTER => "ENTER", # TODO: same here
	});
}

sub key {
	my $self = shift;
	my ($op) = @_;
	return $self->keymap->{$op};
}

sub unbind_key {
	my $self = shift;
	my ($op) = @_;
	$self->keymap->{$op} = undef;
}

sub bind_key {
	my $self = shift;
	my ($op, $key) = @_;
	$self->keymap->{$op} = $key;
}

no Moose;
1;
