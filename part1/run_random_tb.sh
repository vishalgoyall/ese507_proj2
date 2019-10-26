echo "++++++++++++ START COMPILATION ++++++++++"
vlog -f rtl_file_list part1_random_tb.sv
echo "++++++++++++ COMPILATION DONE ++++++++++"

echo "++++++++++++ Launch TestBench ++++++++++"
if [ $1 = 'gui' ]; 
then
	vsim tbench1 +acc
else
	vsim tbench1 -c -do "run -all" 
fi
echo "++++++++++++ Exit TestBench ++++++++++"

