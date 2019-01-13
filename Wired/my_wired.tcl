#create an ns ofject

set ns    [new Simulator]

#create and open trace file
set tr wired.tr 
set nm wired.nam 


set tracefile [open $tr w]
$ns trace-all $tracefile

set namfile [open $nm w]
$ns namtrace-all $namfile

set file1 [open qm.out w]

#taking inputs from shell 

set num_node [lindex $argv 0]
set num_flows [lindex $argv 1]
set packet_rate [lindex $argv 2] 
#packet_rate = packet per second

set cbr_size 64
set cbr_rate 11.0Mb
set cbr_interval [expr 1.0/$packet_rate]

set grid_x_dim 500 
set grid_y_dim 500


#Creating nodes
puts "starting node creation..."

for {set i 0} {$i < $num_node} {incr i} {
	set node_($i) [$ns node]
}

#creating edges in a grid-like way

puts "Creating Edges between the nodes..."


for {set i 0} {$i < $num_node} {incr i} { 

    set right [expr $i + 1]
    set down [expr $i + 10]

    set val [expr $i % 10]


    if {$val != 9} {
        $ns duplex-link $node_($i) $node_($right) 5Mb 2ms DropTail

        set qmon [$ns monitor-queue $node_($i) $node_($right) $file1 0.1]
        [$ns link $node_($i) $node_($right)] queue-sample-timeout
    }

    if {$down < [expr $num_node-1]} {
        $ns duplex-link $node_($i) $node_($down) 5Mb 2ms DropTail

        set qmon [$ns monitor-queue $node_($i) $node_($down) $file1 0.1]
        [$ns link $node_($i) $node_($down)] queue-sample-timeout

    }

    
}

###
# set qmon [$ns monitor-queue $node_(2) $node_(3) $file1 0.1]
# [$ns link $node_(2) $node_(3)] queue-sample-timeout

###

#Create flows and associate them with nodes

for {set i 0} {$i < $num_flows} {incr i} {
    
    set tcp_($i) [new Agent/TCP]
    # $tcp_($i) set windowOption_ 38
	$tcp_($i) set class_ $i
    $tcp_($i) set fid_ $i

	set tcpsink_($i) [new Agent/TCPSink]
	
	if { [expr $i%2] == 0} {
		$ns color $i Blue
	} else {
		$ns color $i Red
	}
    
} 


for {set i 0} {$i < $num_flows} {incr i} { 

    set t [expr (rand() * $num_node)]
    set tt [expr int($t)]

    set t1 [expr (rand() * $num_node)]
    set tt1 [expr int($t1)]

    set src_no [expr $tt % $num_node]
    set sink_no [expr $tt1 % $num_node]
    
    while {$src_no == $sink_no} {
        set t [expr (rand() * $num_node)]
        set tt [expr int($t)]

        set t1 [expr (rand() * $num_node)]
        set tt1 [expr int($t1)]

        set src_no [expr $tt % $num_node]
        set sink_no [expr $tt1 % $num_node]

    }

    # puts "src_no = $src_no && sink_no = $sink_no"

    $ns attach-agent $node_($src_no) $tcp_($i)
  	$ns attach-agent $node_($sink_no) $tcpsink_($i)
}


for {set i 0} {$i < $num_flows } {incr i} {
     $ns connect $tcp_($i) $tcpsink_($i)
}

#######Creating FTP Traffic

for {set i 0} {$i < $num_flows } {incr i} {
	set ftp_($i) [new Application/FTP]
    $ftp_($i)  set packetSize_ $cbr_size
    $ftp_($i) set rate_ $cbr_rate
    $ftp_($i) set interval_ $cbr_interval
    $ftp_($i) attach-agent $tcp_($i)

} 

for {set i 0} {$i < $num_flows } {incr i} {
    $ns at 1.0 "$ftp_($i) start"
    $ns at 10.0 "finish"
}

#######Creating CBR Traffic

# for {set i 0} {$i < $num_flows } {incr i} {
# 	set cbr_($i) [new Application/Traffic/CBR]
# 	$cbr_($i) set packetSize_ $cbr_size
# 	$cbr_($i) set rate_ $cbr_rate
    
# 	$cbr_($i) set interval_ $cbr_interval
# 	$cbr_($i) attach-agent $tcp_($i)
# } 


# for {set i 0} {$i < $num_flows } {incr i} {
#      $ns at 1 "$cbr_($i) start"
# }

##############################Set timings of different events

puts "flow creation complete"
#####END OF FLOW GENERATION

# Tell nodes when the simulation ends
#
for {set i 0} {$i < [expr $num_node] } {incr i} {
    $ns at 11.5 "$node_($i) reset";
}
$ns at 12 "finish"
#$ns_ at [expr $start_time+$time_duration +20] "puts \"NS Exiting...\"; $ns_ halt"
$ns at 12.5 "$ns nam-end-wireless [$ns now]; puts \"NS Exiting...\"; $ns halt"



#finish procedure

proc finish {} {
    puts "finishing"
    
    global ns tr nm  namfile tracefile 
    $ns flush-trace
    close $namfile
    close $tracefile
    # exec nam $nm &
    exit 0
}


$ns run

