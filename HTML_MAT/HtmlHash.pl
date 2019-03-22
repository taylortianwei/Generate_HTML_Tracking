use strict;
use Data::Dumper;
use POSIX;
use File::Path;
use FindBin;
use JSON::XS qw(encode_json decode_json);
use File::Slurp qw(read_file write_file);

my $tempdir="$FindBin::Bin/";

my $json=read_file("$tempdir/StoreHtml.hash", { binmode => ':raw' });
my %Html=%{ decode_json $json };

print Dumper %Html;

#$json = encode_json \%Html;
#write_file("$tempdir/StoreHtml.hash", { binmode => ':raw' }, $json);
