#!/usr/bin/perl 

# faucetad.pl [faucet auto downloader]
# v. 0.3 [20080921] http://marcosiviero.org/blog
# GPL 2 License

# Instructions:
# Set only variables below and then put this script in your crontab.
#
# Changelog:
# v 0.3: [ADD] Email to user when directory space is terminate
# v 0.2: [ADD] User can set max space used for files download
# v 0.1: First version [20080419]


##### PLEASE, SET THESE VARIABLES #####
#my $feed="http://www.vcast.it/JPodcast/Vfaucet/vfs26/10/abcdefghilmnopqrst12345"; #EXAMPLE
my $feed="";
#my $dir=/home/caruso/download"; #EXAMPLE
my $dir="";
#my $maxspace="5"; # EXAMPLE 
my $maxspace="15"; # Set MAX Occupied Space in that directory in GigaBytes

## MAIL SETTINGS
my $myemail='usermail@provider.com';
my $from='faucetad@donotreply.com';
my $subject="No more space in your faucet directory!";
my $body="hello, this is an auto generated email from faucetad script.\n Your space in faucet's directory is terminated and your recordings cannot be downloaded, please review your settings.";


#######################################
#### PLEASE, DO NOT TOUCH FROM HERE ####
#######################################
$tmp="/tmp";
$instance=faucetad;
$sentmail="/tmp/faucet.mail.sent.tmp";

# CHECK IF THE PROGRAM IS RUNNING #
my $lock="$tmp/$instance";
if (-e $lock) { print "Another instance is running! bye bye...\n"; exit 1; }

open LOCKFILE, ">$lock" or die " Unable to create lockfile, exiting !";
close (LOCKFILE);

my $faucetfeed="faucet.rss";

# CHECK DISK SPACE #
$realoccspace=`du -s $dir | cut -f1 | sed 's/[MGKB]//'`;
$maxspaceGB=$maxspace*1024*1024;
if ($realoccspace >= $maxspaceGB) {
	print "Error: MAX used space reach on directory: ($maxspace GB), delete some files or set a different value.\n";
	$sendmailbin="/usr/sbin/sendmail";
	if( (-e $sendmailbin) && (! -e $sentmail) ){
		sendEmail( "$myemail","$from","$subject","$body" );
		open SENTMAIL, ">$sentmail";
		close (SENTMAIL);
	}
	unlink "$tmp/$instance";
	exit 1;
}
else{
unlink "$sentmail";
}

# FEED DOWNLOAD #
`wget -q $feed -O $dir/$faucetfeed`;

# FEED INTO ARRAY #
open READ, "<$dir/$faucetfeed";
@rss=(<READ>);
close READ;
# GET URI FROM FEEDS #
foreach $rss(@rss) {
        if ($rss =~ /url=.(http:\W+\w+\W\w+\W\w+\W\w+\W\w+\W\w+\W\w+\W\w+\W\w+\W\w+)/) {
                ($url[$i])=$1;
                $i++;
        }
        if ($rss =~ /url=.http:\W+\w+\W\w+\W\w+\W\w+\W\w+\W\w+\W\w+\W\w+\W(........)/) {
                ($date[$j])=$1;
                $j++;
        }
        if ($rss =~ /title.(.+)</ && $rss !~ "Faucet at Vcast -") {
                ($name[$z])=$1;
                $name[$z]=~s/\s/_/g;
                $name[$z]=~s/\(//g;
                $name[$z]=~s/\)//g;
                $z++;
        }
        if ($rss =~ /url=.http:\W+\w+\W\w+\W\w+\W\w+\W\w+\W\w+\W\w+\W\w+\W\d+\w+(....)/) {
                ($ext[$e])=$1;
                $e++;
        }
        if ($rss =~ /<author>(.*)</) {
                ($channel[$c])=$1;
                $c++;
        }
}


# DOWNLOAD VIDEO #
$last=$#name;


open DOWN, "<$dir/downloaded";
@downloaded=(<DOWN>);
close DOWN;

open FILE, "+>> $dir/downloaded";
for ($i=0; $i<=$last; $i++) {
        $found=0;
        chomp $url[$i];
        foreach $downloaded(@downloaded) {
                chomp $downloaded;
                if ($url[$i] eq $downloaded){
                        $found=1;
                }
        }
        if ($found == 0){
                $brand="$name[$i]_$channel[$i]_$date[$i]$ext[$i]";
                system "wget -q $url[$i] -O $dir/$brand"; 
                print FILE "$url[$i]\n";
        }
}

close (FILE);

unlink "$tmp/$instance";

##### Functions #####
# SendEmail
# ($to, $from, $subject, $message)
sub sendEmail
{
my ($to, $from, $subject, $message) = @_;
my $sendmail = '/usr/sbin/sendmail';
open(MAIL, "|$sendmail -oi -t");
print MAIL "From: $from\n";
print MAIL "To: $to\n";
print MAIL "Subject: $subject\n\n";
print MAIL "$message\n";
close(MAIL);
}


