# SystemState

 [![pipeline status](https://gitlab.sibgmbh.com/trio/mac-os/systemstate/badges/develop/pipeline.svg?ignore_skipped=true)](https://gitlab.sibgmbh.com/trio/mac-os/systemstate/-/commits/develop)
 [![coverage report](https://gitlab.sibgmbh.com/trio/mac-os/systemstate/badges/develop/coverage.svg)](https://gitlab.sibgmbh.com/trio/mac-os/systemstate/-/commits/develop)
 [![Latest Release](https://gitlab.sibgmbh.com/trio/mac-os/systemstate/-/badges/release.svg)](https://gitlab.sibgmbh.com/trio/mac-os/systemstate/-/releases)

![storage](./Assets/storage.png)
![memory](./Assets/memory.png)
![cpu](./Assets/cpu.png)
![battery](./Assets/battery.png)

macOS system monitor.
## Features
SystemState is an application that allows you to monitor your macOS system.

- [x] CPU utilization
- [x] Memory usage
- [x] Storage utilization
- [x] Battery level
- [x] Sensors information (Temperature, Voltage, Power)
- [x] Device info (os name, os version, memory type, GPU type, storage type, storage size, ...)
- [X] Network usage
- [ ] GPU utilization


## Installation

- File > Swift Packages > Add Package Dependency
- Add `https://gitlab.sibgmbh.com/trio/mac-os/systemstate.git`
- Select "Up to Next Major" with "0.1.0"

If you encounter any problem or have a question on adding the package to an Xcode project, I suggest reading the [Adding Package Dependencies](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app) to Your App guide article from Apple.

## Requirements
- macOS 12.0+ 
- Swift 5.8+

## Usage

### systemstate
```swift
import systemstate

// CPU information
let cpu = CPU()

/// - Returns: an object that include the ``CPULoad`` data
let cpuLoad: CPULoad = cpu.getCPULoad()

/// - Returns: a list of applications that have most used from CPU
let topProcess = cpu.getTopProcess()


/// - Returns: a number that shown temperature and a string that shown readable string
///     ``Double`` -> 23.0000
///     ``String`` ==> 23 ℃
let temperature = cpu.getTemperature()

//================================================================

// Battery information
let battery = Battery()

/// - Returns: a ``BatteryInfoModel`` that include ,
/// the ``BatteryInfoModel/level``, ``BatteryInfoModel/cycles``, and ``BatteryInfoModel/health``.
let batteryInfo: BatteryInfoModel = battery.getBatteryInfo()

/// - Returns: a ``TopProcess`` list of applications that have most use from Battery
let topProcess = battery.getTopProcess()

//================================================================

// DeviceInfo information

/// mac os name
let osName = DeviceInfo.osName

/// mac os version
let osFullVersion = DeviceInfo.osFullVersion

/// CPU Model
let cpuName = DeviceInfo.cpuName

/// Memory size
let memory = DeviceInfo.memory

/// GPU model
let gpu = DeviceInfo.gpu

/// Storage Model
let storageModel = DeviceInfo.storageModel

/// Storage size
let storageSize = DeviceInfo.storageSize

/// CPU Uptime
let uptime = DeviceInfo.uptime

/// CPU uptime with readable format
let uptimeDayHourMinuteFormat = DeviceInfo.uptimeDayHourMinuteFormat

/// Device serial number
let serialNumber = DeviceInfo.serialNumber

//================================================================

// Memory information
let memory = Memory()

/// - Returns: an object the shown memory information. ``MemoryUsage``
let memoryUsage: MemoryUsage = memory.getMemoryUsage()

/// - Returns: a list of application that most use the memory. 
let topProcess = memory.getTopProcess()

//================================================================

// Sensors information
let type: ModuleType = .Storage
let sensors = Sensors()

/// - Returns: a number shown the temperature, and a string that shown the temperature in user friendly format
let diskTemperature = sensors.getStorageTemperature().0 
let diskTemperatureWithFormat = sensors.getStorageTemperature().1

/// - Returns: a number shown the temperature, and a string that shown the temperature in user friendly format
let networkTemperature = sensors.getNetworkTemperature().0 
let networkTemperatureWithFormat = sensors.getNetworkTemperature().1

/// - Returns: a number shown the temperature, and a string that shown the temperature in user friendly format
let batteryTemperature = sensors.getBatteryTemperature().0 
let batteryTemperatureWithFormat = sensors.getBatteryTemperature().1

/// - Returns: a number shown the temperature, and a string that shown the temperature in user friendly format
let systemTemperature = sensors.getSystemTemperature().0 
let systemTemperatureWithFormat = sensors.getSystemTemperature().1

//================================================================

// Storage information
let storage = Storage()

/// - Returns: an ``StorageModel`` object that shown storage information.
let storageInfo: StorageModel = storage.getStorageInfo()

/// - Returns: a list of ``StorageProcess`` that shown which application most use the storage.
let topProcess = storage.topProcess()

/// - Returns: a readable string format for speed
let readSpeed = storage.getReadSpeed()

/// - Returns: a readable string format for speed
let writeSpeed = storage.getWriteSpeed()

//================================================================

// Network information
let network = NetworkInfo()

/// - Returns: an object the include the ``NetworkUsage`` information.
let networkInfo = network.getNetworkInfo()

/// - Return: an object the shown ``NetworkConnectivity`` information
let connectivity = network.getNetworkConnectivity()

/// - Returns: a number that shown network upload speed
let uploadSpeed = network.getUploadSpeed()

/// - Returns: a number that shown network download speed
let downloadSpeed = network.getDownloadSpeed()

/// - Returns: a list of ``NetworkProcess`` that shown which application use most from network.
let topProcess = network.getTopProcess()

```

### CPU
```swift
import CPU

// CPU information
let cpu = CPU()

/// - Returns: an object that include the ``CPULoad`` data
let cpuLoad: CPULoad = cpu.getCPULoad()

/// - Returns: a list of applications that have most used from CPU
let topProcess = cpu.getTopProcess()


/// - Returns: a number that shown temperature and a string that shown readable string
///     ``Double`` -> 23.0000
///     ``String`` ==> 23 ℃
let temperature = cpu.getTemperature()

```

### Battery
```swift
import Battery

// Battery information
let battery = Battery()

/// - Returns: a ``BatteryInfoModel`` that include  the ``BatteryInfoModel/level``, ``BatteryInfoModel/cycles``, and ``BatteryInfoModel/health``.
let batteryInfo: BatteryInfoModel = battery.getBatteryInfo()

/// - Returns: a ``TopProcess`` list of applications that have most use from Battery
let topProcess = battery.getTopProcess()

```

### DeviceInfo
```swift
import DeviceInfo

/// mac os name
let osName = DeviceInfo.osName

/// mac os version
let osFullVersion = DeviceInfo.osFullVersion

/// CPU Model
let cpuName = DeviceInfo.cpuName

/// Memory size
let memory = DeviceInfo.memory

/// GPU model
let gpu = DeviceInfo.gpu

/// Storage Model
let storageModel = DeviceInfo.storageModel

/// Storage size
let storageSize = DeviceInfo.storageSize

/// CPU Uptime
let uptime = DeviceInfo.uptime

/// CPU uptime with readable format
let uptimeDayHourMinuteFormat = DeviceInfo.uptimeDayHourMinuteFormat

/// Device serial number
let serialNumber = DeviceInfo.serialNumber

```

### Memory
```swift
import Memory

// Memory information
let memory = Memory()

/// - Returns: an object the shown memory information. ``MemoryUsage``
let memoryUsage: MemoryUsage = memory.getMemoryUsage()

/// - Returns: a list of application that most use the memory. 
let topProcess = memory.getTopProcess()

```

### Sensors
```swift
import Sensors

// Sensors information
let type: ModuleType = .Storage
let sensors = Sensors()

/// - Returns: a number shown the temperature, and a string that shown the temperature in user friendly format
let diskTemperature = sensors.getStorageTemperature().0 
let diskTemperatureWithFormat = sensors.getStorageTemperature().1

/// - Returns: a number shown the temperature, and a string that shown the temperature in user friendly format
let networkTemperature = sensors.getNetworkTemperature().0 
let networkTemperatureWithFormat = sensors.getNetworkTemperature().1

/// - Returns: a number shown the temperature, and a string that shown the temperature in user friendly format
let batteryTemperature = sensors.getBatteryTemperature().0 
let batteryTemperatureWithFormat = sensors.getBatteryTemperature().1

/// - Returns: a number shown the temperature, and a string that shown the temperature in user friendly format
let systemTemperature = sensors.getSystemTemperature().0 
let systemTemperatureWithFormat = sensors.getSystemTemperature().1
```

### Storage
```swift
import Storage

// Storage information
let storage = Storage()

/// - Returns: an ``StorageModel`` object that shown storage information.
let storageInfo: StorageModel = storage.getStorageInfo()

/// - Returns: a list of ``StorageProcess`` that shown which application most use the storage.
let topProcess = storage.topProcess()

/// - Returns: a readable string format for speed
let readSpeed = storage.getReadSpeed()

/// - Returns: a readable string format for speed
let writeSpeed = storage.getWriteSpeed()

```

### Network
```swift
import NetworkInfo

// Network information
let network = NetworkInfo()

/// - Returns: an object the include the ``NetworkUsage`` information.
let networkInfo = network.getNetworkInfo()

/// - Return: an object the shown ``NetworkConnectivity`` information
let connectivity = network.getNetworkConnectivity()

/// - Returns: a number that shown network upload speed
let uploadSpeed = network.getUploadSpeed()

/// - Returns: a number that shown network download speed
let downloadSpeed = network.getDownloadSpeed()

/// - Returns: a list of ``NetworkProcess`` that shown which application use most from network.
let topProcess = network.getTopProcess()

```
