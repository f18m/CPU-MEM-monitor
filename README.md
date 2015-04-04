# CPU-MEM-monitor
A simple script to log Linux CPU and memory usage over time and output a CSV report that can be easily
analyzed / plotted with e.g., Excel or OpenOffice Calc.

More in details, this script allows to monitor per-thread CPU usage and memory usage by parsing 
in an automated way the output of <a href="http://linux.die.net/man/1/top">TOP</a> or 
<a href="http://sebastien.godard.pagesperso-orange.fr/index.html">PIDSTAT</a> utilities.

The script is focused on monitoring the CPU and memory usage (by thread) of one specific process over time.
The output is written in an Excel-friendly .CSV file whose contents can be easily plotted against time
to analyze the behaviour of a process.


# Example Run

```
    Usage: ./CPU_MEM_monitor.sh THREADNAME_REGEX [USE_PIDSTAT]
    Automates TOP/PIDSTAT monitoring and resource usage statistics export for Excel import
      THREADNAME_REGEX = expression matching one or more thread names running on the system
                         e.g. 'mythread\|myotherthread'
      USE_PIDSTAT = if 'yes', pidstat rather than top will be used (default=no)
```

For example, assume you want to monitor a process called "multithread" that generates several (e.g., 20) threads;
the following screenshot shows the result of calling:

<tt>
    $ ./CPU_MEM_monitor.sh multithread
</tt>

<img src="docs/script_screenshot.png" />


# Example Output File

The .csv file produced by above example can be downloaded
<a href="docs/ubuntu-multithread-2015-04-04-started-at02-28.csv">clicking here</a>.


# Example Of Results

The .csv file can be easily plotted to get an idea of the thread CPU usage and the per-process memory used:

<img src="docs/openoffice_calc_screenshot.png" />

