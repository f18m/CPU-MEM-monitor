#!/bin/bash
# A simple script to log Linux CPU and memory usage over time and output an Excel-friendly report
#
# Original Author: S. Mele
# Rewritten by: F. Montorsi
# Creation: Nov 2014
# Last change: Mar 2015
#
# HISTORY:
# v2: use CPU% as sort key
# v3: fix thread name detection, since now threads are reorderded by CPU%,
#     make output more smooth by increasing averaging time to 5sec
# v4: make memory output easier to import in Excel
# v5: auto-restart in case a monitored process dies
# v6: fix TOP memory parsing using printf utility
#
# Note that 
#
# 1) apparently similar tool
#        DAG http://dag.wiee.rs/home-made/dstat/
#    does not track the CPU usage of single threads
#
# 2) this is just a wrapper for
#      pidstat
#      top
#    utilities


# global configs
OUTPUT_COMMA_AS_DECIMAL_SEPARATOR=1

# defines how much "average" CPU usage results: 3sec is the default... lower means higher temporal resolution, higher means more smoothy averages
TOP_DELAY=5


AUX_PROCESS1="init"
AUX_PROCESS2="init"
AUX_PROCESS3="init"


function show_help()
{
    echo "Usage: $0 [PROCNAME] [THREADNAME REGEX] [USE PIDSTAT]"
    echo "Automates TOP/PIDSTAT monitoring and resource usage statistics export"
}      

function fix_mem_by_top_for_excel()
{
    MEMVALUE_STRING=$1
    
    # eventually convert m prefix put by TOP
    # NOTE: the following won't work simply because if TOP says "1.2g"
    #       the conversion below will output "1.2000000000" = "1.2" ==> WRONG!!
    #MEMVALUE_STRING=${MEMVALUE_STRING//m/000000}
    #MEMVALUE_STRING=${MEMVALUE_STRING//g/000000000}
    
    MEMVALUE_STRING=${MEMVALUE_STRING//m/e6}
    MEMVALUE_STRING=${MEMVALUE_STRING//g/e9}
    MEMVALUE_STRING=$(printf %.0f "$MEMVALUE_STRING")
    
    
    # after above float -> integer and unit prefix conversion, it's unlikely to still have dots
    # in the string but just in case:    
    if [[ $OUTPUT_COMMA_AS_DECIMAL_SEPARATOR ]]; then
        # eventually convert DOT -> COMMA to help Excel import process
        MEMVALUE_STRING=${MEMVALUE_STRING//./,}
    fi    
   
    # return value by echo:
    echo $MEMVALUE_STRING
}

function unit_test_fix_mem_by_top_for_excel()
{
    test1="44.3g"
    test1_res=$(fix_mem_by_top_for_excel $test1)
    echo "for [$test1] the fixed string is [$test1_res]"

    test2="9040m"
    test2_res=$(fix_mem_by_top_for_excel $test2)
    echo "for [$test2] the fixed string is [$test2_res]"

    test3="13116"
    test3_res=$(fix_mem_by_top_for_excel $test3)
    echo "for [$test3] the fixed string is [$test3_res]"
    
    test4="1g"
    test4_res=$(fix_mem_by_top_for_excel $test4)
    echo "for [$test4] the fixed string is [$test4_res]"
}

function ask_proceed_or_abort()
{
    echo -n "continue? (Y/N)"
    stty -echo
    read res
    stty echo
    echo 
    while [ "$res" != "Y" -a "$res" != "y" -a "$res" != "N" -a "$res" != "n" ]; do
        echo -n "please select Y(y)/N(n)"
        stty -echo
        read res
        stty echo
        echo 
    done

    if [ "$res" == "N" -o "$res" == "n" ]
    then
        echo exiting...
        exit 0
    fi
}

function parse_pidstat
{
    # compared to TOP, PIDSTAT has the advantage that the columns always have the same INDEXES,
    # and same SORTING regardless of the user configuration for TOP utility:
    
    selected_lines=$(pidstat -u -r -t -C $THREADNAME)
    #echo "$selected_lines"
    
    # example of SELECTED_THREADS_STATS contents for THREADNAME=mythread
    # and for:
    #  sysstat version 8.1.5
    #  (C) Sebastien Godard (sysstat <at> orange.fr)
    # on SLES

    # 08:48:18 PM       PID       TID    %usr %system  %guest    %CPU   CPU  Command
    # 08:48:08 PM        -     158507    0.22    0.01    0.00    0.22    31  |__mythread/0
    # 08:48:08 PM        -     158508    0.23    0.00    0.00    0.23    14  |__mythread/1
    # 08:48:08 PM        -     158509    0.22    0.00    0.00    0.23     5  |__mythread/2
    # 08:48:08 PM        -     158510    0.23    0.00    0.00    0.23     8  |__mythread/3
    # 08:48:08 PM        -     158516    0.49    0.03    0.00    0.52    38  |__mythread_aux/0
    # 08:48:08 PM        -     158517    0.49    0.03    0.00    0.52    26  |__mythread_aux/1
    
    # 08:48:08 PM        -     158518    0.49    0.03    0.00    0.52     0  |__mythread_aux/2
    # 08:48:08 PM        -     158519    0.49    0.03    0.00    0.52    12  |__mythread_aux/3
    # 08:48:08 PM        -     158520    0.49    0.03    0.00    0.52    10  |__mythread_aux/4
    # 08:48:08 PM        -     158521    0.49    0.03    0.00    0.52    19  |__mythread_aux/5
    # 08:48:08 PM        -     158522    0.49    0.03    0.00    0.52    24  |__mythread_aux/6
    # 08:48:08 PM        -     158523    0.49    0.03    0.00    0.53    22  |__mythread_aux/7
    # 08:48:08 PM        -     158524    0.49    0.03    0.00    0.52    36  |__mythread_aux/8
    # 08:48:08 PM        -     158525    0.49    0.03    0.00    0.52    34  |__mythread_aux/9
    # 08:48:08 PM        -     158526    0.49    0.03    0.00    0.52     2  |__mythread_aux/10
    # 08:48:08 PM        -     158527    0.49    0.03    0.00    0.52     4  |__mythread_aux/11
    #
    # 08:51:46 PM       PID       TID  minflt/s  majflt/s      VSZ      RSS   %MEM  Command
    # 08:48:08 PM        -     158507      0.13      0.00 41627892 41549992  20.96  |__mythread/0
    # 08:48:08 PM        -     158508      0.05      0.00 41627892 41549992  20.96  |__mythread/1
    # 08:48:08 PM        -     158509      0.00      0.00 41627892 41549992  20.96  |__mythread/2
    # 08:48:08 PM        -     158510      0.00      0.00 41627892 41549992  20.96  |__mythread/3
    # 08:48:08 PM        -     158516      0.62      0.00 41627892 41549992  20.96  |__mythread_aux/0
    # 08:48:08 PM        -     158517      0.67      0.00 41627892 41549992  20.96  |__mythread_aux/1
    # 08:48:08 PM        -     158518      0.62      0.00 41627892 41549992  20.96  |__mythread_aux/2
    # 08:48:08 PM        -     158519      0.62      0.00 41627892 41549992  20.96  |__mythread_aux/3
    # 08:48:08 PM        -     158520      0.64      0.00 41627892 41549992  20.96  |__mythread_aux/4
    # 08:48:08 PM        -     158521      0.62      0.00 41627892 41549992  20.96  |__mythread_aux/5
    # 08:48:08 PM        -     158522      0.63      0.00 41627892 41549992  20.96  |__mythread_aux/6
    # 08:48:08 PM        -     158523      0.69      0.00 41627892 41549992  20.96  |__mythread_aux/7
    # 08:48:08 PM        -     158524      0.60      0.00 41627892 41549992  20.96  |__mythread_aux/8
    # 08:48:08 PM        -     158525      0.63      0.00 41627892 41549992  20.96  |__mythread_aux/9
    # 08:48:08 PM        -     158526      0.65      0.00 41627892 41549992  20.96  |__mythread_aux/10
    # 08:48:08 PM        -     158527      0.64      0.00 41627892 41549992  20.96  |__mythread_aux/11
    #
    # IMPORTANT:
    # CPU= num of CPU where the thread is allocated, use %CPU to understand how much CPU was really used!
    
    # first of all, we split the portion containing CPU usages from the portion about memory:
    selected_lines_cpu=$(echo "$selected_lines" | grep -B10000 "RSS" | grep $THREADNAME)
    nlines_cpu=`echo "$selected_lines_cpu" | wc -l`
    #echo "$selected_lines_cpu"
    
    selected_lines_memory=$(echo "$selected_lines" | grep -A10000 "RSS" | grep $THREADNAME)
    nlines_memory=`echo "$selected_lines_memory" | wc -l`
    #echo "$selected_lines_memory"

    if [[ "$nlines_cpu" != "$nlines_memory" ]]; then
        echo "MISMATCHING NUMBER OF CPU/MEM LINES FROM PIDSTAT: $nlines_cpu VS $nlines_memory"
        exit 1
    fi
    
    
    
    # NOTE: MEM column is the 7-th and is equal for all threads
    selected_mem_column=`echo "$selected_lines_memory" | awk '{print $7}' | head -1`
    #echo "$selected_mem_column"
    
    # NOTE: CPU% column is the 8-th (DO NOT USE "CPU" COLUMN, IT'S THE INDEX OF A CORE!!):
    selected_cpu_columns=`echo "$selected_lines_cpu" | awk '{print $8}'`
    #echo "$selected_cpu_columns"
 
    # output vars:
    # NOTE: the syntax ($var) creates a bash array:
    NUM_THREADS=`echo "$selected_lines_memory" | wc -l`
    MEMVALUE=$selected_mem_column
    CPUVALUES=($selected_cpu_columns)
    CPUTHREAD_NAME=($selected_thread_names)
    
    #echo "mem = $MEMVALUE"
    #   for ((c=0; c < $NUM_THREADS; c++)); do echo "CPU/NAME: ${CPUVALUES[$c]} ${CPUTHREAD_NAME[$c]}" ; done
}

function install_toprc
{
custom_toprc=$(cat <<EOF
RCfile for "top with windows"       # shameless braggin'
Id:a, Mode_altscr=0, Mode_irixps=1, Delay_time=3.000, Curwin=0
Def fieldscur=aehioqtwKNmbcdfgjplrsuvyzX
    winflags=128313, sortindx=23, maxtasks=0
    summclr=1, msgsclr=1, headclr=3, taskclr=1
Job fieldscur=ABcefgjlrstuvyzMKNHIWOPQDX
    winflags=62777, sortindx=0, maxtasks=0
    summclr=6, msgsclr=6, headclr=7, taskclr=6
Mem fieldscur=ANOPQRSTUVbcdefgjlmyzWHIKX
    winflags=62777, sortindx=13, maxtasks=0
    summclr=5, msgsclr=5, headclr=4, taskclr=5
Usr fieldscur=ABDECGfhijlopqrstuvyzMKNWX
    winflags=62777, sortindx=4, maxtasks=0
    summclr=3, msgsclr=3, headclr=2, taskclr=3
EOF
)


# this custom .toprc shows very few columns and orders them by CPU% (so that if TOP is used while recording usage, it still shows something usable!)
#    PID  VIRT   %CPU %MEM COMMAND

custom_toprc_with_pid=$(cat <<EOF
RCfile for "top with windows"       # shameless braggin'
Id:a, Mode_altscr=0, Mode_irixps=1, Delay_time=3.000, Curwin=0
Def fieldscur=AehiOqtwKNmbcdfgjplrsuvyzX
    winflags=128313, sortindx=10, maxtasks=0
    summclr=1, msgsclr=1, headclr=3, taskclr=1
Job fieldscur=ABcefgjlrstuvyzMKNHIWOPQDX
    winflags=62777, sortindx=0, maxtasks=0
    summclr=6, msgsclr=6, headclr=7, taskclr=6
Mem fieldscur=ANOPQRSTUVbcdefgjlmyzWHIKX
    winflags=62777, sortindx=13, maxtasks=0
    summclr=5, msgsclr=5, headclr=4, taskclr=5
Usr fieldscur=ABDECGfhijlopqrstuvyzMKNWX
    winflags=62777, sortindx=4, maxtasks=0
    summclr=3, msgsclr=3, headclr=2, taskclr=3
EOF
)

    TOPRC="$HOME/.toprc"
    TOPRC_BACKUP="$HOME/BACKUP.toprc"
    if [[ -e $TOPRC ]]; then
        echo "Saving a backup copy of $TOPRC as $TOPRC_BACKUP"
        mv $TOPRC $TOPRC_BACKUP
    fi
    
    echo "Installing custom $TOPRC"
    echo "$custom_toprc_with_pid" >$TOPRC
}

function parse_top
{
    # TOP produces more accurate CPU usage %
    selected_lines=$(top -s -b -n 1 -d $TOP_DELAY | grep $THREADNAME)
    if [[ -z "$selected_lines" ]]; then
        NUM_THREADS=0
        return
    fi
    
    # example of selected thread stats obtained with: 
    #    THREADNAME=mythread
    #    selected_lines=$(top -s -b -n 1  | grep $THREADNAME)
    #    echo "$selected_lines"
    #
    # e.g.:
    # 24663 3.5g 12.3 22.3 mythread_0
    # 24665 3.5g 12.3 22.3 mythread_2
    # 24666 3.5g 12.3 22.3 mythread_3
    # 24664 3.5g 10.6 22.3 mythread_1
    #
    # where columns are:
    # PID  VIRT   %CPU %MEM COMMAND
    
    
    # reorder lines based on PID: note that PID is actually the thread ID!
    # in this way we basically override the sort key defined in the .toprc and that is mostly useful for human inspection
    # and we also ensure that calling this function multiple times will result always in the same ordering of parsed fields!!!!
    selected_lines=$(echo "$selected_lines" | sort -k1 -n)
    
    
    # NOTE: VIRT column is the 2-th and is equal for all threads => we can take just the first line
    # IMPORTANT: VIRT indicates how much memory the process has allocated; RES indicates how much it has effectively used
    #            from programmer point of view, VIRT is what we need to check!!!
    selected_mem_column=`echo "$selected_lines" | awk '{print $2}' | head -1`
    #echo "$selected_mem_column"
    
    # NOTE: %CPU column is the 3-th:
    selected_cpu_columns=`echo "$selected_lines" | awk '{print $3}'`
    #echo "$selected_cpu_columns"
 
    # NOTE: %COMMAND column is the 5-th, we use it to detect thread name
    selected_thread_names=`echo "$selected_lines" | awk '{print $5}'`
    #echo "$selected_thread_names"
    
    
    # output vars:
    # NOTE: the syntax ($var) creates a bash array:
    NUM_THREADS=`echo "$selected_lines" | wc -l`
    MEMVALUE=$selected_mem_column
    CPUVALUES=($selected_cpu_columns)
    CPUTHREAD_NAME=($selected_thread_names)
    
    #echo "mem = $MEMVALUE"
    #   for ((c=0; c < $NUM_THREADS; c++)); do echo "CPU/NAME: ${CPUVALUES[$c]} ${CPUTHREAD_NAME[$c]}" ; done
    
    # help Excel import process:
    MEMVALUE=$(fix_mem_by_top_for_excel $MEMVALUE)
}

function check_if_aux_processes_are_alive
{
    ISALIVE=true
    
    ps -p $AUX_PROCESS1_PROCPID >/dev/null 2>&1
    if [[ $? != 0 ]]; then ISALIVE=false; fi

    ps -p $AUX_PROCESS2_PROCPID >/dev/null 2>&1
    if [[ $? != 0 ]]; then ISALIVE=false; fi

    ps -p $AUX_PROCESS3_PROCPID >/dev/null 2>&1
    if [[ $? != 0 ]]; then ISALIVE=false; fi
}

function get_resources_probe_chain
{
    # by using -H option with our custom .toprc, we revert to "show threads OFF"
    selected_lines=$(top -s -b -n 1 -H -p $AUX_PROCESS1_PROCPID -p $AUX_PROCESS2_PROCPID -p $AUX_PROCESS3_PROCPID)
    #echo "$selected_lines"
    
    # example output:
    #   top - 17:38:48 up 4 days,  6:23, 10 users,  load average: 1.91, 2.20, 2.16
    #   Tasks:   3 total,   0 running,   3 sleeping,   0 stopped,   0 zombie
    #   Cpu(s):  1.8%us,  1.1%sy,  0.3%ni, 96.6%id,  0.1%wa,  0.0%hi,  0.0%si,  0.0%st
    #   Mem:  16461860k total, 16338852k used,   123008k free,   135792k buffers
    #   Swap: 48225272k total,        0k used, 48225272k free,  7186600k cached
    #   
    #     PID  VIRT %CPU %MEM COMMAND
    #   23548 3.5g 81.9 22.3 AuxProcess1
    #   24878 1.9g 67.9 11.9 AuxProcess3
    #   24844 235m 33.9  1.5 AuxProcess2                 
    
    # NOTE: VIRT column is the 2-th and is equal for all threads
    AUX_PROCESS1_MEM=`echo "$selected_lines" | grep $AUX_PROCESS1 | awk '{print $2}'`
    AUX_PROCESS2_MEM=`echo "$selected_lines" | grep $AUX_PROCESS2 | awk '{print $2}'`
    AUX_PROCESS3_MEM=`echo "$selected_lines" | grep $AUX_PROCESS3 | awk '{print $2}'`
    
    # NOTE: total CPU column is the 3-th:
    AUX_PROCESS1_CPU=`echo "$selected_lines" | grep $AUX_PROCESS1 | awk '{print $3}'`
    AUX_PROCESS2_CPU=`echo "$selected_lines" | grep $AUX_PROCESS2 | awk '{print $3}'`
    AUX_PROCESS3_CPU=`echo "$selected_lines" | grep $AUX_PROCESS3 | awk '{print $3}'`
    
    # help Excel import process:
    AUX_PROCESS1_MEM=$(fix_mem_by_top_for_excel $AUX_PROCESS1_MEM)
    AUX_PROCESS2_MEM=$(fix_mem_by_top_for_excel $AUX_PROCESS2_MEM)
    AUX_PROCESS3_MEM=$(fix_mem_by_top_for_excel $AUX_PROCESS3_MEM)
}

function format_outputfile_header
{
    # NOTE: by using ; we allow Excel to directly understand the resulting file, without IMPORT steps
    
    OUTPUTLINE="Time;Mem $AUX_PROCESS1 (B);Mem $AUX_PROCESS2 (B);Mem $AUX_PROCESS3 (B);Mem $PROCNAME (B);CPU $AUX_PROCESS1;CPU $AUX_PROCESS2;CPU $AUX_PROCESS3"
    
    # then output variable-number columns
    for ((c=0; c < $NUM_THREADS; c++)); do
        OUTPUTLINE="$OUTPUTLINE;CPU thread ${CPUTHREAD_NAME[$c]}"
    done
}

function format_outputfile_line
{
    # NOTE: by using ; we allow Excel to directly understand the resulting file, without IMPORT steps
    
    now=`date +%H:%M:%S`
    OUTPUTLINE="$now;$AUX_PROCESS1_MEM;$AUX_PROCESS2_MEM;$AUX_PROCESS3_MEM;$MEMVALUE;$AUX_PROCESS1_CPU;$AUX_PROCESS2_CPU;$AUX_PROCESS3_CPU"
    
    # then output variable-number columns
    for ((c=0; c < $NUM_THREADS; c++)); do
        OUTPUTLINE="$OUTPUTLINE;${CPUVALUES[$c]}"
    done
}

function setup
{
    # default value:
    OUTPUTFILE="$(hostname)-$PROCNAME-$(date +%F-started-at%H-%M)$PIDSTAT_POTSFIX.csv"

    PROCPID=`pidof $PROCNAME`

    AUX_PROCESS1_PROCPID=`pidof $AUX_PROCESS1`
    AUX_PROCESS2_PROCPID=`pidof $AUX_PROCESS2`
    AUX_PROCESS3_PROCPID=`pidof $AUX_PROCESS3`

    if [[ -z $AUX_PROCESS1_PROCPID ]]; then echo No $AUX_PROCESS1 found. Exiting. ; exit 0; fi
    if [[ -z $AUX_PROCESS2_PROCPID ]]; then echo No $AUX_PROCESS2 found. Exiting. ; exit 0; fi
    if [[ -z $AUX_PROCESS3_PROCPID ]]; then echo No $AUX_PROCESS3 found. Exiting. ; exit 0; fi


    # before using any TOP function, install our custom TOP config file:
    if $USEPIDSTAT; then
        echo "All threads activities will be monitored using pidstat utility."
        parse_pidstat     # we use it to fill NUM_THREADS
    else
        echo "All threads activities will be monitored using top utility."
        install_toprc
        parse_top     # we use it to fill NUM_THREADS
    fi


    echo "CPU activity logger starting with configuration:"
    echo " process name = $PROCNAME (pid=$PROCPID)"
    echo " thread name = $THREADNAME ($NUM_THREADS threads matching)"
    echo " output file = $OUTPUTFILE"
    echo "Other processes automatically monitored:"
    echo " $AUX_PROCESS1 PID = $AUX_PROCESS1_PROCPID"
    echo " $AUX_PROCESS2 PID = $AUX_PROCESS2_PROCPID"
    echo " $AUX_PROCESS3 ENGINE PID = $AUX_PROCESS3_PROCPID"

    if [[ $NUM_THREADS = 0 ]]; then
        echo "The thread REGEX $THREADNAME does not mach any thread... exiting"
        exit 0
    fi

    echo "Starting logging..."
    format_outputfile_header
    echo "$OUTPUTLINE" >$OUTPUTFILE
    echo "Data format is $OUTPUTLINE"
}



# main

if [ $# -lt 2 ]; then
    show_help
    exit 0
fi

PROCNAME="$1"
THREADNAME="$2"
if [[ "$3" = "yes" ]]; then
    USEPIDSTAT=true
    PIDSTAT_POTSFIX="-pidstat"
else
    # by default use TOP
    USEPIDSTAT=false
    PIDSTAT_POTSFIX=""
fi

setup
 
while true; do 
    check_if_aux_processes_are_alive
    if $ISALIVE; then
        
        if $USEPIDSTAT; then
            parse_pidstat
        else
            parse_top
        fi
        format_outputfile_line

        echo "$OUTPUTLINE" >>$OUTPUTFILE
        echo "Appending line: $OUTPUTLINE"
        
        sleep 1
    else
        echo "Detected a possible restart in some component since one of"
        echo " $AUX_PROCESS1 PID = $AUX_PROCESS1_PROCPID"
        echo " $AUX_PROCESS2 PID = $AUX_PROCESS2_PROCPID"
        echo " $AUX_PROCESS3 PID = $AUX_PROCESS3_PROCPID"
        echo " is not valid anymore... waiting 2min before restarting logging"
        sleep 120
        setup
    fi
done
