#!/usr/bin/perl
use strict;
use warnings;

# modules
use Net::Twitter::Lite::WithAPIv1_1;
use JSON;
use LWP::UserAgent;
use SQLite::DB;
 my $db = SQLite::DB->new('twitterlinks');
$db->connect;
use DBI;

my $dbfile = 'twitterlinks';
my $tid=1;
my $tcounter=0;
my $ucounter=0;
my $url="";
my $username="";		
open (my $logfile, '>>twitterlinks.log');

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", '', '') or die "Cannot connect: $DBI::errstr";

 #my $stmt ="drop table if exists urlcache; ";
 #$db->exec($stmt) || print $db->get_error."\n";
 
 my $stmt ="create table if not exists urlcache (first text, final text, last_usage datetime NULL)";
 $db->exec($stmt) || print $db->get_error."\n";
 
 $stmt ="create unique index if not exists ux_uc on urlcache (first, final )";
 $db->exec($stmt) || print $db->get_error."\n";
 
# $stmt="drop table if exists urls";
# $db->exec($stmt) || print $db->get_error."\n";
 
 $stmt="create table if not exists urls (url text , first_seen datetime, value real, last_seen, tweet_id int, maxvalue real)";
  $db->exec($stmt) || print $db->get_error."\n";
  $stmt="create unique index if not exists ux_u on urls (url)";
  $db->exec($stmt)|| print $db->get_error."\n";
  $stmt="delete from urls where last_seen < strftime('%s','now','-6500 hour')";
  $db->exec($stmt)|| print $db->get_error."\n";
  $stmt="delete from urlcache where last_usage < strftime('%s','now','-1300 hour')"; 
  $db->exec($stmt)|| print $db->get_error."\n";

my %config= do 'twitter_config.pl';
 
 my $nt = Net::Twitter::Lite::WithAPIv1_1->new(
      consumer_key        => $config{consumer_key},
      consumer_secret     => $config{consumer_secret},
      access_token        => $config{access_token},
      access_token_secret => $config{access_token_secret}, 
      ssl                 => 1,
	  authenticate => 1
  );


$stmt="select max(tweet_id) tid from urls ";
my $result = $db->select_one_row($stmt)  || print $db->get_error."\n";
if (defined $result){$tid=$$result{tid}};

#use Data::Dumper; print Dumper($tid);

my $statuses =   eval { $nt -> list_statuses({slug =>"pirat", owner_screen_name =>"Gernot_Koepke", 
	  since_id =>$tid, count=>2000, include_rts => 1} )};
	   print $@ ;
 #use Data::Dumper; print Dumper( $statuses);
    for my $status ( @$statuses ) {
		$tcounter=$tcounter+1;
		$username="";
		$url="";
	    while( my ($k, $v) = each %$status ) {
		        if ($k eq "user"){
			while (my ($kk, $vv)= each %$v){
			if ($kk eq "screen_name"){
			$username=$vv;
			#use Data::Dumper; print Dumper($username);
			}}}
        if ($k eq "entities"){
			while (my ($kk, $vv)= each %$v){
			if ($kk eq "urls"){
	
			my $vv2=@$vv[0];
				while (my ($kkk,$vvv)= each %$vv2){
				if ($kkk eq "expanded_url"){#print "key3: $kkk, value: $vvv.\n";   

		$stmt="select final from urlcache where first=?";
		my $result = $db->select_one_row($stmt,$vvv);

		if (defined $result){$url=$$result{final}};
		if ($url eq ""){ 
				my $ua = LWP::UserAgent->new();
				$ua->show_progress(0);
				my $response = $ua->head($vvv);
				if ( $response->is_success ) {
					$url = $response->request->uri->as_string;
				$stmt ="insert or ignore into urlcache (first, final) values (?,?) ";
				$db->exec($stmt,$vvv,$url) || print $db->get_error."\n";
		}}
		$stmt="update or ignore urlcache set last_usage =? where first=? and final=? ";
		$db->exec($stmt,time(), $vvv,$url) || print $db->get_error."\n";
		}}}}}}
		if ($url ne "" && $url ne "https://www.facebook.com/unsupportedbrowser"){
		$ucounter=$ucounter+1;
		$stmt="insert or ignore into urls (url , first_seen , value , last_seen, tweet_id,maxvalue,username) values (?,?,?,?,?,?,?)";
		$db->exec($stmt,$url,time(),1,time(),$status->{id_str},1,$username) || print $db->get_error."\n";
		if ( $db->get_affected_rows != 1){
			$stmt="update urls set value=value+1, last_seen=? where url=?";
			$db->exec($stmt, time(), $url) || print $db->get_error."\n";
		 }
		# print $url."\t".$username."\n";
		$stmt="update urls set username=? where url=? and ifnull(username,'')=''";
		$db->exec($stmt, $username, $url) || print $db->get_error."\n";		 
		 }}
 
 $stmt ="update urls set value=value*0.99";
 $db->exec($stmt)|| print $db->get_error."\n";
 
 $stmt ="update urls set maxvalue=value where value>maxvalue";
 $db->exec($stmt)|| print $db->get_error."\n";
 
 
 # print $logfile "Was starting at ".$tid." Found ".$tcounter." Tweets and ".$ucounter." Urls\n";
 
  ; 
  
