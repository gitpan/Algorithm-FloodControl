#! perl
use warnings;
use strict;

use Algorithm::FloodControl::Backend::Cache::FastMmap;
my $be = "Algorithm::FloodControl::Backend::Cache::FastMmap";
use Cache::FastMmap;
use Test::More tests => 5;
use File::Temp;
my $temp_file = File::Temp->new->filename;
my $c = $be->new(
    {
        storage   => new Cache::FastMmap( { share_file => $temp_file } ),
        expires => 5,
        prefix  => 'test_queue'
    }
);
my $oldsize = $c->size;
$c->increment;
is( $c->size, $oldsize + 1, 'append/size' );
$c->increment;
is( $c->size, $oldsize + 2, 'yet another' );
sleep 3;
$c->increment;
sleep 3;
is( $c->size, 1, 'expiring' );
ok( $c->clear, 'clearing' );

foreach ( 1 .. 15 ) {
    if ( !fork ) {

        my $sub_cache = $be->new(
            {
                storage   => new Cache::FastMmap ( { share_file => $temp_file } ),
                expires => 60,
                prefix  => 'test_queue'
            }
        );
        foreach ( 1 .. 100 ) {
            $sub_cache->increment;
        }
        exit;
    }
}
1 while ( waitpid -1, 0 ) != -1;
is( $c->size, 1500, 'concurrency' );
