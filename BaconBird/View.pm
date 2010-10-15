package BaconBird::View;
use Moose;

use stfl;
use HTML::Strip;

use BaconBird::KeyMap;

use constant PROGRAM_VERSION => "0.2";
use constant TWITTER_MAX_LEN => 140;

use constant HELP_TIMELINE => [
	{ key => BaconBird::KeyMap::KEY_QUIT, desc => "Quit" },
	{ key => BaconBird::KeyMap::KEY_HELP, desc => "Help" },
	{ key => BaconBird::KeyMap::KEY_SEND, desc => "New Tweet" },
	{ key => BaconBird::KeyMap::KEY_RETWEET, desc => "Retweet" },
	{ key => BaconBird::KeyMap::KEY_REPLY, desc => "Reply" },
	{ key => BaconBird::KeyMap::KEY_PUBLICREPLY, desc => "Public Reply" },
	{ key => BaconBird::KeyMap::KEY_SEARCH, desc => "Search" },
	{ key => BaconBird::KeyMap::KEY_SHOW_USER, desc => "User" },
	{ key => BaconBird::KeyMap::KEY_TOGGLE_FAVORITE, desc => "Favorite" },
	{ key => BaconBird::KeyMap::KEY_HOME_TIMELINE, desc => "Home Timeline "},
	{ key => BaconBird::KeyMap::KEY_MENTIONS, desc => "Mentions" },
	{ key => BaconBird::KeyMap::KEY_DIRECT_MESSAGES, desc => "Direct Messages" },
	{ key => BaconBird::KeyMap::KEY_SEARCH_RESULTS, desc => "Search Results" },
	{ key => BaconBird::KeyMap::KEY_USER_TIMELINE, desc => "User Timeline" },
];


use constant HELP_DM => [
	{ key => BaconBird::KeyMap::KEY_QUIT, desc => "Quit" },
	{ key => BaconBird::KeyMap::KEY_HELP, desc => "Help" },
	{ key => BaconBird::KeyMap::KEY_SEND, desc => "New DM" },
	{ key => BaconBird::KeyMap::KEY_REPLY, desc => "Reply" },
	{ key => BaconBird::KeyMap::KEY_SEARCH, desc => "Search" },
	{ key => BaconBird::KeyMap::KEY_SHOW_USER, desc => "User" },
	{ key => BaconBird::KeyMap::KEY_HOME_TIMELINE, desc => "Home Timeline "},
	{ key => BaconBird::KeyMap::KEY_MENTIONS, desc => "Mentions" },
	{ key => BaconBird::KeyMap::KEY_DIRECT_MESSAGES, desc => "Direct Messages" },
	{ key => BaconBird::KeyMap::KEY_SEARCH_RESULTS, desc => "Search Results" },
	{ key => BaconBird::KeyMap::KEY_USER_TIMELINE, desc => "User Timeline" },
];

use constant HELP_TWEET => [
	{ key => BaconBird::KeyMap::KEY_CANCEL, desc => "Cancel" },
	{ key => BaconBird::KeyMap::KEY_ENTER, desc => "Send" },
	{ key => BaconBird::KeyMap::KEY_SHORTEN, desc => "Shorten URLs" },
];

use constant HELP_USERNAME => [
	{ key => BaconBird::KeyMap::KEY_CANCEL, desc => "Cancel" },
	{ key => BaconBird::KeyMap::KEY_ENTER, desc => "Confirm" },
];

use constant HELP_HELP => [
	{ key => BaconBird::KeyMap::KEY_QUIT, desc => "Quit Help" },
];

use Data::Dumper;

has 'f' => (
	is => 'rw',
	isa => 'stfl::stfl_form',
);

has 'ctrl' => (
	is => 'rw',
	isa => 'BaconBird::Controller',
);

has 'saved_status_id' => (
	is => 'rw',
);

has 'saved_rcpt' => (
	is => 'rw',
);

has 'allow_shorten' => (
	is => 'rw',
	isa => 'Bool',
	default => 1,
);

has 'is_help' => (
	is => 'rw',
	isa => 'Bool',
	default => 0,
);

has 'timeline' => (
	is => 'rw',
	isa => 'Int',
	default => BaconBird::Model::HOME_TIMELINE,
);

sub BUILD {
	my $self = shift;

	$self->f(stfl::create( <<"EOT" ));
vbox
  hbox
    .expand:0
    \@style_normal:bg=blue,fg=white,attr=bold
    label text[program]:"" .expand:0
    label text[current_view]:"" .expand:h
    label .tie:r text[rateinfo]:"-1/-1" .expand:0
  list[tweets]
    style_focus[listfocus]:fg=yellow,bg=blue,attr=bold
    .expand:vh
    pos_name[tweetid]:
    pos[tweetpos]:0
  vbox
    .expand:0
    .display:1
    label text[infoline]:">> " .expand:h style_normal:bg=blue,fg=yellow,attr=bold
    label text[shorthelp]:"" .expand:h style_normal:bg=blue,fg=white,attr=bold
  hbox[lastline]
    .expand:0
    label text[msg]:"" .expand:h
EOT

	$self->f->set("program", "[baconbird " . PROGRAM_VERSION . "] ");
	$self->set_shorthelp(HELP_TIMELINE);
	$self->set_caption(BaconBird::Model::HOME_TIMELINE);
}

sub next_event {
	my $self = shift;

	my $e = $self->f->run(10000);

	if (!defined($e)) {
		$self->f->run(-1);
		if ($self->f->get_focus eq "tweetinput") {
			$self->set_remaining($self->f->get("inputfield"));
		}
		if ($self->f->get_focus eq "tweets") {
			$self->update_info_line($self->f->get("tweetid"));
		}
		return;
	}

	if ($self->is_help) {
		if ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_QUIT)) {
			$self->close_help;
		}
	} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_QUIT)) {
		$self->ctrl->quit(1);
	} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_SEND)) {
		if ($self->ctrl->is_direct_message) {
			$self->set_shorthelp(HELP_USERNAME);
			$self->allow_shorten(0);
			$self->set_input_field("DM to: ", "", "end-input-rcpt");
		} else {
			$self->set_shorthelp(HELP_TWEET);
			$self->set_input_field("Tweet: ");
		}
	} elsif ($e eq "cancel-input") {
		$self->allow_shorten(1);
		$self->set_lastline;
		if ($self->ctrl->is_direct_message) {
			$self->set_shorthelp(HELP_DM);
		} else {
			$self->set_shorthelp(HELP_TIMELINE);
		}
		$self->saved_status_id(undef);
	} elsif ($e eq "end-input") {
		my $tweet = $self->f->get("inputfield");
		$self->set_lastline;
		if ($self->ctrl->is_direct_message) {
			$self->set_shorthelp(HELP_DM);
			$self->send_dm($tweet);
		} else {
			$self->set_shorthelp(HELP_TIMELINE);
			$self->post_update($tweet);
		}
	} elsif ($e eq "end-input-rcpt") {
		$self->allow_shorten(1);
		my $rcpt = $self->f->get("inputfield");
		$self->set_lastline;
		if ($rcpt ne "") {
			$self->saved_rcpt($rcpt);
			$self->do_reply(0);
		}
	} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_RETWEET)) {
		my $tweetid = $self->f->get("tweetid");
		if (defined($tweetid) && $tweetid ne "") {
			$self->status_msg("Retweeting...");
			$self->ctrl->retweet($tweetid);
			$self->status_msg("Retweeted.");
		}
	} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_REPLY)) {
		$self->do_reply(0);
	} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_PUBLICREPLY)) {
		$self->do_reply(1);
	} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_SHORTEN)) {
		if ($self->f->get_focus eq "tweetinput") {
			$self->shorten;
		}
	} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_HOME_TIMELINE)) {
		$self->load_timeline(BaconBird::Model::HOME_TIMELINE);
	} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_MENTIONS)) {
		$self->load_timeline(BaconBird::Model::MENTIONS);
	} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_DIRECT_MESSAGES)) {
		$self->load_timeline(BaconBird::Model::DIRECT_MESSAGES);
	} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_SEARCH_RESULTS)) {
		my $searchphrase = $self->ctrl->get_search_phrase;
		if (defined($searchphrase) && $searchphrase ne "") {
			$self->load_timeline(BaconBird::Model::SEARCH_RESULTS);
		} else {
			$self->status_msg("No search results to view.");
		}
	} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_USER_TIMELINE)) {
		my $screen_name = $self->ctrl->get_user_name;
		if (defined($screen_name) && $screen_name ne "") {
			$self->load_timeline(BaconBird::Model::USER_TIMELINE);
		} else {
			$self->status_msg("No user timeline to view.");
		}
	} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_SEARCH)) {
		$self->set_input_field("Search: ", "", "end-input-search");
	} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_SHOW_USER)) {
		$self->show_user_timeline;
	} elsif ($e eq "end-input-search") {
		my $searchphrase = $self->f->get("inputfield");
		$self->set_lastline;
		if (defined($searchphrase) && $searchphrase ne "") {
			$self->ctrl->set_search_phrase($searchphrase);
			$self->load_timeline(BaconBird::Model::SEARCH_RESULTS);
		}
	} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_TOGGLE_FAVORITE)) {
		my $tweetid = $self->f->get("tweetid");
		if (defined($tweetid) && $tweetid ne "") {
			$self->ctrl->toggle_favorite($tweetid);
			$self->get_timeline;
		}
	} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_HELP)) {
		$self->show_help;
	} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_FOLLOW)) {
		$self->follow;
	} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_UNFOLLOW)) {
		$self->unfollow;
	} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_FOLLOW_USER)) {
		$self->set_shorthelp(HELP_USERNAME);
		$self->allow_shorten(0);
		$self->set_input_field("User to follow: ", "", "end-input-follow-user");
	} elsif ($e eq "end-input-follow-user") {
		my $screen_name = $self->f->get("inputfield");
		$self->set_lastline;
		if ($self->ctrl->is_direct_message) {
			$self->set_shorthelp(HELP_DM);
		} else {
			$self->set_shorthelp(HELP_TIMELINE);
		}
		if (defined($screen_name) && $screen_name ne "") {
			$self->status_msg("Following $screen_name...");
			$self->ctrl->follow_user($screen_name);
			$self->status_msg("");
		}
	}
}

sub prepare {
	my $self = shift;

	if ($self->f->get_focus eq "tweets") {
		$self->update_info_line($self->f->get("tweetid"));
	}
}

sub status_msg {
	my $self = shift;
	my ($msg) = @_;

	$self->f->set("msg", $msg);
	$self->f->run(-1);
}

sub set_lastline {
	my $self = shift;
	$self->f->modify("lastline", "replace", '{hbox[lastline] .expand:0 {label text[msg]:"" .expand:h}}');
}

sub set_input_field {
	my $self = shift;
	my ($label, $default_text, $end_input_event) = @_;

	$default_text = "" if !defined($default_text);
	$end_input_event = "end-input" if !defined($end_input_event);

	my $pos = length($default_text);

	$self->f->modify("lastline", "replace", '{hbox[lastline] .expand:0 {label .expand:0 text[prompt]:' . stfl::quote($label) . '}{input[tweetinput] on_ESC:cancel-input on_ENTER:' . $end_input_event . ' modal:1 .expand:h text[inputfield]:' . stfl::quote($default_text) . ' pos:' . $pos . '} {label .tie:r .expand:0 text[remaining]:"" style_normal[remaining_style]:fg=white}');

	$self->set_remaining($default_text);

	$self->f->set_focus("tweetinput");
}

sub set_timeline {
	my $self = shift;
	my ($tl) = @_;

	my $list = "{list ";

	foreach my $tweet (@$tl) {
		my $username = $tweet->{user}{screen_name} || $tweet->{sender}{screen_name} || $tweet->{from_user};
		my $text;
		if ($tweet->{favorited}) {
			$text .= "!";
		} else {
			$text .= " ";
		}
		$text .= sprintf("[%16s] %s", "@" . $username, $tweet->{text});
		$text =~ s/[\r\n]+/ /g;
		$list .= "{listitem[" .  $tweet->{id} . "] text:" . stfl::quote($text) . "}";
	}

	$list .= "}";

	$self->f->modify("tweets", "replace_inner", $list);

	$self->f->run(-1);
}

sub set_rate_limit {
	my $self = shift;
	my ($remaining, $limit, $s_rem ) = @_;
	my $m_rem = int($s_rem / 60);
	$self->f->set("rateinfo", "Next reset: $m_rem min $remaining/$limit");
}

sub do_reply {
	my $self = shift;
	my ($is_public) = @_;
	my $is_dm = $self->ctrl->is_direct_message;

	if ($is_dm && $is_public) {
		die "You can't publicly reply to a direct message.";
	}

	$self->set_shorthelp(HELP_TWEET);

	my $tweetid = $self->f->get("tweetid");

	if ($is_dm) {
		my $rcpt = $self->saved_rcpt || $self->ctrl->get_dm_by_id($tweetid)->{sender}{screen_name};
		$self->set_input_field("DM to $rcpt: ");
		$self->saved_rcpt($rcpt);
		$self->saved_status_id($tweetid);
	} elsif (defined($tweetid) && $tweetid ne "") {
		my $public = "";
		$public = "." if $is_public;
		$self->saved_status_id($tweetid);
		my $username = $self->ctrl->lookup_author($tweetid);
		$self->set_input_field("Reply: ", $public . '@' . $username . ' ');
	}
}

sub get_timeline {
	my $self = shift;
	$self->set_timeline($self->ctrl->get_timeline);
	if (defined($self->f->get_focus) && $self->f->get_focus ne "tweetinput") {
		$self->update_info_line($self->f->get("tweetid"));
	}
}

sub select_timeline {
	my $self = shift;
	my ($view) = @_;
	$self->set_caption($view);
	$self->ctrl->select_timeline($view);
}

sub set_caption {
	my $self = shift;
	my ($view) = @_;
	my %caption = ( BaconBird::Model::HOME_TIMELINE => "Home Timeline", 
					BaconBird::Model::MENTIONS => "Mentions", 
					BaconBird::Model::DIRECT_MESSAGES => "Direct Messages",
					BaconBird::Model::SEARCH_RESULTS => "Search Results",
					BaconBird::Model::USER_TIMELINE => "User Timeline",
					BaconBird::Model::HELP => "Help");
	$self->f->set("current_view", $caption{$view} || "BUG! UNKNOWN VIEW!");
}

sub set_remaining {
	my $self = shift;
	my ($text) = @_;
	my $rem_len = TWITTER_MAX_LEN - length($text);
	$self->f->set("remaining", sprintf("| %4d", $rem_len));
	if ($rem_len > 15) {
		$self->f->set("remaining_style", "fg=white,attr=bold");
	} elsif ($rem_len >= 0) {
		$self->f->set("remaining_style", "fg=yellow,attr=bold");
	} else {
		$self->f->set("remaining_style", "fg=red,attr=bold");
	}
}

sub update_info_line {
	my $self = shift;
	my ($tweetid) = @_;

	my $str = ">> ";

	if ($self->ctrl->is_direct_message) {
		my $dm = $self->ctrl->get_dm_by_id($tweetid);

		if ($dm) {
			$str .= "@" . $dm->{sender_screen_name};
			$str .= " (" . $dm->{sender}{name} . ")" if $dm->{sender}{name};
			if ($dm->{sender}{location}) {
				$str .= " - " . $dm->{sender}{location};
			}

			$str .= " | sent " . $dm->relative_created_at;
		}
	} else {
		my $tweet = $self->ctrl->get_message_by_id($tweetid);

		if ($tweet) {
			my $hs = HTML::Strip->new();

			my $screen_name = $tweet->{user}{screen_name} || $tweet->{from_user};

			$str .= "@" . $screen_name;
			$str .= " (" . $tweet->{user}{name} . ")" if $tweet->{user}{name};
			if ($tweet->{user}{location}) {
				$str .= " - " . $tweet->{user}{location};
			}

			$str .= " | ";

			my $source = $hs->parse($tweet->{source});
			$str .= "posted via " . $source . " " . $tweet->relative_created_at . " | http://twitter.com/" . $screen_name . "/statuses/" . $tweet->{id};
		}
	}

	$self->f->set("infoline", $str);
}

sub shorten {
	my $self = shift;
	if ($self->allow_shorten) {
		my $text = $self->f->get("inputfield");
		my $prompt = $self->f->get("prompt");

		$self->set_lastline;
		$self->status_msg("Shortening...");
		my $newtext = $self->ctrl->shorten($text);
		$self->set_input_field($prompt, $newtext);
	}
}

sub post_update {
	my $self = shift;
	my ($tweet) = @_;
	if ($tweet ne "") {
		$self->status_msg("Posting tweet...");
		eval {
			$self->ctrl->post_update($tweet, $self->saved_status_id);
		};
		if (my $err = $@) {
			$self->status_msg("Error: $err");
			sleep(1);
			$self->set_input_field("Tweet: ", $tweet);
			return;
		} 
		$self->status_msg("");
	}
	$self->saved_status_id(undef);
}

sub send_dm {
	my $self = shift;
	my ($tweet) = @_;
	if ($tweet ne "") {
		my $rcpt = $self->saved_rcpt;
		$self->status_msg("Sending message to $rcpt...");
		eval {
			$self->ctrl->send_dm($tweet, $rcpt);
		};
		if (my $err = $@) {
			$self->status_msg("Error: $err");
			sleep(1);
			$self->set_input_field("DM to $rcpt: ", $tweet);
			return;
		}
		$self->status_msg("");
	}
	$self->saved_rcpt(undef);
	$self->saved_status_id(undef);
}

sub set_shorthelp {
	my $self = shift;
	my ($data) = @_;
	my $text = join(" ", map { $self->ctrl->key($_->{key}) . ":" . $_->{desc} } @$data);
	$self->f->set("shorthelp", $text);
}

sub show_user_timeline {
	my $self = shift;

	my $screen_name = $self->get_current_tweet_screen_name;
	die "couldn't determine current tweet's screen name." unless defined($screen_name);

	$self->ctrl->set_user_name($screen_name);
	$self->load_timeline(BaconBird::Model::USER_TIMELINE);
}

sub load_timeline {
	my $self = shift;
	my ($tl) = @_;

	my %statusmsg_map = ( 
		BaconBird::Model::USER_TIMELINE => "Loading user timeline...", 
		BaconBird::Model::SEARCH_RESULTS => "Loading search results...", 
		BaconBird::Model::DIRECT_MESSAGES => "Loading direct messages...", 
		BaconBird::Model::MENTIONS => "Loading mentions...", 
		BaconBird::Model::HOME_TIMELINE => "Loading home timeline...", 
	);

	$self->set_shorthelp_by_tl($tl);
	$self->status_msg($statusmsg_map{$tl});
	$self->select_timeline($tl);
	$self->get_timeline;
	$self->timeline($tl);
	$self->status_msg("");
}

sub set_shorthelp_by_tl {
	my $self = shift;
	my ($tl) = @_;

	my %shorthelp_map = ( 
		BaconBird::Model::USER_TIMELINE => HELP_TIMELINE, 
		BaconBird::Model::SEARCH_RESULTS => HELP_TIMELINE, 
		BaconBird::Model::DIRECT_MESSAGES => HELP_DM, 
		BaconBird::Model::MENTIONS => HELP_TIMELINE, 
		BaconBird::Model::HOME_TIMELINE => HELP_TIMELINE, 
	);

	$self->set_shorthelp($shorthelp_map{$tl});
}

sub show_help {
	my $self = shift;

	$self->is_help(1);
	$self->set_shorthelp(HELP_HELP);
	$self->set_caption(BaconBird::Model::HELP);
	$self->f->set("infoline", ">> ");
	$self->f->modify("tweets", "replace", "{textview[help] }");

	my $list = "{list";

	foreach my $h (@{$self->ctrl->get_help_desc}) {
		my $str = sprintf("%s %s %s", $h->{key}, " " x (8 - length($h->{key})), $h->{desc});
		$list .= "{list text:" . stfl::quote($str) . "}";
	}

	$list .= "}";

	$self->f->modify("help", "replace_inner", $list);
}

sub close_help {
	my $self = shift;
	$self->is_help(0);

	$self->f->modify("help", "replace", "{list[tweets] style_focus[listfocus]:fg=yellow,bg=blue,attr=bold .expand:vh pos_name[tweetid]: pos[tweetpos]:0}");
	# TODO: set_shorthelp
	$self->set_shorthelp_by_tl($self->timeline);
	$self->get_timeline;
}

sub follow {
	my $self = shift;

	my $screen_name = $self->get_current_tweet_screen_name;
	die "couldn't determine current tweet's screen name." unless defined($screen_name);

	$self->status_msg("Following $screen_name...");
	$self->ctrl->follow_user($screen_name);
	$self->status_msg("");
}

sub unfollow {
	my $self = shift;

	my $screen_name = $self->get_current_tweet_screen_name;
	die "couldn't determine current tweet's screen name." unless defined($screen_name);

	$self->status_msg("Unfollowing $screen_name...");
	$self->ctrl->unfollow_user($screen_name);
	$self->status_msg("");
}

sub get_current_tweet_screen_name {
	my $self = shift;

	my $tweetid = $self->f->get("tweetid");
	return undef if !defined($tweetid) || $tweetid eq "";

	my $screen_name;

	if ($self->ctrl->is_direct_message) {
		$screen_name = $self->ctrl->get_dm_by_id($tweetid)->{sender}{screen_name};
	} else {
		my $tweet = $self->ctrl->get_message_by_id($tweetid);
		$screen_name = $tweet->{user}{screen_name} || $tweet->{from_user};
	}

	return $screen_name;
}

no Moose;
1;
