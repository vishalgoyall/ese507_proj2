rm -r work
echo "++++++++++++ START COMPILATION ++++++++++"
vlog -f ../rtl_file_list part2_random_tb.sv
echo "++++++++++++ COMPILATION DONE ++++++++++"

echo "++++++++++++ Launch TestBench ++++++++++"
if [ $1 = 'gui' ]; 
then
	vsim tbench2 +acc
else
	vsim tbench2 -sv_seed $2 -c -do "run -all" 
fi
echo "++++++++++++ Exit TestBench ++++++++++"

