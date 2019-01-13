
#####Set Grid Size
set x_dim 500
set y_dim 500


set num_node [lindex $argv 0]
set num_flow [lindex $argv 1]
set packet_rate [lindex $argv 2]
set tx_range [lindex $argv 3]
set cbr_interval [expr 1.0/$packet_rate]
# puts "cbr_interval = $cbr_interval"
### cbr_interval == 1 for 1 packets per second and 0.1 for 10 packets per second


set num_col 5 
if {$num_node >= 50} {
	set num_col [expr 2*$num_col]
	puts "$num_col"
}

set num_row [expr $num_node/$num_col] 

set num_parallel_flow 0
set num_cross_flow 0
set num_random_flow 0


######################Set Flow Numbers

# set num_parallel_flow [expr ($num_row*$num_col)];# along column

# if {$num_parallel_flow > [expr $num_flow/2]} {
# 	set num_parallel_flow [expr $num_flow/2]
# }


# set num_cross_flow [expr $num_flow-$num_parallel_flow] 

# if {$num_cross_flow > [expr (int($num_col/2))*$num_row]} {
# 	set num_random_flow  [expr $num_cross_flow - (int($num_col/2))*$num_row]
# 	set num_cross_flow [expr (int($num_col/2))*$num_row]
# }

#########################Declaration Of Some Variables

# set cbr_type FTP
set cbr_size 16;#64
set cbr_rate 11.0Mb; #11.0Mb

# set tcp_src Agent/TCP 
# set tcp_sink Agent/TCPSink


set tcp_src Agent/UDP 
set tcp_sink Agent/Null

set grid 0

set time_duration 25 
set start_time  1
set extra_time  5

set flow_start_gap   0.1
set parallel_start_gap 0.1
set cross_start_gap 0.0
set random_start_gap 0.2


###########################Set Energy Parameter

set val(energymodel_11)    EnergyModel     ;
set val(initialenergy_11)  1000            ;# Initial energy in Joules
set val(idlepower_11) 900e-3			;#Stargate (802.11b) 
set val(rxpower_11) 925e-3			;#Stargate (802.11b)
set val(txpower_11) 1425e-3			;#Stargate (802.11b)
set val(sleeppower_11) 300e-3			;#Stargate (802.11b)
set val(transitionpower_11) 200e-3		;#Stargate (802.11b)	
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


# Mac/802_11 set syncFlag_ 1
# Mac/802_11 set dataRate_ 0.250Mb
# # Mac/802_15_4 set dataRate_ 11Mb
# Mac/802_11 set dutyCycle_ cbr_interval




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

set topofile [open $topo_file "w"]

# set up topography object
set topo  [new Topography]
$topo load_flatgrid $x_dim $y_dim


create-god [expr $num_row * $num_col ]

################################## coverage area


set dist(40m) 1.20174e-07
set dist(100m)  6.8808e-09
set dist(200m)  8.9175e-10 
set dist(300m)  1.7615e-10 
set dist(400m)  5.5735e-11 
set dist(500m)  2.2829e-11 

# puts "TxRange = $tx_range"
Phy/WirelessPhy set CSThresh_ $dist([expr $tx_range]m)
Phy/WirelessPhy set RXThresh_ $dist([expr $tx_range]m)

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



##############Some necessary Functions
# puts "cbr_interval = $cbr_interval"
proc create_FTP_App { } {
	global cbr_type cbr_size cbr_rate cbr_interval

	# set cbr_ [new Application/FTP]
	set cbr_ [new Application/Traffic/CBR]
	
	# $cbr_ set type_ $cbr_type
	$cbr_ set packetSize_ $cbr_size
	$cbr_ set rate_ $cbr_rate
	$cbr_ set interval_ $cbr_interval
	return $cbr_
}

# proc paralell_Node_No {i} {
# 	global num_row num_col

# 	set curRow [expr int($i/$num_col)]
# 	return [expr ($i%$num_col)+(($num_row-1-$curRow)*$num_col)]
# }

# proc getNodeNoForCross {i} {
# 	global num_row num_col

# 	set nodeRow [expr ($i/(int($num_col/2)))]
# 	set curColm [expr int($i%($num_col/2))]
# 	set i [expr $curColm+($nodeRow*$num_col)]
# 	return $i	
# }

# # 0->4 1->3 5->9
# # 0th row -> last row
# # 1st row -> (last-1) row
# proc cross_Node_No {i} {
# 	global num_row num_col

# 	set nodeRow [expr ($i/(int($num_col)))]
# 	set curColm [expr int($i%$num_col)]
# 	return [expr (($nodeRow+1)*$num_col-1)-$curColm]
# }


# set v 5
# set v [cross_Node_No $v]



#####################Create nodes with positioning

puts "start node creation"

for {set i 0} {$i < [expr $num_node]} {incr i} {
	set node_($i) [$ns_ node]
	# $node_($i) random-motion 0       
}

# GRID Topology

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


for {set i 0} {$i < $num_flow} {incr i} {
	set udp_($i) [new $tcp_src] ; #it's actually UDP
	set null_($i) [new $tcp_sink] ; #it's actually Null

	$udp_($i) set class_ $i
	$udp_($i) set fid_ $i

	# $udp_($i) set windowOption_ 38
	$udp_($i) set packetSize_ 40
	$udp_($i) attach $tracefd

	# $ns_ color $i Blue
	if { [expr $i%2] == 0} {
		$ns_ color $i Red
	} else {
		$ns_ color $i Blue
	}
}
###

# puts "i= $i"

###PARALLEL FLOW

#CHNG
# if {$num_parallel_flow > $num_col} {
# 	set num_parallel_flow $num_col
# }

set num_parallel_flow 0
set num_cross_flow 0
set num_random_flow $num_flow

puts "Parallel flow: $num_parallel_flow"
# set k 0

# for {set i 0} {$i < $num_parallel_flow } {incr i} {
# 	set udp_node $i
# 	set null_node [paralell_Node_No $i];#CHNG
# 	# set null_node [expr $i+(($num_col)*($num_row-1))];#CHNG
# 	$ns_ attach-agent $node_($udp_node) $udp_($k)
#   	$ns_ attach-agent $node_($null_node) $null_($k)
# 	puts -nonewline $topofile "PARALLEL: Src: $udp_node Dest: $null_node\n"
# 	incr k
# }


######++++++++++++++++++##########

# set k 0
# #CHNG
# for {set i 0} {$i < $num_parallel_flow } {incr i} {
#      $ns_ connect $udp_($k) $null_($k)
# 	 incr k
# }

# set k 0
# #CHNG
# for {set i 0} {$i < $num_parallel_flow } {incr i} {
# 	set cbr_($k) [create_FTP_App]
# 	$cbr_($k) attach-agent $udp_($k)
# 	incr k
# }


# set k 0
# #CHNG
# for {set i 0} {$i < $num_parallel_flow } {incr i} {
#      $ns_ at [expr $start_time+$i*$parallel_start_gap] "$cbr_($k) start"
# 	 incr k
# }


####################################CROSS FLOW
# along row 1st -> last
# set num_cross_flow 0

puts "Cross flow: $num_cross_flow"

# #CHNG
# set k $num_parallel_flow
# #CHNG
# for {set i 0} {$i < $num_cross_flow } {incr i} {
# 	set udp_node [getNodeNoForCross $i];#CHNG
# 	set null_node [cross_Node_No $udp_node];#CHNG
# 	# set null_node [expr ($i+1)*$num_col-1];#CHNG
# 	$ns_ attach-agent $node_($udp_node) $udp_($k)
#   	$ns_ attach-agent $node_($null_node) $null_($k)
# 	puts -nonewline $topofile "CROSS: Src: $udp_node Dest: $null_node\n"
# 	incr k
# } 

# #CHNG
# set k $num_parallel_flow
# #CHNG
# for {set i 0} {$i < $num_cross_flow } {incr i} {
# 	$ns_ connect $udp_($k) $null_($k)
# 	incr k
# }
# #CHNG
# set k $num_parallel_flow
# #CHNG
# for {set i 0} {$i < $num_cross_flow } {incr i} {
# 	set cbr_($k) [create_FTP_App]
# 	$cbr_($k) attach-agent $udp_($k)
# 	incr k
# }

# #CHNG
# set k $num_parallel_flow
# #CHNG
# for {set i 0} {$i < $num_cross_flow } {incr i} {
# 	$ns_ at [expr $start_time+$i*$cross_start_gap] "$cbr_($k) start"
# 	incr k
# }

##################--------------------------###############


# ======================= Random flow =========================
# set num_random_flow 0
puts "Random flow: $num_random_flow"

set k [expr $num_parallel_flow+$num_cross_flow]
# assign agent to node
for {set i 0} {$i < $num_random_flow} {incr i} {
	set source_number [expr int($num_node*rand())]
	set sink_number [expr int($num_node*rand())]

	while {$sink_number==$source_number} {
		set sink_number [expr int($num_node*rand())]
	}

	$ns_ attach-agent $node_($source_number) $udp_($k)
  	$ns_ attach-agent $node_($sink_number) $null_($k)

	puts -nonewline $topofile "RANDOM:  Src: $source_number Dest: $sink_number\n"
	incr k
}


set k [expr $num_parallel_flow+$num_cross_flow] ; #k is set to '0'
# Creating packet generator (CBR) for source node
for {set i 0} {$i < $num_random_flow } {incr i} {

	# set cbr_($k) [create_FTP_App]
	# $cbr_($k) attach-agent $udp_($k)
	# # $ns_ at $start_time "$cbr_($k) start"
	# incr k

	set cbr_($k) [new Application/Traffic/CBR]
	
	# $cbr_($k) set type_ $cbr_type
	$cbr_($k) set packetSize_ $cbr_size
	$cbr_($k) set rate_ $cbr_rate
	$cbr_($k) set interval_ $cbr_interval
	$cbr_($k) attach-agent $udp_($k)
	# $ns_ at $start_time "$cbr_($k) start"
	incr k
}


set k [expr $num_parallel_flow+$num_cross_flow]
for {set i 0} {$i < $num_random_flow } {incr i} {
	$ns_ at $start_time "$cbr_($k) start"
	incr k
}

set k [expr $num_parallel_flow+$num_cross_flow]
# Connecting udp_node & null_node
for {set i 0} {$i < $num_random_flow } {incr i} {
     $ns_ connect $udp_($k) $null_($k)
	incr k
}
# =============================================================




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