/**
 * ============================================================================
 * Smart Campus Resource & Lab Booking System (Version 2.0)
 * File: nosql/mongo_demo.js
 * Description: MongoDB NoSQL Extension for Semi-Structured Maintenance & Inspection Logs
 * Author: Person B (Teammate B) - Analytics & NoSQL Specialist
 * 
 * Execution:
 *   mongosh nosql/mongo_demo.js
 *   OR in MongoDB Compass / mongosh:
 *   use smart_campus_nosql;
 *   load("nosql/mongo_demo.js");
 * ============================================================================
 */

// Switch / create database
db = db.getSiblingDB("smart_campus_nosql");

print("============================================================================");
print("1. INITIALIZING & CLEANING UP COLLECTIONS");
print("============================================================================");

db.maintenance_reports.drop();
print("Dropped existing 'maintenance_reports' collection.");

print("\n============================================================================");
print("2. INSERTING 15 SEMI-STRUCTURED MAINTENANCE & INSPECTION DOCUMENTS");
print("============================================================================");

const maintenanceDocuments = [
  {
    report_id: "MR-2026-001",
    resource_id: 1,
    resource_code: "GPU-DGX-01",
    equipment_name: "NVIDIA DGX Station A100-01",
    category: "GPU Computing Server",
    severity: "Low",
    status: "Completed",
    inspection_date: new Date("2026-11-15T13:00:00Z"),
    technician: {
      name: "Ramesh Yadav",
      staff_id: "TECH-09",
      certification: "NVIDIA Certified Enterprise IT Specialist"
    },
    sensor_telemetry: {
      peak_gpu_temp_celsius: 72.4,
      fan_rpm: 3800,
      power_draw_watts: 420,
      liquid_cooling_pressure_psi: 14.8
    },
    checklist: [
      { check_item: "Liquid coolant transparency and level", passed: true, notes: "Coolant level topped up with low-conductivity fluid." },
      { check_item: "PCIe 4.0 bus link integrity check", passed: true, notes: "All 8 links operating at Gen4 x16." },
      { check_item: "Dust radiator fin cleaning", passed: true, notes: "De-dusted with filtered compressed air." }
    ],
    parts_replaced: [
      { part_name: "De-ionized Coolant Fluid (1L)", part_code: "COOL-DGX-1", unit_cost: 65.00, quantity: 1 }
    ],
    total_cost_usd: 125.00,
    downtime_hours: 6.0,
    next_inspection_date: new Date("2027-02-15T00:00:00Z")
  },
  {
    report_id: "MR-2026-002",
    resource_id: 4,
    resource_code: "GPU-RTX-02",
    equipment_name: "RTX 4090 Deep Learning Rig 2",
    category: "GPU Computing Server",
    severity: "High",
    status: "In_Progress",
    inspection_date: new Date("2026-11-20T10:00:00Z"),
    technician: {
      name: "Ramesh Yadav",
      staff_id: "TECH-09",
      certification: "Hardware & Server Diagnostics Specialist"
    },
    sensor_telemetry: {
      peak_gpu_temp_celsius: 94.2,
      thermal_throttling_events: 18,
      fan_rpm: 4900,
      power_draw_watts: 480
    },
    checklist: [
      { check_item: "GPU 2 Thermal Junction Temperature", passed: false, notes: "Exceeding 94C under moderate load; thermal paste degradation observed." },
      { check_item: "PCIe Riser Gold Finger Contact", passed: false, notes: "Micro-corrosion on PCIe riser gold contacts causing bus speed drop to x4." },
      { check_item: "Case intake filters", passed: true, notes: "Cleaned." }
    ],
    parts_replaced: [
      { part_name: "Thermal Grizzly Kryonaut Extreme 2g", part_code: "TG-KE-2G", unit_cost: 32.50, quantity: 1 },
      { part_name: "Linkup Shielded PCIe 4.0 Riser Cable", part_code: "LU-PCIE4-25", unit_cost: 78.00, quantity: 1 }
    ],
    total_cost_usd: 195.50,
    downtime_hours: 14.5,
    next_inspection_date: new Date("2026-12-20T00:00:00Z")
  },
  {
    report_id: "MR-2026-003",
    resource_id: 11,
    resource_code: "ROB-UR5-01",
    equipment_name: "Universal Robots UR5e Cobot Arm",
    category: "Robotic Arm Kit",
    severity: "Medium",
    status: "Completed",
    inspection_date: new Date("2026-11-10T09:30:00Z"),
    technician: {
      name: "Ganesh Patil",
      staff_id: "TECH-11",
      certification: "Universal Robots Core Certified Trainer"
    },
    sensor_telemetry: {
      joint_3_temperature_c: 48.0,
      repeatability_deviation_mm: 0.04,
      payload_test_kg: 5.0,
      safety_stop_latency_ms: 220
    },
    checklist: [
      { check_item: "ISO 10218-1 Safety Stop circuit test", passed: true, notes: "Triggered emergency stop verified within 250ms spec." },
      { check_item: "Joint harmonic drive gear grease", passed: true, notes: "Replaced degraded lubricating grease." },
      { check_item: "Teach Pendant capacitive touchscreen calibration", passed: true, notes: "Recalibrated." }
    ],
    parts_replaced: [
      { part_name: "Harmonic Drive Synthetic Grease 250g", part_code: "HD-SYN-25", unit_cost: 85.00, quantity: 1 }
    ],
    total_cost_usd: 180.00,
    downtime_hours: 8.5,
    next_inspection_date: new Date("2027-05-10T00:00:00Z")
  },
  {
    report_id: "MR-2026-004",
    resource_id: 12,
    resource_code: "ROB-KUK-01",
    equipment_name: "KUKA KR4 Agilus Robotic Arm",
    category: "Robotic Arm Kit",
    severity: "Critical",
    status: "In_Progress",
    inspection_date: new Date("2026-11-21T14:00:00Z"),
    technician: {
      name: "Ganesh Patil",
      staff_id: "TECH-11",
      certification: "Industrial Robotics Master Certified"
    },
    sensor_telemetry: {
      axis_4_backlash_arcmin: 8.5,
      motor_encoder_jitter_hz: 62.0,
      controller_voltage_drop: 1.8
    },
    checklist: [
      { check_item: "Axis 4 Gearbox backlash measurement", passed: false, notes: "Backlash exceeds 3 arcmin maximum manufacturer tolerance." },
      { check_item: "Absolute encoder optical glass disk", passed: true, notes: "Clean, no scratches." },
      { check_item: "KRC4 Controller safety bus communication", passed: true, notes: "EtherCAT bus stable." }
    ],
    parts_replaced: [
      { part_name: "KUKA Precision Harmonic Drive Gear Unit Axis 4", part_code: "KUK-AX4-HD", unit_cost: 850.00, quantity: 1 },
      { part_name: "Rotary Encoder Dust Seal Ring", part_code: "KUK-SEAL-04", unit_cost: 45.00, quantity: 2 }
    ],
    total_cost_usd: 1140.00,
    downtime_hours: 28.0,
    next_inspection_date: new Date("2026-12-05T00:00:00Z")
  },
  {
    report_id: "MR-2026-005",
    resource_id: 5,
    resource_code: "PRN-3D-01",
    equipment_name: "Ultimaker S5 Pro 3D Printer",
    category: "3D Printer & Rapid Prototyper",
    severity: "Low",
    status: "Open",
    inspection_date: new Date("2026-11-28T09:00:00Z"),
    technician: {
      name: "Suresh Babu",
      staff_id: "TECH-10",
      certification: "Additive Manufacturing Guild Certified"
    },
    sensor_telemetry: {
      print_head_hours: 1420.5,
      build_plate_temp_uniformity_sigma: 1.2,
      feeder_motor_steps_lost: 0
    },
    checklist: [
      { check_item: "Print core AA 0.4mm nozzle wear check", passed: true, notes: "Minor abrasive carbon fiber wear." },
      { check_item: "XY belt tension frequency tuning", passed: true, notes: "Tuned to 78Hz standard using acoustic sensor." },
      { check_item: "Material Station dehumidifier desiccant silica", passed: true, notes: "Regeneration scheduled." }
    ],
    parts_replaced: [
      { part_name: "Ultimaker Print Core CC 0.6mm Ruby Nozzle", part_code: "UM-PCC-06", unit_cost: 110.00, quantity: 1 }
    ],
    total_cost_usd: 145.00,
    downtime_hours: 3.0,
    next_inspection_date: new Date("2027-01-28T00:00:00Z")
  },
  {
    report_id: "MR-2026-006",
    resource_id: 6,
    resource_code: "PRN-3D-02",
    equipment_name: "Formlabs Form 3+ SLA Printer",
    category: "3D Printer & Rapid Prototyper",
    severity: "Medium",
    status: "Completed",
    inspection_date: new Date("2026-11-04T11:00:00Z"),
    technician: {
      name: "Suresh Babu",
      staff_id: "TECH-10",
      certification: "Stereolithography Optics Specialist"
    },
    sensor_telemetry: {
      laser_power_mw: 248.5,
      galvanometer_drift_urad: 12.0,
      resin_tank_cycles: 42
    },
    checklist: [
      { check_item: "405nm Violet Laser Power meter test", passed: true, notes: "Measured 248.5mW (Spec: 250mW +/- 5mW)." },
      { check_item: "Light Processing Unit (LPU) Anti-reflective glass", passed: true, notes: "Cleaned with optical isopropanol." },
      { check_item: "Resin Tank optical film clarity", passed: false, notes: "Clouding detected on central region; replaced tank." }
    ],
    parts_replaced: [
      { part_name: "Formlabs Form 3 Resin Tank V2.1", part_code: "RT-F3-02", unit_cost: 149.00, quantity: 1 }
    ],
    total_cost_usd: 189.00,
    downtime_hours: 5.0,
    next_inspection_date: new Date("2027-02-04T00:00:00Z")
  },
  {
    report_id: "MR-2026-007",
    resource_id: 8,
    resource_code: "SCP-MSO-01",
    equipment_name: "Tektronix MSO 1GHz Scope Bench A",
    category: "High-End Digital Oscilloscope",
    severity: "Low",
    status: "Open",
    inspection_date: new Date("2026-11-29T10:00:00Z"),
    technician: {
      name: "Suresh Babu",
      staff_id: "TECH-10",
      certification: "NIST Traceable Metrology Calibration Tech"
    },
    sensor_telemetry: {
      internal_reference_drift_ppm: 0.8,
      channel_1_snr_db: 62.4,
      trigger_jitter_ps: 45
    },
    checklist: [
      { check_item: "10MHz Clock Reference synchronization", passed: true, notes: "Verified with GPS-disciplined oscillator." },
      { check_item: "Probe Compensation calibration 1kHz", passed: true, notes: "All 4 active probes trimmed." }
    ],
    parts_replaced: [],
    total_cost_usd: 60.00,
    downtime_hours: 2.0,
    next_inspection_date: new Date("2027-11-29T00:00:00Z")
  },
  {
    report_id: "MR-2026-008",
    resource_id: 10,
    resource_code: "SCP-KEY-01",
    equipment_name: "Keysight Infiniium 4-CH Scope",
    category: "High-End Digital Oscilloscope",
    severity: "Medium",
    status: "Completed",
    inspection_date: new Date("2026-11-18T10:00:00Z"),
    technician: {
      name: "Suresh Babu",
      staff_id: "TECH-10",
      certification: "NIST Traceable Metrology Calibration Tech"
    },
    sensor_telemetry: {
      channel_2_offset_mv: 14.2,
      adc_enob_bits: 9.8,
      cooling_exhaust_temp_c: 41.5
    },
    checklist: [
      { check_item: "Channel 2 BNC input impedance", passed: false, notes: "High contact resistance on BNC center pin due to student over-torque." },
      { check_item: "Internal self-calibration routine", passed: true, notes: "Passed after BNC pin restoration." }
    ],
    parts_replaced: [
      { part_name: "Keysight Precision BNC Front Receptacle", part_code: "KS-BNC-50", unit_cost: 95.00, quantity: 1 }
    ],
    total_cost_usd: 155.00,
    downtime_hours: 4.5,
    next_inspection_date: new Date("2027-05-18T00:00:00Z")
  },
  {
    report_id: "MR-2026-009",
    resource_id: 14,
    resource_code: "AV-BAR-01",
    equipment_name: "Barco 4K Laser Projection Alpha",
    category: "Smart Conference Audio/Video",
    severity: "Low",
    status: "Completed",
    inspection_date: new Date("2026-11-03T08:00:00Z"),
    technician: {
      name: "Ramesh Yadav",
      staff_id: "TECH-09",
      certification: "AVIXA CTS Certified Audio Visual Specialist"
    },
    sensor_telemetry: {
      laser_diode_bank_hours: 3240,
      lumen_output_ansi: 11800,
      color_gamut_coverage_dci_p3: 98.2
    },
    checklist: [
      { check_item: "High-efficiency electrostatic intake filter", passed: true, notes: "Replaced dirty filter module." },
      { check_item: "Optical keystone and motorized lens shift", passed: true, notes: "Recalibrated." },
      { check_item: "HDMI 2.1 EDID handshake test", passed: true, notes: "4K 60Hz HDR verified." }
    ],
    parts_replaced: [
      { part_name: "Barco Electrostatic Intake Filter Dual Pack", part_code: "BAR-FILT-02", unit_cost: 75.00, quantity: 1 }
    ],
    total_cost_usd: 110.00,
    downtime_hours: 3.5,
    next_inspection_date: new Date("2027-02-03T00:00:00Z")
  },
  {
    report_id: "MR-2026-010",
    resource_id: 17,
    resource_code: "VR-QST-01",
    equipment_name: "Meta Quest Pro Enterprise Rig 01",
    category: "VR / AR Headset Station",
    severity: "Low",
    status: "Completed",
    inspection_date: new Date("2026-11-19T14:00:00Z"),
    technician: {
      name: "Ramesh Yadav",
      staff_id: "TECH-09",
      certification: "Consumer Electronics & VR Systems Tech"
    },
    sensor_telemetry: {
      battery_health_capacity_pct: 94.0,
      inside_out_camera_latency_ms: 11.2,
      ipd_motor_travel_smoothness: "Nominal"
    },
    checklist: [
      { check_item: "Pancake lens optical surface scratch check", passed: true, notes: "Pristine; anti-fog coating refreshed." },
      { check_item: "Touch Pro controller tracking cameras", passed: true, notes: "Firmware updated." }
    ],
    parts_replaced: [
      { part_name: "Silicone Medical-Grade Facial Interface Pad", part_code: "MQ-FACE-SIL", unit_cost: 35.00, quantity: 1 }
    ],
    total_cost_usd: 55.00,
    downtime_hours: 2.0,
    next_inspection_date: new Date("2027-02-19T00:00:00Z")
  },
  {
    report_id: "MR-2026-011",
    resource_id: 20,
    resource_code: "CNC-LPK-01",
    equipment_name: "LPKF ProtoMat S64 PCB Milling Unit",
    category: "PCB Prototyping Milling Machine",
    severity: "High",
    status: "Completed",
    inspection_date: new Date("2026-11-08T11:00:00Z"),
    technician: {
      name: "Suresh Babu",
      staff_id: "TECH-10",
      certification: "CNC Machine Tools & Precision Spindle Tech"
    },
    sensor_telemetry: {
      spindle_rpm_max: 60000,
      runout_total_indicated_reading_um: 1.5,
      vacuum_table_suction_mbar: -820
    },
    checklist: [
      { check_item: "High-frequency spindle collet concentricity", passed: true, notes: "Runout within 2 microns acceptable limit." },
      { check_item: "HEPA vacuum dust extraction suction", passed: false, notes: "Airflow restricted due to saturated secondary cartridge." }
    ],
    parts_replaced: [
      { part_name: "HEPA Dust Collector Filter Cartridge H13", part_code: "LPKF-HEPA-13", unit_cost: 115.00, quantity: 1 },
      { part_name: "Precision 1/8 inch Ceramic Hybrid Tool Collet", part_code: "LPKF-COL-18", unit_cost: 130.00, quantity: 1 }
    ],
    total_cost_usd: 310.00,
    downtime_hours: 7.0,
    next_inspection_date: new Date("2027-03-08T00:00:00Z")
  },
  {
    report_id: "MR-2026-012",
    resource_id: 23,
    resource_code: "UAV-DJI-01",
    equipment_name: "DJI Matrice 300 RTK Flight Rig",
    category: "Drone / UAV Development Rig",
    severity: "Medium",
    status: "Completed",
    inspection_date: new Date("2026-11-14T09:00:00Z"),
    technician: {
      name: "Ganesh Patil",
      staff_id: "TECH-11",
      certification: "DGCA Certified Drone Maintenance Specialist"
    },
    sensor_telemetry: {
      tb60_battery_cycle_count: 38,
      rtk_positional_accuracy_cm: 1.8,
      tof_obstacle_sensor_latency_ms: 14.5
    },
    checklist: [
      { check_item: "Carbon fiber propeller leading edge", passed: false, notes: "Minor chip on propeller #3 tip; replaced pair." },
      { check_item: "RTK D-RTK 2 base station radio link", passed: true, notes: "915MHz telemetry link strong." }
    ],
    parts_replaced: [
      { part_name: "DJI 2110 High-Altitude Propeller CW/CCW Pair", part_code: "DJI-M300-PROP", unit_cost: 80.00, quantity: 1 }
    ],
    total_cost_usd: 140.00,
    downtime_hours: 4.0,
    next_inspection_date: new Date("2027-02-14T00:00:00Z")
  },
  {
    report_id: "MR-2026-013",
    resource_id: 2,
    resource_code: "GPU-DGX-02",
    equipment_name: "NVIDIA DGX Station A100-02",
    category: "GPU Computing Server",
    severity: "Low",
    status: "Open",
    inspection_date: new Date("2026-11-30T08:00:00Z"),
    technician: {
      name: "Ramesh Yadav",
      staff_id: "TECH-09",
      certification: "NVIDIA Certified Enterprise IT Specialist"
    },
    sensor_telemetry: {
      peak_gpu_temp_celsius: 69.8,
      fan_rpm: 3400,
      power_draw_watts: 395
    },
    checklist: [
      { check_item: "Ubuntu 22.04 LTS OS & Kernel patch level", passed: true, notes: "Ready for NVIDIA Container Toolkit update." },
      { check_item: "InfiniBand / 100GbE NIC link check", passed: true, notes: "Verified." }
    ],
    parts_replaced: [],
    total_cost_usd: 50.00,
    downtime_hours: 2.0,
    next_inspection_date: new Date("2027-02-28T00:00:00Z")
  },
  {
    report_id: "MR-2026-014",
    resource_id: 15,
    resource_code: "AV-CHR-01",
    equipment_name: "Christie Digital Cinema Projector",
    category: "Smart Conference Audio/Video",
    severity: "Critical",
    status: "Completed",
    inspection_date: new Date("2026-11-12T09:00:00Z"),
    technician: {
      name: "Ramesh Yadav",
      staff_id: "TECH-09",
      certification: "AVIXA CTS Certified Audio Visual Specialist"
    },
    sensor_telemetry: {
      laser_chamber_temp_c: 64.0,
      cooling_flow_rate_lpm: 3.2,
      power_supply_ripple_mv: 45
    },
    checklist: [
      { check_item: "Laser ballast power supply voltage stability", passed: true, notes: "Adjusted output regulator to steady 48V DC." },
      { check_item: "Liquid chiller radiator fan relay", passed: false, notes: "Relay contacts pitted; replaced solid state relay." }
    ],
    parts_replaced: [
      { part_name: "Crydom Solid State Relay 50A 240VAC", part_code: "SSR-50A-CRY", unit_cost: 120.00, quantity: 1 },
      { part_name: "Chiller De-ionizing Filter Cartridge", part_code: "CHR-DI-01", unit_cost: 95.00, quantity: 1 }
    ],
    total_cost_usd: 315.00,
    downtime_hours: 7.5,
    next_inspection_date: new Date("2027-05-12T00:00:00Z")
  },
  {
    report_id: "MR-2026-015",
    resource_id: 7,
    resource_code: "PRN-3D-03",
    equipment_name: "Markforged Onyx Pro Carbon Printer",
    category: "3D Printer & Rapid Prototyper",
    severity: "Low",
    status: "Completed",
    inspection_date: new Date("2026-11-02T10:00:00Z"),
    technician: {
      name: "Suresh Babu",
      staff_id: "TECH-10",
      certification: "Additive Manufacturing Guild Certified"
    },
    sensor_telemetry: {
      fiber_extruder_pressure_kpa: 310,
      bed_level_optical_sensor_mv: 4200,
      total_filament_extruded_meters: 840
    },
    checklist: [
      { check_item: "Continuous Fiberglass strand feed mechanism", passed: true, notes: "Feed roller tension verified." },
      { check_item: "Hardened steel Onyx composite nozzle gap", passed: true, notes: "Calibrated to 100 microns." }
    ],
    parts_replaced: [
      { part_name: "Markforged Hardened Tool Steel Nozzle V2", part_code: "MF-NZL-HTS", unit_cost: 85.00, quantity: 1 }
    ],
    total_cost_usd: 120.00,
    downtime_hours: 3.5,
    next_inspection_date: new Date("2027-02-02T00:00:00Z")
  }
];

const insertResult = db.maintenance_reports.insertMany(maintenanceDocuments);
print(`Successfully inserted ${insertResult.insertedIds ? Object.keys(insertResult.insertedIds).length : 15} documents into 'maintenance_reports'.`);

print("\n============================================================================");
print("3. CRUD OPERATIONS DEMONSTRATION");
print("============================================================================");

// --- READ 1: Active / Critical Incidents ---
print("\n>>> READ 1: Active High or Critical severity maintenance reports (In_Progress / Open):");
const activeHighSeverity = db.maintenance_reports.find(
  {
    severity: { $in: ["High", "Critical"] },
    status: { $in: ["In_Progress", "Open"] }
  },
  { report_id: 1, resource_code: 1, equipment_name: 1, severity: 1, status: 1, total_cost_usd: 1, "technician.name": 1 }
).toArray();
printjson(activeHighSeverity);

// --- READ 2: Expensive Reports (> $200) ---
print("\n>>> READ 2: High-Expense Reports (total_cost_usd > 200.00):");
const highCostReports = db.maintenance_reports.find(
  { total_cost_usd: { $gt: 200.00 } },
  { report_id: 1, resource_code: 1, equipment_name: 1, category: 1, total_cost_usd: 1, parts_replaced: 1 }
).toArray();
printjson(highCostReports);

// --- UPDATE ---
print("\n>>> UPDATE: Transitioning MR-2026-002 to 'Completed' and adding stress benchmark:");
const updateResult = db.maintenance_reports.updateOne(
  { report_id: "MR-2026-002" },
  {
    $set: {
      status: "Completed",
      completed_at: new Date("2026-11-22T18:00:00Z"),
      "sensor_telemetry.peak_gpu_temp_celsius": 68.5,
      "sensor_telemetry.thermal_throttling_events": 0
    },
    $push: {
      checklist: {
        check_item: "Post-repair 4-hour FurMark GPU stress benchmark",
        passed: true,
        notes: "Passed stress benchmark with zero thermal throttling."
      }
    }
  }
);
print(`Matched: ${updateResult.matchedCount}, Modified: ${updateResult.modifiedCount}`);

// --- DELETE ---
print("\n>>> DELETE: Temporary test report removal:");
db.maintenance_reports.insertOne({
  report_id: "TEMP-DEL-999",
  equipment_name: "Obsolete Test Breadboard",
  status: "Retired",
  total_cost_usd: 0.00
});
const delResult = db.maintenance_reports.deleteOne({ report_id: "TEMP-DEL-999" });
print(`Deleted temporary document 'TEMP-DEL-999'. Acknowledged: ${delResult.acknowledged}, DeletedCount: ${delResult.deletedCount}`);

print("\n============================================================================");
print("4. MONGODB AGGREGATION PIPELINE ($group): Category Maintenance Cost & Downtime Analysis");
print("============================================================================");

const categoryAnalysisPipeline = [
  {
    $match: {
      total_cost_usd: { $gt: 0 }
    }
  },
  {
    $group: {
      _id: "$category",
      total_incident_count: { $sum: 1 },
      total_maintenance_expenditure_usd: { $sum: "$total_cost_usd" },
      avg_maintenance_cost_usd: { $avg: "$total_cost_usd" },
      total_downtime_hours: { $sum: "$downtime_hours" },
      avg_downtime_hours: { $avg: "$downtime_hours" },
      high_critical_incidents: {
        $sum: {
          $cond: [{ $in: ["$severity", ["High", "Critical"]] }, 1, 0]
        }
      }
    }
  },
  {
    $project: {
      _id: 0,
      equipment_category: "$_id",
      total_incident_count: 1,
      total_maintenance_expenditure_usd: { $round: ["$total_maintenance_expenditure_usd", 2] },
      avg_maintenance_cost_usd: { $round: ["$avg_maintenance_cost_usd", 2] },
      total_downtime_hours: { $round: ["$total_downtime_hours", 1] },
      avg_downtime_hours: { $round: ["$avg_downtime_hours", 1] },
      high_critical_incidents: 1
    }
  },
  {
    $sort: { total_maintenance_expenditure_usd: -1 }
  }
];

const aggregationResults = db.maintenance_reports.aggregate(categoryAnalysisPipeline).toArray();
print(">>> AGGREGATION OUTPUT ($group by category):");
printjson(aggregationResults);

print("\n============================================================================");
print("NOSQL SCRIPT EXECUTION COMPLETED SUCCESSFULLY");
print("============================================================================");
