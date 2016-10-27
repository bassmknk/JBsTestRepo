#!/usr/bin/perl

## Script for parsing sshd disconnects logged by failed attemps. If
## there are over a desired amount of attempts in the current day & hour,
## collect and log the message and summary data. Then create & run & blacklist
## iptables rule. Also adds the rule to a black-list script
##
## Modified 10-27-2016 by JB (bassmknk@gmail.com)

## Call perl mods:
use Getopt::Std;
use Time::localtime;

# Make sure option/tag values are set to default (0)

$debug=0;
$reportonly=0;
$lsthour=0;
$moonly=0;
$tday=0;
$runiptabcmd=0;
$matchcnt=0;
$iprulechk=0;
$iptabchk=0;
$maxmatchcnt=10;

#Check options
getopts("drhlmt");
if ($opt_d) 
   { 
    print "Debug Set\n";
    $debug=1;
   }
if ($opt_r) 
   { 
    print "Report Only Set\n";
    $reportonly=1;
   }
if ($opt_h)
   {
    print "$0: [-r] [-d] [-l] [-h]\n";
    exit 0;
   }
if ($opt_l)
   {
   $lsthour=1;
   }
if ($opt_m)
   {
   $moonly=1;
   }
if ($opt_t)
   {
   $tday=1;
   }


#Set timestamps
$nowtime=ctime(); 
$monumber=localtime->mon;
$todaydate=localtime->mday;
$scanhr=localtime->hour;
@monames = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
if ( $todaydate =~ /^\d$/) { $todaydate=" $todaydate"; }
if ( $lsthour ) { $scanhr=$scanhr-1; }
if ( $scanhr =~ /^\d$/) { $scanhr="0$scanhr"; }
if ( $moonly ) { $timestamp = "$monames[$monumber]"; }
   elsif ( $tday ) { $timestamp="$monames[$monumber] $todaydate"; }
   else  { $timestamp="$monames[$monumber] $todaydate $scanhr:"; }

# Set directories and commands.
$basedir="/root/sshd-abuse";
$bindir="$basedir/bin/";
$logdir="$basedir/log/";
$etcdir="$basedir/etc/";
$runlogfile="$logdir"."blacklist-sshd-log";
$vlmlogfile="/var/log/messages";
$errstr="Received disconnect from";
$sysiptabfile="/etc/sysconfig/iptables";
$saveiptabcmd="/etc/init.d/iptables save";
#$mailaddrs="bassmknk\@gmail.com 6502241547\@txt.att.net";
$mailaddrs="bassmknk\@gmail.com";
$mailsubj="sshd attack detected: $timestamp";
$mailer="/usr/bin/Mail -s \"$mailsubj\" $mailaddrs";

if ($debug) {
	     print "timestamp: $timestamp\n";
	     print "basedir: $basedir\n";
	     print "mailer: $mailer\n";
	    }

open (VLM, "$vlmlogfile" || die "Can not open $vlmlogfile: $!");

while ($vlmline = <VLM>)

	{
        # Match lines that are for the defined time stamp, Also match sshd 
	# label and procid, error string, and IP address. 

	if ($vlmline =~/^$timestamp.*sshd\[\d+\]: $errstr ((\d+\.){3}\d+):.*/)
	   {
		if ($debug) { print "Match: $vlmline"; }
		$matchcnt++; 
		if (exists($iparray{$1})) {
		   $iparray{$1}++;
		} else {
		   $iparray{$1} = 1;
		}
		$ipdata{$1}=$ipdata{$1}."$vlmline";
	   }
        # Any other stuff can be parsed out of VLM here
	}


# Start actions here if the match count is more then the defined limit:

if ($debug) {print "sshd erreors found: $matchcnt\n";}
if ($matchcnt >= $maxmatchcnt) 
   {
    $summary="Total sshd erreors found: $matchcnt\n";
    while (($k,$v) = each(%iparray))
          { 

	  # If the specific IP is under the max attempt limit 
	  # log a warning.
	  if ( $v < $maxmatchcnt )
             {
	      print "Warning: $k Attempts: $v\n";
	      next;
	     } 
             
	  $summary="$summary $k  Attempts: $v\n";

          ## Dont create logs if in debug/report mode
	  if (!$reportonly && !$debug) 
             {
	      $iplogfile="$logdir"."$k-log";
    	      open(IPLOGFILE, ">$iplogfile");
	      print IPLOGFILE "$ipdata{$k}";
	      close(IPLOGFILE);
             }

          # See if the IP exists in the iptables file or active rules.
	  $iptabchk=`grep -c $k $sysiptabfile`;
	  $iprulechk=`/sbin/iptables -L INPUT -n | grep -c $k `;

	  # If the IP is active in iptables make sure it is in the 
          # iptables file. 
	  if ( $iprulechk != "0") 
	     { 
	      print "Warning: $k is active in iptables.\nChecking iptables file.. ";

	      if ("$iptabchk" == "0") 
		 { 
		   print "marked for add.\n";
		   $runiptabcmd=1;
		 } else { print "[OK]\n"; }

	      next;
	     }
 
	 $blacklistcmd="/sbin/iptables -A INPUT -s $k  -j DROP";
	 if ($debug) { print "Created Rule: $blacklistcmd\n";}
	 ## Dont add rule if in debug/report mode
	 if (!$reportonly && !$debug) 
	    { 
             system($blacklistcmd); 
	    }
	 if ($debug) { print "Setting: $saveiptabcmd\n";}
	 $runiptabcmd=1;


	  } # End hash while loop

   if ($runiptabcmd = 1) 
      {
      if (!$reportonly && !$debug) {`$saveiptabcmd`;}
      }

   print "Summary Info:\n"."$summary";

   # Send Mail with summary data and update/create log files 
   # (non report/debug)
   if (!$reportonly && !$debug )
      {
       open(NOTIFY, "|$mailer");
       print NOTIFY "Summary Info:\n"."$summary"; 
       close (NOTIFY);

      }
   } # End matchcnt if statement 

if (!$reportonly && !$debug)
   {
    open(RUNLOG, ">> $runlogfile");
    print RUNLOG "$0: $nowtime: $matchcnt sshd events detected\n"; 
    close(RUNLOG);
   }


