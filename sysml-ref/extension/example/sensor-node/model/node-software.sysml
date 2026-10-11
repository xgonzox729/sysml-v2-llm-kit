package NodeSoftware {
    doc
    /*
     * The EnviroNode's firmware: its components and tasks on the microcontroller, what they
     * cost in flash, RAM and CPU time, and the software requirements. Paths in @Implements and
     * @VerifiedBy are relative to this file.
     */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Electronics::*;
    private import Software::*;
    private import NodeArchitecture::*;

    part def NodeFirmware {
        doc /* Everything that runs on the MCU. */
        part rtos : SoftwareComponent {
            :>> flash = 12 [KiB]; :>> ram = 2 [KiB];
            @Implements { file = "../firmware/src/rtos_port.c"; }
        }
        part loraStack : SoftwareComponent { :>> flash = 96 [KiB]; :>> ram = 8 [KiB]; }
        part sensorDriver : SoftwareComponent {
            :>> flash = 4 [KiB]; :>> ram = 256 [B];
            @Implements { file = "../firmware/src/tmp117.c"; symbol = "tmp117_read"; }
        }

        part wakeIsr : Task {
            doc /* The wake-up interrupt; at most every 10 ms. */
            :>> period = 10 [ms]; :>> wcet = 50 ['µs']; :>> priority = 10; :>> stack = 256 [B];
        }
        part sampler : Task {
            :>> period = 100 [ms]; :>> wcet = 4 [ms]; :>> stack = 1 [KiB]; :>> flash = 2 [KiB];
            @Implements { file = "../firmware/src/sampler.c"; symbol = "sampler_task"; }
        }
        part radioTask : Task {
            :>> period = 1 [s]; :>> wcet = 40 [ms]; :>> deadline = 200 [ms]; :>> stack = 2 [KiB];
            @Implements { file = "../firmware/src/radio.c"; symbol = "radio_task"; }
        }
        part watchdog : Task { :>> period = 500 [ms]; :>> wcet = 200 ['µs']; :>> stack = 512 [B]; }
    }

    requirement def <'SW-1'> CpuHeadroom {
        doc /* The firmware leaves at least 30 % of the CPU free. */
        subject m : Microcontroller;
        require constraint { Utilization(m) <= 0.7 }
    }
    requirement def <'SW-2'> RadioDeadline {
        doc /* A reading is on its way to the radio within 200 ms of its release. */
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
        subject n : EnviroNode;
        require constraint { Latency(n.measurementCycle) <= 60 [ms] }
    }

    requirement cpuHeadroom : CpuHeadroom { @VerifiedBy { file = "../firmware/test/test_schedule.c"; test = "test_cpu_load"; } }
    requirement radioDeadline : RadioDeadline;
    requirement memoryBudget : MemoryBudget;
    requirement cycleLatency : CycleLatency { @VerifiedBy { file = "../firmware/test/test_cycle.c"; test = "test_cycle_latency"; } }
    satisfy cpuHeadroom by node.mcu;
    satisfy radioDeadline by node.firmware.radioTask;
    satisfy memoryBudget by node.mcu;
    satisfy cycleLatency by node;
}
