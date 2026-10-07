// GOLD EXAMPLE — validated SysML v2 textual notation.
// Shows structure, ports/interfaces/flows, behavior (actions + states),
// requirements with satisfy, a calc, and a variation point in one small model.
package BatteryChargerModel {
	private import ScalarValues::*;
	private import ISQ::*;
	private import SI::*;

	doc /* Small DC battery charger used as a reference pattern. */

	// ---------- Items and signals ----------
	item def DCPower;
	attribute def PlugInSignal;
	attribute def UnplugSignal;
	attribute def FullSignal;

	enum def ChargeMode {
		enum trickle;
		enum bulk;
	}

	// ---------- Ports and interfaces ----------
	port def DCOutPort {
		out item dcPower : DCPower;
		attribute outVoltage : ElectricPotentialDifferenceValue;
	}

	interface def DCLink {
		end source : DCOutPort;
		end sink : ~DCOutPort;
		flow source.dcPower to sink.dcPower;
	}

	// ---------- Calculation ----------
	calc def ChargePower {
		in v : ElectricPotentialDifferenceValue;
		in i : ElectricCurrentValue;
		return : PowerValue = v * i;
	}

	// ---------- Part definitions ----------
	part def PowerSupply {
		port dcOut : DCOutPort;
		attribute ratedCurrent : ElectricCurrentValue;
	}

	part def Battery {
		port dcIn : ~DCOutPort;
		attribute capacity : ElectricChargeValue;
		attribute stateOfCharge : Real;
	}

	part def ChargeController {
		attribute mode : ChargeMode;
		attribute maxCurrent : ElectricCurrentValue;
	}

	part def Charger {
		part supply : PowerSupply;
		part controller : ChargeController;
		part battery : Battery;

		interface link : DCLink connect
			source ::> supply.dcOut to
			sink ::> battery.dcIn;

		attribute outputPower : PowerValue =
			ChargePower(supply.dcOut.outVoltage, controller.maxCurrent);

		exhibit state chargingStates : ChargingStates;
		perform action charge : ChargeBattery;
	}

	// ---------- Behavior: actions ----------
	action def MeasureVoltage { out v : ElectricPotentialDifferenceValue; }
	action def ApplyCurrent { in v : ElectricPotentialDifferenceValue; }
	action def StopCharging;

	action def ChargeBattery {
		first start;
		then merge loopBack;
		then action measure : MeasureVoltage;
		then decide;
			if measure.v < 4.2 [V] then apply;
			if measure.v >= 4.2 [V] then stop;

		action apply : ApplyCurrent {
			in v = measure.v;
		}
		then loopBack;

		action stop : StopCharging;
		then done;
	}

	// ---------- Behavior: states ----------
	state def ChargingStates {
		entry; then idle;

		state idle;
		accept PlugInSignal
			then charging;

		state charging {
			entry action startTimer;
			do action regulate;
			exit action logEnergy;
		}
		accept FullSignal
			then complete;
		accept UnplugSignal
			then idle;

		state complete;
		accept UnplugSignal
			then idle;
	}

	// ---------- Requirements ----------
	requirement def <'R1'> MaxChargeCurrent {
		doc /* The charger shall limit charge current to the specified maximum. */
		subject charger : Charger;
		attribute limit : ElectricCurrentValue;
		require constraint { charger.controller.maxCurrent <= limit }
	}

	requirement <'R1.1'> chargeCurrentLimit : MaxChargeCurrent {
		attribute :>> limit = 2 [A];
	}

	// ---------- Variability ----------
	variation part def SupplyChoices :> PowerSupply {
		variant part lowPower : PowerSupply {
			attribute :>> ratedCurrent = 1 [A];
		}
		variant part highPower : PowerSupply {
			attribute :>> ratedCurrent = 3 [A];
		}
	}

	// ---------- Configuration + satisfaction ----------
	part charger1 : Charger {
		part :>> supply : SupplyChoices = SupplyChoices::highPower;
		part :>> controller {
			attribute :>> maxCurrent = 2 [A];
			attribute :>> mode = ChargeMode::bulk;
		}
	}

	satisfy chargeCurrentLimit by charger1;
}
