use strict;
use Data::Dumper;
use POSIX;
use File::Path;
use FindBin;
use JSON::XS qw(encode_json decode_json);
use File::Slurp qw(read_file write_file);

my $tempdir="$FindBin::Bin/";
my $tempfile="$tempdir/StoreFeatureExternal.hash";

my $json=read_file($tempfile, { binmode => ':raw' });
my %Feature=%{ decode_json $json };
#print Dumper %html;
print Dumper %Feature;

my %LineOrder=(
"ReadNum" => ["ReadNum","Standard Line"],
"BaseNum" => ["BaseNum","Standard Line"],
"Q20" => ["read total","Standard Line"],
"Q30" => ["read total","Standard Line"],
"estError" => ["read total","Standard Line"],
"signal" => ["A","C","G","T"],
"background" => ["A","C","G","T"],
"snr" => ["A","C","G","T"],
"rho" => ["A","C","G","T"],
"runon" => ["A","C","G","T","AVG"],
"lag" => ["A","C","G","T","AVG"],
"movement" => ["A_X","A_Y","T_X","T_Y"],
"baseTypeDist" => ["A","C","G","T","N"],
"gcDist" => ["read total"],
"qual" => ["read total"],
"qualPortion" => ["[0-10)","[10-20)","[20-30)","[30-40]"],
);

my %CutOff=
(
"ReadNum" => 1.35/4,
"BaseNum" => 1.35/4,
"Q20" => 90,
"Q30" => 80,
"estError" => 1,
);

my %Title=
(
"ReadNum" => "Reads Number Generated(bn)",
"BaseNum" => "Bases Number Generated(bn)",
"Q20" => "Q20(%)",
"Q30" => "Q30(%)",
"estError" => "Error Rate Estimation",
"signal" => "Intensity of All DNBs",
"background" => "Background Intensity",
"snr" => "SNR",
"rho" => "RHO Intensity",
"runon" => "Runon",
"lag" => "Lag",
"movement" => "Offset by Cycles",
"baseTypeDist" => "Bases Distribution",
"gcDist" => "GC Distribution",
"qual" => "Average Quality Distribution",
"qualPortion" => "Quality Proportion Distribution"
);

my %XTitle=(
"ReadNum" => "Data per Run",
"BaseNum" => "Lane",
"Q20" => "Lane",
"Q30" => "Lane",
"estError" => "Lane",
"signal" => "Lane",
"background" => "Lane",
"snr" => "Lane",
"rho" => "Lane",
"runon" => "Lane",
"lag" => "Lane",
"movement" => "Lane",
"baseTypeDist" => "Lane",
"gcDist" => "Lane",
"qual" => "Lane",
"qualPortion" => "Lane",
);

my %YTitle=(
"ReadNum" => "Total Bases(bn)",
"BaseNum" => "Total Reads(bn)",
"Q20" => "Percentage(%)",
"Q30" => "Percentage(%)",
"estError" => "Error Rate(%)",
"signal" => "Raw Intensity(T3_35)",
"background" => "Background",
"snr" => "SNR",
"rho" => "RHO Intensity",
"runon" => "Percentage(%)",
"lag" => "Percentage(%)",
"movement" => "Offset",
"baseTypeDist" => "Percentage(%)",
"gcDist" => "Percentage(%)",
"qual" => "Quality",
"qualPortion" => "Percentage(%)",
);

my %FigOrder=(
"Part1" => ["ReadNum","Q20","Q30","estError"],
"Part2" => ["signal","rho","background","snr","runon","lag","baseTypeDist","gcDist","qual","qualPortion"]
);

my @DataSource=("ReadNum","BaseNum","Q20","Q30","estError");

my %Feature=(
"LineOrder" => \%LineOrder,
"CutOff" => \%CutOff,
"Title" => \%Title,
"XTitle" => \%XTitle,
"YTitle" => \%YTitle,
"FigOrder" => \%FigOrder,
"DataSource" => \@DataSource
);

$json = encode_json \%Feature;
write_file($tempfile, { binmode => ':raw' }, $json);
