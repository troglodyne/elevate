#!/usr/local/cpanel/3rdparty/bin/perl

#                                      Copyright 2024 WebPros International, LLC
#                                                           All rights reserved.
# copyright@cpanel.net                                         http://cpanel.net
# This code is subject to the cPanel license. Unauthorized copying is prohibited.

package test::cpev::blockers;

use FindBin;

use Test2::V0;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception;

use Test::MockFile 0.032 qw<nostrict>;
use Test::MockModule qw/strict/;

use lib $FindBin::Bin . "/lib";
use Test::Elevate;

use cPstrict;

require $FindBin::Bin . '/../elevate-cpanel';

my $mock_log_file = Test::MockFile->file('/var/log/elevate-cpanel.log');

my $cpev = cpev->new->_init;

like(
    dies { cpev->ssystem('nope') },
    qr/Program 'nope' is not an executable absolute path/,
    'Program is not an executable path.'
);

like(
    dies { cpev->ssystem('grep') },
    qr/Program 'grep' is not an executable absolute path/,
    'Program is not an executable absolute path.'
);

like(
    dies { cpev->ssystem('/etc/apache2/conf/httpd.conf') },
    qr{Program '/etc/apache2/conf/httpd.conf' is not an executable absolute path},
    'Paths that are not executable are not allowed.'
);

ok(
    lives { cpev->ssystem('/bin/true') },
    'Program is not an executable absolute path.'
);

is( cpev->ssystem("/bin/true"), 0, q[ssystem( "/bin/true" ) == 0] );
isnt( my $status_false = cpev->ssystem("/bin/false"), 0, q[ssystem( "/bin/false" ) != 0] );

is( cpev->ssystem(qw{ /bin/echo 12345}), 0, q[ssystem( "echo 12345" ) == 0] );

my $out = cpev->ssystem_capture_output("/bin/true");
is $out, {
    status => 0,
    stdout => [],
    stderr => [],
  },
  q[ssystem_capture_output( "/bin/true" )]
  or diag explain $out;

$out = cpev->ssystem_capture_output("/bin/false");
is $out, {
    status => $status_false,
    stdout => [],
    stderr => [],
  },
  q[ssystem_capture_output( "/bin/false" )]
  or diag explain $out;

$out = cpev->ssystem_capture_output(qw{/bin/echo 12345});
is $out, {
    'status' => 0,
    'stderr' => [],
    'stdout' => ['12345']
  },
  q[ssystem_capture_output( "/bin/echo 12345" )]
  or diag explain $out;

$out = cpev->ssystem_capture_output( qw{ /bin/echo -e }, 'a\nb\nc' );
is $out, {
    'status' => 0,
    'stderr' => [],
    'stdout' => [
        'a',
        'b',
        'c'
    ]
  },
  q[ssystem_capture_output( echo -e 'a\nb\nc' )]
  or diag explain $out;

done_testing();
exit;
