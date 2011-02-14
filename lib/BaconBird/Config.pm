package BaconBird::Config;
use Moose;

use Config::General;

has 'configfile' => (
	is => 'rw',
	isa => 'Str',
	default => $ENV{'HOME'} . "/.baconbird/config",
);

has 'configdata' => (
	is => 'rw',
	isa => 'HashRef',
);

has 'default_config' => (
	is => 'rw',
	isa => 'HashRef',
);

sub BUILD {
	my $self = shift;
	$self->default_config({
			"browser"      => undef,
			"editor"       => undef,
			"count"        => 50,
			"timeline_format" => "%F%R[%16u] %t",
			"confirm_quit" => 0,
	});
	eval {
		my $conf = new Config::General(-LowerCaseNames => 1, -ConfigFile => $self->configfile);
		my %config = $conf->getall;
		$self->configdata(\%config);
		undef $conf;
	};
	$self->configdata({ }) if not $self->configdata;
	warn $@ if $@;
}

sub get_value {
	my $self = shift;
	my ($key) = @_;
	return $self->configdata->{$key} || $self->default_config->{$key};
}

no Moose;
1;
