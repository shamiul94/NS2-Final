while read  var
do
  echo "$var"

  A="$(echo "$var" | cut -d' ' -f1)"
  B="$(echo "$var" | cut -d' ' -f2)"
iteration_float=1
  arr["$A"]="$B"
  echo "===${arr["$A"]}, $B"

  arr["$A"]=$(echo "scale=5; ${arr["$A"]}+$B/$iteration_float" | bc)

#   s_packet=$(echo "scale=5; $s_packet+$val/$iteration_float" | bc)
echo "===${arr["$A"]}, $B-------${arr[0]}"
r=5
# for i in {0..5}
# do
#    arr["$i"]=0
# done

for (( c=1; c<=$r; c++ ))
do  
   arr["$i"]=0
   echo "===${arr["$A"]}, $B-------${arr[$i]}"
done

echo "===${arr["$A"]}, $B-------${arr[0]}"
done < yyy.txt