class DeviceKeywords {
  static const List<String> electronicKeywords = [
    'phone', 'smartphone', 'iphone', 'android', 'samsung', 'laptop', 'computer',
    'monitor', 'tv', 'television', 'screen', 'tablet', 'ipad', 'keyboard', 'mouse',
    'printer', 'scanner', 'camera', 'headphone', 'earphone', 'speaker', 'microphone',
    'charger', 'adapter', 'cable', 'battery', 'electronic', 'device', 'gadget',
    'appliance', 'console', 'playstation', 'xbox', 'nintendo', 'wii', 'router',
    'modem', 'cpu', 'processor', 'circuit', 'board', 'motherboard', 'hard drive',
    'ssd', 'memory', 'ram'
  ];

  static bool isElectronicDevice(String item) {
    return electronicKeywords.any((keyword) => item.toLowerCase().contains(keyword));
  }
}
