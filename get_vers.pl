#!/usr/bin/perl 

use strict;
use warnings;
use lib '.';

use Moose;
use BaconBird::KeyMap;
use Config::General;
use Data::Dumper;
use Encode::Encoder;
use HTML::Strip;
use I18N::Langinfo;
use IO::Handle;
use Net::Twitter;
use stfl;
use Text::Wrap;
use URI::Find;
use WWW::Shorten;

print "\nBaconBird::KeyMap version: ";
print $BaconBird::KeyMap::VERSION;

print "\nConfig::General version: ";
print $Config::General::VERSION;

print "\nData::Dumper version: ";
print $Data::Dumper::VERSION;

print "\nEncode::Encoder version: ";
print $Encode::Encoder::VERSION;

print "\nHTML::Strip version: ";
print $HTML::Strip::VERSION;

print "\nI18N::Langinfo version: ";
print $I18N::Langinfo::VERSION;

print "\nIO::Handle version: ";
print $IO::Handle::VERSION;

print "\nMoose version: ";
print $Moose::VERSION;

print "\nNet::Twitter version: ";
print $Net::Twitter::VERSION;

print "\nstfl version: ";
print $stfl::VERSION;

print "\nText::Wrap version: ";
print $Text::Wrap::VERSION;

print "\nURI::Find version: ";
print $URI::Find::VERSION;

print "\nWWW::Shorten version: ";
print $WWW::Shorten::VERSION;

print "\n";
