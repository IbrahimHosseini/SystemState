//
//  File.swift
//  
//
//  Created by Ibrahim on 3/18/24.
//

import Foundation
import SystemKit

let HIDSensorsList: [SensorModel] = [
    SensorModel(key: "pACC MTR Temp Sensor%", name: "CPU performance core %", group: .CPU, type: .temperature, platforms: Platform.all),
    SensorModel(key: "eACC MTR Temp Sensor%", name: "CPU efficiency core %", group: .CPU, type: .temperature, platforms: Platform.all),
    
    SensorModel(key: "GPU MTR Temp Sensor%", name: "GPU core %", group: .GPU, type: .temperature, platforms: Platform.all),
    SensorModel(key: "SOC MTR Temp Sensor%", name: "SOC core %", group: .sensor, type: .temperature, platforms: Platform.all),
    SensorModel(key: "ANE MTR Temp Sensor%", name: "Neural engine %", group: .sensor, type: .temperature, platforms: Platform.all),
    SensorModel(key: "ISP MTR Temp Sensor%", name: "Image Signal Processor %", group: .sensor, type: .temperature, platforms: Platform.all),
    
    SensorModel(key: "PMGR SOC Die Temp Sensor%", name: "Power manager die %", group: .sensor, type: .temperature, platforms: Platform.all),
    SensorModel(key: "PMU tdev%", name: "Power management unit dev %", group: .sensor, type: .temperature, platforms: Platform.all),
    SensorModel(key: "PMU tdie%", name: "Power management unit die %", group: .sensor, type: .temperature, platforms: Platform.all),
    
    SensorModel(key: "gas gauge battery", name: "Battery", group: .sensor, type: .temperature, platforms: Platform.all),
    SensorModel(key: "NAND CH% temp", name: "Disk %s", group: .GPU, type: .temperature, platforms: Platform.all)
]


// List of keys: https://github.com/acidanthera/VirtualSMC/blob/master/Docs/SMCSensorKeys.txt
let SensorsList: [SensorModel] = [
    // Temperature
    SensorModel(key: "TA%P", name: "Ambient %", group: .sensor, type: .temperature, platforms: Platform.all),
    SensorModel(key: "Th%H", name: "Heatpipe %", group: .sensor, type: .temperature, platforms: [.intel]),
    SensorModel(key: "TZ%C", name: "Thermal zone %", group: .sensor, type: .temperature, platforms: Platform.all),
    
    SensorModel(key: "TC0D", name: "CPU diode", group: .CPU, type: .temperature, platforms: Platform.all),
    SensorModel(key: "TC0E", name: "CPU diode virtual", group: .CPU, type: .temperature, platforms: Platform.all),
    SensorModel(key: "TC0F", name: "CPU diode filtered", group: .CPU, type: .temperature, platforms: Platform.all),
    SensorModel(key: "TC0H", name: "CPU heatsink", group: .CPU, type: .temperature, platforms: Platform.all),
    SensorModel(key: "TC0P", name: "CPU proximity", group: .CPU, type: .temperature, platforms: Platform.all),
    SensorModel(key: "TCAD", name: "CPU package", group: .CPU, type: .temperature, platforms: Platform.all),
    
    SensorModel(key: "TC%c", name: "CPU core %", group: .CPU, type: .temperature, platforms: Platform.all, average: true),
    SensorModel(key: "TC%C", name: "CPU Core %", group: .CPU, type: .temperature, platforms: Platform.all, average: true),
    
    SensorModel(key: "TCGC", name: "GPU Intel Graphics", group: .GPU, type: .temperature, platforms: Platform.all),
    SensorModel(key: "TG0D", name: "GPU diode", group: .GPU, type: .temperature, platforms: Platform.all),
    SensorModel(key: "TGDD", name: "GPU AMD Radeon", group: .GPU, type: .temperature, platforms: Platform.all),
    SensorModel(key: "TG0H", name: "GPU heatsink", group: .GPU, type: .temperature, platforms: Platform.all),
    SensorModel(key: "TG0P", name: "GPU proximity", group: .GPU, type: .temperature, platforms: Platform.all),
    
    SensorModel(key: "Tm0P", name: "Mainboard", group: .system, type: .temperature, platforms: Platform.all),
    SensorModel(key: "Tp0P", name: "Powerboard", group: .system, type: .temperature, platforms: [.intel]),
    SensorModel(key: "TB1T", name: "Battery", group: .system, type: .temperature, platforms: [.intel]),
    SensorModel(key: "TW0P", name: "Airport", group: .system, type: .temperature, platforms: Platform.all),
    SensorModel(key: "TL0P", name: "Display", group: .system, type: .temperature, platforms: Platform.all),
    SensorModel(key: "TI%P", name: "Thunderbolt %", group: .system, type: .temperature, platforms: Platform.all),
    SensorModel(key: "TH%A", name: "Disk % (A)", group: .system, type: .temperature, platforms: Platform.all),
    SensorModel(key: "TH%B", name: "Disk % (B)", group: .system, type: .temperature, platforms: Platform.all),
    SensorModel(key: "TH%C", name: "Disk % (C)", group: .system, type: .temperature, platforms: Platform.all),
    
    SensorModel(key: "TTLD", name: "Thunderbolt left", group: .system, type: .temperature, platforms: Platform.all),
    SensorModel(key: "TTRD", name: "Thunderbolt right", group: .system, type: .temperature, platforms: Platform.all),
    
    SensorModel(key: "TN0D", name: "Northbridge diode", group: .system, type: .temperature, platforms: Platform.all),
    SensorModel(key: "TN0H", name: "Northbridge heatsink", group: .system, type: .temperature, platforms: Platform.all),
    SensorModel(key: "TN0P", name: "Northbridge proximity", group: .system, type: .temperature, platforms: Platform.all),
    
    // Apple Silicon
    SensorModel(key: "Tp09", name: "CPU efficiency core 1", group: .CPU, type: .temperature, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra], average: true),
    SensorModel(key: "Tp0T", name: "CPU efficiency core 2", group: .CPU, type: .temperature, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra], average: true),
    SensorModel(key: "Tp01", name: "CPU performance core 1", group: .CPU, type: .temperature, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra], average: true),
    SensorModel(key: "Tp05", name: "CPU performance core 2", group: .CPU, type: .temperature, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra], average: true),
    SensorModel(key: "Tp0D", name: "CPU performance core 3", group: .CPU, type: .temperature, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra], average: true),
    SensorModel(key: "Tp0H", name: "CPU performance core 4", group: .CPU, type: .temperature, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra], average: true),
    SensorModel(key: "Tp0L", name: "CPU performance core 5", group: .CPU, type: .temperature, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra], average: true),
    SensorModel(key: "Tp0P", name: "CPU performance core 6", group: .CPU, type: .temperature, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra], average: true),
    SensorModel(key: "Tp0X", name: "CPU performance core 7", group: .CPU, type: .temperature, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra], average: true),
    SensorModel(key: "Tp0b", name: "CPU performance core 8", group: .CPU, type: .temperature, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra], average: true),
    
    SensorModel(key: "Tg05", name: "GPU 1", group: .GPU, type: .temperature, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra], average: true),
    SensorModel(key: "Tg0D", name: "GPU 2", group: .GPU, type: .temperature, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra], average: true),
    SensorModel(key: "Tg0L", name: "GPU 3", group: .GPU, type: .temperature, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra], average: true),
    SensorModel(key: "Tg0T", name: "GPU 4", group: .GPU, type: .temperature, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra], average: true),
    
    SensorModel(key: "Tm02", name: "Memory 1", group: .sensor, type: .temperature, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra]),
    SensorModel(key: "Tm06", name: "Memory 2", group: .sensor, type: .temperature, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra]),
    SensorModel(key: "Tm08", name: "Memory 3", group: .sensor, type: .temperature, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra]),
    SensorModel(key: "Tm09", name: "Memory 4", group: .sensor, type: .temperature, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra]),
    
    // M2
    SensorModel(key: "Tp1h", name: "CPU efficiency core 1", group: .CPU, type: .temperature, platforms: [.m2, .m2Max, .m2Pro, .m2Ultra], average: true),
    SensorModel(key: "Tp1t", name: "CPU efficiency core 2", group: .CPU, type: .temperature, platforms: [.m2, .m2Max, .m2Pro, .m2Ultra], average: true),
    SensorModel(key: "Tp1p", name: "CPU efficiency core 3", group: .CPU, type: .temperature, platforms: [.m2, .m2Max, .m2Pro, .m2Ultra], average: true),
    SensorModel(key: "Tp1l", name: "CPU efficiency core 4", group: .CPU, type: .temperature, platforms: [.m2, .m2Max, .m2Pro, .m2Ultra], average: true),
       
    SensorModel(key: "Tp01", name: "CPU performance core 1", group: .CPU, type: .temperature, platforms: [.m2, .m2Max, .m2Pro, .m2Ultra], average: true),
    SensorModel(key: "Tp05", name: "CPU performance core 2", group: .CPU, type: .temperature, platforms: [.m2, .m2Max, .m2Pro, .m2Ultra], average: true),
    SensorModel(key: "Tp09", name: "CPU performance core 3", group: .CPU, type: .temperature, platforms: [.m2, .m2Max, .m2Pro, .m2Ultra], average: true),
    SensorModel(key: "Tp0D", name: "CPU performance core 4", group: .CPU, type: .temperature, platforms: [.m2, .m2Max, .m2Pro, .m2Ultra], average: true),
    SensorModel(key: "Tp0X", name: "CPU performance core 5", group: .CPU, type: .temperature, platforms: [.m2, .m2Max, .m2Pro, .m2Ultra], average: true),
    SensorModel(key: "Tp0b", name: "CPU performance core 6", group: .CPU, type: .temperature, platforms: [.m2, .m2Max, .m2Pro, .m2Ultra], average: true),
    SensorModel(key: "Tp0f", name: "CPU performance core 7", group: .CPU, type: .temperature, platforms: [.m2, .m2Max, .m2Pro, .m2Ultra], average: true),
    SensorModel(key: "Tp0j", name: "CPU performance core 8", group: .CPU, type: .temperature, platforms: [.m2, .m2Max, .m2Pro, .m2Ultra], average: true),
    
    SensorModel(key: "Tg0f", name: "GPU 1", group: .GPU, type: .temperature, platforms: [.m2, .m2Max, .m2Pro, .m2Ultra], average: true),
    SensorModel(key: "Tg0j", name: "GPU 2", group: .GPU, type: .temperature, platforms: [.m2, .m2Max, .m2Pro, .m2Ultra], average: true),
    
    // M3
    SensorModel(key: "Te05", name: "CPU efficiency core 1", group: .CPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Te0L", name: "CPU efficiency core 2", group: .CPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Te0P", name: "CPU efficiency core 3", group: .CPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Te0S", name: "CPU efficiency core 4", group: .CPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    
    SensorModel(key: "Tf04", name: "CPU performance core 1", group: .CPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Tf09", name: "CPU performance core 2", group: .CPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Tf0A", name: "CPU performance core 3", group: .CPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Tf0B", name: "CPU performance core 4", group: .CPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Tf0D", name: "CPU performance core 5", group: .CPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Tf0E", name: "CPU performance core 6", group: .CPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Tf44", name: "CPU performance core 7", group: .CPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Tf49", name: "CPU performance core 8", group: .CPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Tf4A", name: "CPU performance core 9", group: .CPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Tf4B", name: "CPU performance core 10", group: .CPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Tf4D", name: "CPU performance core 11", group: .CPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Tf4E", name: "CPU performance core 12", group: .CPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    
    SensorModel(key: "Tf14", name: "GPU 1", group: .GPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Tf18", name: "GPU 2", group: .GPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Tf19", name: "GPU 3", group: .GPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Tf1A", name: "GPU 4", group: .GPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Tf24", name: "GPU 5", group: .GPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Tf28", name: "GPU 6", group: .GPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Tf29", name: "GPU 7", group: .GPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    SensorModel(key: "Tf2A", name: "GPU 8", group: .GPU, type: .temperature, platforms: [.m3, .m3Max, .m3Pro, .m3Ultra], average: true),
    
    SensorModel(key: "TaLP", name: "Airflow left", group: .sensor, type: .temperature, platforms: Platform.apple),
    SensorModel(key: "TaRF", name: "Airflow right", group: .sensor, type: .temperature, platforms: Platform.apple),
    
    SensorModel(key: "TH0x", name: "NAND", group: .system, type: .temperature, platforms: Platform.apple),
    SensorModel(key: "TB1T", name: "Battery 1", group: .system, type: .temperature, platforms: Platform.apple),
    SensorModel(key: "TB2T", name: "Battery 2", group: .system, type: .temperature, platforms: Platform.apple),
    SensorModel(key: "TW0P", name: "Airport", group: .system, type: .temperature, platforms: Platform.apple),
    
    // Voltage
    SensorModel(key: "VCAC", name: "CPU IA", group: .CPU, type: .voltage, platforms: Platform.all),
    SensorModel(key: "VCSC", name: "CPU System Agent", group: .CPU, type: .voltage, platforms: Platform.all),
    SensorModel(key: "VC%C", name: "CPU Core %", group: .CPU, type: .voltage, platforms: Platform.all),
    
    SensorModel(key: "VCTC", name: "GPU Intel Graphics", group: .GPU, type: .voltage, platforms: Platform.all),
    SensorModel(key: "VG0C", name: "GPU", group: .GPU, type: .voltage, platforms: Platform.all),
    
    SensorModel(key: "VM0R", name: "Memory", group: .system, type: .voltage, platforms: Platform.all),
    SensorModel(key: "Vb0R", name: "CMOS", group: .system, type: .voltage, platforms: Platform.all),
    
    SensorModel(key: "VD0R", name: "DC In", group: .sensor, type: .voltage, platforms: Platform.all),
    SensorModel(key: "VP0R", name: "12V rail", group: .sensor, type: .voltage, platforms: Platform.all),
    SensorModel(key: "Vp0C", name: "12V vcc", group: .sensor, type: .voltage, platforms: Platform.all),
    SensorModel(key: "VV2S", name: "3V", group: .sensor, type: .voltage, platforms: Platform.all),
    SensorModel(key: "VR3R", name: "3.3V", group: .sensor, type: .voltage, platforms: Platform.all),
    SensorModel(key: "VV1S", name: "5V", group: .sensor, type: .voltage, platforms: Platform.all),
    SensorModel(key: "VV9S", name: "12V", group: .sensor, type: .voltage, platforms: Platform.all),
    SensorModel(key: "VeES", name: "PCI 12V", group: .sensor, type: .voltage, platforms: Platform.all),
    
    // Current
    SensorModel(key: "IC0R", name: "CPU High side", group: .sensor, type: .current, platforms: Platform.all),
    SensorModel(key: "IG0R", name: "GPU High side", group: .sensor, type: .current, platforms: Platform.all),
    SensorModel(key: "ID0R", name: "DC In", group: .sensor, type: .current, platforms: Platform.all),
    SensorModel(key: "IBAC", name: "Battery", group: .sensor, type: .current, platforms: Platform.all),
    
    // Power
    SensorModel(key: "PC0C", name: "CPU Core", group: .CPU, type: .power, platforms: Platform.all),
    SensorModel(key: "PCAM", name: "CPU Core (IMON)", group: .CPU, type: .power, platforms: Platform.all),
    SensorModel(key: "PCPC", name: "CPU Package", group: .CPU, type: .power, platforms: Platform.all),
    SensorModel(key: "PCTR", name: "CPU Total", group: .CPU, type: .power, platforms: Platform.all),
    SensorModel(key: "PCPT", name: "CPU Package total", group: .CPU, type: .power, platforms: Platform.all),
    SensorModel(key: "PCPR", name: "CPU Package total (SMC)", group: .CPU, type: .power, platforms: Platform.all),
    SensorModel(key: "PC0R", name: "CPU Computing high side", group: .CPU, type: .power, platforms: Platform.all),
    SensorModel(key: "PC0G", name: "CPU GFX", group: .CPU, type: .power, platforms: Platform.all),
    SensorModel(key: "PCEC", name: "CPU VccEDRAM", group: .CPU, type: .power, platforms: Platform.all),
    
    SensorModel(key: "PCPG", name: "GPU Intel Graphics", group: .GPU, type: .power, platforms: Platform.all),
    SensorModel(key: "PG0R", name: "GPU", group: .GPU, type: .power, platforms: Platform.all),
    SensorModel(key: "PCGC", name: "Intel GPU", group: .GPU, type: .power, platforms: Platform.all),
    SensorModel(key: "PCGM", name: "Intel GPU (IMON)", group: .GPU, type: .power, platforms: Platform.all),
    
    SensorModel(key: "PC3C", name: "RAM", group: .sensor, type: .power, platforms: Platform.all),
    SensorModel(key: "PPBR", name: "Battery", group: .sensor, type: .power, platforms: Platform.all),
    SensorModel(key: "PDTR", name: "DC In", group: .sensor, type: .power, platforms: Platform.all),
    SensorModel(key: "PSTR", name: "System Total", group: .sensor, type: .power, platforms: Platform.all),
    
    SensorModel(key: "PDBR", name: "Power Delivery Brightness", group: .sensor, type: .power, platforms: [.m1, .m1Pro, .m1Max, .m1Ultra])
]
