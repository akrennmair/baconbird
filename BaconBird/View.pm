package BaconBird::View;
use Moose;

use stfl;

use constant HOME_TIMELINE => 1;
use constant MENTIONS => 2;

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

has 'current_timeline' => (
	is => 'rw',
	default => HOME_TIMELINE,
);

sub BUILD {
	my $self = shift;

	$self->f(stfl::create( <<"EOT" ));
vbox
  hbox
    .expand:0
    \@style_normal:bg=blue,fg=white,attr=bold
    label text:"[baconbird 0.1]" .expand:h
    label .tie:r text[rateinfo]:"-1/-1" .expand:0
  list[tweets]
    style_focus[listfocus]:fg=yellow,bg=blue,attr=bold
    .expand:vh
    pos_name[tweetid]:
    pos[tweetpos]:0
  vbox
    .expand:0
    .display:1
    label text:"q:Quit ENTER:New Tweet ^R:Retweet r:Reply R:Public Reply" .expand:h style_normal:bg=blue,fg=white,attr=bold
  hbox[lastline]
    .expand:0
    label text[msg]:"" .expand:h
EOT
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
		$self->ctrl->post_update($tweet, $self->saved_status_id);
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
	} elsif ($e eq "h") {
		$self->current_timeline(HOME_TIMELINE);
		$self->get_timeline;
	} elsif ($e eq "m") {
		$self->current_timeline(MENTIONS);
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
      my $text = "@" . $tweet->{user}{screen_name} . ": " . $tweet->{text};
      $list .= "{listitem[" .  $tweet->{id} . "] text:" . stfl::quote($text) . "}";
	}

	$list .= "}";

	$self->f->modify("tweets", "replace_inner", $list);
}

sub set_rate_limit {
	my $self = shift;
	my ($remaining, $limit ) = @_;
	$self->f->set("rateinfo", "$remaining/$limit");
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

	if ($self->current_timeline == HOME_TIMELINE) {
		$self->set_timeline($self->ctrl->get_home_timeline);
	} elsif ($self->current_timeline == MENTIONS) {
		$self->set_timeline($self->ctrl->get_mentions);
	}
	# TODO: show which timeline we're on somewhere
}


no Moose;
1;
