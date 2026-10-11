package NodeUseCases {
    doc /* What people do with a sensor node: use cases with their actors, traced to the
         * requirements they lead to and carried out by actions. Open the diagram for the use case
         * view; simulate "readData" to step through it. */
    private import ScalarValues::*;

    part def SensorNode;
    part def Technician;
    part def Operator;
    item def Reading;

    use case def InstallNode {
        doc /* A technician mounts a node and brings it on line. */
        subject node : SensorNode;
        actor technician : Technician;
        objective { doc /* The node reports its first reading within a minute. */ }
    }

    use case def ReadData {
        doc /* An operator looks at the latest readings of a node. */
        subject node : SensorNode;
        actor operator : Operator;
    }

    use case def ReplaceBattery {
        subject node : SensorNode;
        actor technician : Technician;
    }

    part sensorNode : SensorNode;

    use case install : InstallNode {
        first start;
        then action mount;
        then action powerOn;
        then action pair;
        then include use case checkFirstReading : ReadData;
        then done;
    }

    use case readData : ReadData {
        first start;
        then action requestReading;
        then action waitForReading accept Reading;
        then action showReading;
        then done;
    }

    use case replaceBattery : ReplaceBattery {
        first start;
        then action openCase;
        then action swapCells;
        then include use case install2 : InstallNode;
        then done;
    }

    requirement def <'UC-1'> FirstReadingFast {
        doc /* After installation, the first reading arrives within 60 s. */
        subject node : SensorNode;
    }
    /* The use case leads to this requirement. */
    dependency from install to FirstReadingFast;
}
