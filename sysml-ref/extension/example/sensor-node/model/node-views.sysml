package NodeViews {
    doc /* What each review of the EnviroNode looks at: a view per review, exposing the elements it needs. */
    private import NodeArchitecture::*;
    private import NodeRequirements::*;

    viewpoint def PowerReview {
        doc /* The hardware review: the power tree and the battery life. */
    }
    viewpoint def FirmwareReview {
        doc /* The firmware review: the MCU, its tasks and memory. */
    }

    view def PowerView { satisfy requirement : PowerReview; }
    view def FirmwareView { satisfy requirement : FirmwareReview; }

    view powerView : PowerView {
        expose node::battery;
        expose node::ldo;
        expose node::sensorLdo;
        expose nodeLifetime;
    }
    view firmwareView : FirmwareView {
        expose node::mcu;
        expose node::firmware::*;
    }
}
