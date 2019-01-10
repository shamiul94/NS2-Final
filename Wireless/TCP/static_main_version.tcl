
set x_dim 500
set y_dim 500


set num_node [lindex $argv 0]

set num_col 5 
if {$num_node >= 50} {
	set num_col [expr 2*$num_col]
	puts "$num_col"
}
set num_row [expr $num_node/$num_col] 


set num_parallel_flow [lindex $argv 1]

# set num_flows $num_parallel_flow

set num_cross_flow 0
set num_random_flow 0


set cbr_size 64
set cbr_rate 11.0Mb

set packet_rate [lindex $argv 2]

set cbr_interval [expr 1.0/$packet_rate];# ?????? 1 for 1 packets per second and 0.1 for 10 packets per second

set cover_area [lindex $argv 3]

set time_duration 5 ;#50
set start_time 10 ;#100
set parallel_start_gap 1.0

set tcp_src Agent/TCP ;# Agent/TCP or Agent/TCP/Reno or Agent/TCP/Newreno or Agent/TCP/FullTcp/Sack or Agent/TCP/Vegas
set tcp_sink Agent/TCPSink ;# Agent/TCPSink or Agent/TCPSink/Sack1

set grid 0
set extra_time 10 ;#10


set val(energymodel_11)    EnergyModel     ;
set val(initialenergy_11)  1000            ;# Initial energy in Joules
set val(idlepower_11) 900e-3			;#Stargate (802.11b) 
set val(rxpower_11) 925e-3			;#Stargate (802.11b)
set val(txpower_11) 1425e-3			;#Stargate (802.11b)
set val(sleeppower_11) 300e-3			;#Stargate (802.11b)
set val(transitionpower_11) 200e-3		;#Stargate (802.11b)	??????????????????????????????/
set val(transitiontime_11) 3			;#Stargate (802.11b)


##################Protocols and models for different layers
set val(chan) Channel/WirelessChannel ;# channel type
set val(prop) Propagation/TwoRayGround ;# radio-propagation model
#set val(prop) Propagation/FreeSpace ;# radio-propagation model
set val(netif) Phy/WirelessPhy ;# network interface type
set val(mac) Mac/802_11 ;# MAC type
#set val(mac) SMac/802_15_4 ;# MAC type
set val(ifq) Queue/DropTail/PriQueue ;# interface queue type
set val(ll) LL ;# link layer type
# puts "ant1 = $ant" 
set val(ant) Antenna/OmniAntenna ;# antenna model
set val(ifqlen) 50 ;# max packet in ifq
# set val(rp) DSDV ;# routing protocol

set val(rp) AODV ;# routing protocol


####################Initialize ns
set nm my_wireless_static_nam.nam
set tr my_wireless_static_trace.tr
set topo_file my_wireless_static_topo.txt

set ns_ [new Simulator]

#####################Open required files such as trace file

set tracefd [open $tr w]
$ns_ trace-all $tracefd

set namtrace [open $nm w]
$ns_ namtrace-all-wireless $namtrace $x_dim $y_dim

set topofilename "topo.txt"
set topofile [open $topo_file "w"]

# set up topography object
set topo  [new Topography]
$topo load_flatgrid $x_dim $y_dim

$topo load_flatgrid 500 500

create-god [expr $num_row * $num_col ]

################################## coverage area

# set dist(5m)  7.69113e-06
# set dist(9m)  2.37381e-06
# set dist(10m) 1.92278e-06
# set dist(11m) 1.58908e-06
# set dist(12m) 1.33527e-06
# set dist(13m) 1.13774e-06
# set dist(14m) 9.81011e-07
# set dist(15m) 8.54570e-07
# set dist(16m) 7.51087e-07
# set dist(20m) 4.80696e-07
# set dist(25m) 3.07645e-07
# set dist(30m) 2.13643e-07
# set dist(35m) 1.56962e-07
# set dist(40m) 1.20174e-07

# append cover_area "m"

# Phy/WirelessPhy set CSThresh_ $dist($cover_area)
# Phy/WirelessPhy set RXThresh_ $dist($cover_area)


##################################



#############Set node configuration

$ns_ node-config 	-adhocRouting $val(rp) -llType $val(ll) \
					-macType $val(mac) -ifqType $val(ifq) \
					-ifqLen $val(ifqlen) -antType $val(ant) \
					-propType $val(prop)  -phyType $val(netif) \
					-channel  [new $val(chan)]  -topoInstance $topo \
					-agentTrace ON  -routerTrace OFF\
					-macTrace ON \
					-movementTrace OFF \
					-energyModel $val(energymodel_11) \
					-idlePower $val(idlepower_11) \
					-rxPower $val(rxpower_11) \
					-txPower $val(txpower_11) \
					-sleepPower $val(sleeppower_11) \
					-transitionPower $val(transitionpower_11) \
					-transitionTime $val(transitiontime_11) \
					-initialEnergy $val(initialenergy_11)


#####################Create nodes with positioning

puts "start node creation"

for {set i 0} {$i < [expr $num_row*$num_col]} {incr i} {
	set node_($i) [$ns_ node]
	$node_($i) random-motion 0       
}

set x_start [expr $x_dim/($num_col*2)];
set y_start [expr $y_dim/($num_row*2)];


set i 0;

while {$i < $num_row } {
#in same column
    for {set j 0} {$j < $num_col } {incr j} {
#in same row
	set m [expr $i*$num_col+$j];

#grid topology

    set x_pos [expr $x_start+$j*($x_dim/$num_col)];#grid settings
    set y_pos [expr $y_start+$i*($y_dim/$num_row)];#grid settings
	
	$node_($m) set X_ $x_pos;
	$node_($m) set Y_ $y_pos;
	$node_($m) set Z_ 0.0

#	puts "$m"

	puts -nonewline $topofile "$m x: [$node_($m) set X_] y: [$node_($m) set Y_] \n"
    }

    incr i;
}; 


########################Create flows and associate them with nodes

for {set i 0} {$i < [expr $num_parallel_flow]} {incr i} {
   # set udp_($i) [new Agent/UDP]
   # set null_($i) [new Agent/Null]

	set udp_($i) [new $tcp_src]
	set null_($i) [new $tcp_sink]

	$udp_($i) set class_ $i
	$udp_($i) set fid_ $i

	if { [expr $i%2] == 0} {
		$ns_ color $i Blue
	} else {
		$ns_ color $i Red
	}
} 

# puts "i= $i"

###PARALLEL FLOW

#CHNG
if {$num_parallel_flow > $num_col} {
	set num_parallel_flow $num_col
}

for {set i 0} {$i < $num_parallel_flow } {incr i} {
	# puts "nooooeoeoe"
	set udp_node $i
	set null_node [expr $i+(($num_col)*($num_row-1))-1];#CHNG
	# puts "udp = $udp_node && null = $null_node" 
	$ns_ attach-agent $node_($udp_node) $udp_($i)
  	$ns_ attach-agent $node_($null_node) $null_($i)
	puts -nonewline $topofile "PARALLEL: Src: $udp_node Dest: $null_node\n"
} 

#CHNG

for {set i 0} {$i < $num_parallel_flow } {incr i} {
     $ns_ connect $udp_($i) $null_($i)
}


##############Create FTP

for {set i 0} {$i < $num_parallel_flow } {incr i} {
	set ftp_($i) [new Application/FTP]
	$ftp_($i)  set packetSize_ $cbr_size
    $ftp_($i) set rate_ $cbr_rate
    $ftp_($i) set interval_ $cbr_interval
    $ftp_($i) attach-agent $udp_($i)
} 

for {set i 0} {$i < $num_parallel_flow } {incr i} {
    $ns_ at 1.0 "$ftp_($i) start"
    $ns_ at 10.0 "finish"
}


#CHNG
# for {set i 0} {$i < $num_parallel_flow } {incr i} {
# 	set cbr_($i) [new Application/Traffic/CBR]
# 	$cbr_($i) set packetSize_ $cbr_size
# 	$cbr_($i) set rate_ $cbr_rate
# 	$cbr_($i) set interval_ $cbr_interval
# 	$cbr_($i) attach-agent $udp_($i)
# } 



#CHNG
# for {set i 0} {$i < $num_parallel_flow } {incr i} {
#      $ns_ at [expr $start_time+$i*$parallel_start_gap] "$cbr_($i) start"
# }

##############################Set timings of different events

puts "flow creation complete"
#####END OF FLOW GENERATION

# Tell nodes when the simulation ends
#
for {set i 0} {$i < [expr $num_row*$num_col] } {incr i} {
    $ns_ at [expr $start_time+$time_duration] "$node_($i) reset";
}
$ns_ at [expr $start_time+$time_duration +$extra_time] "finish"
#$ns_ at [expr $start_time+$time_duration +20] "puts \"NS Exiting...\"; $ns_ halt"
$ns_ at [expr $start_time+$time_duration +$extra_time] "$ns_ nam-end-wireless [$ns_ now]; puts \"NS Exiting...\"; $ns_ halt"

$ns_ at [expr $start_time+$time_duration/2] "puts \"half of the simulation is finished\""
$ns_ at [expr $start_time+$time_duration] "puts \"end of simulation duration\""


proc finish {} {
	puts "finishing"
	global ns_ tracefd namtrace topofile nm
	#global ns_ topofile
	$ns_ flush-trace
	close $tracefd
	close $namtrace
	close $topofile
    # exec nam $nm &
    exit 0
}

#define the nodes

for {set i 0} {$i < [expr $num_row*$num_col]  } { incr i} {
	$ns_ initial_node_pos $node_($i) 4
}

####################################Run the simulation
puts "Starting Simulation..."
$ns_ run 