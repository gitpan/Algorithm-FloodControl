##############################################################################
#
#  Algorith::FloodControl
#  Vladi Belperchinov-Shabanski "Cade" <cade@biscom.net> <cade@datamax.bg>
#  $Id: FloodControl.pm,v 1.1 2004/02/29 03:39:24 cade Exp $
#
#  DISTRIBUTED UNDER GPL! SEE `COPYING' FILE FOR DETAILS
#
##############################################################################
package Algorithm::FloodControl;
use strict;
use Carp;
use Exporter;
our @ISA = qw( Exporter );
our $VERSION = '1.00';
our @EXPORT = qw(
                flood_check
                flood_storage
                );

our %FLOOD = ();

sub flood_check
{
  my $fc = shift; # max flood events count
  my $fp = shift; # max flood time period for $fc events
  my $en = shift; # event name (key) which identifies flood check data
  
  if( $en eq '' )
    {
    my ( $p, $f, $l ) = caller; # construct event name by:
    $en = "$p:$f:$l";           # package + filename + line
    # print STDERR "EN: $en\n";
    }
  
  $FLOOD{ $en } ||= [];   # make empty flood array for this event name
  my $ar = $FLOOD{ $en }; # get array ref for event's flood array
  my $ec = @$ar;          # events count in the flood array
  
  if( $ec >= $fc ) 
    {
    # flood array has enough events to do real flood check
    my $ot = $$ar[0];      # oldest event timestamp in the flood array
    my $tp = time() - $ot; # time period between current and oldest event
    
    # now calculate time in seconds until next allowed event
    my $wait = int( ( $ot + ( $ec * $fp / $fc ) ) - time() );
    if( $wait > 0 )
      {
      # positive number of seconds means flood in progress
      # event should be rejected or postponed
      # print "WARNING: next event will be allowed in $wait seconds\n";
      return $wait;
      }
    # negative or 0 seconds means that event should be accepted
    # oldest event is removed from the flood array
    shift @$ar;
    }
  # flood array is not full or oldest event is already removed
  # so current event has to be added
  push  @$ar, time();
  # event is ok
  return 0;
}

sub flood_storage
{
  if( @_ )
    {
    croak "flood_storage sub requires hash reference as single argument" 
        unless ref( $_[0] ) eq 'HASH';
    %FLOOD = %{ $_[0] };
    }
  return \%FLOOD;
}

1;

=pod

=head1 NAME

Algorithm::FloodControl - Limit event processing to count/time ratio.

=head1 SYNOPSIS

  use Algorithm::FloodControl;

  my $wait = flood_check( 5, 60, 'FLOOD EVENT NAME' );

  if( $wait )
    {
    print "Please wait $wait sec. before requesting this resource again.";
    }
  else
    {
    print "Ok, here you are.";
    }  

=head1 DESCRIPTION

"Flood control" method is used to restrict the number of events to happen or 
to be processed in specific perion of time. Few examples are: web server can 
limit requsets number to a page or you may want to receive no more than 10 SMS 
messages on your GSM Phone per hour. Applications of this method are unlimited.

=head1 FUNCTIONS

This module exports several functions:

=over 4

=item flood_check( $count, $time, $event_name )

This function is the core of the module. It receives 3 arguments: maximum event 
count, maximum time period (in seconds) for this event count and finally the event 
name. There is internal storage so flood_check() can track several events by name.

Third argument could be omitted. In this case the event name will be constructed
from the package name, file name and line number from the calling point. However
this is not recommendet unless you need it for very simple program.

The return value is time in seconds that this event must wait to be processed
or 0 if event can be processed immediately.

=item flood_storage( <$ref> )

If you want to save and restore the internal storage (for example for cgi use),
you can get reference to it with flood_storage() function which returns this
reference and it can be stored with other module like FreezeThaw or Storable.
When restoring you must pass the storage reference as single argument to
flood_storage().

=back

=head1 EXAMPLE

CGI script is very usefull as example because it has all elements of
Algorithm::FloodControl use:

  #!/usr/bin/perl
  use strict;
  use Storable qw( store retrieve ); # used to save/restore the internal data
  use LockFile::Simple qw( lock unlock ); # used to lock the data file
  use Algorithm::FloodControl;
  
  my $flood_file = "/tmp/flood-cgi.dat";
  
  lock( $flood_file );                                   # lock the storage
  my $FLOOD = retrieve( $flood_file ) if -r $flood_file; # read storage data
  flood_storage( $FLOOD ) if $FLOOD;                     # load storage 
  my $wait = flood_check( 5, 60, 'FLOOD TEST CGI' );     # check for flood
  store( flood_storage(), $flood_file );                 # save storage data
  unlock( $flood_file );                                 # unlock the file
  
  print "Content-type: text/plain\n\n";
  if( $wait )
    {
    print "Please wait $wait seconds before requesting this page again.\n";
    exit;
    }
  print "Hello, this is main script here\n";

This example is just one of very large number of cases where flood control can
be useful. I used it in IRC bots, email notifications, web site updates, etc.

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"

  <cade@biscom.net> <cade@datamax.bg> <cade@cpan.org>

  http://cade.datamax.bg

=head1 VERSION

  $Id: FloodControl.pm,v 1.1 2004/02/29 03:39:24 cade Exp $

=cut
