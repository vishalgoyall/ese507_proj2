rm -r work
echo "++++++++++++ START COMPILATION ++++++++++"
vlog -f ../rtl_file_list conv_time_check.sv
echo "++++++++++++ COMPILATION DONE ++++++++++"

echo "++++++++++++ Launch TestBench ++++++++++"
if [ $1 = 'gui' ]; 
then
	vsim conv_time +acc
else
	vsim conv_time -c -do "run -all" 
fi
echo "++++++++++++ Exit TestBench ++++++++++"

