echo "++++++++++++ START COMPILATION ++++++++++"
vlog -f rtl_file_list part1_simple_tb.sv
echo "++++++++++++ COMPILATION DONE ++++++++++"

echo "++++++++++++ Launch TestBench ++++++++++"
if [ $1 = 'gui' ]; 
then
	vsim check_timing +acc
else
	vsim check_timing -c -do "run -all" 
fi
echo "++++++++++++ Exit TestBench ++++++++++"

