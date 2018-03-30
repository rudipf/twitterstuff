#!/usr/bin/perl
use strict;
use warnings;

# modules
use Net::Twitter::Lite::WithAPIv1_1;
use JSON;
use LWP::UserAgent;
use SQLite::DB;
use Date::Parse;
 
  
 my $db = SQLite::DB->new('twitterlinks');
$db->connect;
use DBI;

my $dbfile = 'twitterlinks';

my $intro="<a href=twitterlinks.html>aktuell</a> \n<a href=twitterlinks_woche.html>Wochensicht</a> \n <a href=twitterlinks_monat.html>Monatssicht</a> \n <a href=twitterlinks_all.html>Alles in der DB</a>\n <a href=twitterlinks_piraten.html>Stichwort Piraten</a> \n";

&dohtml("/var/www/twitterlinks/twitterlinks.html",36,"value",$intro);
&dohtml("/var/www/twitterlinks/twitterlinks_woche.html",180,"maxvalue",$intro);
&dohtml("/var/www/twitterlinks/twitterlinks_monat.html",756,"maxvalue",$intro);
&dohtml("/var/www/twitterlinks/twitterlinks_all.html",10000,"maxvalue",$intro);
&dohtml("/var/www/twitterlinks/twitterlinks_piraten.html",360,"value",$intro,"'%piraten%'");


sub dohtml {
my $myhtmldoc = $_[0];
my $hours = $_[1];
my $sortcol =$_[2];
my $intro =$_[3];
my $pattern=$_[4];
my $stmt="";

open (my $myhtml,">",$myhtmldoc);
print $myhtml "";
close ($myhtml);

open ($myhtml,">>",$myhtmldoc);
print $myhtml '<!doctype html>';
print $myhtml '<html><head>';
print $myhtml '<title>URL Sturm der Menschen auf twitter.com/Gernot_Koepke/lists/pirat Code by @RudiPf</title>';
print $myhtml '<script src="sorttable.js"></script>';
print $myhtml '<style>';
print $myhtml 'table.sortable th:not(.sorttable_sorted):not(.sorttable_sorted_reverse):not(.sorttable_nosort):after { content: " \25B4\25BE"}';
print $myhtml '</style></head>';

print $myhtml "<body>";

print $myhtml $intro."\n";

print $myhtml "<table class='sortable'>";
print $myhtml "<thead><tr><th>Tweeted By</th><th>Url</th><th>Aktuell</th><th>Max</th><th>Zuletzt</th></tr></thead><tbody>";

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", '', '') or die "Cannot connect: $DBI::errstr";

if($pattern){
$stmt="select url , first_seen , value , datetime(last_seen,'unixepoch','localtime'), tweet_id, maxvalue,ifnull(username,'') from urls where url like ".$pattern." and last_seen > strftime('%s','now','-".$hours." hour') order by ".$sortcol." desc,last_seen desc limit 500";
}else{
$stmt="select url , first_seen , value , datetime(last_seen,'unixepoch','localtime'), tweet_id, maxvalue,ifnull(username,'') from urls where last_seen > strftime('%s','now','-".$hours." hour') order by ".$sortcol." desc,last_seen desc limit 500";
}

my $sth = $dbh->prepare($stmt);
$sth->execute;
my  $hash_ref = $sth->fetchall_arrayref;
  
# my $result=$dbh->select($stmt) || print $db->get_error."\n";
# use Data::Dumper; print Dumper( $hash_ref);

for my $tid (@$hash_ref){
	#use Data::Dumper; print Dumper( $tid);
	#use Data::Dumper; print Dumper( @$tid[5]);
	if(@$tid[6] eq ""){
	print $myhtml "<tr><td></td>";
	}else{
	print $myhtml "<tr><td><a href=https://twitter.com/".@$tid[6]."/status/".@$tid[4].">".@$tid[6]."</a></td>";
	}
	
	
	print $myhtml "<td><a href=".@$tid[0].">".substr(@$tid[0],index (@$tid[0],"://")+3,100)."</a></td>";
	
	print $myhtml "<td>".sprintf("%.2f",@$tid[2])."</td>";
	print $myhtml "<td>".sprintf("%.2f",@$tid[5])."</td>";

	print $myhtml "<td>".@$tid[3]."</td>";
	
	print $myhtml "</tr>\n";
	}
print $myhtml "</table></body>";
close ($myhtml);
}

