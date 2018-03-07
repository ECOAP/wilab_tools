EXPERIMENT_DURATION=1800
DIR_RESULTS_STR="\/groups\/wall2-ilabt-iminds-be\/ecoap\/results"
DIR_RESULTS=/groups/wall2-ilabt-iminds-be/ecoap/results

controller=$(head -n 1 /home/carlo/Testbed/wishful/tools_wilab/nodes.conf)

PERIODS="1 2 5 10 15 20"
#CC="default simple cocoa"
#PERIODS="1"
CC="cocoa"


for i in {1..2}
do
for c in $CC
do
for t in $PERIODS
do
#echo "mac,IEEE802154e_macSlotframeSize,30" > tmp.csv
#echo "mac,IEEE802154_phyTXPower,20" >> tmp.csv
#echo "mac,IEEE802154e_macTsTimeslotLength,10000" >> tmp.csv
echo "app,rpl_objective_function,1" > tmp.csv
echo "app,app_payload_length,95" >> tmp.csv
echo "app,app_send_interval,${t}" >> tmp.csv

scp -o StrictHostKeyChecking=no -oPort=22 -i '/home/carlo/Testbed/wishful/tools_wilab/unipi_nopwd.pem' tmp.csv unipi@${controller}:/groups/wall2-ilabt-iminds-be/ecoap/code/examples/contiki/ecoap_advanced

params="cc_${c}_period_${t}_run_${i}"

# ADD SOME CYCLE THROUGH SOME PARAMS (MODIFY ecoap_advanced/coap_settings.csv and ecoap_advanced/measurement_settings.yaml)
# REMOVE SUDO PWD also from the nodes

/home/carlo/Testbed/wishful/tools_wilab/bin/wilab-run-cmd-all "killall python"
/home/carlo/Testbed/wishful/tools_wilab/bin/wilab-run-cmd-all "sudo killall tunslip6"

/home/carlo/Testbed/wishful/tools_wilab/bin/wilab-remote-reset-all

while read p; do
  #echo "${p} socat UDP4-RECVFROM:10000,broadcast EXEC:/bin/bash"
  #ssh -o StrictHostKeyChecking=no -n ${USER}@${p} "socat UDP4-RECVFROM:10000,broadcast EXEC:/bin/bash" &
  ssh -o StrictHostKeyChecking=no -n -oPort=22 -i '/home/carlo/Testbed/wishful/tools_wilab/unipi_nopwd.pem' unipi@${p} "cd /groups/wall2-ilabt-iminds-be/ecoap/code && source dev/bin/activate && cd examples/contiki && python agent.py --config ecoap_advanced/ecoap_agent.yaml &> log_${p} " & # &> log_${p}
done < /home/carlo/Testbed/wishful/tools_wilab/nodes.conf

sleep 30

ssh -o StrictHostKeyChecking=no -n -oPort=22 -i '/home/carlo/Testbed/wishful/tools_wilab/unipi_nopwd.pem' unipi@${controller} "cd /groups/wall2-ilabt-iminds-be/ecoap/code && source dev/bin/activate && cd examples/contiki && python ecoap_advanced/global_cp.py --config config/localhost/global_cp_config.yaml --nodes config/localhost/nodes_testbed.yaml --event_config_file ecoap_advanced/event_settings.csv --measurements ecoap_advanced/file_measurement_settings.yaml --param_config_file ecoap_advanced/tmp.csv --congestion_policy $c &> log_0" & # &> log_0

sleep $EXPERIMENT_DURATION

/home/carlo/Testbed/wishful/tools_wilab/bin/wilab-run-cmd-all "killall python"
/home/carlo/Testbed/wishful/tools_wilab/bin/wilab-run-cmd-all "sudo killall tunslip6"

ssh -o StrictHostKeyChecking=no -oPort=22 -i '/home/carlo/Testbed/wishful/tools_wilab/unipi_nopwd.pem' unipi@${controller} "mkdir -p ${DIR_RESULTS}/${params}"

ssh -o StrictHostKeyChecking=no -oPort=22 -i '/home/carlo/Testbed/wishful/tools_wilab/unipi_nopwd.pem' unipi@${controller} "mv ${DIR_RESULTS}/coap_stats* ${DIR_RESULTS}/${params}"

ssh -o StrictHostKeyChecking=no -oPort=22 -i '/home/carlo/Testbed/wishful/tools_wilab/unipi_nopwd.pem' unipi@${controller} "cd /groups/wall2-ilabt-iminds-be/ecoap/code/examples/contiki && mv log_* ${DIR_RESULTS}/${params}"

done
done
done
