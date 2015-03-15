#!/usr/bin/env perl

use strict;
use warnings;

my $filename = 'output.log';
open(my $fh,'<',$filename) or die "couldn't open $filename $!";

my $count=0;

my $gather_data=0;

while(defined(my $row = <$fh>)){
	chomp $row;
	$row =~ s/\r/\n/g;
#	print $count++." $row";

	if($gather_data){
		#print $row;
		$gather_data=0;

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
				#we'll just skip these values as well so our results arent skewed
				
				if($curr_speed > (2*$avg_speed)){
					next;
				}

				print "$percent_done $avg_speed $curr_speed\n";
			}
		}	
	}

	if($row =~ /(Fetching|Uploading) .* to .*/){
		$gather_data=1;
	}

}	
