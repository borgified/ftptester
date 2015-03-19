#!/usr/bin/env perl

use warnings;
use strict;

use Expect;
use IO::Pty;
use CGI qw/:standard/;


my %config = do '/secret/ftptester2.config';

sub main {

	print header;

	print << "HTMLJUNK";
<html>
<head>
<script type="text/javascript"
src="https://www.google.com/jsapi?autoload={
'modules':[{
'name':'visualization',
'version':'1',
'packages':['corechart']
}]
}"></script>
HTMLJUNK

	&run_ftptest($config{'ftp2'});
	&parse_log($config{'ftp2'});

}

&main;


sub run_ftptest {

	my $ftp = shift;

	if(system("/bin/dd if=/dev/urandom of=b.random bs=1M count=50 2>/dev/null") != 0){
		die $!;
	}

	my $exp = new Expect;
	$exp->log_stdout(0);
#$exp->raw_pty(1);
	$exp->spawn("/usr/bin/sftp $config{'username'}\@$ftp");
	unlink("output.log2");
	$exp->log_file("output.log2");

	$exp->expect(10,
		[ qr/continue connecting \(yes\/no\)\?/ => sub { $exp->send("yes\n"); } ],
	);

	$exp->expect(undef,
		[ qr/password$/ => sub { $exp->send("$config{'password'}\n"); } ],
	);


	$exp->expect(undef,
		[ qr/sftp> $/ => sub { $exp->send("cd ftptests\n"); } ],
	);
	$exp->expect(undef,
		[ qr/sftp> $/ => sub { $exp->send("put b.random\n"); } ],
	);

	$exp->expect(undef,
		[ qr/sftp> $/ => sub { $exp->send("get b.random\n"); } ],
	);

	$exp->expect(undef,
		[ qr/sftp> $/ => sub { $exp->print("quit\n"); } ],
	);

	$exp->soft_close();

#we should have output.log at this point, ready to be parsed.
}

sub parse_log{

	my $ftp = shift;

	my $filename = "output.log2";
	open(my $fh,'<',$filename) or die "couldn't open $filename $!";

	my $count=0;

	my $gather_data=0;
	my %upload;
	my %download;

	while(defined(my $row = <$fh>)){
		chomp $row;
		$row =~ s/\r/\n/g;
#	print $count++." $row";

		if($gather_data){
#			print $row;

			my @data = split (/\n/,$row);
			foreach my $line (@data){
				#skip blank lines
				#skip any - stalled - or -negative values
				if($line =~ /^$|-/){
					next;
				}else{
					my @items = split(/\s+/, $line);

					#strip %
					my $percent_done = $items[1];
					$percent_done =~ s/%//;
					my $curr_speed = $items[3];
					$curr_speed =~ s/KB\/s//;
					#convert everything to KB/s
					if($curr_speed =~ /MB\/s/){
						$curr_speed =~ s/MB\/s//;
						$curr_speed *= 1000;
					}

#				print "$percent_done $curr_speed\n";
					if($gather_data == 1){
						my $a = [];
						push(@$a,$curr_speed);
						$upload{$percent_done} = $a;

					}elsif($gather_data==2){
						my $a = [];
						push(@$a,$curr_speed);
						$download{$percent_done} = $a;
					}

				}
			}	
			$gather_data=0;

		}

		if($row =~ /Uploading .* to .*/){
			$gather_data=1;
		}
		if($row =~ /Fetching .* to .*/){
			$gather_data=2;
		}

	}



	my $upload_data;
	my $download_data;

#verify that data got stored correctly
#print "upload data\n";
	foreach my $k (sort {$a<=>$b} keys %upload){
#	print "$k @{$upload{$k}}\n";
#	$upload_data=$upload_data."[$k,${$upload{$k}}[0],${$upload{$k}}[1]],";
#	prev line includes avg speed data, line below doesnt
		$upload_data=$upload_data."[$k,${$upload{$k}}[0]],";
	}
	#
#print "download data\n";
	foreach my $k (sort {$a<=>$b} keys %download){
#	$download_data=$download_data."[$k,${$download{$k}}[0],${$download{$k}}[1]],";
#	prev line includes avg speed data, line below doesnt
		$download_data=$download_data."[$k,${$download{$k}}[0]],";
	}


#['2004',  1000,      400],
#['2005',  1170,      460],
#['2006',  660,       1120],
#['2007',  1030,      540]



#output google line chart html

	my $html = << "EOHTML";

<script type="text/javascript">
google.setOnLoadCallback(drawChart);

function drawChart() {
var data = google.visualization.arrayToDataTable([
['% amount of data transferred', 'current speed (KB/s)'],
$upload_data
]);

var options = {
title: 'speed vs percentage of 50M file transferred (RWC upload to $ftp)',
legend: { position: 'bottom' }
};

var chart = new google.visualization.LineChart(document.getElementById('curve_chart1'));

chart.draw(data, options);
}
</script>

<script type="text/javascript">
google.setOnLoadCallback(drawChart);

function drawChart() {
var data = google.visualization.arrayToDataTable([
['% amount of data transferred', 'current speed (KB/s)'],
$download_data
]);

var options = {
title: 'speed vs percentage of 50M file transferred (RWC download from $ftp)',
legend: { position: 'bottom' },
};

var chart = new google.visualization.LineChart(document.getElementById('curve_chart2'));

chart.draw(data, options);
}
</script>


</head>
<body>
<div id="curve_chart1" style="width: 900px; height: 500px"></div>
<div id="curve_chart2" style="width: 900px; height: 500px"></div>
</body>
</html>

EOHTML

print $html;


}
