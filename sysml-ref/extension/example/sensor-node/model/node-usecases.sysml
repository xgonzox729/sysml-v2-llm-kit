package NodeUseCases {
    doc
    /*
     * What people do with an EnviroNode: use cases with their actors. They lead to requirements
     * (dependencies) and are carried out by actions, so they can be stepped through.
     */
    private import NodeArchitecture::*;
    private import NodeRequirements::*;
    private import NodeIcd::Reading;

    part def Technician;
    part def Operator;

    use case def InstallNode {
        doc /* A technician mounts a node and brings it on line. */
        subject node : EnviroNode;
        actor technician : Technician;
        objective { doc /* The first reading arrives within a minute. */ }
    }

    use case def ReadData {
        doc /* An operator looks at a node's latest readings. */
        subject node : EnviroNode;
        actor operator : Operator;
    }

    use case def ReplaceCell {
        doc /* A technician replaces a flat cell. */
        subject node : EnviroNode;
        actor technician : Technician;
    }

    use case install : InstallNode {
        first start;
        then action mount;
        then action insertCell;
        then action joinNetwork;
        then include use case firstReading : ReadData;
        then done;
    }

    use case readData : ReadData {
        first start;
        then action requestReading;
        then action waitForReading accept Reading;
        then action showReading;
        then done;
    }

    use case replaceCell : ReplaceCell {
        first start;
        then action openEnclosure;
        then action swapCell;
        then include use case reinstall : InstallNode;
        then done;
    }

    /* The lifetime requirement comes from how often cells can be replaced. */
    dependency from replaceCell to NodeLifetime;
}
