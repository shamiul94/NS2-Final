BEGIN {
	
    time = 0.0 ; 
    start_node = 0 ; 
    end_node = 0 ; 
    size_byte = 0.0 ; 
    size_packets = 0.0; 
	
	
}

{
	
    time = $1 ; 
    start_node = $2 ; 
    end_node = $3 ; 
    size_byte = $4 ; 
    size_packets = $5 ; 

    if (size_byte != "0.0" && size_byte != "0") {
        printf( "Time: %3.5f, Start Node: %3d, End Node: %3d, Size in Bytes: %7.5f, Size in Packets: %7.5f\n", time , start_node , end_node , size_byte , size_packets ); 
    }
}

END {
   
}


