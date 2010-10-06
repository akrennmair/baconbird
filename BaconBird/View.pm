package BaconBird::View;
use Moose;

use stfl;
use HTML::Strip;

use constant PROGRAM_VERSION => "0.2";
use constant TWITTER_MAX_LEN => 140;

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
    label text:"q:Quit ENTER:New Tweet ^R:Retweet r:Reply R:Public Reply ^O:Shorten /:Search 1:Home Timeline 2:Mentions 3:Direct Messages 4:Search Results" .expand:h style_normal:bg=blue,fg=white,attr=bold
  hbox[lastline]
    .expand:0
    label text[msg]:"" .expand:h
EOT

	$self->f->set("program", "[baconbird " . PROGRAM_VERSION . "] ");
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

	if ($e eq "q") {
		$self->ctrl->quit(1);
	} elsif ($e eq "ENTER") {
		if ($self->ctrl->is_direct_message) {
			$self->set_input_field("DM to: ", "", "end-input-rcpt");
		} else {
			$self->set_input_field("Tweet: ");
		}
	} elsif ($e eq "cancel-input") {
		$self->set_lastline;
		$self->saved_status_id(undef);
	} elsif ($e eq "end-input") {
		my $tweet = $self->f->get("inputfield");
		$self->set_lastline;
		if ($self->ctrl->is_direct_message) {
			$self->send_dm($tweet);
		} else {
			$self->post_update($tweet);
		}
	} elsif ($e eq "end-input-rcpt") {
		my $rcpt = $self->f->get("inputfield");
		$self->set_lastline;
		if ($rcpt ne "") {
			$self->saved_rcpt($rcpt);
			$self->do_reply(0);
		}
	} elsif ($e eq "^R") {
		my $tweetid = $self->f->get("tweetid");
		if (defined($tweetid) && $tweetid ne "") {
			$self->status_msg("Retweeting...");
			$self->ctrl->retweet($tweetid);
			$self->status_msg("Retweeted.");
		}
	} elsif ($e eq "r") {
		$self->do_reply(0);
	} elsif ($e eq "R") {
		$self->do_reply(1);
	} elsif ($e eq "^O") {
		if ($self->f->get_focus eq "tweetinput") {
			$self->shorten;
		}
	} elsif ($e eq "1") {
		$self->status_msg("Loading home timeline...");
		$self->select_timeline(BaconBird::Model::HOME_TIMELINE);
		$self->get_timeline;
		$self->status_msg("");
	} elsif ($e eq "2") {
		$self->status_msg("Loading mentions...");
		$self->select_timeline(BaconBird::Model::MENTIONS);
		$self->get_timeline;
		$self->status_msg("");
	} elsif ($e eq "3") {
		$self->status_msg("Loading direct messages...");
		$self->select_timeline(BaconBird::Model::DIRECT_MESSAGES);
		$self->get_timeline;
		$self->status_msg("");
	} elsif ($e eq "4") {
		$self->status_msg("Loading search results...");
		$self->select_timeline(BaconBird::Model::SEARCH_RESULTS);
		$self->get_timeline;
		$self->status_msg("");
	} elsif ($e eq "/") {
		$self->set_input_field("Search: ", "", "end-input-search");
	} elsif ($e eq "end-input-search") {
		my $searchphrase = $self->f->get("inputfield");
		$self->set_lastline;
		if (defined($searchphrase) && $searchphrase ne "") {
			$self->status_msg("Searching...");
			$self->ctrl->set_search_phrase($searchphrase);
			$self->select_timeline(BaconBird::Model::SEARCH_RESULTS);
			$self->get_timeline;
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

	$self->f->modify("lastline", "replace", '{hbox[lastline] .expand:0 {label .expand:0 text:' . stfl::quote($label) . '}{input[tweetinput] on_ESC:cancel-input on_ENTER:' . $end_input_event . ' modal:1 .expand:h text[inputfield]:' . stfl::quote($default_text) . ' pos:' . $pos . '} {label .tie:r .expand:0 text[remaining]:"" style_normal[remaining_style]:fg=white}');

	$self->set_remaining($default_text);

	$self->f->set_focus("tweetinput");
}

sub set_timeline {
	my $self = shift;
	my ($tl) = @_;

	my $list = "{list ";

	foreach my $tweet (@$tl) {
		my $username = $tweet->{user}{screen_name} || $tweet->{sender}{screen_name} || $tweet->{from_user};
		my $text = sprintf("[%16s] %s", "@" . $username, $tweet->{text});
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
					BaconBird::Model::SEARCH_RESULTS => "Search Results" );
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
	my $tweet = $self->ctrl->get_message_by_id($tweetid);

	if ($tweet) {
		my $hs = HTML::Strip->new();

		$str .= "@" . $tweet->{user}{screen_name};
		$str .= " (" . $tweet->{user}{name} . ")" if $tweet->{user}{name};
		if ($tweet->{user}{location}) {
			$str .= " - " . $tweet->{user}{location};
		}

		$str .= " | ";

		my $source = $hs->parse($tweet->{source});
		$str .= "posted via " . $source . " " . $tweet->relative_created_at . " | http://twitter.com/" . $tweet->{user}{screen_name} . "/statuses/" . $tweet->{id};
	}

	$self->f->set("infoline", $str);
}

sub shorten {
	my $self = shift;
	my $text = $self->f->get("inputfield");

	$self->set_lastline;
	$self->status_msg("Shortening...");
	my $newtext = $self->ctrl->shorten($text);
	$self->set_input_field("Tweet: ", $newtext);
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

no Moose;
1;
