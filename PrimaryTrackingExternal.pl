use strict;
use Data::Dumper;
use POSIX;
use File::Path;
use FindBin;
use JSON::XS qw(encode_json decode_json);
use File::Slurp qw(read_file write_file);

my $tempdir="$FindBin::Bin/HTML_MAT";

if(@ARGV < 2){
	die "perl $0 <Outdir> <Machine1,Machine2...>\n";
}
my $json=read_file("$tempdir/StoreHtml.hash", { binmode => ':raw' });
my %html = %{ decode_json $json };
$json=read_file("$tempdir/StoreFeatureExternal.hash", { binmode => ':raw' });
my %Feature=%{ decode_json $json };
#print Dumper %html;

my $OutDir=shift; $OutDir=~s/\/$//;
mkpath($OutDir) unless -e ($OutDir);

my @machines=split(/\,/,$ARGV[0]);

my @Lths=(50,100,125,150);

my ($FH,$BI)=&get_hash(\%html,\@machines,\%Feature);
#print Dumper @machines;
#print Dumper $FH;

open O1,">$OutDir/".join("_",@machines).".html";

#step1 output head and basic information;
my $output=&Templete("$tempdir/templete_P1.txt");
my $now=`date "+%F"`;chomp $now;

$output.="
        // Basic Information

        var colorType = \"is4Color\";
        var reportTitle = \"Tracking of ".join("_",@machines)."\";
        var reportTime = \"$now\";

        ";

my $Items;
my $I=$Feature{YTitle};
foreach my $tmpkey(@{$Feature{FigOrder}{Part1}}){

	my $record=$Feature{Title}{$tmpkey}; $record=~s/\s/\_/g;

        my $ToPrint="
        var $tmpkey = {";

	my $tmphash=$FH->{$tmpkey};
	my $LineOrder=$Feature{LineOrder}{$tmpkey};
        foreach my $key(@$LineOrder,"xTag"){
		
                $ToPrint.=&OutVar($tmphash->{$key},$BI->{reportTime},$key);
        }
        $ToPrint=~s/\,$/\n\t\}\;\n/;
        $output.= $ToPrint;

}
open O, ">$OutDir/DataSource.xls";
print O &OutRecord($FH,$BI,\%Feature);
close O;

#step3 output drawing information
$output.=&Templete("$tempdir/templete_P2.txt").
&OutFun(\%Feature,"Part1","Basic Quality Information").
"
;;;;window.onresize=function(){q();};
</script>\n</body>\n</html>
";

print O1 "$output\n";



sub get_hash
{
my $html=shift;
my $mcs=shift;
my $Feature=shift;
my $FigHash;
my $BasicInfo;

foreach my $mc(@$mcs){
    my $subhtml=$html->{$mc};
    foreach my $file(keys %$subhtml){
	my ($flowcell,$lane)=split(/\_/,$file);
	$BasicInfo->{Machine}{$flowcell}=$mc;
    	if($subhtml->{$file}=~/html$/){
	    open (F,$subhtml->{$file}) || die "can't open file $subhtml->{$file}\n";
	    while(<F>){
	        chomp;
	        last if /\/\/\s*VALUES\s*END/;

                next unless s/^\s+var\s+//;
                my @c=split(/\=\s+/,$_);
      	        if($c[0]=~/reportTime/){ ## Tables
                    $c[1]=~s/\"|\'|\s|\;//g; $c[0]=~s/\s//g;
                    $BasicInfo->{reportTime}{$flowcell}=$c[1];
		}elsif($c[0]=~/readType/){
		    $c[1]=~s/\"|\'|\s|\;//g; $c[0]=~s/\s//g;
		    $BasicInfo->{$c[0]}{$flowcell}=$c[1];
                }elsif($c[0]=~/summaryTable\s/){
                    my @matches = ($c[1] =~ /\[(.*?)\]/g);
                    for(my $i=1;$i<@matches;$i++){
                        $matches[$i]=~s/\'|\s//g;
                        my @LineCt=split(/\,/,$matches[$i]);
                        if($LineCt[0] eq "CycleNumber"){
                            $BasicInfo->{ReadLength}{$flowcell}=&CheckLength($LineCt[1],@Lths);
			    $BasicInfo->{CycleNumber}{$flowcell}=$LineCt[1];
                        }
	            }
                }elsif($c[0]=~/fqTable\s/){
                    $c[0]=~s/\s//g;$c[1]=~s/\"|\'//g;
                    my @matches = ($c[1] =~ /\[(.*?)\]/g);
                    my @LineName=split(/\,\s+/,$matches[0]);
		    if($BasicInfo->{readType}{$flowcell} eq "PE"){
			for(my $i=1;$i<@matches;$i++){
			    my @LineCt=split(/\,\s+/,$matches[$i]);
			    for(my $j=1;$j<@LineCt;$j++){
                                $LineName[$j]=~s/\(|\)|\%//g;
                                if($LineName[$j] eq "Q30" or $LineName[$j] eq "Q20"){
				    next unless $LineCt[0] eq "read total";
                                    push @{$FigHash->{$LineName[$j]}{$LineCt[0]}{$flowcell}},$LineCt[$j];
                                    $FigHash->{$LineName[$j]}{"Standard Line"}{$flowcell}=$Feature->{CutOff}{$LineName[$j]};
                                    $FigHash->{$LineName[$j]}{"xTag"}{$flowcell}="\"$flowcell $BasicInfo->{reportTime}{$flowcell}\"";
                                }elsif($LineName[$j] eq "ReadNum" or $LineName[$j] eq "BaseNum"){
                                    next unless ($LineCt[0] eq "read total");
                                    $FigHash->{$LineName[$j]}{$LineName[$j]}{$flowcell}+=$LineCt[$j]/1000000000;
                                    $FigHash->{$LineName[$j]}{"Standard Line"}{$flowcell}=$Feature->{CutOff}{$LineName[$j]};
                                    $FigHash->{$LineName[$j]}{"xTag"}{$flowcell}=join("","\"",$flowcell," ",$BasicInfo->{reportTime}{$flowcell},"\"");
                                }
                            }
			}
		    }else{
			my @LineCt=split(/\,\s+/,$matches[1]);
			for(my $j=1;$j<@LineCt;$j++){
                            $LineName[$j]=~s/\(|\)|\%//g;
                            if($LineName[$j] eq "Q30" or $LineName[$j] eq "Q20"){
				push @{$FigHash->{$LineName[$j]}{"read total"}{$flowcell}},$LineCt[$j];
                                $FigHash->{$LineName[$j]}{"Standard Line"}{$flowcell}=$Feature->{CutOff}{$LineName[$j]};
                                $FigHash->{$LineName[$j]}{"xTag"}{$flowcell}="\"$flowcell $BasicInfo->{reportTime}{$flowcell}\"";
                            }elsif($LineName[$j] eq "ReadNum" or $LineName[$j] eq "BaseNum"){
                                $FigHash->{$LineName[$j]}{$LineName[$j]}{$flowcell}+=$LineCt[$j]/1000000000;
                                $FigHash->{$LineName[$j]}{"Standard Line"}{$flowcell}=$Feature->{CutOff}{$LineName[$j]};
                                $FigHash->{$LineName[$j]}{"xTag"}{$flowcell}=join("","\"",$flowcell," ",$BasicInfo->{reportTime}{$flowcell},"\"");
                            }
                        }
		    }
                }elsif($c[0]=~/gcDist\s|estError\s|qual\s/){ ## Figures
                    $c[0]=~s/\s//g;
                    $c[1]=~/\"(.*?)\"\:\s\[(.*?)\]/;
                    my ($Nm,$Ct)=($1,$2);
                    my @numbers=split(/\,\s+/,$Ct);
                    my $Temp=\@numbers;
                    my $Lth=$BasicInfo->{ReadLength}{$flowcell};
                    if($BasicInfo->{readType}{$flowcell} eq "PE"){
		        push @{$FigHash->{$c[0]}{"read total"}{$flowcell}},(&CalCovAvg($Temp,1..$Lth)+&CalCovAvg($Temp,$Lth+1..2*$Lth))/2;
		    }else{
		        push @{$FigHash->{$c[0]}{"read total"}{$flowcell}},&CalCovAvg($Temp,1..$Lth);
		    }
                    $FigHash->{$c[0]}{"Standard Line"}{$flowcell}=$Feature->{CutOff}{$c[0]} if $Feature->{CutOff}{$c[0]};
                    $FigHash->{$c[0]}{"xTag"}{$flowcell}="\"$flowcell $BasicInfo->{reportTime}{$flowcell}\"";
#		}elsif($c[0]=~/background\s|snr\s|rho\s|runon\s|lag\s|movement\s|baseTypeDist\s|qualPortion\s|signal\s/){
#		    $c[0]=~s/\s//g;
#		    my @matches = ($c[1] =~ /\"(.*?)\"\:\s\[(.*?)\]/g);
#		    for(my $i=0;$i<scalar(@matches);$i+=2){
#                        my @numbers=split(/\,\s+/,$matches[$i+1]);
#			$FigHash->{$c[0]}{$matches[$i]}{$file}=&CalCovAvg(\@numbers,1..$#numbers);
#			$FigHash->{$c[0]}{"xTag"}{$file}="\"$file $BasicInfo->{reportTime}{$file}\"";;
#		    }
		}
            }
	}
    }
}
return ($FigHash,$BasicInfo);
}

sub OutVar
{
	my ($tmphash,$bi,$key)=@_;

        my $output="
	\"$key\": [";
        foreach my $flowcell(sort {$bi->{$a} cmp $bi->{$b} or $a cmp $b} keys %$tmphash){
#print sum(@{$tmphash->{$flowcell}})/@{$tmphash->{$flowcell}},"\n";
#               	$output.= sum(@{$tmphash->{$flowcell}})/@{$tmphash->{$flowcell}}.", ";
		if($key eq "xTag" or $key eq "Standard Line" or $key eq "ReadNum" or $key eq "BaseNum"){
			$output.= $tmphash->{$flowcell}.", ";
		}else{
			$output.= &CalCovAvg(\@{$tmphash->{$flowcell}},1..scalar(@{$tmphash->{$flowcell}})).", ";
		}
        }
        $output=~s/\,\s*$/],/; 
	return $output;
}

sub OutFun
{
        my ($feature,$part,$name)=@_;

        my $output="
var $part = {
  \"name\":\"$name\",
  \"data\":[
";
	foreach my $fig(@{$feature->{FigOrder}{$part}}){
		$output.="
    [\"line\",\"$feature->{Title}{$fig}\",$fig,
    {
        \"series\":[";
		my $series;
		foreach my $lin(@{$feature->{LineOrder}{$fig}}){
			$series.="\"$lin\",";
		}
		$series=~s/\,$/\]\,/;
		$output.=$series."
      \"xTitle\":\"$feature->{XTitle}{$fig}\",\"yTitle\":\"$feature->{YTitle}{$fig}\"
    }],";
	}
	$output=~s/\,$/\n  \]\n\}\;/;
	$output.="
o(\"reportBody\",$part,'True');
";
        return $output;
}

sub OutRecord
{
	my $ToPrint=shift;
	my $BI=shift;
	my $Feature=shift;
        my %record;
	my $out="Machine\tFlowcell\tDate";
	my $num;
	
	foreach my $key(@{$Feature->{DataSource}}){
		my $tmd=$Feature->{$key};
		foreach my $k(@{$Feature->{LineOrder}{$key}}){
			my $count;
			next if ($k eq "xTag" or $k eq "Standard Line");
			my $SubHash=$ToPrint->{$key}{$k};
			$out.="\t".$key;

			foreach my $flowcell(sort {$BI->{reportTime}{$a} cmp $BI->{reportTime}{$b} or $a cmp $b} keys %$SubHash){
				$count++;
				if($k eq "ReadNum" or $k eq "BaseNum"){
					$record{$flowcell}.="\t".sprintf("%.2f",$SubHash->{$flowcell});
				}else{
					$record{$flowcell}.="\t".sprintf("%.2f",&CalCovAvg(\@{$SubHash->{$flowcell}},1..scalar(@{$SubHash->{$flowcell}})));
				}
				$num->{$flowcell}=$count;
			}
		}
	}
	$out.="\n";
	foreach my $j(sort {$num->{$a}<=>$num->{$b} or $a cmp $b} keys %record){
		my @kkk=split(/\_/,$j);
		$out.=join("\t",$BI->{Machine}{$j},@kkk,$BI->{reportTime}{$j}).$record{$j}."\n";
	}
	return $out;
}

sub CheckLength
{
	my $lth=shift;
	my @array=@_;
	
	my $min=10000; my $k;
	for(my $i=0;$i<@array;$i++){
		if(abs($lth/2-$array[$i]) < $min){
			$min=abs($lth/2-$array[$i]);
			$k=$i;
		}
	}
	return $array[$k];
}
sub Templete
{
	my $in=shift;
	open I,$in;
	
	my $c;
	while(<I>){
		$c.=$_;
	}
	return $c;
}

sub CalCovAvg
{
	my $array=shift;
	my @mem=@_;

	my $sum;
	foreach my $c(@mem){
		$sum+=$array->[$c-1];
	}
	return $sum/scalar(@mem);
}

sub split_str1
{
	my $in=shift;
	my $sub_hash;
	my @matches = ($in =~ /\[(.*?)\]/g);
	foreach my $cc(@matches){
		$cc=~s/\[|\]//g;
		my @cc=split(/\s*\,\s*/,$cc);
		$sub_hash->{$cc[0]}=$cc[1];
	}
	return $sub_hash;
}
sub split_str2
{
        my $in=shift;
        my $sub_hash;
        my @matches = ($in =~ /\[(.*?)\]/g);
	$matches[0]=~s/\[|\]//g; $matches[1]=~s/\[|\]//g;
	for(my $i=1;$i<@matches;$i++){
                my @k=split(/\s*\,\s*/,$matches[$i]);
                push @{$sub_hash->{$k[0]}},@k[1..$#k];
        }
        return $sub_hash;
}
sub split_str3
{
	my $in=shift;
        my $sub_hash;
        my @matches = ($in =~ /\[(.*?)\]/g);
	for(my $i=1;$i<6;$i++){
		my @k=split(/\s*\,\s*/,$matches[$i]);
		push @{$sub_hash->{"Reads1.".$k[0]}},@k[1..$#k];
	}
	if(@matches > 5){
		for(my $j=7;$j<@matches;$j++){
			my @k=split(/\s*\,\s*/,$matches[$j]);
			push @{$sub_hash->{"Reads2.".$k[0]}},@k[1..$#k];
		}
	}
	return $sub_hash;
}
sub split_str4
{
        my $in=shift;
        my $sub_hash;
        my @matches = ($in =~ /(\w+\s*\:\s*\[.*?\]|\[\d+\-\d+\]\s*\:\s*\[.*?\]|\[\d+\-\d+\)\s*\:\s*\[.*?\])/g);
	my @cont;
	foreach (@matches){
		my @tmp_nm=split(/\s*\:\s*/,$_);
		my @number=($tmp_nm[1] =~ /(\-*\d+\.*\d+)\s*/g);
		$cont[0].="\t$tmp_nm[0]";
		foreach (my $i=0; $i<@number; $i++){
			$cont[$i+1].="\t$number[$i]"
		}
	}
	$sub_hash="Pos".$cont[0]."\n";
	for (my $i=1; $i<@cont; $i++){
		$sub_hash.="$i".$cont[$i]."\n";
	}
	return $sub_hash;
}
