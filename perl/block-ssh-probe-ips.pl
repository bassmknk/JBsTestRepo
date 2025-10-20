#!/usr/bin/perl

## Script for parsing sshd disconnects logged by failed attemps. If
## there are over a desired amount of attempts in the current day & hour,
## collect and log the message and summary data. Then create & run & blacklist
## iptables rule. Also adds the rule to a black-list script
##
## Created 02-08-2009 by JB (bassmknk@gmail.com)
## OMG, code change in 2015! renamed and modified to use journalctl

## Call perl mods:
use Getopt::Std;
use Time::localtime;

# Make sure option/tag values are set to default (0)

$debug=0;
$reportonly=0;
$num_months=0;
$lsthour=0;
$tday=0;
$runiptabcmd=0;
$matchcnt=0;
$iprulechk=0;
$iptabchk=0;
$maxmatchcnt=5;

#Check options
getopts("drhlm:t");
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
#if ($opt_m) { $num_months=$opt_m; }

if ($opt_t)
   {
   $tday=1;
   }


#Set timestamps
$datestring=`date +"%M %D %H"`; 

# Set directories and commands.
$basedir="/root/sshd-abuse";
$bindir="$basedir/bin/";
$logdir="$basedir/log/";
$etcdir="$basedir/etc/";
$runlogfile="$logdir"."blacklist-sshd-log";

$errstr="Received disconnect from";

#### $sysiptabfile="/etc/sysconfig/iptables";
#### $saveiptabcmd="/etc/init.d/iptables save";
#$mailaddrs="bassmknk\@gmail.com 6502241547\@txt.att.net";

$fwcmd="firewall-cmd --permanent --zone=\"FedoraWorkstation\" --add-rich-rule=\'rule family=\"ipv4\" source address=\"XXXXXXX\" reject\'";
$mailaddrs="bassmknk\@gmail.com";
$mailsubj="sshd attack detected: $days[$wday] $months[$mon] $mday $hour";
$mailer="/usr/bin/Mail -s \"$mailsubj\" $mailaddrs";

# No longer having to read the /var/log/messages file for ssh errors. Data now comes from journalctl
# firewall commands are now dealt with though firewall-cmd. 
# First get the default firewall zone
$fw_default_zone=`firewall-cmd --get-default-zone`;

if ($debug) {
   print "basedir: $basedir\n";
   print "mailer: $mailer\n";
   print "firewall-cmd default zone: $fw_default_zone\n";
}

@ssh_jctl_data = `journalctl --since yesterday -u sshd.service`;
foreach $line ( @ssh_jctl_data )
      {
	if ($line =~/^(\w+\s+\w+).*sshd\[\d+\]: $errstr ((\d+\.){3}\d+):.*/)
           {
	      #if ($debug) { print "Line Match: $line"; }
	      $matchcnt++;
		if (exists($iparray{$2})) {
		   $iparray{$2}++;
		} else {
		   $iparray{$2} = 1;
		}
		#if (exists($iparray{$1})) {
		#   $iparray{$1}++;
		#} else {
		#   $iparray{$1} = 1;
		#}
               
           }  
      }


#
## Start actions here if the match count is more then the defined limit:
#

if ($matchcnt >= $maxmatchcnt) 
   {
    $summary="\nsshd attack details:\n";
    foreach my $ipaddr (reverse sort { $iparray{$a} <=> $iparray{$b} } keys %iparray)
          { 

	  # If the specific IP is under the max attempt limit 
	  # log a warning.
	  if ( $iparray{$ipaddr} < $maxmatchcnt )
             {
	      printf "Warning - Probes Detected: %-15s Attempts: %s\n", $ipaddr, $iparray{$ipaddr};
	      #printf "%-15s %s\n", Warning - ssh probe detected: $ipaddr, "Attempts: ", $iparray{$ipaddr};
	      next;
	     } 
             
	  $summary="$summary" . "$ipaddr  Attempts: $iparray{$ipaddr}\n";
          }
   $summary="$summary" . "\nTotal sshd erreors found: $matchcnt\n";
   print "$summary";
   }



          ## Dont create logs if in debug/report mode
#	  if (!$reportonly && !$debug) 
#             {
#	      $iplogfile="$logdir"."$k-log";
#    	      open(IPLOGFILE, ">$iplogfile");
#	      print IPLOGFILE "$ipdata{$k}";
#	      close(IPLOGFILE);
#             }
#
#          # See if the IP exists in the iptables file or active rules.
#	  $iptabchk=`grep -c $k $sysiptabfile`;
#	  $iprulechk=`/sbin/iptables -L INPUT -n | grep -c $k `;
#
#	  # If the IP is active in iptables make sure it is in the 
#          # iptables file. 
#	  if ( $iprulechk != "0") 
#	     { 
#	      print "Warning: $k is active in iptables.\nChecking iptables file.. ";
#
#	      if ("$iptabchk" == "0") 
#		 { 
#		   print "marked for add.\n";
#		   $runiptabcmd=1;
#		 } else { print "[OK]\n"; }
#
#	      next;
#	     }
# 
#	 $blacklistcmd="/sbin/iptables -A INPUT -s $k  -j DROP";
#	 if ($debug) { print "Created Rule: $blacklistcmd\n";}
#	 ## Dont add rule if in debug/report mode
#	 if (!$reportonly && !$debug) 
#	    { 
#             system($blacklistcmd); 
#	    }
#	 if ($debug) { print "Setting: $saveiptabcmd\n";}
#	 $runiptabcmd=1;
#
#
#	  } # End hash while loop
#
#   if ($runiptabcmd = 1) 
#      {
#      if (!$reportonly && !$debug) {`$saveiptabcmd`;}
#      }
#
#   print "Summary Info:\n"."$summary";
#
#   # Send Mail with summary data and update/create log files 
#   # (non report/debug)
#   if (!$reportonly && !$debug )
#      {
#       open(NOTIFY, "|$mailer");
#       print NOTIFY "Summary Info:\n"."$summary"; 
#       close (NOTIFY);
#
#      }
#   } # End matchcnt if statement 
#
#if (!$reportonly && !$debug)
#   {
#    open(RUNLOG, ">> $runlogfile");
#    print RUNLOG "$0: $nowtime: $matchcnt sshd events detected\n"; 
#    close(RUNLOG);
#   }
#
#
