package BaconBird::View;
use Moose;

use stfl;
use HTML::Strip;
use Text::Wrap;
use URI::Find;

use BaconBird::KeyMap;
use BaconBird::Model;

use constant PROGRAM_VERSION => "0.3";
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
	{ key => BaconBird::KeyMap::KEY_MY_TIMELINE, desc => "My Timeline" },
	{ key => BaconBird::KeyMap::KEY_OPEN_URL, desc => "Open URLs" },
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
	{ key => BaconBird::KeyMap::KEY_MY_TIMELINE, desc => "My Timeline" },
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

use constant HELP_LOAD_SEARCH => [
	{ key => BaconBird::KeyMap::KEY_YES, desc => "Search" },
	{ key => BaconBird::KeyMap::KEY_ENTER, desc => "Search" },
	{ key => BaconBird::KeyMap::KEY_DELETE_ITEM, desc => "Delete search" },
	{ key => BaconBird::KeyMap::KEY_QUIT, desc => "Cancel" },
	{ key => BaconBird::KeyMap::KEY_CANCEL, desc => "Cancel" },
];

use constant HELP_FRIENDS => [
	{ key => BaconBird::KeyMap::KEY_SHOW_USER, desc => "Show timeline" },
	{ key => BaconBird::KeyMap::KEY_UNFOLLOW, desc => "Unfollow" },
	{ key => BaconBird::KeyMap::KEY_ENTER, desc => "Direct Message" },
	{ key => BaconBird::KeyMap::KEY_QUIT, desc => "Close" },
];

use constant HELP_FOLLOWERS => [
	{ key => BaconBird::KeyMap::KEY_SHOW_USER, desc => "Show timeline" },
	{ key => BaconBird::KeyMap::KEY_FOLLOW, desc => "Follow" },
	{ key => BaconBird::KeyMap::KEY_UNFOLLOW, desc => "Unfollow" },
	{ key => BaconBird::KeyMap::KEY_ENTER, desc => "Direct Message" },
	{ key => BaconBird::KeyMap::KEY_QUIT, desc => "Close" },
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

has 'config' => (
	is => 'rw',
	isa => 'BaconBird::Config',
);

has 'highlight_patterns' => (
	is => 'rw',
	isa => 'ArrayRef',
	default => sub { [ ] },
);

has 'hide_patterns' => (
	is => 'rw',
	isa => 'ArrayRef',
	default => sub { [ ] },
);

has 'is_load_search' => (
	is => 'rw',
	isa => 'Bool',
	default => 0,
);

has 'is_quit_prompt' => (
	is => 'rw',
	isa => 'Bool',
	default => 0,
);

has 'keybindings' => (
	is => 'rw',
	isa => 'Str',
);

has 'form_style' => (
	is => 'rw',
	isa => 'Str',
);

has 'limit_expression' => (
	is => 'rw',
	isa => 'Str',
);

has 'current_tweet' => (
	is => 'rw',
	isa => 'Str',
	default => '',
);

has 'is_followers' => (
	is => 'rw',
	isa => 'Bool',
	default => 0,
);

has 'is_friends' => (
	is => 'rw',
	isa => 'Bool',
	default => 0,
);

sub BUILD {
	my $self = shift;

	my $keybindings = 'bind_up:"** k" bind_down:"** j" bind_page_down:"** RIGHT" bind_page_up:"** LEFT"';

	my $form_style = "style_focus[listfocus]:fg=yellow,bg=blue,attr=bold $keybindings .expand:vh pos_name[tweetid]: pos[tweetpos]:0 richtext:1";

	$self->keybindings($keybindings);
	$self->form_style($form_style);

	$self->f(stfl::create( <<"EOT" ));
vbox[root]
  hbox
    .expand:0
    \@style_normal:bg=blue,fg=white,attr=bold
    label text[program]:"" .expand:0
    label text[current_view]:"" .expand:h
    label .tie:r text[rateinfo]:"-1/-1" .expand:0
  vbox
    \@style_1_normal:fg=yellow,bg=red,attr=bold
    .expand:vh
    list[tweets]
      $form_style
    vbox 
      .display[displayview]:0
      .expand:0
      label .expand:0 .height:1 style_normal:bg=blue
      textview[tweetview]
        .expand:v
      .height[viewheight]:10
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

	my $filters = $self->config->get_value("filters");
	if ($filters) {
		my $highlight = $filters->{highlight};
		if (ref($highlight) eq "ARRAY") {
			foreach my $expr (@$highlight) {
				push(@{$self->highlight_patterns}, { regex => $expr, id => 1 });
			}
		} elsif ($highlight) {
				push(@{$self->highlight_patterns}, { regex => $highlight, id => 1 });
		}
		my $hide = $filters->{hide};
		if (ref($hide) eq "ARRAY") {
			foreach my $expr (@$hide) {
				push(@{$self->hide_patterns}, { regex => $expr });
			}
		} elsif ($hide) {
			push(@{$self->hide_patterns}, { regex => $hide });
		}
	}
}

sub next_event {
	my $self = shift;

	my $e = $self->f->run(10000);
	$self->f->run(-1);

	my $tweetid = $self->f->get("tweetid");

	if (my $focus = $self->f->get_focus) {
		if ($focus eq "tweetinput") {
			$self->set_remaining($self->f->get("inputfield"));
		}
		if ($focus eq "tweets" || $self->is_friends || $self->is_followers) {
			$self->update_info_line($tweetid);
		}
	}
	if ($self->is_friends || $self->is_followers) {
		$self->update_user_view($tweetid);
	} else {
		$self->update_view($tweetid);
	}

	return unless defined($e);

	if ($self->is_quit_prompt) {
		if ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_YES)) {
			$self->status_msg("Quit baconbird? (y/[n]) yes");
			$self->ctrl->quit(1);
			$self->is_quit_prompt(0);
		} elsif (
			$e eq $self->ctrl->key(BaconBird::KeyMap::KEY_NO) ||
			$e eq $self->ctrl->key(BaconBird::KeyMap::KEY_ENTER) ||
			$e eq $self->ctrl->key(BaconBird::KeyMap::KEY_CANCEL)
		) {
			$self->status_msg("Quit baconbird? (y/[n]) no");
			$self->is_quit_prompt(0);
			$self->set_lastline;
		}
		return;
	} elsif ($self->is_help) {
		if ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_QUIT)) {
			$self->close_help;
		}
		return;
	} elsif ($self->is_load_search) {
		if (
			$e eq $self->ctrl->key(BaconBird::KeyMap::KEY_QUIT) ||
			$e eq $self->ctrl->key(BaconBird::KeyMap::KEY_CANCEL)
		) {
			$self->close_load_search;
		} elsif (
			$e eq $self->ctrl->key(BaconBird::KeyMap::KEY_YES) ||
			$e eq $self->ctrl->key(BaconBird::KeyMap::KEY_ENTER)
		) {
			my $searchid = $self->f->get("tweetid");
			$self->close_load_search;
			my $searchphrase = $self->ctrl->get_query_from_saved_search_id($searchid);
			$self->status_msg("Loading saved search $searchphrase...");
			$self->ctrl->set_search_phrase($searchphrase);
			$self->load_timeline(BaconBird::Model::SEARCH_RESULTS);
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_DELETE_ITEM)) {
			$self->set_lastline;
			my $searchid = $self->f->get("tweetid");
			$self->status_msg("Deleting saved search...");
			$self->ctrl->destroy_saved_search($searchid);
			$self->status_msg("Deleted saved search.");
			$self->show_load_search;
		}
		return;
	} elsif ($self->is_followers) {
		if ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_QUIT)) {
			$self->close_followers;
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_VIEW)) {
			$self->toggle_view;
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_SHOW_USER)) {
			$self->close_friends;
			$self->show_user_timeline_from_user($tweetid);
		}
		return;
	} elsif ($self->is_friends) {
		if ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_QUIT)) {
			$self->close_friends;
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_VIEW)) {
			$self->toggle_view;
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_SHOW_USER)) {
			$self->close_friends;
			$self->show_user_timeline_from_user($tweetid);
		}
		return;
	} else {
		# Default mode
		if ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_QUIT)) {
			if ($self->config->get_value("confirm_quit") =~ m/^(?:1|yes|true|on)$/i) {
				$self->status_msg("Quit baconbird? (y/[n])");
				$self->is_quit_prompt(1);
			} else {
				$self->ctrl->quit(1);
			}
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
			$self->set_input_field("Search: ", "", "end-input-search", 1);
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
			$self->set_input_field("User to follow: ", "", "end-input-follow-user", 1);
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
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_VIEW)) {
			$self->toggle_view;
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_REDRAW)) {
			stfl::reset();
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_OPEN_URL)) {
			$self->open_url($tweetid);
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_FAVORITES)) {
			$self->load_timeline(BaconBird::Model::FAVORITES_TIMELINE);
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_RT_BY_ME)) {
			$self->load_timeline(BaconBird::Model::RT_BY_ME_TIMELINE);
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_RT_OF_ME)) {
			$self->load_timeline(BaconBird::Model::RT_OF_ME_TIMELINE);
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_MY_TIMELINE)) {
			$self->load_timeline(BaconBird::Model::MY_TIMELINE);
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_ENTER_USER)) {
			$self->set_input_field("User: ", "", "end-user-search", 1);
		} elsif ($e eq "end-user-search") {
			my $user_name = $self->f->get("inputfield");
			$self->set_lastline;
			if (defined($user_name) && $user_name ne "") {
				$self->ctrl->set_user_name($user_name);
				$self->load_timeline(BaconBird::Model::USER_TIMELINE);
			}
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_ENTER_HIGHLIGHT)) {
			$self->set_input_field("Expression to highlight: ", "", "end-new-highlight", 1);
		} elsif ($e eq "end-new-highlight") {
			my $highlight = $self->f->get("inputfield");
			$self->set_lastline;

			if (defined($highlight) && $highlight ne "") {
				my $active = 0;
				for (my $i = 0; $i < scalar @{$self->highlight_patterns}; $i++) {
					my $pattern = $self->highlight_patterns->[$i];

					if ($pattern->{regex} eq $highlight) {
						$active = 1;
						splice @{$self->highlight_patterns}, $i, 1;
					}
				}

				unless ($active) {
					push(@{$self->highlight_patterns}, { regex => $highlight, id => 1 });
				}

				$self->get_timeline;
			}
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_ENTER_HIDE)) {
			$self->set_input_field("Expression to hide: ", "", "end-new-hide", 1);
		} elsif ($e eq "end-new-hide") {
			my $hide = $self->f->get("inputfield");
			$self->set_lastline;
			if (defined($hide) && $hide ne "") {
				my $active = 0;
				for (my $i = 0; $i < scalar @{$self->hide_patterns}; $i++) {
					my $pattern = $self->hide_patterns->[$i];

					if ($pattern->{regex} eq $hide) {
						$active = 1;
						splice @{$self->hide_patterns}, $i, 1;
					}
				}

				unless ($active) {
					push(@{$self->hide_patterns}, { regex => $hide, id => 1 });
				}

				$self->get_timeline;
			}
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_SAVE_SEARCH)) {
			my $searchphrase = $self->ctrl->get_search_phrase;
			if (defined($searchphrase) && $searchphrase ne "") {
				$self->ctrl->create_saved_search;
				$self->status_msg("Search saved.");
			} else {
				$self->status_msg("No search query to save.");
			}
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_LOAD_SEARCH)) {
			$self->show_load_search;
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_DELETE_ITEM)) {
			if ($self->ctrl->is_direct_message) {
				$self->status_msg("Deleting direct message...");
				my $error = $self->ctrl->destroy_direct_message($tweetid);
				if ($error) {
					$self->status_msg("Error deleting direct message...");
				} else {
					$self->status_msg("Deleted direct message.");
					$self->get_timeline;
					stfl::reset();
				}
			} else {
				$self->status_msg("Deleting your tweet...");
				my $error = $self->ctrl->destroy_status($tweetid);
				if ($error) {
					$self->status_msg("Error deleting your tweet...");
				} else {
					$self->status_msg("Deleted your tweet.");
					$self->get_timeline;
					stfl::reset();
				}
			}
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_LIMIT_TIMELINE)) {
			$self->set_input_field("Limit ('all' to reset): ", "", "end-limit-expression", 1);
		} elsif ($e eq "end-limit-expression") {
			my $expression = $self->f->get("inputfield");
			$self->set_lastline;
			if (defined($expression) && $expression ne "") {
				$self->limit_expression($expression);
				$self->get_timeline;
			}
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_FRIENDS)) {
			$self->status_msg("Loading users I follow...");
			$self->show_friends;
		} elsif ($e eq $self->ctrl->key(BaconBird::KeyMap::KEY_FOLLOWERS)) {
			$self->status_msg("Loading users who follow me...");
			$self->show_followers;
		}
	}
}

sub prepare {
	my $self = shift;

	my $tweetid = $self->f->get("tweetid");

	if ($self->f->get_focus eq "tweets") {
		$self->update_info_line($tweetid);
	}
	$self->update_view($tweetid);
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
	my ($label, $default_text, $end_input_event, $do_not_show_remaining) = @_;

	$default_text = "" unless defined($default_text);
	$end_input_event = "end-input" unless defined($end_input_event);

	my $pos = length($default_text);

	my $last_line_text = '{hbox[lastline] .expand:0 {label .expand:0 text[prompt]:' . stfl::quote($label) . '}{input[tweetinput] on_ESC:cancel-input on_ENTER:' . $end_input_event . ' modal:1 .expand:h text[inputfield]:' . stfl::quote($default_text);

	unless ($do_not_show_remaining) {
		$last_line_text .= ' pos:' . $pos . '} {label .tie:r .expand:0 text[remaining]:"" style_normal[remaining_style]:fg=white}';
	}

	$self->f->modify("lastline", "replace", $last_line_text);

	$self->set_remaining($default_text);

	$self->f->set_focus("tweetinput");
}

sub set_timeline {
	my $self = shift;
	my ($tl) = @_;

	my $re;

	my $expression = $self->limit_expression;
	if ($expression && $expression ne "") {
		if ($expression eq "all") {
			$expression = "";
			$self->limit_expression($expression);
		} else {
			$re = qr/$expression/i;
		}
	}

	my $pos = -1;
	my $position = "0";

	my $list = "{list ";

	foreach my $tweet (@$tl) {
		my $username = $tweet->{user}{screen_name} || $tweet->{sender}{screen_name} || $tweet->{from_user};

		if ($re and $tweet->{text} !~ m/$re/ and $username !~ m/$re/) {
			next;
		}

		$pos++;
		if ($tweet->{id} eq $self->current_tweet) {
			$position = $pos;
		}

		my $text;

		if ($tweet->{favorited}) {
			$text .= "!";
		} else {
			$text .= " ";
		}

		if ($tweet->{retweeted} ||
			($tweet->{retweet_count} && $tweet->{retweet_count} ne '0')
		) {
			$text .= "R";
		} else {
			$text .= " ";
		}

		$text .= sprintf("[%16s] %s", "@" . $username, $tweet->{text});
		$text =~ s/[\r\n]+/ /g;
		$text =~ s/\</<>/g;
		if (!$self->matches_hidden($text)) {
			$text = $self->highlight_text($text);
			$list .= "{listitem[" .  $tweet->{id} . "] text:" . stfl::quote($text) . "}";
		}
	}

	$list .= "}";

	$self->f->modify("tweets", "replace_inner", $list);

	$self->f->run(-1);

	$self->f->set("tweetpos", "$position");

	if (defined($self->f->get_focus) && $self->f->get_focus ne "tweetinput") {
		$self->update_info_line($self->f->get("tweetid"));
	}
	$self->update_view($self->f->get("tweetid"));
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
	my ($preserve_position) = @_;

	return if ($self->is_friends || $self->is_followers);

	my $tweetid = $self->f->get("tweetid");
	if ($preserve_position && $tweetid) {
		$self->current_tweet($tweetid);
	}
	$self->set_timeline($self->ctrl->get_timeline);
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
					BaconBird::Model::HELP => "Help",
					BaconBird::Model::FAVORITES_TIMELINE => "Favorites Timeline",
					BaconBird::Model::RT_BY_ME_TIMELINE => "Retweets by me",
					BaconBird::Model::RT_OF_ME_TIMELINE => "Retweets of me",
					BaconBird::Model::MY_TIMELINE => "My timeline",
					BaconBird::Model::LOAD_SEARCH => "Load Saved Search",
					BaconBird::Model::FRIENDS => "Users I Follow",
					BaconBird::Model::FOLLOWERS => "Users Following Me",
				);
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

	if ($self->is_followers || $self->is_friends) {
		my $user = $self->ctrl->get_user_by_id($tweetid);
		my $screen_name = $user->screen_name;
		$str .= "@" . $screen_name;
		$str .= " (" . $user->{name} . ")" if $user->{name};
		if ($user->{location}) {
			$str .= " - " . $user->{location};
		}

		$str .= " | http://twitter.com/" . $screen_name;
	} elsif ($self->ctrl->is_direct_message) {
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

sub open_url {
	my $self = shift;
	my ($tweetid) = @_;

	if ($tweetid ne "") {
		my $tweet = $self->ctrl->get_message_by_id($tweetid) || $self->ctrl->get_dm_by_id($tweetid);
		my $text = $tweet->text;

		my $open_url = sub {
			my ($URI, $text) = @_;

			$self->status_msg("Opening $text in browser...");
			$self->open_url_in_browser($text);
			$self->status_msg("Opened $text in browser");
		};

		my $finder = URI::Find->new($open_url);
		my $uris_found = $finder->find(\$text);

		if (!$uris_found) {
			$self->status_msg("No URL found in tweet.");
		}
	}
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
		BaconBird::Model::FAVORITES_TIMELINE => "Loading favorites timeline...", 
		BaconBird::Model::RT_BY_ME_TIMELINE => "Loading retweeted-by-me timeline...",
		BaconBird::Model::RT_OF_ME_TIMELINE => "Loading retweets-of-me timeline...",
		BaconBird::Model::MY_TIMELINE => "Loading my timeline...",
	);

	$self->limit_expression("");
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
		BaconBird::Model::FAVORITES_TIMELINE => HELP_TIMELINE, 
		BaconBird::Model::RT_BY_ME_TIMELINE => HELP_TIMELINE, 
		BaconBird::Model::RT_OF_ME_TIMELINE => HELP_TIMELINE, 
		BaconBird::Model::MY_TIMELINE => HELP_TIMELINE, 
	);

	$self->set_shorthelp($shorthelp_map{$tl});
}

sub show_help {
	my $self = shift;

	my $keybindings = $self->keybindings;

	$self->is_help(1);
	$self->set_shorthelp(HELP_HELP);
	$self->set_caption(BaconBird::Model::HELP);
	$self->f->set("infoline", ">> ");
	$self->f->modify("tweets", "replace", "{textview[help] $keybindings }");

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

	my $form_style = $self->form_style;
	$self->f->modify("help", "replace", "{list[tweets] $form_style}");
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

sub toggle_view {
	my $self = shift;

	my $enabled = $self->f->get("displayview");

	if ($enabled eq "0") {
		$self->f->set("displayview", "1");
	} else {
		$self->f->set("displayview", "0");
	}
}

sub update_view {
	my $self = shift;
	my ($tweetid) = @_;

	return unless defined($tweetid);

	my @lines;

	if ($self->ctrl->is_direct_message) {
		my $dm = $self->ctrl->get_dm_by_id($tweetid);

		push(@lines, $self->split_lines($dm->{text}, int($self->f->get("root:w"))));
		push(@lines, "");
		push(@lines, $self->fill_user($dm->{sender}{screen_name}, $dm->{sender}));

	} else {
		my $tweet = $self->ctrl->get_message_by_id($tweetid);

		push(@lines, $self->split_lines($tweet->{text}, int($self->f->get("root:w"))));
		push(@lines, "");
		if (defined($tweet->{retweeted_by}) && scalar(@{$tweet->{retweeted_by}}) > 0) {
			push(@lines, $self->format_retweeters($tweet->{retweeted_by}));
		}
		push(@lines, $self->fill_user($tweet->{user}{screen_name} || $tweet->{from_user}, $tweet->{user}));
	}

	$self->f->modify("tweetview", "replace_inner", $self->stfl_listify(\@lines));
}

sub format_retweeters {
	my $self = shift;
	my ($rts) = @_;

	my $text = "Retweeted by ";

	my $i;
	for ($i=0;$i<4 && $i<scalar(@$rts);$i++) {
		$text .= ", " if $i > 0;
		$text .= "@" . $rts->[$i]->{screen_name};
	}
	if ($i < scalar(@$rts)) {
		$text .= " and " . sprintf("%u", scalar(@$rts)-$i) . " other(s)";
	}

	return $text;
}

sub fill_user {
	my $self = shift;
	my ($screen_name, $user) = @_;

	my $width = int($self->f->get("root:w"));

	my @lines;

	$screen_name ||= '';

	my $name_line = '@' . $screen_name;
	$name_line .= ' ' . $user->{name} if $user->{name};
	$name_line .= " - " . $user->{location} if $user->{location};
	push(@lines, $self->split_lines($name_line, $width));

	push(@lines, $self->split_lines($user->{description}, $width)) if $user->{description};
	push(@lines, $self->split_lines($user->{url}, $width)) if $user->{url};

	my @numbers;
	push(@numbers, $user->{statuses_count} . " Tweets") if $user->{statuses_count};
	push(@numbers, $user->{friends_count} . " Following") if $user->{friends_count};
	push(@numbers, $user->{followers_count} . " Followers") if $user->{followers_count};
	push(@numbers, $user->{listed_count} . " Listed") if $user->{listed_count};

	push(@lines, $self->split_lines(join(" | ", @numbers), $width)) if scalar(@numbers) > 0;

	return @lines;
}

sub split_lines {
	my $self = shift;
	my ($text, $width) = @_;

	my $old_width = $Text::Wrap::columns;

	$Text::Wrap::columns = $width;
	my @lines = split("\n", wrap('', '', $text));
	$Text::Wrap::columns = $old_width;

	return @lines;
}

sub stfl_listify {
	my $self = shift;
	my ($items) = @_;

	my $result = "{list ";

	foreach my $line (@$items) {
		$result .= "{listitem text:" . stfl::quote($line) . "}";
	}

	return $result . "}";
}

sub open_url_in_browser {
	my $self = shift;
	my ($url) = @_;

	my $browser = $self->config->get_value("browser");

	$url =~ s/"/\\"/g;
	if ($browser =~ /%u/) {
		$browser =~ s/%u/"$url"/g;
	} else {
		$browser .= ' "' . $url . '"';
	}

	stfl::reset();
	system($browser);
}

sub highlight_text {
	my $self = shift;
	my ($text) = @_;
	if ($self->highlight_patterns) {
		foreach my $p (@{$self->highlight_patterns}) {
			$text =~ s/($p->{regex})/<$p->{id}>$1<\/>/ig;
		}
	}
	return $text;
}

sub matches_hidden {
	my $self = shift;
	my ($text) = @_;

	foreach my $p (@{$self->hide_patterns}) {
		return 1 if $text =~ /$p->{regex}/i;
	}

	return undef;
}

sub show_load_search {
	my $self = shift;

	my $form_style = $self->form_style;

	$self->is_load_search(1);
	$self->set_shorthelp(HELP_LOAD_SEARCH);
	$self->set_caption(BaconBird::Model::LOAD_SEARCH);
	$self->f->set("infoline", ">> ");
	$self->f->modify("tweets", "replace", "{list[load_search] $form_style}");

	my $list = "{list";

	my $id = 0;
	foreach my $s (@{$self->ctrl->saved_searches}) {
		my $text;

		$text .= sprintf("%3d - %s", ++$id, $s->{query});
		$text =~ s/[\r\n]+/ /g;
		$text =~ s/\</<>/g;
		$list .= "{listitem[" .  $s->{id} . "] text:" . stfl::quote($text) . "}";
	}

	$list .= "}";

	$self->f->modify("load_search", "replace_inner", $list);
}

sub close_load_search {
	my $self = shift;
	$self->is_load_search(0);

	my $form_style = $self->form_style;
	$self->f->modify("load_search", "replace", "{list[tweets] $form_style}");
	# TODO: set_shorthelp
	$self->set_shorthelp_by_tl($self->timeline);
	$self->get_timeline;
}

sub show_friends {
	my $self = shift;

	my $form_style = $self->form_style;

	$self->is_friends(1);
	$self->set_shorthelp(HELP_FRIENDS);
	$self->set_caption(BaconBird::Model::FRIENDS);
	$self->f->set("infoline", ">> ");
	$self->f->modify("tweets", "replace", "{list[friends] $form_style}");

	my $list = "{list";

	foreach my $user (@{$self->ctrl->friends}) {
		my $text;

		my $screen_name = $user->{screen_name} || "";
		my $following   = $user->{follow_request_sent}   || "";
		my $description = $user->{description} || "";

		$text .= sprintf("[%16s] %s", "@" . $screen_name, $description);
		$text =~ s/[\r\n]+/ /g;
		$text =~ s/\</<>/g;
		$list .= "{listitem[" .  $user->{id} . "] text:" . stfl::quote($text) . "}";
	}

	$list .= "}";

	$self->f->modify("friends", "replace_inner", $list);
	$self->status_msg("");
}

sub close_friends {
	my $self = shift;
	$self->is_friends(0);

	my $form_style = $self->form_style;
	$self->f->modify("friends", "replace", "{list[tweets] $form_style}");
	# TODO: set_shorthelp
	$self->set_shorthelp_by_tl($self->timeline);
	$self->get_timeline;
}

sub show_followers {
	my $self = shift;

	my $form_style = $self->form_style;

	$self->is_followers(1);
	$self->set_shorthelp(HELP_FOLLOWERS);
	$self->set_caption(BaconBird::Model::FOLLOWERS);
	$self->f->set("infoline", ">> ");
	$self->f->modify("tweets", "replace", "{list[followers] $form_style}");

	my $list = "{list";

	foreach my $user (@{$self->ctrl->followers}) {
		my $text;

		$text .= sprintf("[%16s] (%1s) %s", "@" . $user->{screen_name}, $user->{following} ? 'F' : ' ', $user->{description} || '');
		$text =~ s/[\r\n]+/ /g;
		$text =~ s/\</<>/g;
		$list .= "{listitem[" .  $user->{id} . "] text:" . stfl::quote($text) . "}";
	}

	$list .= "}";

	$self->f->modify("followers", "replace_inner", $list);
	$self->status_msg("");
}

sub close_followers {
	my $self = shift;
	$self->is_followers(0);

	my $form_style = $self->form_style;
	$self->f->modify("followers", "replace", "{list[tweets] $form_style}");
	# TODO: set_shorthelp
	$self->set_shorthelp_by_tl($self->timeline);
	$self->get_timeline;
}

sub update_user_view {
	my $self = shift;
	my ($userid) = @_;

	return unless defined($userid);

	my @lines;

	my $user = $self->ctrl->get_user_by_id($userid);

	my $text = '';
	$text = $user->status->text if ($user->{status} and $user->status->{text});
	my $retweeted_by;
	$retweeted_by = $user->status->{retweeted_by} if ($user->{status} and $user->status->{retweeted_by});

	push(@lines, $self->split_lines($text, int($self->f->get("root:w"))));
	push(@lines, "");
	if (defined($retweeted_by) && scalar(@$retweeted_by) > 0) {
		push(@lines, $self->format_retweeters($retweeted_by));
	}
	push(@lines, $self->fill_user($user->{screen_name}, $user));

	$self->f->modify("tweetview", "replace_inner", $self->stfl_listify(\@lines));
}

sub show_user_timeline_from_user {
	my $self = shift;
	my $userid = (@_);
	my $user = $self->ctrl->get_user_by_id($userid);

	my $screen_name = $user->{screen_name};

	$self->ctrl->set_user_name($screen_name);
	$self->load_timeline(BaconBird::Model::USER_TIMELINE);
}

no Moose;
1;
