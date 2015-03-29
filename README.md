# CPU-MEM-monitor
A simple script to log Linux CPU and memory usage over time and output an Excel-friendly report.

More in details, this script allows to monitor per-thread CPU usage and memory usage by parsing 
in an automated way the output of <a href="http://linux.die.net/man/1/top">TOP</a> or 
<a href="http://sebastien.godard.pagesperso-orange.fr/index.html">PIDSTAT</a> utilities.

The script is focused on monitoring the CPU and memory usage (by thread) of one specific process over time.
The output is written in an Excel-friendly .CSV file whose contents can be easily plotted against time
to analyze the behaviour of a process.

