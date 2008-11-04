#! perl
use warnings;
use strict;

my $be = "Algorithm::FloodControl::Backend::Cache::Memcached::Fast";
use Test::More;
BEGIN {
    eval { require Cache::Memcached::Fast };
    if ( $@ ) {
        plan skip_all => 'Cache::Memcached::Fast is required for this test';
    }
    require Algorithm::FloodControl::Backend::Cache::Memcached::Fast;
}
if ( !$ENV{MEMCACHED_SERVER} ) {
    plan skip_all => '$ENV{MEMCACHED_SERVER} is not set';
}
plan tests => 5;

my $c = $be->new(
    {
        storage   => new Cache::Memcached::Fast( { servers => [ $ENV{MEMCACHED_SERVER} ] } ),
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
                storage   => new Cache::Memcached::Fast( { servers => [ $ENV{MEMCACHED_SERVER} ] } ),
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
