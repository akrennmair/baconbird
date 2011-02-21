require 5.010;
use ExtUtils::MakeMaker;

WriteMakefile (
	NAME		=> 'BaconBird',
	AUTHOR		=> 'Andreas Krennmair <ak@synflood.at>',
	ABSTRACT	=> 'BaconBird is a Twitter client for text terminals.',
	VERSION		=> '0.3',
	EXE_FILES	=> [ 'baconbird' ],
	PREREQ_PM	=> {
			'stfl' => 0,
			'Moose' => '0.54',
			'Net::Twitter' => '3.13007',
			'WWW::Shorten' => '1.88',
			'URI::Find' => '0.16',
			'HTML::Strip' => '1.06',
			'IO::Socket::SSL' => '1.16',
			'Config::General' => '2.40',
			'String::Format' => '1.16',
			'autodie' => '2.10',
			'IPC::System::Simple' => '1.21',
	}
);
