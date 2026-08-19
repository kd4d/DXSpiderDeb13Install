# -*- perl -*-
# The system variables - those indicated will need to be changed to suit your
# circumstances (and callsign)
#
# Copyright (c) 1998-2007 - Dirk Koopman G1TLH
#
#

package main;

# this really does need to change for your system!!!!			   
# use CAPITAL LETTERS
$mycall = "????";

# your name
$myname = "?????";

# Your 'normal' callsign (in CAPTTAL LETTERS) 
$myalias = "??????";  # Example:  W3LPL-9

# Your latitude (+)ve = North (-)ve = South in degrees and decimal degrees
$mylatitude = ?????;  #  Example:  +39.3

# Your Longtitude (+)ve = East, (-)ve = West in degrees and decimal degrees
$mylongitude = ????; #  Example:  -77.0

# Your locator (USE CAPITAL LETTERS)
$mylocator = "?????";  #  Example:  FM19LG

# Your QTH (roughly)
$myqth = "?????";     #  Example:  Glenwood, MD

# Your e-mail address
$myemail = "????????";

# the country codes that my node is located in
# 
# for example 'qw(EA EA8 EA9 EA0)' for Spain and all its islands.
# if you leave this blank then it will use the country code for
# your $mycall. This will suit 98% of sysops (including GB7 BTW).
#

@my_cc = qw();

# are we debugging ?
@debug = qw(chan state msg cron connect progress nologchan);

# are we doing xml?
$do_xml = 0;

$Internet::contest_host = "contest.dxtron.com";

# the SQL Spot database DBI dsn
#$dsn = "dbi:SQLite:dbname=$root/data/dxspider.db";
#$dbuser = "";
#$dbpass = "";

# From now on SQLite3 will be the User database storage method.
# It is known to work with SQLite3 and *may* work with mysql
# It does not use the '$dsn' variables because I believe that
# the users file should be separate from spots and other things.
# YMMV...
#
# If YM does indeed V then you can simply assign the "spot" $dsn to $userdsn.
# Not tested but should work.
#
our $userdsn = "dbi:SQLite:dbname=$root/local_data/dxusers.db";

# In /spider/local/DXVars.pm

@listen = (
    [ '0.0.0.0', 7300, 'dx' ],    # User Handler (interactive login: banners, 'login:' prompt)
    [ '0.0.0.0', 8001, 'node' ],  # Dedicated Node Handler (raw PC protocol, no banners/prompts)
);

1;
