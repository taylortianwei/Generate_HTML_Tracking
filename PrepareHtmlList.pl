use strict;
use Data::Dumper;
use POSIX;
use File::Path;
use FindBin;
use JSON::XS qw(encode_json decode_json);
use File::Slurp qw(read_file write_file);

my $Bin=$FindBin::Bin;
my $StoreHash="$Bin/HTML_MAT/StoreHtml.hash";

my %html;my $json;
$json=read_file($StoreHash, { binmode => ':raw' });
%html = %{ decode_json $json };
#print Dumper %html;

if(@ARGV < 1){
	print "perl $0 <CSV dir>\n";
	exit(0);
}
my $record=shift;

my $datadir="/share";

opendir D_R,$record || die "$!";

foreach my $ff(readdir D_R){
	next unless $ff=~/^(Zebra\d+)\_(CL\d+)\_.*\.csv$/i or $ff=~/^(Panda\d+)\_(V\d+)\_.*\.csv$/i;
	my($zebra,$flowcell)=($1,$2);

	open II,"$record/$ff";
	my $RunName; my $RunDate;
	while(<II>){
		chomp; s/\s+$//g;
		my @a=split(/\,/,$_);

		if ($a[0] eq "Run Name"){
			$RunName=$a[2];
			next;
		}elsif($a[0] eq "SequencingDate"){
			$RunDate=$a[1];
			next;
		}
		$RunDate="2017-12-01";
		next unless $a[5]=~/$flowcell\_(L\d+)\_(.*)/ and $a[0]=~/^1|2|3|4/;
		my $lane="L0".$a[0];
		next if $html{$zebra}{$flowcell."\_".$lane};	
print join("\t",localtime(),"NEW ADD",$zebra,$flowcell,$lane),"\n";

		unless ($a[12]){
			if($ff=~/badrun|BAD RUN|BAD_RUN/){
				$a[12]= "BADRUN";
			}else{
				$a[12]="COMPLETE";
			}
		}
		if($a[12] eq "COMPLETE" or $a[12] eq "BADRUN_COMPLETE"){
			print "Warning: Runs complete but no 'Run Name' for $ff\n" unless $RunName;
		}else{
			$html{$zebra}{$flowcell."_".$lane}=$RunDate;
			next;
		}

		my $mc_type=$zebra; $mc_type=~s/\d+$//;

		my $file;
		if($mc_type eq "Panda"){
			$file="$datadir/$mc_type"."Data01"."/$zebra/$flowcell/$lane/$flowcell\_$lane.summaryReport.html";
		}else{
			$file="$datadir/$mc_type"."Data01"."/$zebra/$flowcell/$lane/$RunName\_$flowcell\_$lane.summaryReport.html"
		}

		if(-e $file){
			$html{$zebra}{$flowcell."_".$lane}=$file;	
		}else{
			$file=~s/Data01/Data00/;
			if(-e $file){
				$html{$zebra}{$flowcell."_".$lane}=$file;
			}else{
				opendir DD,"$datadir/$mc_type"."Data00"."/$zebra/$flowcell/$lane/";
				my $check=0;
				foreach my $ff(readdir DD){
                        		if ($ff=~/summaryReport\.html/){
                                		$html{$zebra}{"$flowcell\_$lane"}="$datadir/$mc_type"."Data00"."/$zebra/$flowcell/$lane/$ff";
						$check=1;
                        		}
				}
				opendir DD,"$datadir/$mc_type"."Data01"."/$zebra/$flowcell/$lane/";
                                foreach my $ff(readdir DD){
                                        if ($ff=~/summaryReport\.html/){
                                                $html{$zebra}{"$flowcell\_$lane"}="$datadir/$mc_type"."Data01"."/$zebra/$flowcell/$lane/$ff";
                                                $check=1;
					}
                                }
				$html{$zebra}{$flowcell."_".$lane}=$RunDate if $check ==0;
			}
		};
	}
}
close D_R;

# Save the %html to a file
$json = encode_json \%html;
write_file($StoreHash, { binmode => ':raw' }, $json);
