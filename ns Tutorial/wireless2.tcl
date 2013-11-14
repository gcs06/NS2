# ==========================================================================
# Define options
# ==========================================================================
set opt(chan)		Channel/WirelessChannel 	;# channel type
set opt(prop)		Propagation/TwoRayGround	;# radio-propagation model
set opt(ant)		Antenna/OmniAntenna			;# Antenna type
set opt(ll)			LL 							;# Link layer type
set opt(ifq)		Queue/DropTail/PriQueue		;# Interface queue type
set opt(ifqlen)		50							;# max packet in ifq
set opt(netif)		Phy/WirelessPhy				;# network interface type
set opt(mac)			Mac/802_11					;# MAC type
set opt(adhocRouting)	DSDV						;# ad-hoc routing protocol
set opt(nn)				3							;# number of mobilenodes
set opt(x)				670							;# X dimension of the topography
set opt(y)				670							;# Y dimension of the topography
set opt(seed)			0.0
set opt(cp)				""
set opt(sc)				"../ns-allinone-2.35/ns-2.35/tcl/mobility/scene/scen-3-test"
set opt(stop)			300							;# time to stop simulation
set opt(ftp1-start)		160.0
set opt(ftp2-start)     170.0

set num_wired_nodes		2
set num_bs_nodes		1

# ==========================================================================
# Main program
# ==========================================================================
set ns_ 	   [new Simulator]

$ns_ node-config -addressType hierarchical
AddrParams set domain_num_ 2 				;# number of domains
lappend cluster_num 2 1 					;# number of clusters in each domain
AddrParams set cluster_num_ $cluster_num 
lappend eilastlevel 1 1 4 					;# number of nodes in each cluster
AddrParams set nodes_num_ $eilastlevel 		;# for each domain

set tracefd    [open wireless2-out.tr w]	;# for wireless traces
set namtrace [open wireless2-out.nam w]	;# for nam tracing
$ns_ trace-all $tracefd
$ns_ namtrace-all-wireless $namtrace $opt(x) $opt(y)

set topo	   [new Topography]

# Topography object with x and y co-ordinates
$topo load_flatgrid 500 500

# Create general operations director
create-god $val(nn)

# Create wired nodes
set temp {0.0.0 0.1.0} 						;# hierarchical addresses to be used
for {set i 0} {$i < $num_wired_nodes} {incr i} {
	set W($i) [$ns_ node [lindex $temp $i]]
}

# Configure nodes 
		$ns_ node-config -adhocRouting $val(adhocRouting) \
			-llType $val(ll) \
			-macType $val(mac) \
			-ifqType $val(ifq) \
			-ifqLen $val(ifqlen) \
			-antType $val(ant) \
			-propType $val(prop) \
			-phyType $val(netif) \
			-channelType $val(chan) \
			-topoInstance $topo \
			-agentTrace ON \
			-routerTrace ON \
			-macTrace OFF \
			-movementTrace OFF

# Create mobilenodes
		for {set i 0} {$i < $val(nn) } {incr i} {
				set node_($i) [$ns_ node]	
				$node_($i) random-motion 0		;# disable random motion
			}

# Define node movement model
puts "Loading connection pattern..."
source $val(cp)

#Define traffic model
puts "Loading scenario file..."
source $val(sc)

# Define node initial position in nam
for {set i 0} {$i < $val(nn)} {incr i} {
	# 20 defines the node size in nam, must adjust it according to your scenario size.
	# The function must be called after mobility model is defined
	$ns_ initial_node_pos $node_($i) 20
}

# Provide initial (X,Y, for now Z=0) co-ordinates for node_(0) and node_(1)
$node_(0) set X_ 5.0
$node_(0) set Y_ 2.0
$node_(0) set Z_ 0.0

$node_(1) set X_ 390.0
$node_(1) set Y_ 385.0
$node_(1) set Z_ 0.0

# Node movements
# Node_(1) starts to move towards node_(0)
# at time 50.0s, node1 starts to move towards the destination (x=25, y=20) at a speed of 15m/s
$ns_ at 50.0 "$node_(1) setdest 25.0 20.0 15.0"
$ns_ at 10.0 "$node_(0) setdest 20.0 18.0 1.0"

# Node_(1) then starts to move away from node_(0)
$ns_ at 100.0 "$node_(1) setdest 490.0 480.0 15.0"

# Setup traffic flow between node_(0) and node_(1)
set tcp [new Agent/TCP]
$tcp set class_ 2
set sink [new Agent/TCPSink]
$ns_ attach-agent $node_(0) $tcp
$ns_ attach-agent $node_(1) $sink
$ns_ connect $tcp $sink
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns_ at 10.0 "$ftp start"

# Tell nodes when the simulation ends
for {set i 0} {$i < $val(nn)} {incr i} {
	$ns_ at 150.0 "$node_($i) reset";
}
$ns_ at 150.0001 "stop"
$ns_ at 150.0002 "puts \"NS EXITING...\" ; $ns_ halt"
proc stop {} {
	global ns_ tracefd
	close $tracefd
}

puts "Starting Simulation"

puts $tracefd "M 0.0 nn $val(nn) x $val(x) y $val(y) rp $val(adhocRouting)"
puts $tracefd "M 0.0 sc $val(sc) cp $val(cp) seed $val(seed)"
puts $tracefd "M 0.0 prop $val(prop) ant $val(ant)"

$ns_ run