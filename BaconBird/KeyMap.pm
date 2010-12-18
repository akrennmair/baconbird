package BaconBird::KeyMap;
use Moose;

use Data::Dumper;

use constant KEY_QUIT            => 0;
use constant KEY_SEND            => 1;
use constant KEY_RETWEET         => 2;
use constant KEY_REPLY           => 3;
use constant KEY_PUBLICREPLY     => 4;
use constant KEY_SHORTEN         => 5;
use constant KEY_HOME_TIMELINE   => 6;
use constant KEY_MENTIONS        => 7;
use constant KEY_DIRECT_MESSAGES => 8;
use constant KEY_SEARCH_RESULTS  => 9;
use constant KEY_USER_TIMELINE   => 10;
use constant KEY_SEARCH          => 11;
use constant KEY_SHOW_USER       => 12;
use constant KEY_TOGGLE_FAVORITE => 13;
use constant KEY_CANCEL          => 14;
use constant KEY_ENTER           => 15;
use constant KEY_HELP            => 16;
use constant KEY_FOLLOW          => 17;
use constant KEY_UNFOLLOW        => 18;
use constant KEY_FOLLOW_USER     => 19;
use constant KEY_VIEW            => 20;
use constant KEY_REDRAW          => 21;
use constant KEY_OPEN_URL        => 22;
use constant KEY_FAVORITES       => 23;
use constant KEY_RT_BY_ME        => 24;
use constant KEY_RT_OF_ME        => 25;
use constant KEY_MY_TIMELINE     => 26;
use constant KEY_ENTER_USER      => 27;
use constant KEY_ENTER_HIGHLIGHT => 28;
use constant KEY_ENTER_HIDE      => 29;
use constant KEY_SAVE_SEARCH     => 30;
use constant KEY_LOAD_SEARCH     => 31;
use constant KEY_DELETE_ITEM     => 32;

has 'keymap' => (
	is => 'rw',
	isa => 'HashRef',
);

has 'config' => (
	is => 'rw',
	isa => 'BaconBird::Config',
);

sub BUILD {
	my $self = shift;
	$self->keymap({
		BaconBird::KeyMap::KEY_QUIT              => { key => "q",     desc => "Quit baconbird" },
		BaconBird::KeyMap::KEY_SEND              => { key => "ENTER", desc => "Send new tweet or direct message" },
		BaconBird::KeyMap::KEY_RETWEET           => { key => "^R",    desc => "Retweet currently selected tweet" },
		BaconBird::KeyMap::KEY_REPLY             => { key => "r",     desc => "Reply to currently selected tweet" },
		BaconBird::KeyMap::KEY_PUBLICREPLY       => { key => "R",     desc => "Publicly reply to currently selected tweet" },
		BaconBird::KeyMap::KEY_SHORTEN           => { key => "^O",    desc => "Shorten all URLs in the current input field" },
		BaconBird::KeyMap::KEY_HOME_TIMELINE     => { key => "1",     desc => "Go to home timeline" },
		BaconBird::KeyMap::KEY_MENTIONS          => { key => "2",     desc => "Go to mentions" },
		BaconBird::KeyMap::KEY_DIRECT_MESSAGES   => { key => "3",     desc => "Go to direct messages" },
		BaconBird::KeyMap::KEY_SEARCH_RESULTS    => { key => "4",     desc => "Go to search results (if search function was used before)" },
		BaconBird::KeyMap::KEY_USER_TIMELINE     => { key => "5",     desc => "Go to user timeline (if show user function was used before)" },
		BaconBird::KeyMap::KEY_SEARCH            => { key => "/",     desc => "Start new search" },
		BaconBird::KeyMap::KEY_SHOW_USER         => { key => "u",     desc => "Show timeline of currently selected tweet's author" },
		BaconBird::KeyMap::KEY_TOGGLE_FAVORITE   => { key => "^F",    desc => "Toggle favorite flag of currently selected tweet" },
		BaconBird::KeyMap::KEY_HELP              => { key => '?',     desc => "Show help" },
		BaconBird::KeyMap::KEY_FOLLOW            => { key => 'F',     desc => 'Follow author of currently selected tweet' },
		BaconBird::KeyMap::KEY_UNFOLLOW          => { key => 'U',     desc => 'Unfollow author of currently selected tweet' },
		BaconBird::KeyMap::KEY_FOLLOW_USER       => { key => 'f',     desc => 'Follow a user. You will be asked for the user name.' },
		BaconBird::KeyMap::KEY_VIEW              => { key => 'v',     desc => 'Toggle detail view of current tweet.' },
		BaconBird::KeyMap::KEY_REDRAW            => { key => '^L',    desc => 'Redraw screen.' },
		BaconBird::KeyMap::KEY_OPEN_URL          => { key => 'o',     desc => 'Open URL in default browser.' },
		BaconBird::KeyMap::KEY_FAVORITES         => { key => 'V',     desc => 'Show favorite tweets.' },
		BaconBird::KeyMap::KEY_RT_BY_ME          => { key => '6',     desc => 'Show tweets retweeted by me.' },
		BaconBird::KeyMap::KEY_RT_OF_ME          => { key => '7',     desc => 'Show my tweets that were retweeted.' },
		BaconBird::KeyMap::KEY_MY_TIMELINE       => { key => '8',     desc => 'Show my tweets.' },
		BaconBird::KeyMap::KEY_ENTER_USER        => { key => 'l',     desc => 'Go to a given user timeline.' },
		BaconBird::KeyMap::KEY_ENTER_HIGHLIGHT   => { key => 'h',     desc => 'Enter an expression to highlight. Enter it again to un-highlight.' },
		BaconBird::KeyMap::KEY_ENTER_HIDE        => { key => 'e',     desc => 'Enter an expression to hide. Enter it again to show.' },
		BaconBird::KeyMap::KEY_SAVE_SEARCH       => { key => 's',     desc => 'Save current sought for expression' },
		BaconBird::KeyMap::KEY_LOAD_SEARCH       => { key => 'S',     desc => 'Load saved search.' },
		BaconBird::KeyMap::KEY_DELETE_ITEM       => { key => 'd',     desc => 'Delete item.' },
		BaconBird::KeyMap::KEY_CANCEL            => { key => "ESC",   internal => 1 },
		BaconBird::KeyMap::KEY_ENTER             => { key => "ENTER", internal => 1 },
	});
}

sub key {
	my $self = shift;
	my ($op) = @_;
	return $self->keymap->{$op}->{key};
}

sub unbind_key {
	my $self = shift;
	my ($op) = @_;
	$self->keymap->{$op}->{key} = undef;
}

sub bind_key {
	my $self = shift;
	my ($op, $key) = @_;
	$self->keymap->{$op}->{key} = $key;
}

sub get_help_desc {
	my $self = shift;
	my @descs;

	foreach my $v (values %{$self->keymap}) {
		push(@descs, $v) unless $v->{internal};
	}
	@descs = sort { $a->{key} cmp $b->{key} } @descs;
	return \@descs;
}

no Moose;
1;
