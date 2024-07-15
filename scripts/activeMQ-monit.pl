#!/usr/bin/perl
#
# This script can be used for monitoring an ActiveMQ JMS Broker. 
# The script will connect to the broker, place a message in the monitTestQueue 
# and then pull the message back off the queue.  
# 
# If the test is a success it will exit with a zero code. Otherwise it gives a non-zero exit.
#
# This script was modified from the script found at 
# http://it.toolbox.com/blogs/unix-sysadmin/monitoring-activemq-from-nagios-27743
#
# NOTE: you must enable stomp in activemq.xml by adding the following to the <transportConnectors> tag:
# <transportConnector name="stomp" uri="stomp://localhost:61613"/>
#
 
use strict;
use Net::Stomp;
use Text::Trim;
use Sys::HostIP qw/ip ips interfaces/;

my $time = time;
my $host = ip();
my $hostname = `hostname`;
my $queue = "/queue/monitTestQueue." . $hostname;
my $errorFile = "/var/log/activeMQ-monit-check.lasterror";

# Test if the ActiveMQ broker is running 
my $stomp = Net::Stomp->new({ 
    hostname => "$host",
    port     => "61613"
});

$stomp->connect( );

# Send test message containing $time timestamp.
$stomp->send({
    destination => "$queue",
    body        => "$time"
});

# Subscribe to messages from the $queue.
$stomp->subscribe({
    destination             => "$queue",
    'ack'                   => 'client',
    'activemq.prefetchSize' => 1
});

# Wait max 5 seconds for message to appear.
my $can_read = $stomp->can_read({ timeout => "10" });
if (!$can_read){
    logError("Unable to receive message");
}

my $success;
while ($can_read){
    # There is a message to collect.
    my $frame = $stomp->receive_frame;
    $stomp->ack( { frame => $frame } );
    my $framebody=trim($frame->body);    
    if ( $framebody eq "$time" ) {
        $success = 1;
    }
    else {
        logError("Incorrect message body; Message body should be \"$time\", but was \"$framebody\"");
    }
    
    #try the next message.  this would only occur if the previous cron job timed out
    $can_read = $stomp->can_read({ timeout => "5" });
}

if (!$success){
    logError("Unable to read the proper message body");
}

sub logError(){
    my $msg = shift;

    open (ERRFILE, ">> $errorFile");
    print ERRFILE time."\tWARNING: $msg\n";
    close (ERRFILE);

    exit(1);
}

