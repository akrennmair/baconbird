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
		"browser"		=> "links %u",
	});
	$self->configdata({ });
}

sub load {
	my $self = shift;
	eval {
		my $conf = new Config::General(-LowerCaseNames => 1, -ConfigFile => $self->configfile);
		my %config = $conf->getall;
		$self->configdata(\%config);
		undef $conf;
	};
}

sub get_value {
	my $self = shift;
	my ($key) = @_;
	return $self->configdata->{$key} || $self->default_config->{$key};
}

no Moose;
1;
