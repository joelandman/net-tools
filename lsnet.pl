#!/usr/bin/env perl
# copyright 2012-2019 Joe Landman
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use Data::Utils;
use Getopt::Long;

my ($f,$dev,@devices,$cmd,$rc,@bonds,$bond,$slave_net,@slaves,$bond_nic);
my ($path,$net,@ethtool,@ip,$ipv4,$ipv6,$line,$first,@proc);
my ($bm,@dev,$kver,$kmajor,$kminor,$krel,@kv,$width_state,$width_ipaddr);
my ($width_dev,$header,$format,$width_master,$width_mtu,$width_RX,$width_TX);
my ($width_speed,@ifs);

exit if (!(-e '/sys/class/net/'));

my $csv 	 = (1==0);
my $iface  ;

GetOptions ("csv|c" => \$csv, "iface|i=s"  => \@ifs);



($kmajor,$kminor,$krel,@kv) = split(/\./,`uname -r`);
$kver=$kmajor+$kminor/100;
# grab kernel revision, because things change between releases ...

	$width_state=
	$width_ipaddr 	=
	$width_dev 	=
	$width_master	=
	$width_mtu 	=
	$width_RX 	=
	$width_TX 	= -1;
$width_speed	= 4;

chomp(@devices    = `ls /sys/class/net/ `);
foreach $dev (sort @devices) {
	 next if ((@ifs) && (grep {!/$dev/} @ifs ));
   my $_s = ($net->{$dev}->{carrier} ? "up" : "dn" );
   #$_s .= sprintf "@%iG",$net->{$dev}->{speed}/1000 if ($net->{$dev}->{speed} > 0);
   $net->{$dev}->{'state'} = $_s;
   $width_state = ( length($_s) > $width_state ? length($_s) : $width_state );

   $net->{$dev}->{'colwidth'} = length($dev);
   $width_dev = ( length($dev) > $width_dev ? length($dev) : $width_dev );

   next if ($dev =~ /bonding_masters/);
   $net->{$dev}->{state} =
          &get_sys_nic_data($dev,'operstate');
   $net->{$dev}->{carrier} =
               &get_sys_nic_data($dev,'carrier');
   $net->{$dev}->{mac} =
               &get_sys_nic_data($dev,'address');
   $net->{$dev}->{speed} =
               &get_sys_nic_data($dev,'speed');
   $net->{$dev}->{rx} =
	       &get_sys_nic_data($dev,'statistics/rx_bytes');
   $net->{$dev}->{tx} =
	       &get_sys_nic_data($dev,'statistics/tx_bytes');

   chomp(@ip = split(/\n/,`ip addr show dev $dev`));

   foreach my $line (@ip) {
       $line =~ s/\s+$//;
       $line =~ s/^\s+//;
       if ($line =~ /\<(.*?)\>\s+(.*?)\s{0,}$/) {
	  my $flags = $1;
	  my $kvps  = $2;
	  my @kvp   = split(/\s/,$kvps);
	  map {$net->{$dev}->{flag}->{$_}=1;} (split(/\,/,$flags));
	  for (my $_i=0;$_i<=$#kvp;$_i+=2) {
	      my $_x = $kvp[$_i+1];
	      my $_y = $kvp[$_i];
	      $net->{$dev}->{flags}->{$_y}=$_x;
	  }
	}
      if ($line =~ /inet\s+(.*?)\s+(.*?)\s+(.*?)\s+/) {
	push @{$net->{$dev}->{ipv4}},{addr => $1, mask => $3};
	$width_ipaddr = ( length($1) > $width_ipaddr ? length($1) : $width_ipaddr );
      }
      if ($line =~ /inet6\s+(.*?)\s+.*/) {
	push @{$net->{$dev}->{ipv6}},{addr => $1};
	$width_ipaddr = ( length($1) > $width_ipaddr ? length($1) : $width_ipaddr );
      }
    }
    if ($dev !~ /^lo$/) {
      chomp(@ethtool = split(/\n/,`ethtool -i $dev`));
      foreach my $line (@ethtool) {
	$line =~ s/\s+//g;
	my ($k,$v) = split(/:/,$line);
	$net->{$dev}->{$k}=$v
      }
      chomp(@ethtool = split(/\n/,`ethtool -P $dev`));
      foreach my $line (@ethtool) {
	$line =~ s/\s+//g;
	my ($k,$v) = split(/:/,$line,2);
	$net->{$dev}->{real_mac}=$v
      }
    }
}

foreach $dev (sort keys %{$net}) {
 $net->{$dev}->{flags}->{master}	= (defined($net->{$dev}->{flags}->{master}) ? $net->{$dev}->{flags}->{master} : "");
	$width_master = (length($net->{$dev}->{flags}->{master}) > $width_master ? length($net->{$dev}->{flags}->{master}) : $width_master );
	$width_mtu = (length($net->{$dev}->{flags}->{mtu}) > $width_mtu ? length($net->{$dev}->{flags}->{mtu}) :  $width_mtu );
}

$width_TX = $width_RX = 10;

my $p = "%";
my $pl = "";
if (!$csv) {
	   $format = sprintf "%s%is \[%s%is\] %s%is %s%is %s%is %s%is  %s%s%is  %s%s%is\n",
				$p,$width_dev,
				$p,$width_master,
				$p,$width_state,
				$p,$width_speed,
				$p,$width_ipaddr,
				$p,$width_mtu,
				$p,$pl,$width_TX,
				$p,$pl,$width_RX;
   }
 else {
    $format = "%s,%s,%s,%s,%s,%s,%s,%s\n";
}

if ($csv) {
	printf "#Device,Master,State,Speed,IP,MTU,TX,RX\n";	
}
else {
	printf $format,"DEV","MST","ST","SP","IP","MTU","TX","RX";
}

foreach $dev (sort keys %{$net}) {
  my $_st = ($net->{$dev}->{carrier} ? "up" : "dn" );
  my $_sp = ($net->{$dev}->{speed} > 0 ? sprintf "%iG",$net->{$dev}->{speed}/1000 : "");
  my $_ms = (defined($net->{$dev}->{flags}->{master}) ? $net->{$dev}->{flags}->{master} : "");
  my $_mt = (defined($net->{$dev}->{flags}->{mtu}) ? $net->{$dev}->{flags}->{mtu} : "" );
  my $_tx = $net->{$dev}->{tx};
  my $_rx = $net->{$dev}->{rx};
  my $_txs = Data::Utils->autoscale(Data::Utils->size_to_bytes($_tx),{debug => false});
	 my $_rxs = Data::Utils->autoscale(Data::Utils->size_to_bytes($_rx),{debug => false});
																		
	
  if (defined($net->{$dev}->{ipv4})) {
     foreach my $_ip (@{$net->{$dev}->{ipv4}}) {
			  printf $format,	$dev, $_ms, $_st, $_sp, $_ip->{addr}, $_mt, $_txs, $_rxs;
		  }
	}
	if (defined($net->{$dev}->{ipv6})) {
    foreach my $_ip (@{$net->{$dev}->{ipv6}}) {

      printf $format,
								$dev,
								$_ms,
								$_st,
								$_sp,
								$_ip->{addr},
								$_mt,
								$_txs,
								$_rxs;
  		}
	}
	
	if ((!defined($net->{$dev}->{ipv6})) && (!defined($net->{$dev}->{ipv4})) ) {
		
	printf $format,
								$dev,
								$_ms,
								$_st,
								$_sp,
								"",
								$_mt,
								$_txs,
								$_rxs;
	}
}

sub get_sys_nic_data {
  my ($b,$f) = @_;
  my ($fh,$data,$buf,$len);
  my $path = sprintf '/sys/class/net/%s/%s',$b,$f;
  sysopen $fh,$path,'O_RDONLY' or return undef;
  $len = sysread $fh,$buf,4096 or return undef;
  close($fh);
  return "" if ($len == 0);
  $buf =~ s/\s+$//;
  return $buf;
}

sub format_mac {
  my ($mac,$fmt) = @_;

  if ($fmt eq "default") {
    return $mac;
    }
    elsif ($fmt eq "cisco") {
      my @octants = split(":",$mac);
      $mac="";
      for(my $i=0;$i<6;$i++) {
        $mac .= $octants[$i];
        $mac .= "." if (($i % 2) && ($i != 5));
      }
      return $mac;
    }
}
