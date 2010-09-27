package BaconBird::View;
use Moose;

use stfl;

has 'f' => (
	is => 'rw',
	isa => 'stfl::stfl_form',
);

has 'ctrl' => (
	is => 'rw',
	isa => 'BaconBird::Controller',
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
    pos_name[tweetposname]:
    pos[tweetpos]:0
  vbox
    .expand:0
    .display:1
    label text:"q:Quit ... more help" .expand:h style_normal:bg=blue,fg=white,attr=bold
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
	} elsif ($e eq "r") {
		$self->ctrl->reload_home_timeline();
	} elsif ($e eq "ENTER") {
		$self->set_input_field("Tweet: ");
	} elsif ($e eq "cancel-input") {
		$self->set_lastline;
	} elsif ($e eq "end-input") {
		my $tweet = $self->f->get("inputfield");
		$self->set_lastline;
		$self->ctrl->post_update($tweet);
	} else {
		$self->status_msg("input: $e");
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
	my ($label) = @_;

	$self->f->modify("lastline", "replace", '{hbox[lastline] .expand:0 {label .expand:0 text:' . stfl::quote($label) . '}{input[tweetinput] on_ESC:cancel-input on_ENTER:end-input modal:1 .expand:h text[inputfield]:""}}');
	$self->f->set_focus("tweetinput");
}

sub set_timeline {
	my $self = shift;
	my ($tl) = @_;

	my $list = "{list ";

    foreach my $tweet (@$tl) {
      my $text = "@" . $tweet->{user}{screen_name} . ": " . $tweet->{text};
      $list .= "{listitem text:" . stfl::quote($text) . "}";
	}

	$list .= "}";

	$self->f->modify("tweets", "replace_inner", $list);
}

sub set_rate_limit {
	my $self = shift;
	my ($remaining, $limit ) = @_;
	$self->f->set("rateinfo", "$remaining/$limit");
}


no Moose;
1;
