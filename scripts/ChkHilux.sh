#!/bin/bash
echo "Monitoring Nodo Hilux..."
while true; do
        date
        process_number=$(pgrep hiluxd | head -1)
        echo "Process $process_number"
        ps -p $process_number -o %cpu,nlwp,%mem,rssize,vsize,cmd
        echo "Sockets $(ls -l /proc/$process_number/fd | wc -l)"
        echo ""
        sleep 3s
done
