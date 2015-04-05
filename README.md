# CPU-MEM-monitor
A simple script to log Linux CPU and memory usage over time and output a CSV report that can be easily
analyzed / plotted with e.g., Excel or OpenOffice Calc.

More in details, this script allows to monitor per-thread CPU usage and memory usage by parsing 
in an automated way the output of <a href="http://linux.die.net/man/1/top">TOP</a> or 
<a href="http://sebastien.godard.pagesperso-orange.fr/index.html">PIDSTAT</a> utilities.

The script is focused on monitoring the CPU and memory usage (by thread) of one specific process over time.
The output is written in an Excel-friendly .CSV file whose contents can be easily plotted against time
to analyze the behaviour of a process.

The script is also useful to analyze a (multithreaded) process during a long amount of time (e.g., several days / months).
For this usage scenario it is convenient to use the <a href="https://www.linode.com/docs/networking/ssh/using-gnu-screen-to-manage-persistent-terminal-sessions">screen utility</a>.


# Example Run

The script accepts the following command-line options:

```
    Usage: ./CPU_MEM_monitor.sh [-h] [-v] [--use-pidstat] [-t THREADNAME_REGEX] [-p AUX_PROCESS1] [-p AUX_PROCESS2] ...
    Version 0.9, by Francesco Montorsi
    Automates TOP/PIDSTAT monitoring and resource usage statistics logging to a .CSV file
      -h              this help
      -v              be verbose
      --use-pidstat   pidstat rather than top will be used
      -t <tregex>     monitor threads whose name match the regex <tregex>; e.g. 'mythread\|myotherthread'
      -p <auxproc>    monitor CPU and memory usage of the auxiliary process <auxproc>
    Default option values:
      VERBOSE: false
      USEPIDSTAT: false
      THREADNAME_REGEX: multithread
      AUX_PROCESS #0: init
      AUX_PROCESS #1: firefox
      Output .csv file name will be automatically generated based on current date and hostname.
      Associated to the .csv also a .log file containing info messages will be generated.
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

