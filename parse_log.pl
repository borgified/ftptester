#!/usr/bin/env perl

use strict;
use warnings;

my $filename = 'output.log';
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
		#print $row;

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
				my $avg_speed = $items[3];
				$avg_speed =~ s/KB\/s//;
				my $curr_speed = $items[4];
				$curr_speed =~ s/KB\/s//;
				#convert everything to KB/s
				if($curr_speed =~ /MB\/s/){
					$curr_speed =~ s/MB\/s//;
					$curr_speed *= 1000;
				}
				if($avg_speed =~ /MB\/s/){
					$avg_speed =~ s/MB\/s//;
					$avg_speed *= 1000;
				}

				#sometimes current speed is crazy high towards the end of the upload/download
				#we'll just skip these values so our results arent skewed

				if($curr_speed >= 8000){
					next;
				}

#				print "$percent_done $avg_speed $curr_speed\n";
				if($gather_data == 1){
					my $a = [];
					push(@$a,$avg_speed);
					push(@$a,$curr_speed);
					$upload{$percent_done} = $a;

				}elsif($gather_data==2){
					my $a = [];
					push(@$a,$avg_speed);
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
	$upload_data=$upload_data."[$k,${$upload{$k}}[1]],";
}
#
#print "download data\n";
foreach my $k (sort {$a<=>$b} keys %download){
#	$download_data=$download_data."[$k,${$download{$k}}[0],${$download{$k}}[1]],";
#	prev line includes avg speed data, line below doesnt
	$download_data=$download_data."[$k,${$download{$k}}[1]],";
}


#['2004',  1000,      400],
#['2005',  1170,      460],
#['2006',  660,       1120],
#['2007',  1030,      540]



#output google line chart html

my $html = << "EOHTML";
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

<script type="text/javascript">
google.setOnLoadCallback(drawChart);

function drawChart() {
var data = google.visualization.arrayToDataTable([
['% amount of data transferred', 'current speed'],
$upload_data
]);

var options = {
title: 'Upload FTP Performance (RWC upload to FTP)',
legend: { position: 'bottom' }
};

var chart = new google.visualization.LineChart(document.getElementById('curve_chart1'));

chart.draw(data, options);
}
</script>

<script type="text/javascript"
src="https://www.google.com/jsapi?autoload={
'modules':[{
'name':'visualization',
'version':'1',
'packages':['corechart']
}]
}"></script>

<script type="text/javascript">
google.setOnLoadCallback(drawChart);

function drawChart() {
var data = google.visualization.arrayToDataTable([
['% amount of data transferred', 'current speed'],
$download_data
]);

var options = {
title: 'Download FTP Performance (RWC download from FTP)',
legend: { position: 'bottom' }
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








