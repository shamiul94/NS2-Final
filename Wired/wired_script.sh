#INPUT: output file AND number of iterations

outputDirectory="output_wired/"
rm -rf $outputDirectory
rm -rf Output/
rm -rf QueueMonitor/
mkdir -p QueueMonitor/
mkdir -p $outputDirectory

tclFile="my_wired.tcl"


iteration_float=1.0;
under="_";

outFile="$outputDirectory""OUT"
tempFile="$outputDirectory""TEMPFILE"
graphData="$outputDirectory""GRAPH"
nodeThrData="$outputDirectory""NodeThr"


nNodesInit=20
nFlowsInit=10
pcktRateInit=100
speedInit=5

nNodes=$nNodesInit
nFlows=$nFlowsInit
pcktRate=$pcktRateInit
speed=$speedInit

iteration=$(printf %.0f $iteration_float);



echo 'Which parameter do you want to vary?'
echo '1. # of Nodes'
echo '2. # of flows'
echo '3. Packet rate'

read param

echo 'Please enter the # of iteration'
read nIter

round=1

while [ $round -le $nIter ]
do

	for (( count=0; count<=$nNodes; count++ ))
	do  
		currNodeThr["$count"]=0
	done

	###############################START A ROUND

	echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "                         ROUND : $round                              "
	echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	l=0;thr=0.0;del=0.0;s_packet=0.0;r_packet=0.0;d_packet=0.0;del_ratio=0.0;
	dr_ratio=0.0;time=0.0;total_retransmit=0.0;rTotalDelay=0.0; 

	i=0
	while [ $i -lt $iteration ]
	do
		#################START AN ITERATION
		echo "################EXECUTING $(($i+1)) th ITERATION################"

		ns $tclFile $nNodes $nFlows $pcktRate
		echo "SIMULATION COMPLETE. BUILDING STAT..."

		qf="QueueMonitor/qMonitor_round-$round-iteration-$iteration"
		awk -f queue_awk.awk qm.out > $qf


		flnm="$outputDirectory""tem""$round"
		awk -f wired_awk.awk wired.tr > $tempFile
		cp wired.tr $flnm


		# ======================================================================
		# UPDATING THE VALUES IN EACH ITERATION
		# ======================================================================
		while read val
		do

			l=$(($l+1))

			if [ "$l" == "1" ]; then
				thr=$(echo "scale=5; $thr+$val/$iteration_float" | bc)
				#		echo -ne "throughput: $thr "
			elif [ "$l" == "2" ]; then
				del=$(echo "scale=5; $del+$val/$iteration_float" | bc)
				#		echo -ne "delay: "
			elif [ "$l" == "3" ]; then
				s_packet=$(echo "scale=5; $s_packet+$val/$iteration_float" | bc)
				#		echo -ne "send packet: "
			elif [ "$l" == "4" ]; then
				r_packet=$(echo "scale=5; $r_packet+$val/$iteration_float" | bc)
				#		echo -ne "received packet: "
			elif [ "$l" == "5" ]; then
				d_packet=$(echo "scale=5; $d_packet+$val/$iteration_float" | bc)
				#		echo -ne "drop packet: "
			elif [ "$l" == "6" ]; then
				del_ratio=$(echo "scale=5; $del_ratio+$val/$iteration_float" | bc)
				#		echo -ne "delivery ratio: "
			elif [ "$l" == "7" ]; then
				dr_ratio=$(echo "scale=5; $dr_ratio+$val/$iteration_float" | bc)
				#		echo -ne "drop ratio: "
			elif [ "$l" == "8" ]; then
				time=$(echo "scale=5; $time+$val/$iteration_float" | bc)
				#		echo -ne "time: "
			elif [ "$l" == "9" ]; then
				rTotalDelay=$(echo "scale=5; $rTotalDelay+$val/$iteration_float" | bc)
			else 
				nodeIdxVal="$(echo "$val" | cut -d' ' -f1)"
				# echo "val == $val"
  				thisNodeThrVal="$(echo "$val" | cut -d' ' -f2)" 

				
				currNodeThr["$nodeIdxVal"]=$(echo "scale=5; ${currNodeThr[$nodeIdxVal]}+$thisNodeThrVal/$iteration_float" | bc)
				echo "node index = $nodeIdxVal, ${currNodeThr[$nodeIdxVal]}"
			fi

			# echo "val: $val"
		done < $tempFile

		i=$(($i+1))
		l=0 
	done


	########## OUTPUT FILE GENERATION
	
	output_file="$outFile$under$round"
	echo "" > $output_file # clearing the output file

			
	echo "# of Nodes:                   $nNodes " >> $output_file
	echo "# of flows:                   $nFlows " >> $output_file
	echo "Packet size:                  $pcktRate " >> $output_file


	echo "" >> $output_file
	echo "" >> $output_file
	echo "" >> $output_file


	echo "Throughput:                   $thr " >> $output_file
	echo "AverageDelay:                 $del " >> $output_file
	echo "Sent Packets:                 $s_packet " >> $output_file
	echo "Received Packets:             $r_packet " >> $output_file
	echo "Dropped Packets:              $d_packet " >> $output_file
	echo "PacketDeliveryRatio:          $del_ratio " >> $output_file
	echo "PacketDropRatio:              $dr_ratio " >> $output_file
	echo "Total time:                   $time " >> $output_file
	echo "Total Delay: 					$rTotalDelay " >> $output_file
	# ==========================================================================
##############################
	echo "Initial setup: " 				
	echo "# of Nodes:                   $nNodes " 
	echo "# of flows:                   $nFlows " 
	echo "Packet size:                  $pcktRate " 


	echo "" 
	echo "" 
	echo "" 


	echo "Throughput:                   $thr " 
	echo "AverageDelay:                 $del " 
	echo "Sent Packets:                 $s_packet " 
	echo "Received Packets:             $r_packet " 
	echo "Dropped Packets:              $d_packet " 
	echo "PacketDeliveryRatio:          $del_ratio " 
	echo "PacketDropRatio:              $dr_ratio " 
	echo "Total time:                   $time " 
	echo "Total Delay: 					$rTotalDelay "


############################
	round=$(($round+1))
#
	########Plotting Graph

	
	if [ "$param" == "1" ]; then
		xax="No of nodes"
	elif [ "$param" == "2" ]; then
		xax="No of flows"
	elif [ "$param" == "3" ]; then
		xax="Packet Rate"
	fi


	for (( count=0; count<=$nNodes; count++ ))
	do  
		echo "$count ${currNodeThr["$count"]}" >> $nodeThrData
	done

	arr4[0]=""
	arr4[1]=""
	arr4[2]="Per-Node-Throughput-Round-"

	arr5[0]=""
	arr5[1]=""
	arr5[2]="Per-Node-Throughput ( bit/second )"


	ii=2
	while [ $ii -ge 2 ]
	do
		tem=$(($round-1))
		gnuplot -persist -e "set terminal png size 700,500; set output '$outputDirectory${arr4[$ii]}VS$xax-round$under$tem.png';set title 'Wired (After Modification) : ${arr5[$ii]} vs $xax - Round - $tem'; set xlabel '$xax'; set ylabel '${arr5[$ii]}'; plot '$nodeThrData' using 1:$ii with lines"
		ii=$(($ii-1))
	done

	# cp $nodeThrData t.txt
	rm -rf $nodeThrData


	if [ "$param" == "1" ]; then
		echo -ne "$nNodes " >> $graphData
		nNodes=$(($nNodesInit*$round))
	elif [ "$param" == "2" ]; then
		echo -ne "$nFlows " >> $graphData
		nFlows=$(($nFlowsInit*$round))
	elif [ "$param" == "3" ]; then
		echo -ne "$pcktRate " >> $graphData
		pcktRate=$(($pcktRateInit*$round))
	fi

	# echo "throughput: $thr delay: $del deliver_rat: $del_ratio drop_rat: $dr_ratio" >> $graphData
	echo "$thr $del $del_ratio $dr_ratio" >> $graphData	


	#####################END A ROUND
done

if [ "$param" == "1" ]; then
	param="No of nodes"
elif [ "$param" == "2" ]; then
	param="No of flows"
elif [ "$param" == "3" ]; then
	param="Packet Rate"
fi

arr[0]=""
arr[1]=""
arr[2]="Throughput"
arr[3]="Average Delay"
arr[4]="Packet Delivery Ratio"
arr[5]="Packet Drop Ratio"

arr2[0]=""
arr2[1]=""
arr2[2]="Throughput ( bit/second )"
arr2[3]="Average Delay ( second )"
arr2[4]="Packet Delivery Ratio ( % )"
arr2[5]="Packet Drop Ratio ( % )"

i=5
while [ $i -ge 2 ]
do
	gnuplot -persist -e "set terminal png size 700,500; set output '$outputDirectory${arr[$i]}VS$param.png';set title 'Wired (After Modification) : ${arr[$i]} vs $param'; set xlabel '$param'; set ylabel '${arr2[i]}'; plot 'output_wired/GRAPH' using 1:$i with lines"

	# gnuplot -persist -e "set terminal png size 700,500; set output '$outputDirectory${arr[$i]}VS$param.png';set title 'Wired : ${arr[$i]} vs $param'; set xlabel '$param'; set ylabel '${arr2[i]}'; plot 'output_wired/GRAPH' using 1:$i with lines"

	i=$(($i-1))
done

# mv $outputDirectory "Output"