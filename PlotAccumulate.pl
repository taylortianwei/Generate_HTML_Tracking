use strict;
use Data::Dumper;

if(@ARGV < 1){
	print "perl $0 <Data to plot>\n";
	exit(0);
}
my $in=shift;

open IN,$in;
my $Date; my $BaseNum; my $mc; my $Q30;
my %Time2Data; my %Machines;
my %sum; my %ave;
my @machines=("Zebra01","Zebra02","Zebra03","Panda01","Panda02");
while(<IN>){
	my @line=split;
	if(/^Machine/){
		for(my $i=0;$i<@line;$i++){
			if($line[$i] eq "Date"){
				$Date=$i;
			}elsif($line[$i] eq "BaseNum"){
				$BaseNum=$i;
			}elsif($line[$i] eq "Q30"){
				$Q30 = $i;
			}elsif($line[$i] eq "Machine"){
				$mc=$i;
			}
		}
	}else{
		$sum{All}+=$line[$BaseNum];
		$sum{$line[$mc]}+=$line[$BaseNum];
		$Time2Data{$line[$Date]}=$sum{All};
		foreach my $mcc(@machines){
			$sum{$mcc}=0 unless $sum{$mcc};
			$Machines{$line[$Date]}{$mcc}=$sum{$mcc};
		}
	}
}

$in=~s/\/.*?$//;
open O,">$in/ForAccumulate.xls";
my $ToOut= "Date\tMachine\tBaseNum\n";

foreach (sort keys %Time2Data){
	my $tt=$Machines{$_};
	$ToOut.="$_\tAll\t$Time2Data{$_}\n";
	foreach my $mc(@machines){
		$tt->{$mc}=0 unless $tt->{$mc};
		$ToOut.="$_\t$mc\t$tt->{$mc}\n";
	}
}
print O "$ToOut";
close O;

my $BegDate="2018-03-22";
my $EndDate="2018-07-08";

my %McSet=(
"Zebra01" => "2017-08-05",
"Zebra02" => "2017-11-08",
"Zebra03" => "2018-02-08",
"Panda01" => "2018-08-26",
"Panda02" => "2019-02-06",
);

open R,">$in/ForAccumulate.R";
print R "
library(data.table)
library(ggplot2)

wd<-\"$in/\"
InName <- paste0(wd,\"ForAccumulate.xls\")
pdf(file=paste0(wd,\"AccumulateData.pdf\"),width = 10, height = 6)
mydata <- read.table(InName,sep=\"\\t\",header=T)
mydata\$Date <- as.POSIXct(as.POSIXlt(as.Date(mydata\$Date) ,format=\"%Y-%M-%D\",tz = \"GMT\"))

mindate<-as.POSIXct(\"2017-07-10\")
maxdate<-max(mydata\$Date)

mydata[mydata==0]<-NA
SUM<- sum(mydata\$BaseNum)/1000

ggplot(mydata[!is.na(mydata\$BaseNum),],aes(x=Date,y=BaseNum,color=Machine,group=Machine)) + 
  geom_line(na.rm=TRUE) +
  scale_x_datetime(expand=c(0,0),
                   date_breaks= \"60 days\", 
                   date_labels = \"%m/%y\", 
                   limits = as.POSIXct(c(mindate, maxdate))) +

  annotate(\"rect\", xmin = labMv, xmax = labMvend, ymin = ".$Time2Data{$BegDate}.", ymax = ".$Time2Data{$EndDate}.", alpha = .2) +
  annotate(\"text\", x = labMv, y = ".$Time2Data{$BegDate}." - 1000, hjust=\"left\",label = \"Lab move and renovation\",size=2.5) +

  #ggtitle(paste0(\"All Sequencers Data = \",round(SUM,2),\" Tbases\")) +
  theme(axis.title = element_text(size=14,face=\"bold\"), axis.text = element_text(size=10)) +
  theme(legend.position=\"none\")

";



