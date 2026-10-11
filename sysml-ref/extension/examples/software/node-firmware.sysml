package NodeFirmware {
    doc /* The firmware of a sensor node: components and periodic tasks on its microcontroller,
         * the timing of its measurement cycle, and requirements on CPU load, deadlines, memory
         * and latency. The Software tab of the Simulation panel (Verify Requirements) shows the
         * schedule and the memory budget. */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Electronics::*;
    private import Software::*;

    part def SensorNode {
        part mcu : Microcontroller {
            :>> flash = 256 [KiB];
            :>> ram = 32 [KiB];

            part rtos : SoftwareComponent {
                :>> flash = 12 [KiB]; :>> ram = 2 [KiB];
                @Implements { file = "firmware/src/rtos_port.c"; }
            }
            part radioStack : SoftwareComponent { :>> flash = 96 [KiB]; :>> ram = 12 [KiB]; }
            part sensorDriver : SoftwareComponent {
                :>> flash = 4 [KiB]; :>> ram = 256 [B];
                @Implements { file = "firmware/src/tmp117.c"; symbol = "tmp117_read"; }
            }

            part gpioIsr : Task {
                doc /* Wake-up button; at most every 10 ms. */
                :>> period = 10 [ms]; :>> wcet = 50 ['µs']; :>> priority = 10; :>> stack = 256 [B];
            }
            part sampler : Task {
                :>> period = 100 [ms]; :>> wcet = 4 [ms]; :>> stack = 1 [KiB]; :>> flash = 2 [KiB];
                @Implements { file = "firmware/src/sampler.c"; symbol = "sampler_task"; }
            }
            part radioTask : Task { :>> period = 1 [s]; :>> wcet = 40 [ms]; :>> deadline = 200 [ms]; :>> stack = 4 [KiB]; }
            part watchdog : Task { :>> period = 500 [ms]; :>> wcet = 200 ['µs']; :>> stack = 512 [B]; }
        }

        action measurementCycle {
            first start;
            then action wake { @Timing { duration = 1 [ms]; } }
            then action sample { @Timing { duration = 4 [ms]; } }
            then fork split;
            then store;
            then transmit;
            action store { @Timing { duration = 2 [ms]; } }
            action transmit { @Timing { duration = 40 [ms]; } }
            join both;
            first store then both;
            first transmit then both;
            first both then sleep;
            action sleep { @Timing { duration = 0.5 [ms]; } }
            then done;
        }
    }

    part node : SensorNode;

    requirement def <'SW-1'> CpuHeadroom {
        doc /* The firmware leaves at least 30 % of the CPU free. */
        subject m : Microcontroller;
        require constraint { Utilization(m) <= 0.7 }
    }
    requirement def <'SW-2'> RadioDeadline {
        doc /* A radio packet is out within 200 ms of its release. */
        subject t : Task;
        require constraint { ResponseTime(t) <= 200 [ms] }
    }
    requirement def <'SW-3'> MemoryBudget {
        doc /* At least 25 % of flash and RAM stay free for updates. */
        subject m : Microcontroller;
        require constraint { FlashUsed(m) <= 0.75 * m.flash }
        require constraint { RamUsed(m) <= 0.75 * m.ram }
    }
    requirement def <'SW-4'> CycleLatency {
        doc /* A measurement is sent within 60 ms of waking up. */
        subject n : SensorNode;
        require constraint { Latency(n.measurementCycle) <= 60 [ms] }
    }

    requirement cpuHeadroom : CpuHeadroom { @VerifiedBy { file = "firmware/test/test_schedule.c"; test = "test_cpu_load"; } }
    requirement radioDeadline : RadioDeadline;
    requirement memoryBudget : MemoryBudget;
    requirement cycleLatency : CycleLatency { @VerifiedBy { file = "firmware/test/test_cycle.c"; } }
    satisfy cpuHeadroom by node.mcu;
    satisfy radioDeadline by node.mcu.radioTask;
    satisfy memoryBudget by node.mcu;
    satisfy cycleLatency by node;
}
