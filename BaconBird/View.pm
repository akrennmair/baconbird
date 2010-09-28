package BaconBird::View;
use Moose;

use stfl;

use constant PROGRAM_VERSION => "0.1";

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
    label text:"q:Quit ENTER:New Tweet ^R:Retweet r:Reply R:Public Reply 1:Home Timeline 2:Mentions 3:Direct Messages" .expand:h style_normal:bg=blue,fg=white,attr=bold
  hbox[lastline]
    .expand:0
    label text[msg]:"" .expand:h
EOT

	$self->f->set("program", "[baconbird " . PROGRAM_VERSION . "] ");
	$self->set_caption("home_timeline");
}

sub next_event {
	my $self = shift;

	my $e = $self->f->run(10000);
	return if (!defined($e));

	if ($e eq "q") {
		$self->ctrl->quit(1);
	} elsif ($e eq "ENTER") {
		$self->set_input_field("Tweet: ");
	} elsif ($e eq "cancel-input") {
		$self->set_lastline;
		$self->saved_status_id(undef);
	} elsif ($e eq "end-input") {
		my $tweet = $self->f->get("inputfield");
		$self->set_lastline;
		$self->status_msg("Posting tweet...");
		$self->ctrl->post_update($tweet, $self->saved_status_id);
		$self->status_msg("");
		$self->saved_status_id(undef);
	} elsif ($e eq "^R") {
		my $tweetid = $self->f->get("tweetid");
		if (defined($tweetid) && $tweetid ne "") {
			$self->ctrl->retweet($tweetid);
			$self->status_msg("Retweeted.");
		}
	} elsif ($e eq "r") {
		$self->do_reply(0);
	} elsif ($e eq "R") {
		$self->do_reply(1);
	} elsif ($e eq "1") {
		$self->select_timeline("home_timeline");
		$self->get_timeline;
	} elsif ($e eq "2") {
		$self->select_timeline("mentions");
		$self->get_timeline;
	} elsif ($e eq "3") {
		$self->select_timeline("direct_messages");
		$self->get_timeline;
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
	my ($label, $default_text) = @_;

	$default_text = "" if !defined($default_text);
	my $pos = length($default_text);

	$self->f->modify("lastline", "replace", '{hbox[lastline] .expand:0 {label .expand:0 text:' . stfl::quote($label) . '}{input[tweetinput] on_ESC:cancel-input on_ENTER:end-input modal:1 .expand:h text[inputfield]:' . stfl::quote($default_text) . ' pos:' . $pos . '}}');
	$self->f->set_focus("tweetinput");
}

sub set_timeline {
	my $self = shift;
	my ($tl) = @_;

	my $list = "{list ";

	foreach my $tweet (@$tl) {
		my $username = $tweet->{user}{screen_name} || $tweet->{sender}{screen_name};
		my $text = "@" . $username . ": " . $tweet->{text};
		$list .= "{listitem[" .  $tweet->{id} . "] text:" . stfl::quote($text) . "}";
	}

	$list .= "}";

	$self->f->modify("tweets", "replace_inner", $list);
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

	my $tweetid = $self->f->get("tweetid");

	if (defined($tweetid) && $tweetid ne "") {
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
	my %caption = ( "home_timeline" => "Home Timeline", "mentions" => "Mentions", "direct_messages" => "Direct Messages" );
	$self->f->set("current_view", $caption{$view} || "BUG! UNKNOWN VIEW!");
}


no Moose;
1;
